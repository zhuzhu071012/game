extends Node
class_name TurnManager

# 回合管理器：按照固定顺序结算常驻槽位、事件、隐患与终局。
# 主循环能否跑通，核心就在这个文件里。

const GOVERNANCE_WRIT_CHANCE_XUN_YU: float = 0.80
const GOVERNANCE_WRIT_CHANCE_DEFAULT: float = 0.20
const GOVERNANCE_FIRST_WRIT_BONUS: int = 1
const RESEARCH_STRONG_THRESHOLD: int = 16
const RESEARCH_BASIC_THRESHOLD: int = 13
const RECRUIT_CHARACTER_THRESHOLD: int = 13
const RECRUIT_RESOURCE_THRESHOLD: int = 9

signal turn_finished

var _result_presentations: Array = []

func consume_result_presentations() -> Array:
	var payloads: Array = _result_presentations.duplicate(true)
	_result_presentations.clear()
	return payloads

func _clear_result_presentations() -> void:
	_result_presentations.clear()

func _snapshot_reward_state(run_state: RunState) -> Dictionary:
	return {
		"resources": run_state.resource_states.duplicate(true),
		"roster": run_state.roster_ids.duplicate(true)
	}

func _collect_result_rewards(before_state: Dictionary, run_state: RunState) -> Array:
	var rewards: Array = []
	var before_roster: Array = before_state.get("roster", []) as Array
	for character_id_variant in run_state.roster_ids:
		var character_id: String = str(character_id_variant)
		if not before_roster.has(character_id):
			rewards.append({
				"card_type": "character",
				"id": character_id,
				"amount": 1
			})
	var before_resources: Dictionary = before_state.get("resources", {}) as Dictionary
	for resource_id_variant in run_state.resource_states.keys():
		var resource_id: String = str(resource_id_variant)
		var delta: int = int(run_state.resource_states.get(resource_id, 0)) - int(before_resources.get(resource_id, 0))
		if delta > 0:
			rewards.append({
				"card_type": "resource",
				"id": resource_id,
				"amount": delta
			})
	return rewards

func _append_result_presentation_from_state(before_state: Dictionary, run_state: RunState, source_kind: String, source_id: String, title: String, logs: Array, extra: Dictionary = {}) -> void:
	var rewards: Array = _collect_result_rewards(before_state, run_state)
	var lines: Array[String] = []
	for log_variant in logs:
		var line: String = str(log_variant).strip_edges()
		if not line.is_empty():
			lines.append(line)
	if rewards.is_empty() and lines.is_empty():
		return
	var payload: Dictionary = {
		"source_kind": source_kind,
		"source_id": source_id,
		"title": title,
		"body": "\n\n".join(lines),
		"rewards": rewards
	}
	for key_variant in extra.keys():
		payload[str(key_variant)] = extra[key_variant]
	_result_presentations.append(payload)

func resolve_turn(run_state: RunState, board_manager: BoardManager, event_manager: EventManager, relation_manager: RelationManager, characters: Dictionary, resources: Dictionary, tutorial_manager = null, story_event_manager = null) -> Array[String]:
	_clear_result_presentations()
	if tutorial_manager != null and tutorial_manager.is_active(run_state):
		var tutorial_step_before: int = tutorial_manager.current_step(run_state)
		var reward_snapshot: Dictionary = _snapshot_reward_state(run_state)
		_clear_result_presentations()
		var tutorial_logs: Array[String] = tutorial_manager.resolve_turn(run_state, board_manager, event_manager, relation_manager, characters, resources)
		var tutorial_rewards: Array = _collect_result_rewards(reward_snapshot, run_state)
		if not tutorial_rewards.is_empty():
			var tutorial_result_title: String = tutorial_manager.report_title(run_state)
			if tutorial_result_title.strip_edges().is_empty():
				tutorial_result_title = TextDB.get_text("tutorial.steps.step_%d.title" % tutorial_step_before, "Tutorial Step %d" % tutorial_step_before)
			_append_result_presentation_from_state(
				reward_snapshot,
				run_state,
				"tutorial",
				"step_%d" % tutorial_step_before,
				tutorial_result_title,
				tutorial_logs
			)
		board_manager.reset_turn_targets(run_state.active_event_ids)
		run_state.log_entries.append_array(tutorial_logs)
		emit_signal("turn_finished")
		return tutorial_logs
	var logs: Array[String] = []
	var risk_defs: Dictionary = GameData.create_risks()
	logs.append(TextDB.format_text("logs.turn.start", [run_state.turn_index]))
	logs.append_array(_resolve_slots(run_state, board_manager, relation_manager, characters))
	logs.append_array(GameRules.check_immediate_risk_endings(run_state, risk_defs))
	if run_state.game_over:
		return _finish_run(run_state, board_manager, logs)
	for event_id_variant in run_state.active_event_ids.duplicate():
		var event_id: String = str(event_id_variant)
		var event_cards: Array = board_manager.get_event_cards(event_id)
		var reward_snapshot: Dictionary = _snapshot_reward_state(run_state)
		var event_state: Dictionary = run_state.active_event_states.get(event_id, {}) as Dictionary
		if bool(event_state.get("story_event", false)) and story_event_manager != null:
			var story_result: Dictionary = story_event_manager.resolve_board_event(run_state, event_id, event_cards, characters, resources)
			var story_logs: Array[String] = []
			for line_variant in story_result.get("logs", []) as Array:
				story_logs.append(str(line_variant))
			logs.append_array(story_logs)
			var presentation_lines: Array[String] = []
			for line_variant in story_result.get("presentation_lines", []) as Array:
				presentation_lines.append(str(line_variant))
			_append_result_presentation_from_state(
				reward_snapshot,
				run_state,
				"event",
				event_id,
				str(story_result.get("title", story_event_manager.event_title(event_id))),
				presentation_lines,
				{"dice": (story_result.get("dice", {}) as Dictionary).duplicate(true)}
			)
		else:
			var event_logs: Array[String] = event_manager.resolve_event(run_state, event_id, event_cards, relation_manager, characters, resources)
			logs.append_array(event_logs)
			var event: EventData = event_manager.event_defs.get(event_id) as EventData
			var event_title: String = event.title if event != null else event_id
			_append_result_presentation_from_state(reward_snapshot, run_state, "event", event_id, event_title, event_logs)
		logs.append_array(GameRules.check_immediate_risk_endings(run_state, risk_defs))
		if run_state.game_over:
			return _finish_run(run_state, board_manager, logs)
	logs.append_array(_consume_committed_resources(run_state, board_manager, resources))
	logs.append_array(event_manager.advance_unresolved_events(run_state, relation_manager))
	if story_event_manager != null:
		for expired_variant in story_event_manager.advance_unresolved_board_events(run_state):
			var expired: Dictionary = expired_variant as Dictionary
			var expired_logs: Array[String] = []
			for line_variant in expired.get("logs", []) as Array:
				expired_logs.append(str(line_variant))
			logs.append_array(expired_logs)
			var body_lines: Array[String] = []
			for line_variant in expired.get("presentation_lines", []) as Array:
				body_lines.append(str(line_variant))
			if not expired_logs.is_empty() or not body_lines.is_empty():
				_result_presentations.append({
					"source_kind": "event",
					"source_id": str(expired.get("event_id", "")),
					"title": str(expired.get("title", "")),
					"body": "\n\n".join(body_lines),
					"rewards": []
				})
	logs.append_array(GameRules.check_immediate_risk_endings(run_state, risk_defs))
	if run_state.game_over:
		return _finish_run(run_state, board_manager, logs)
	logs.append_array(relation_manager.resolve_personal_lines(run_state))
	_sync_pressure_flags(run_state)
	if int(run_state.risk_states.get("headwind", 0)) > 0:
		run_state.flags["first_headwind_seen"] = true
	_sync_risk_flags(run_state)
	logs.append_array(GameRules.apply_risk_penalties(run_state, risk_defs))
	GameRules.clamp_stats(run_state)
	if run_state.game_over:
		return _finish_run(run_state, board_manager, logs)
	if bool(run_state.flags.get("force_conclusion", false)):
		run_state.flags["force_conclusion"] = false
		GameRules.conclude_run_by_time(run_state, characters)
		return _finish_run(run_state, board_manager, logs)
	if run_state.turn_index >= GameRules.playable_turns():
		GameRules.conclude_run_by_time(run_state, characters)
		return _finish_run(run_state, board_manager, logs)
	run_state.turn_index += 1
	run_state.stage_index = GameRules.stage_for_turn(run_state.turn_index)
	var spawned: Array[String] = event_manager.spawn_events_for_turn(run_state)
	for event_id_variant in spawned:
		var event_id: String = str(event_id_variant)
		var event: EventData = event_manager.event_defs[event_id] as EventData
		logs.append(TextDB.format_text("logs.turn.spawned", [event.title]))
	board_manager.reset_turn_targets(run_state.active_event_ids)
	run_state.log_entries.append_array(logs)
	emit_signal("turn_finished")
	return logs

func _finish_run(run_state: RunState, board_manager: BoardManager, logs: Array[String]) -> Array[String]:
	run_state.turn_index = GameRules.settlement_turn()
	run_state.stage_index = GameRules.stage_for_turn(GameRules.playable_turns())
	if not run_state.ending_id.is_empty():
		logs.append(TextDB.format_text("logs.turn.final", [run_state.ending_id]))
	board_manager.reset_turn_targets([])
	run_state.log_entries.append_array(logs)
	emit_signal("turn_finished")
	return logs

func _resolve_slots(run_state: RunState, board_manager: BoardManager, relation_manager: RelationManager, characters: Dictionary) -> Array[String]:
	var logs: Array[String] = []
	for slot_id in GameRules.SLOT_RESOLUTION_ORDER:
		var cards: Array = board_manager.get_slot_cards(slot_id)
		var reward_snapshot: Dictionary = _snapshot_reward_state(run_state)
		var slot_logs: Array[String] = []
		match slot_id:
			"governance":
				slot_logs = _resolve_governance(run_state, cards, relation_manager, characters)
			"audience":
				slot_logs = _resolve_audience(run_state, cards, relation_manager, characters)
			"research":
				slot_logs = _resolve_research(run_state, cards, relation_manager, characters)
			"recruit":
				slot_logs = _resolve_recruit(run_state, cards, relation_manager, characters)
			"rest":
				slot_logs = _resolve_rest(run_state, cards, relation_manager, characters)
		logs.append_array(slot_logs)
		_append_result_presentation_from_state(reward_snapshot, run_state, "slot", slot_id, TextDB.get_text("system.slots.%s.title" % slot_id, slot_id), slot_logs)
	return logs

func _resolve_governance(run_state: RunState, cards: Array, relation_manager: RelationManager, characters: Dictionary) -> Array[String]:
	var logs: Array[String] = []
	var character_ids: Array[String] = _character_ids_from_cards(cards)
	if character_ids.is_empty():
		return logs
	var primary_id: String = character_ids[0]
	var support_id: String = character_ids[1] if character_ids.size() > 1 else ""
	if character_ids.has("cao_cao"):
		run_state.flags["last_cao_governance_turn"] = run_state.turn_index
	var roll_value: int = GameRules.roll_2d6()
	var total_score: float = _pair_slot_total(run_state, primary_id, support_id, "governance", characters) + float(roll_value)
	var silver_gain: int = maxi(0, int(floor(total_score / 7.0)))
	var treasury_gain: int = silver_gain * 3
	if primary_id == "cao_cao":
		silver_gain += 1
		treasury_gain += 2
		run_state.cao_mind -= 1
		_set_character_track(run_state, "cao_cao", "mental_state", run_state.cao_mind)
	if silver_gain > 0:
		_gain_resource(run_state, "silver_pack", silver_gain)
	run_state.money += treasury_gain
	match primary_id:
		"cao_cao":
			if total_score >= 13.0:
				run_state.morale += 1
			logs.append(TextDB.get_text("logs.slots.governance.cao_cao"))
		"xun_yu":
			run_state.jingzhou_stability += 1 + int(total_score >= 12.0)
			logs.append(TextDB.get_text("logs.slots.governance.xun_yu"))
		"zhang_liao":
			run_state.morale += 1 + int(total_score >= 12.0)
			logs.append(TextDB.get_text("logs.slots.governance.zhang_liao"))
		"yu_jin":
			run_state.jingzhou_stability += 1
			run_state.morale += int(total_score >= 12.0)
			logs.append(TextDB.get_text("logs.slots.governance.yu_jin"))
		"cao_pi":
			run_state.money += 1
			logs.append(TextDB.get_text("logs.slots.governance.cao_pi"))
		_:
			logs.append(TextDB.get_text("logs.slots.governance.other"))
	if not primary_id.is_empty() and primary_id != "cao_cao":
		_apply_favor_progression(run_state, relation_manager, primary_id, 1, false)
	if not support_id.is_empty() and support_id != "cao_cao":
		_apply_favor_progression(run_state, relation_manager, support_id, 1, false)
	var writ_chance: float = GOVERNANCE_WRIT_CHANCE_XUN_YU if primary_id == "xun_yu" else GOVERNANCE_WRIT_CHANCE_DEFAULT
	if randf() <= writ_chance:
		_gain_resource(run_state, "recruit_writ", 1)
	if not bool(run_state.flags.get("first_governance_done", false)):
		run_state.flags["first_governance_done"] = true
		_gain_resource(run_state, "sealed_letter", 1)
		_gain_resource(run_state, "recruit_writ", GOVERNANCE_FIRST_WRIT_BONUS)
		logs.append(TextDB.get_text("logs.slots.governance.first"))
	return logs

func _resolve_audience(run_state: RunState, cards: Array, relation_manager: RelationManager, characters: Dictionary) -> Array[String]:
	var logs: Array[String] = []
	var character_ids: Array[String] = _character_ids_from_cards(cards)
	if character_ids.is_empty():
		return logs
	var risk_ids: Array[String] = _risk_ids_from_cards(cards)
	var silver_count: int = _resource_count(cards, "silver_pack")
	var gift_count: int = _resource_count_any(cards, ["gift", "sanjian_dao"])
	var letter_count: int = _resource_count_any(cards, ["sealed_letter", "yecheng_letter"])
	var communal_aid_count: int = _resource_count(cards, "communal_aid")
	if not risk_ids.is_empty():
		var primary_id: String = character_ids[0]
		var support_id: String = character_ids[1] if character_ids.size() > 1 else ""
		var risk_id: String = risk_ids[0]
		if risk_id not in ["rumor", "alienation"]:
			return logs
		var risk_roll: int = GameRules.roll_2d6()
		var aid_bonus: int = communal_aid_count * 3 if risk_id == "alienation" else 0
		var risk_total: int = int(floor(_pair_slot_total(run_state, primary_id, support_id, "audience", characters))) + risk_roll + aid_bonus
		if risk_total > 15:
			var reduction: int = 1 + (communal_aid_count if risk_id == "alienation" else 0)
			var before_risk: int = int(run_state.risk_states.get(risk_id, 0))
			run_state.risk_states[risk_id] = maxi(0, before_risk - reduction)
			logs.append(TextDB.get_text("logs.slots.audience.success"))
			if risk_id == "alienation" and communal_aid_count > 0 and before_risk > int(run_state.risk_states.get(risk_id, 0)):
				logs.append(TextDB.get_text("logs.slots.audience.communal_aid"))
		else:
			if risk_total <= 8:
				run_state.risk_states[risk_id] = int(run_state.risk_states.get(risk_id, 0)) + 1
			logs.append(TextDB.get_text("logs.slots.audience.misfire"))
		return logs
	if character_ids.has("cao_cao") and character_ids.size() >= 2:
		var partner_id: String = ""
		for character_id in character_ids:
			if character_id != "cao_cao":
				partner_id = character_id
				break
		if partner_id.is_empty():
			return logs
		var roll_value: int = GameRules.roll_2d6()
		var total_score: int = int(floor(_pair_slot_total(run_state, "cao_cao", partner_id, "audience", characters))) + roll_value + silver_count + gift_count * 3 + letter_count * 2
		if total_score > 11:
			var favor_gain: int = 1 + int(total_score >= 18) + int(gift_count > 0)
			_apply_favor_progression(run_state, relation_manager, partner_id, favor_gain)
			if gift_count > 0 or letter_count > 0:
				relation_manager.add_rumor_risk(run_state, partner_id, -1)
			if silver_count > 0 and total_score >= 16:
				run_state.morale += 1
			if communal_aid_count > 0 and int(run_state.risk_states.get("alienation", 0)) > 0:
				run_state.risk_states["alienation"] = maxi(0, int(run_state.risk_states.get("alienation", 0)) - communal_aid_count)
				logs.append(TextDB.get_text("logs.slots.audience.communal_aid"))
			logs.append(TextDB.get_text("logs.slots.audience.success"))
			if gift_count > 0:
				logs.append(TextDB.get_text("logs.slots.audience.gift"))
		else:
			relation_manager.add_rumor_risk(run_state, partner_id, 1)
			run_state.risk_states["rumor"] = int(run_state.risk_states.get("rumor", 0)) + 1
			logs.append(TextDB.get_text("logs.slots.audience.misfire"))
		return logs
	return logs

func _resolve_research(run_state: RunState, cards: Array, relation_manager: RelationManager, characters: Dictionary) -> Array[String]:
	var logs: Array[String] = []
	var character_ids: Array[String] = _character_ids_from_cards(cards)
	if character_ids.is_empty():
		return logs
	var primary_id: String = character_ids[0]
	var support_id: String = character_ids[1] if character_ids.size() > 1 else ""
	var roll_value: int = GameRules.roll_2d6()
	var total_score: int = int(floor(_pair_slot_total(run_state, primary_id, support_id, "research", characters))) + roll_value + _research_resource_bonus(cards) + _research_event_bonus(cards)
	if total_score >= RESEARCH_STRONG_THRESHOLD:
		var reward_id: String = _pick_research_reward(cards, character_ids, characters, true)
		_gain_resource(run_state, reward_id, 1)
		if reward_id == "naval_chart":
			run_state.naval_readiness += 1
			run_state.flags["east_wind_event_established"] = true
		if reward_id in ["spy_report", "sealed_letter"]:
			run_state.flags["scheme_counter_ready"] = true
		logs.append(TextDB.get_text("logs.slots.research.discovery"))
	elif total_score >= RESEARCH_BASIC_THRESHOLD:
		var basic_reward_id: String = _pick_research_reward(cards, character_ids, characters, false)
		_gain_resource(run_state, basic_reward_id, 1)
		if basic_reward_id in ["spy_report", "sealed_letter"]:
			run_state.flags["scheme_counter_ready"] = true
		logs.append(TextDB.get_text("logs.slots.research.discovery"))
	else:
		logs.append(TextDB.get_text("logs.slots.research.routine"))
	for character_id in character_ids:
		if character_id != "cao_cao":
			_apply_favor_progression(run_state, relation_manager, character_id, 1)
	return logs

func _resolve_recruit(run_state: RunState, cards: Array, relation_manager: RelationManager, characters: Dictionary) -> Array[String]:
	var logs: Array[String] = []
	var character_ids: Array[String] = _character_ids_from_cards(cards)
	if character_ids.is_empty():
		if not cards.is_empty():
			logs.append(TextDB.get_text("logs.slots.recruit.failed"))
		return logs
	var primary_id: String = character_ids[0]
	var support_id: String = character_ids[1] if character_ids.size() > 1 else ""
	var silver_count: int = _resource_count(cards, "silver_pack")
	var writ_count: int = _resource_count(cards, "recruit_writ")
	var roll_value: int = GameRules.roll_2d6()
	var total_score: int = int(floor(_pair_slot_total(run_state, primary_id, support_id, "recruit", characters))) + roll_value + silver_count * 2 + writ_count * 3 + _recruit_resource_bonus(cards)
	var has_search: bool = _has_any_specialty(character_ids, ["search"], characters)
	var has_negotiation: bool = _has_any_specialty(character_ids, ["negotiation"], characters)
	var has_medical: bool = _has_any_specialty(character_ids, ["medical"], characters)
	var extra_help: bool = has_search or has_negotiation
	if silver_count <= 0:
		logs.append(TextDB.get_text("logs.slots.recruit.failed"))
		return logs
	var recruit_threshold: int = RECRUIT_CHARACTER_THRESHOLD - int(has_negotiation)
	if writ_count > 0 and total_score >= recruit_threshold and not run_state.locked_character_ids.is_empty():
		logs.append_array(_grant_recruit_character(run_state, relation_manager, characters, extra_help))
		return logs
	if total_score >= RECRUIT_RESOURCE_THRESHOLD:
		if total_score >= recruit_threshold or has_search or has_negotiation or has_medical:
			logs.append_array(_grant_recruit_resource(run_state, has_search, has_negotiation, has_medical))
		else:
			logs.append_array(_grant_recruit_clue(run_state, extra_help))
	else:
		logs.append(TextDB.get_text("logs.slots.recruit.failed"))
	return logs

func _resolve_rest(run_state: RunState, cards: Array, relation_manager: RelationManager, characters: Dictionary) -> Array[String]:
	var logs: Array[String] = []
	var character_ids: Array[String] = _character_ids_from_cards(cards)
	if character_ids.is_empty():
		return logs
	var target_id: String = character_ids[0]
	var support_id: String = character_ids[1] if character_ids.size() > 1 else ""
	if not support_id.is_empty() and _character_has_specialty(target_id, "medical", characters) and not _character_has_specialty(support_id, "medical", characters):
		target_id = support_id
		support_id = character_ids[0]
	var silver_count: int = _resource_count(cards, "silver_pack")
	var herb_count: int = _resource_count(cards, "herbal_tonic")
	var xiaoyao_count: int = _resource_count(cards, "calming_incense")
	var risk_ids: Array[String] = _risk_ids_from_cards(cards)
	var medical_support: bool = _character_has_specialty(support_id, "medical", characters)
	var health_restore: int = 0
	var mental_restore: int = 0
	if silver_count > 0:
		health_restore += 1
	if herb_count > 0 or medical_support:
		health_restore += 1
		mental_restore += 1
	if xiaoyao_count > 0:
		mental_restore += 1
	_restore_character(run_state, target_id, health_restore, mental_restore)
	if target_id == "cao_cao" and run_state.turn_index >= 3 and not bool(run_state.flags.get("dream_seen_once", false)):
		run_state.flags["ember_dream_ready"] = true
	if xiaoyao_count > 0 and target_id == "cao_cao" and risk_ids.has("headwind"):
		run_state.risk_states["headwind"] = maxi(0, int(run_state.risk_states.get("headwind", 0)) - 1)
	if herb_count > 0 or medical_support:
		run_state.risk_states["miasma"] = maxi(0, int(run_state.risk_states.get("miasma", 0)) - 1)
	if not support_id.is_empty() and support_id == "cao_cao" and target_id != "cao_cao":
		_apply_favor_progression(run_state, relation_manager, target_id, 1)
	if not cards.is_empty():
		logs.append(TextDB.get_text("logs.slots.rest.done"))
	return logs

func _pair_slot_total(run_state: RunState, primary_id: String, support_id: String, slot_id: String, characters: Dictionary) -> float:
	var total: float = float(_slot_character_score(run_state, primary_id, slot_id, characters))
	if not support_id.is_empty():
		total += float(_slot_character_score(run_state, support_id, slot_id, characters)) * 0.5
	return total

func _slot_character_score(run_state: RunState, character_id: String, slot_id: String, characters: Dictionary) -> int:
	if not characters.has(character_id):
		return 0
	var character: CharacterData = characters[character_id] as CharacterData
	var character_state: Dictionary = run_state.active_character_states.get(character_id, {})
	return GameRules.slot_attribute_total(slot_id, character, character_state) + GameRules.slot_specialty_bonus(slot_id, character.specialty_tags)

func _character_has_specialty(character_id: String, specialty_id: String, characters: Dictionary) -> bool:
	if character_id.is_empty() or not characters.has(character_id):
		return false
	var character: CharacterData = characters[character_id] as CharacterData
	return character.specialty_tags.has(specialty_id)

func _has_any_specialty(character_ids: Array[String], specialty_ids: Array[String], characters: Dictionary) -> bool:
	for character_id in character_ids:
		for specialty_id in specialty_ids:
			if _character_has_specialty(character_id, specialty_id, characters):
				return true
	return false

func _character_ids_from_cards(cards: Array) -> Array[String]:
	var result: Array[String] = []
	for card_variant in cards:
		var card: Dictionary = card_variant as Dictionary
		if str(card.get("card_type", "")) == "character":
			result.append(str(card.get("id", "")))
	return result

func _resource_count(cards: Array, resource_id: String) -> int:
	var total: int = 0
	for card_variant in cards:
		var card: Dictionary = card_variant as Dictionary
		if str(card.get("card_type", "")) == "resource" and str(card.get("id", "")) == resource_id:
			total += 1
	return total

func _resource_count_any(cards: Array, resource_ids: Array[String]) -> int:
	var total: int = 0
	for resource_id in resource_ids:
		total += _resource_count(cards, resource_id)
	return total

func _risk_ids_from_cards(cards: Array) -> Array[String]:
	var result: Array[String] = []
	for card_variant in cards:
		var card: Dictionary = card_variant as Dictionary
		if str(card.get("card_type", "")) == "risk":
			result.append(str(card.get("id", "")))
	return result

func _research_resource_bonus(cards: Array) -> int:
	var bonus: int = 0
	bonus += _resource_count(cards, "silver_pack")
	bonus += _resource_count(cards, "spy_report") * 3
	bonus += _resource_count(cards, "sealed_letter") * 2
	bonus += _resource_count(cards, "naval_chart") * 2
	bonus += _resource_count(cards, "gift")
	return bonus

func _research_event_bonus(cards: Array) -> int:
	var bonus: int = 0
	var event_tags: Array[String] = _event_tags_from_cards(cards)
	if event_tags.is_empty():
		return bonus
	bonus += _event_card_count(cards) * 2
	if _has_any_card_tag(event_tags, ["research", "intel", "document", "secret_report", "scheme"]):
		bonus += 2
	if _has_any_card_tag(event_tags, ["naval", "search", "relation", "rumor", "medicine", "rest"]):
		bonus += 1
	return bonus

func _event_card_count(cards: Array) -> int:
	var total: int = 0
	for card_variant in cards:
		var card: Dictionary = card_variant as Dictionary
		if str(card.get("card_type", "")) == "event":
			total += 1
	return total

func _event_tags_from_cards(cards: Array) -> Array[String]:
	var result: Array[String] = []
	for card_variant in cards:
		var card: Dictionary = card_variant as Dictionary
		if str(card.get("card_type", "")) != "event":
			continue
		for tag in _card_tags(card):
			if not result.has(tag):
				result.append(tag)
	return result

func _card_tags(card: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for tag_variant in card.get("tags", []):
		var tag: String = str(tag_variant)
		if not tag.is_empty():
			result.append(tag)
	return result

func _has_any_card_tag(source_tags: Array[String], candidate_tags: Array[String]) -> bool:
	for candidate_tag in candidate_tags:
		if source_tags.has(candidate_tag):
			return true
	return false

func _pick_research_reward(cards: Array, character_ids: Array[String], characters: Dictionary, strong_result: bool) -> String:
	var has_search: bool = _has_any_specialty(character_ids, ["search"], characters)
	var has_stratagem: bool = _has_any_specialty(character_ids, ["stratagem"], characters)
	var has_medical: bool = _has_any_specialty(character_ids, ["medical"], characters)
	var event_tags: Array[String] = _event_tags_from_cards(cards)
	var reward_pool: Array[String] = []
	if strong_result and (_resource_count(cards, "naval_chart") > 0 or has_stratagem or _has_any_card_tag(event_tags, ["naval"])):
		reward_pool.append_array(["naval_chart", "naval_chart", "naval_chart"])
	if _resource_count(cards, "spy_report") > 0 or has_search or _has_any_card_tag(event_tags, ["research", "intel", "document", "secret_report", "search"]):
		reward_pool.append_array(["spy_report", "spy_report", "spy_report"])
	if has_medical or _resource_count(cards, "herbal_tonic") > 0 or _has_any_card_tag(event_tags, ["medicine", "rest"]):
		reward_pool.append_array(["herbal_tonic", "herbal_tonic"])
	if _has_any_card_tag(event_tags, ["relation", "rumor"]):
		reward_pool.append_array(["gift", "gift", "sealed_letter"])
	if _has_any_card_tag(event_tags, ["research", "intel", "document", "secret_report", "scheme"]):
		reward_pool.append_array(["spy_report", "sealed_letter"])
	if _has_any_card_tag(event_tags, ["recruit", "search"]):
		reward_pool.append_array(["recruit_writ", "sealed_letter"])
	if strong_result:
		reward_pool.append_array(["sealed_letter", "sealed_letter", "gift"])
	else:
		reward_pool.append_array(["sealed_letter", "gift"])
	return _pick_weighted_reward(reward_pool, "sealed_letter")

func _recruit_resource_bonus(cards: Array) -> int:
	var bonus: int = 0
	bonus += _resource_count(cards, "sealed_letter") * 1
	bonus += _resource_count(cards, "spy_report") * 2
	return bonus

func _restore_character(run_state: RunState, character_id: String, health_restore: int, mental_restore: int) -> void:
	if character_id.is_empty():
		return
	var state: Dictionary = run_state.active_character_states.get(character_id, {}).duplicate(true)
	state["health_state"] = int(state.get("health_state", 8)) + health_restore
	state["mental_state"] = int(state.get("mental_state", 8)) + mental_restore
	run_state.active_character_states[character_id] = state
	if character_id == "cao_cao":
		run_state.cao_health += health_restore
		run_state.cao_mind += mental_restore
	_set_character_track(run_state, character_id, "health_state", int(state.get("health_state", 8)))
	_set_character_track(run_state, character_id, "mental_state", int(state.get("mental_state", 8)))

func _set_character_track(run_state: RunState, character_id: String, key: String, value: int) -> void:
	if not run_state.active_character_states.has(character_id):
		return
	run_state.active_character_states[character_id][key] = clampi(value, 0, 12)

func _apply_favor_progression(run_state: RunState, relation_manager: RelationManager, character_id: String, delta: int, grant_calming_incense: bool = true) -> void:
	if delta == 0 or not run_state.relation_states.has(character_id):
		return
	var before_favor: int = int(run_state.relation_states[character_id].get("favor", 0))
	var before_label: String = GameRules.relation_label(before_favor)
	relation_manager.apply_favor(run_state, character_id, delta)
	var after_favor: int = int(run_state.relation_states[character_id].get("favor", 0))
	var after_label: String = GameRules.relation_label(after_favor)
	if grant_calming_incense and after_favor > before_favor and after_label != before_label:
		_gain_resource(run_state, "calming_incense", 1)

func _gain_resource(run_state: RunState, resource_id: String, amount: int) -> void:
	if amount <= 0:
		return
	run_state.resource_states[resource_id] = int(run_state.resource_states.get(resource_id, 0)) + amount

func _grant_recruit_character(run_state: RunState, relation_manager: RelationManager, characters: Dictionary, extra_help: bool) -> Array[String]:
	var logs: Array[String] = []
	if run_state.locked_character_ids.is_empty():
		return _grant_recruit_resource(run_state, extra_help, extra_help, false)
	var pick_index: int = randi_range(0, run_state.locked_character_ids.size() - 1)
	var character_id: String = str(run_state.locked_character_ids[pick_index])
	run_state.locked_character_ids.remove_at(pick_index)
	if not run_state.roster_ids.has(character_id):
		run_state.roster_ids.append(character_id)
	if run_state.relation_states.has(character_id):
		_apply_favor_progression(run_state, relation_manager, character_id, 1 + int(extra_help), false)
	var character: CharacterData = characters.get(character_id) as CharacterData
	var display_name: String = character_id
	if character != null:
		display_name = character.display_name
	if character_id == "guo_jia":
		run_state.flags["guojia_meet_scene"] = true
	if character_id == "hua_tuo":
		_gain_resource(run_state, "herbal_tonic", 1)
	if extra_help:
		_gain_resource(run_state, "sealed_letter", 1)
	run_state.flags["first_recruit_done"] = true
	logs.append(TextDB.format_text("logs.slots.recruit.success", [display_name]))
	return logs

func _grant_recruit_resource(run_state: RunState, has_search: bool, has_negotiation: bool, has_medical: bool) -> Array[String]:
	var resource_pool: Array[String] = ["silver_pack"]
	resource_pool.append("gift")
	resource_pool.append("sealed_letter")
	if has_search:
		resource_pool.append_array(["spy_report", "spy_report", "naval_chart", "naval_chart"])
	else:
		resource_pool.append_array(["spy_report", "naval_chart"])
	if has_medical:
		resource_pool.append_array(["herbal_tonic", "herbal_tonic", "herbal_tonic"])
	else:
		resource_pool.append("herbal_tonic")
	if has_negotiation:
		resource_pool.append_array(["gift", "gift", "recruit_writ"])
	var resource_id: String = _pick_weighted_reward(resource_pool, "silver_pack")
	var amount: int = 1
	if has_search and resource_id in ["spy_report", "naval_chart"]:
		amount += 1
	if has_medical and resource_id == "herbal_tonic":
		amount += 1
	_gain_resource(run_state, resource_id, amount)
	var display_name: String = TextDB.get_text("resources.%s.name" % resource_id, resource_id)
	return [TextDB.format_text("logs.slots.recruit.lead", [display_name])]

func _grant_recruit_clue(run_state: RunState, strong_clue: bool) -> Array[String]:
	var clue_id: String = "sealed_letter" if strong_clue else "spy_report"
	_gain_resource(run_state, clue_id, 1)
	if strong_clue and randf() <= 0.45:
		_gain_resource(run_state, "recruit_writ", 1)
	var display_name: String = TextDB.get_text("resources.%s.name" % clue_id, clue_id)
	return [TextDB.format_text("logs.slots.recruit.clue", [display_name])]

func _pick_weighted_reward(pool: Array[String], fallback_id: String) -> String:
	if pool.is_empty():
		return fallback_id
	return pool[randi_range(0, pool.size() - 1)]

func _consume_committed_resources(run_state: RunState, board_manager: BoardManager, resources: Dictionary) -> Array[String]:
	var logs: Array[String] = []
	for slot_id_variant in board_manager.slot_assignments.keys():
		var slot_id: String = str(slot_id_variant)
		for card_variant in board_manager.slot_assignments[slot_id]:
			var card: Dictionary = card_variant as Dictionary
			logs.append_array(_consume_if_needed(run_state, card, resources))
	for event_id_variant in board_manager.event_assignments.keys():
		var event_id: String = str(event_id_variant)
		var event_slots: Dictionary = board_manager.event_assignments[event_id]
		for slot_type_variant in event_slots.keys():
			var slot_type: String = str(slot_type_variant)
			for card_variant in event_slots[slot_type]:
				var card2: Dictionary = card_variant as Dictionary
				logs.append_array(_consume_if_needed(run_state, card2, resources))
	return logs

func _consume_if_needed(run_state: RunState, card: Dictionary, resources: Dictionary) -> Array[String]:
	if str(card.get("card_type", "")) != "resource":
		return []
	var resource_id: String = str(card.get("id", ""))
	if not resources.has(resource_id):
		return []
	var resource: ResourceCardData = resources[resource_id] as ResourceCardData
	if not resource.consumable:
		return []
	run_state.resource_states[resource_id] = maxi(0, int(run_state.resource_states.get(resource_id, 0)) - 1)
	return [TextDB.format_text("logs.resources.consumed", [resource.display_name])]

func _sync_pressure_flags(run_state: RunState) -> void:
	var rumor_pressure: bool = run_state.jingzhou_stability <= 4 or int(run_state.risk_states.get("rumor", 0)) >= 1 or run_state.fire_progress >= 6
	run_state.flags["jingzhou_rumor_active"] = rumor_pressure
	run_state.flags["alliance_forming"] = run_state.fire_progress < 9

func _sync_risk_flags(run_state: RunState) -> void:
	for risk_id_variant in run_state.risk_states.keys():
		var risk_id: String = str(risk_id_variant)
		for level_variant in [1, 2, 3]:
			var level: int = int(level_variant)
			run_state.flags["risk_%s_%d" % [risk_id, level]] = int(run_state.risk_states[risk_id]) == level
