extends RefCounted
class_name TutorialManager

const TUTORIAL_EVENT_ID: String = "tutorial_patrol_gap"
const TUTORIAL_STRATEGIST_EVENT_ID: String = "tutorial_strategist_descends"
const TUTORIAL_LETTER_ID: String = "yecheng_letter"
const TUTORIAL_GIFT_ID: String = "sanjian_dao"
const TUTORIAL_CLUE_ID: String = "night_watch_roll"
const TUTORIAL_ARMY_ID: String = "northern_corps"
const STEP_ONE_POPUP_ID: String = "step_1_letter"

func current_step(run_state: RunState) -> int:
	return int(run_state.flags.get("tutorial_step", 0))

func is_active(run_state: RunState) -> bool:
	var step: int = current_step(run_state)
	return step >= 1 and step <= 5 and not bool(run_state.flags.get("tutorial_completed", false))

func unlocked_slot_ids(run_state: RunState) -> Array[String]:
	var step: int = current_step(run_state)
	match step:
		1:
			return ["governance"]
		2:
			return ["governance", "recruit"]
		3:
			return ["governance", "recruit", "audience"]
		4, 5:
			return ["governance", "recruit", "audience", "research", "rest"]
		_:
			return ["governance", "research", "recruit", "audience", "rest"]

func is_minimal_mode(run_state: RunState) -> bool:
	return current_step(run_state) == 1 and is_active(run_state)

func sync_unlock_flags(run_state: RunState) -> bool:
	var changed: bool = false
	var step: int = current_step(run_state)
	var recruit_open: bool = step >= 2 or bool(run_state.flags.get("tutorial_completed", false))
	var audience_open: bool = step >= 3 or bool(run_state.flags.get("tutorial_completed", false))
	var research_open: bool = step >= 4 or bool(run_state.flags.get("tutorial_completed", false))
	var rest_open: bool = step >= 4 or bool(run_state.flags.get("tutorial_completed", false))
	for pair in [
		["unlocked_recruit", recruit_open],
		["unlocked_audience", audience_open],
		["unlocked_research", research_open],
		["unlocked_rest", rest_open]
	]:
		var flag_id: String = str(pair[0])
		var flag_value: bool = bool(pair[1])
		if bool(run_state.flags.get(flag_id, false)) != flag_value:
			run_state.flags[flag_id] = flag_value
			changed = true
	return changed

func total_capacity_override(run_state: RunState, slot_id: String) -> int:
	if is_active(run_state) and current_step(run_state) == 1 and slot_id == "governance":
		return 1
	return -1

func can_assign(run_state: RunState, _board_manager: BoardManager, target_id: String, payload: Dictionary) -> bool:
	if not is_active(run_state):
		return true
	if payload.is_empty():
		return false
	var card_type: String = str(payload.get("card_type", ""))
	var card_id: String = str(payload.get("id", ""))
	var event_id: String = ""
	var event_slot_type: String = ""
	var detail_slot_key: String = ""
	var slot_id: String = target_id
	if target_id.contains("#"):
		detail_slot_key = target_id.get_slice("#", 1)
		slot_id = target_id.get_slice("#", 0)
	if slot_id.contains(":"):
		event_id = slot_id.get_slice(":", 0)
		event_slot_type = slot_id.get_slice(":", 1)
	match current_step(run_state):
		1:
			return slot_id == "governance" and card_type == "character" and card_id == "cao_cao"
		2:
			if slot_id != "recruit":
				return false
			match detail_slot_key:
				"recruit_primary":
					return card_type == "character" and card_id == "cao_cao"
				"recruit_support":
					return card_type == "character" and card_id != "cao_cao"
				"recruit_money":
					return card_type == "resource" and card_id == "silver_pack"
				"recruit_task":
					return card_type == "resource" and card_id == "recruit_writ"
			if card_type == "character":
				return card_id == "cao_cao"
			if card_type == "resource":
				return card_id in ["silver_pack", "recruit_writ"]
			return false
		3:
			if slot_id != "audience":
				return false
			if card_type == "character":
				return card_id in ["cao_cao", "yu_jin"]
			if card_type == "resource":
				return card_id == TUTORIAL_GIFT_ID
			return false
		4:
			if slot_id == "rest":
				if card_type == "risk":
					return card_id == "headwind"
				if card_type == "resource":
					return card_id == "calming_incense"
				if card_type == "character":
					return card_id == "cao_cao"
				return false
			if slot_id == "research":
				if card_type == "character":
					return card_id == "yu_jin"
				if card_type == "resource":
					return card_id == "silver_pack"
				if card_type == "event":
					return card_id == TUTORIAL_EVENT_ID
				return false
			if slot_id in ["governance", "recruit"]:
				return card_type == "character" and card_id == "cao_cao"
			return false
		5:
			if event_id == TUTORIAL_EVENT_ID:
				if event_slot_type == "character":
					return card_type == "character" and card_id == "yu_jin"
				if event_slot_type == "resource":
					return card_type == "resource" and card_id == TUTORIAL_CLUE_ID
				return false
			if event_id == TUTORIAL_STRATEGIST_EVENT_ID:
				return event_slot_type == "character" and card_type == "character" and card_id == "cao_cao"
			if slot_id in ["governance", "recruit"]:
				return card_type == "character" and card_id == "cao_cao"
			return false
	return true

func consume_prompt(run_state: RunState) -> Dictionary:
	if not is_active(run_state):
		return {}
	var step: int = current_step(run_state)
	var prompt_flag: String = "tutorial_prompt_step_%d_seen" % step
	if bool(run_state.flags.get(prompt_flag, false)):
		return {}
	run_state.flags[prompt_flag] = true
	return force_prompt(run_state)

func force_prompt(run_state: RunState) -> Dictionary:
	if not is_active(run_state):
		return {}
	var step: int = current_step(run_state)
	return {
		"title": TextDB.get_text("tutorial.steps.step_%d.title" % step),
		"subtitle": TextDB.get_text("tutorial.steps.step_%d.subtitle" % step),
		"body": TextDB.get_text("tutorial.steps.step_%d.body" % step)
	}

func consume_followup_popup(run_state: RunState) -> Dictionary:
	var popup_id: String = str(run_state.flags.get("tutorial_pending_popup", ""))
	if popup_id.is_empty():
		return {}
	run_state.flags["tutorial_pending_popup"] = ""
	return {
		"title": TextDB.get_text("tutorial.followups.%s.title" % popup_id),
		"subtitle": TextDB.get_text("tutorial.followups.%s.subtitle" % popup_id),
		"body": TextDB.get_text("tutorial.followups.%s.body" % popup_id),
		"chain_to_prompt": true
	}

func pre_report_dialogue(run_state: RunState) -> Dictionary:
	var step: int = int(run_state.flags.get("tutorial_last_report_step", 0))
	if step != 3 and step != 5:
		return {}
	var dialogue_key: String = "tutorial.dialogues.step_3_audience" if step == 3 else "tutorial.dialogues.step_5_guojia"
	var dialogue: Dictionary = TextDB.get_dict(dialogue_key)
	var lines: Array = TextDB.get_array("%s.lines" % dialogue_key)
	if dialogue.is_empty() or lines.is_empty():
		return {}
	var payload: Dictionary = dialogue.duplicate(true)
	payload["lines"] = lines.duplicate(true)
	return payload

func blocked_prompt(run_state: RunState) -> Dictionary:
	var prompt: Dictionary = force_prompt(run_state)
	if prompt.is_empty():
		return {}
	prompt["title"] = TextDB.get_text("tutorial.messages.blocked_title")
	prompt["subtitle"] = TextDB.get_text("tutorial.messages.blocked_subtitle")
	return prompt

func overview_hint(run_state: RunState) -> String:
	if not is_active(run_state):
		return ""
	return TextDB.get_text("tutorial.steps.step_%d.hint" % current_step(run_state))

func end_turn_status(run_state: RunState, board_manager: BoardManager) -> Dictionary:
	if not is_active(run_state):
		return {"ok": true}
	var ok: bool = false
	match current_step(run_state):
		1:
			ok = _matches_slot(board_manager.get_slot_cards("governance"), ["cao_cao"], [], [])
		2:
			ok = _matches_recruit_tutorial_setup(board_manager.get_slot_cards("recruit"))
		3:
			ok = _matches_slot(board_manager.get_slot_cards("audience"), ["cao_cao", "yu_jin"], [TUTORIAL_GIFT_ID], [])
		4:
			var rest_ok: bool = _matches_slot(board_manager.get_slot_cards("rest"), ["cao_cao"], ["calming_incense"], [], ["headwind"])
			var research_ok: bool = _matches_slot(board_manager.get_slot_cards("research"), ["yu_jin"], ["silver_pack"], [TUTORIAL_EVENT_ID])
			ok = rest_ok and research_ok
		5:
			var patrol_ok: bool = _matches_event(board_manager, TUTORIAL_EVENT_ID, ["yu_jin"], [TUTORIAL_CLUE_ID])
			var strategist_ok: bool = _matches_event(board_manager, TUTORIAL_STRATEGIST_EVENT_ID, ["cao_cao"], [])
			ok = patrol_ok and strategist_ok
		_:
			ok = true
	if ok:
		return {"ok": true}
	var prompt: Dictionary = blocked_prompt(run_state)
	prompt["ok"] = false
	prompt["toast_body"] = _toast_hint(run_state)
	return prompt

func _toast_hint(run_state: RunState) -> String:
	var step: int = current_step(run_state)
	if step <= 0:
		return ""
	return TextDB.get_text("tutorial.steps.step_%d.hint" % step)

func resolve_turn(run_state: RunState, board_manager: BoardManager, _event_manager: EventManager, relation_manager: RelationManager, characters: Dictionary, _resources: Dictionary) -> Array[String]:
	var step: int = current_step(run_state)
	var logs: Array[String] = []
	if not is_active(run_state):
		return logs
	run_state.flags["tutorial_last_report_step"] = step
	run_state.flags["_tutorial_slot_snapshot"] = {
		"governance": board_manager.get_slot_cards("governance").duplicate(true),
		"recruit": board_manager.get_slot_cards("recruit").duplicate(true),
		"research": board_manager.get_slot_cards("research").duplicate(true),
		"rest": board_manager.get_slot_cards("rest").duplicate(true),
		"audience": board_manager.get_slot_cards("audience").duplicate(true)
	}
	logs.append(TextDB.format_text("tutorial.logs.step_start", [step]))
	match step:
		1:
			logs.append_array(_resolve_step_one(run_state))
		2:
			logs.append_array(_resolve_step_two(run_state, relation_manager, characters))
		3:
			logs.append_array(_resolve_step_three(run_state, relation_manager))
		4:
			logs.append_array(_resolve_step_four(run_state))
		5:
			logs.append_array(_resolve_step_five(run_state, relation_manager, characters))
	sync_unlock_flags(run_state)
	GameRules.clamp_stats(run_state)
	return logs

func report_index(run_state: RunState, fallback_index: int) -> int:
	var step: int = int(run_state.flags.get("tutorial_last_report_step", 0))
	return step if step > 0 else fallback_index

func report_title(run_state: RunState) -> String:
	var step: int = int(run_state.flags.get("tutorial_last_report_step", 0))
	if step <= 0:
		return ""
	var override_title: String = TextDB.get_text("tutorial.steps.step_%d.report_title" % step)
	if _has_meaningful_report_text(override_title):
		return override_title
	var step_title: String = TextDB.get_text("tutorial.steps.step_%d.title" % step)
	if _has_meaningful_report_text(step_title):
		return step_title
	return TextDB.format_text("tutorial.report.title", [step], {}, "Tutorial Step %d")

func report_subtitle(run_state: RunState, _fallback_turn_index: int) -> String:
	var step: int = int(run_state.flags.get("tutorial_last_report_step", 0))
	if step <= 0:
		return ""
	var subtitle: String = TextDB.get_text("tutorial.steps.step_%d.report_subtitle" % step)
	return subtitle if _has_meaningful_report_text(subtitle) else ""

func should_show_report(run_state: RunState) -> bool:
	var step: int = int(run_state.flags.get("tutorial_last_report_step", 0))
	return step > 0

func report_body_override(run_state: RunState) -> String:
	var step: int = int(run_state.flags.get("tutorial_last_report_step", 0))
	if step <= 0:
		return ""
	var body: String = TextDB.get_text("tutorial.steps.step_%d.report_body" % step)
	return body if _has_meaningful_report_text(body) else ""

func _has_meaningful_report_text(text: String) -> bool:
	var content: String = text.strip_edges()
	if content.is_empty():
		return false
	for index in range(content.length()):
		var code: int = content.unicode_at(index)
		if [9, 10, 13, 32, 33, 45, 63, 0x3002, 0xFF01, 0xFF1F, 0xFF0C, 0x3001, 0x2026].has(code):
			continue
		return true
	return false

func clear_report_context(run_state: RunState) -> void:
	run_state.flags["tutorial_last_report_step"] = 0

func _resolve_step_one(run_state: RunState) -> Array[String]:
	_gain_resource(run_state, "silver_pack", 2)
	_gain_resource(run_state, "recruit_writ", 1)
	_gain_resource(run_state, "herbal_tonic", 1)
	_gain_resource(run_state, TUTORIAL_GIFT_ID, 1)
	run_state.flags["first_governance_done"] = true
	run_state.flags["unlocked_recruit"] = true
	run_state.flags["tutorial_step"] = 2
	run_state.flags["tutorial_pending_popup"] = STEP_ONE_POPUP_ID
	return [
		TextDB.get_text("tutorial.logs.step_1_governance"),
		TextDB.get_text("tutorial.logs.step_1_rewards")
	]

func _resolve_step_two(run_state: RunState, relation_manager: RelationManager, characters: Dictionary) -> Array[String]:
	_consume_resource(run_state, "silver_pack", 1)
	_consume_resource(run_state, "recruit_writ", 1)
	if run_state.locked_character_ids.has("yu_jin"):
		run_state.locked_character_ids.erase("yu_jin")
	if not run_state.roster_ids.has("yu_jin"):
		run_state.roster_ids.append("yu_jin")
	relation_manager.apply_favor(run_state, "yu_jin", 1)
	run_state.flags["first_recruit_done"] = true
	run_state.flags["unlocked_audience"] = true
	run_state.flags["tutorial_step"] = 3
	var display_name: String = "于禁"
	if characters.has("yu_jin"):
		var character: CharacterData = characters["yu_jin"] as CharacterData
		if character != null:
			display_name = character.display_name
	return [
		TextDB.get_text("tutorial.logs.step_2_recruit"),
		TextDB.format_text("logs.slots.recruit.success", [display_name])
	]

func _resolve_step_three(run_state: RunState, relation_manager: RelationManager) -> Array[String]:
	_consume_resource(run_state, TUTORIAL_GIFT_ID, 1)
	relation_manager.apply_favor(run_state, "yu_jin", 2)
	_gain_resource(run_state, "calming_incense", 1)
	var yu_jin_state: Dictionary = run_state.active_character_states.get("yu_jin", {}).duplicate(true)
	yu_jin_state["bonus_perception"] = int(yu_jin_state.get("bonus_perception", 0)) + 1
	run_state.active_character_states["yu_jin"] = yu_jin_state
	run_state.flags["unlocked_research"] = true
	run_state.flags["unlocked_rest"] = true
	run_state.risk_states["headwind"] = int(run_state.risk_states.get("headwind", 0)) + 1
	run_state.flags["first_headwind_seen"] = true
	_ensure_tutorial_event(run_state)
	run_state.flags["tutorial_step"] = 4
	return [
		TextDB.get_text("tutorial.logs.step_3_audience"),
		TextDB.get_text("tutorial.logs.step_3_growth"),
		TextDB.get_text("tutorial.logs.step_3_xiaoyao"),
		TextDB.get_text("tutorial.logs.step_3_headwind")
	]

func _resolve_step_four(run_state: RunState) -> Array[String]:
	_consume_resource(run_state, "silver_pack", 1)
	_consume_resource(run_state, "calming_incense", 1)
	_restore_cao(run_state, 0, 1)
	run_state.risk_states["headwind"] = maxi(0, int(run_state.risk_states.get("headwind", 0)) - 1)
	if _slot_contains_character(run_state, "governance", "cao_cao"):
		_gain_resource(run_state, "recruit_writ", 1)
	if _slot_contains_character(run_state, "recruit", "cao_cao"):
		_gain_resource(run_state, "herbal_tonic", 1)
	_gain_resource(run_state, TUTORIAL_CLUE_ID, 1)
	_ensure_strategist_event(run_state)
	run_state.flags["tutorial_step"] = 5
	run_state.flags["unlocked_recruit"] = true
	run_state.flags["unlocked_audience"] = true
	run_state.flags["unlocked_research"] = true
	run_state.flags["unlocked_rest"] = true
	return [
		TextDB.get_text("tutorial.logs.step_4_rest"),
		TextDB.get_text("tutorial.logs.step_4_research"),
		TextDB.get_text("tutorial.logs.step_4_clue")
	]

func _resolve_step_five(run_state: RunState, relation_manager: RelationManager, characters: Dictionary) -> Array[String]:
	_consume_resource(run_state, TUTORIAL_CLUE_ID, 1)
	run_state.morale += 1
	_gain_resource(run_state, TUTORIAL_ARMY_ID, 1)
	if run_state.locked_character_ids.has("guo_jia"):
		run_state.locked_character_ids.erase("guo_jia")
	if not run_state.roster_ids.has("guo_jia"):
		run_state.roster_ids.append("guo_jia")
	if run_state.active_character_states.has("guo_jia"):
		run_state.active_character_states["guo_jia"]["sick_stage"] = 1
	relation_manager.apply_favor(run_state, "guo_jia", 1)
	if characters.has("guo_jia"):
		var guo_jia: CharacterData = characters["guo_jia"] as CharacterData
		if guo_jia != null:
			run_state.log_entries.append(TextDB.format_text("logs.slots.recruit.success", [guo_jia.display_name]))
	_remove_tutorial_event(run_state, TUTORIAL_EVENT_ID)
	_remove_tutorial_event(run_state, TUTORIAL_STRATEGIST_EVENT_ID)
	run_state.flags["tutorial_completed"] = true
	run_state.flags["tutorial_step"] = 0
	run_state.flags["unlocked_recruit"] = true
	run_state.flags["unlocked_audience"] = true
	run_state.flags["unlocked_research"] = true
	run_state.flags["unlocked_rest"] = true
	return [
		TextDB.get_text("tutorial.logs.step_5_patrol"),
		TextDB.get_text("tutorial.logs.step_5_guojia"),
		TextDB.get_text("tutorial.logs.step_5_army")
	]

func _slot_contains_character(run_state: RunState, slot_id: String, character_id: String) -> bool:
	var assignments: Dictionary = run_state.flags.get("_tutorial_slot_snapshot", {}) as Dictionary
	if assignments.is_empty() or not assignments.has(slot_id):
		return false
	for card_variant in assignments[slot_id]:
		var card: Dictionary = card_variant as Dictionary
		if str(card.get("card_type", "")) == "character" and str(card.get("id", "")) == character_id:
			return true
	return false

func _ensure_tutorial_event(run_state: RunState) -> void:
	if run_state.active_event_ids.has(TUTORIAL_EVENT_ID):
		return
	run_state.active_event_ids.append(TUTORIAL_EVENT_ID)
	run_state.active_event_states[TUTORIAL_EVENT_ID] = {"turns_left": 3, "timeout_total": 3}

func _ensure_strategist_event(run_state: RunState) -> void:
	if run_state.active_event_ids.has(TUTORIAL_STRATEGIST_EVENT_ID):
		return
	run_state.active_event_ids.append(TUTORIAL_STRATEGIST_EVENT_ID)
	run_state.active_event_states[TUTORIAL_STRATEGIST_EVENT_ID] = {"turns_left": 1, "timeout_total": 1}

func _remove_tutorial_event(run_state: RunState, event_id: String) -> void:
	run_state.active_event_ids.erase(event_id)
	if run_state.active_event_states.has(event_id):
		run_state.active_event_states.erase(event_id)

func _matches_recruit_tutorial_setup(cards: Array) -> bool:
	var has_primary: bool = false
	var has_money: bool = false
	var has_task: bool = false
	for card_variant in cards:
		var card: Dictionary = card_variant as Dictionary
		var card_type: String = str(card.get("card_type", ""))
		var card_id: String = str(card.get("id", ""))
		if card_type == "character" and card_id == "cao_cao":
			has_primary = true
		elif card_type == "resource" and card_id == "silver_pack":
			has_money = true
		elif card_type == "resource" and card_id == "recruit_writ":
			has_task = true
	return has_primary and has_money and has_task and cards.size() == 3

func _matches_event(board_manager: BoardManager, event_id: String, expected_characters: Array[String], expected_resources: Array[String]) -> bool:
	if not board_manager.event_assignments.has(event_id):
		return false
	return _matches_slot(board_manager.get_event_cards(event_id), expected_characters, expected_resources, [])

func _matches_slot(cards: Array, expected_characters: Array[String], expected_resources: Array[String], expected_events: Array[String], expected_risks: Array[String] = []) -> bool:
	var actual_characters: Array[String] = []
	var actual_resources: Array[String] = []
	var actual_events: Array[String] = []
	var actual_risks: Array[String] = []
	for card_variant in cards:
		var card: Dictionary = card_variant as Dictionary
		match str(card.get("card_type", "")):
			"character":
				actual_characters.append(str(card.get("id", "")))
			"resource":
				actual_resources.append(str(card.get("id", "")))
			"event":
				actual_events.append(str(card.get("id", "")))
			"risk":
				actual_risks.append(str(card.get("id", "")))
	actual_characters.sort()
	actual_resources.sort()
	actual_events.sort()
	actual_risks.sort()
	var sorted_expected_characters: Array[String] = expected_characters.duplicate()
	var sorted_expected_resources: Array[String] = expected_resources.duplicate()
	var sorted_expected_events: Array[String] = expected_events.duplicate()
	var sorted_expected_risks: Array[String] = expected_risks.duplicate()
	sorted_expected_characters.sort()
	sorted_expected_resources.sort()
	sorted_expected_events.sort()
	sorted_expected_risks.sort()
	return actual_characters == sorted_expected_characters and actual_resources == sorted_expected_resources and actual_events == sorted_expected_events and actual_risks == sorted_expected_risks

func _gain_resource(run_state: RunState, resource_id: String, amount: int) -> void:
	if amount <= 0:
		return
	run_state.resource_states[resource_id] = int(run_state.resource_states.get(resource_id, 0)) + amount

func _consume_resource(run_state: RunState, resource_id: String, amount: int) -> void:
	if amount <= 0:
		return
	run_state.resource_states[resource_id] = maxi(0, int(run_state.resource_states.get(resource_id, 0)) - amount)

func _restore_cao(run_state: RunState, health_delta: int, mind_delta: int) -> void:
	run_state.cao_health += health_delta
	run_state.cao_mind += mind_delta
	if run_state.active_character_states.has("cao_cao"):
		run_state.active_character_states["cao_cao"]["health_state"] = clampi(int(run_state.active_character_states["cao_cao"].get("health_state", 10)) + health_delta, 0, 12)
		run_state.active_character_states["cao_cao"]["mental_state"] = clampi(int(run_state.active_character_states["cao_cao"].get("mental_state", 10)) + mind_delta, 0, 12)
