extends Node
class_name EventManager

# 事件管理器：负责事件生成、条件检查、投入判定与结果发放。
# 临时事件卡的玩法规则优先集中在这里，避免写进 UI。

signal events_changed

var event_defs: Dictionary = {}

func setup(definitions: Dictionary) -> void:
	event_defs = definitions

func spawn_events_for_turn(run_state: RunState) -> Array[String]:
	var spawned: Array[String] = []
	for event_id_variant in event_defs.keys():
		var event_id: String = str(event_id_variant)
		var event: EventData = event_defs[event_id] as EventData
		if run_state.active_event_states.has(event_id):
			continue
		if _can_activate(event, run_state):
			var timeout_turns: int = _event_timeout(event)
			run_state.active_event_ids.append(event_id)
			run_state.active_event_states[event_id] = {"turns_left": timeout_turns, "timeout_total": timeout_turns}
			spawned.append(event_id)
			if event.trigger_type == "condition":
				run_state.flags["%s_spawned" % event_id] = true
	emit_signal("events_changed")
	return spawned

func resolve_event(run_state: RunState, event_id: String, assigned_cards: Array, relation_manager: RelationManager, character_defs: Dictionary, resource_defs: Dictionary) -> Array[String]:
	if not event_defs.has(event_id):
		return []
	var event: EventData = event_defs[event_id] as EventData
	var evaluation: Dictionary = _evaluate_assignment(run_state, event, assigned_cards, character_defs, resource_defs)
	var has_character: bool = int(evaluation.get("character_count", 0)) > 0
	var effective_total: int = int(evaluation.get("effective_total", 0))
	var qualified: bool = bool(evaluation.get("qualified", true))
	var logs: Array[String] = []
	if qualified and has_character and effective_total >= event.success_threshold:
		_apply_effect(run_state, event.success_effect_id, relation_manager)
		_activate_followups(run_state, event)
		logs.append(TextDB.format_text("logs.events.auto_success", [event.title, effective_total, event.success_threshold]))
		_clear_event(run_state, event_id)
		return logs
	if qualified and has_character and effective_total >= event.minimum_requirement:
		var roll_value: int = randi_range(1, 20)
		var adjusted_dc: int = _effective_dc(event, run_state)
		var final_total: int = roll_value + effective_total
		if final_total >= adjusted_dc:
			_apply_effect(run_state, event.success_effect_id, relation_manager)
			_activate_followups(run_state, event)
			logs.append(TextDB.format_text("logs.events.roll_success", [event.title, roll_value, final_total, adjusted_dc]))
		else:
			_apply_effect(run_state, event.fail_effect_id, relation_manager)
			logs.append(TextDB.format_text("logs.events.roll_fail", [event.title, roll_value, final_total, adjusted_dc]))
		_clear_event(run_state, event_id)
		return logs
	if not assigned_cards.is_empty():
		logs.append(TextDB.format_text("logs.events.pending", [event.title, effective_total, event.minimum_requirement]))
	return logs

func advance_unresolved_events(run_state: RunState, relation_manager: RelationManager) -> Array[String]:
	var logs: Array[String] = []
	for event_id_variant in run_state.active_event_ids.duplicate():
		var event_id: String = str(event_id_variant)
		var state: Dictionary = run_state.active_event_states.get(event_id, {})
		if state.is_empty():
			continue
		state["turns_left"] = int(state.get("turns_left", 0)) - 1
		run_state.active_event_states[event_id] = state
		if int(state["turns_left"]) <= 0:
			var event: EventData = event_defs[event_id] as EventData
			_apply_effect(run_state, event.expire_effect_id, relation_manager)
			logs.append(TextDB.format_text("logs.events.expired", [event.title]))
			_clear_event(run_state, event_id)
	emit_signal("events_changed")
	return logs

func describe_event_rules(event: EventData, run_state: RunState) -> String:
	var adjusted_dc: int = _effective_dc(event, run_state)
	var lines: Array[String] = []
	lines.append(TextDB.format_text("ui.event_rules.summary", [event.minimum_requirement, event.success_threshold, adjusted_dc, _event_timeout(event)]))
	lines.append(TextDB.get_text("ui.event_rules.rule_line"))
	var attribute_keys: Array[String] = GameRules.event_attribute_keys(event)
	if not attribute_keys.is_empty():
		lines.append(TextDB.format_text("ui.event_rules.attributes", [_join_attribute_labels(attribute_keys)]))
	var specialties: Array[String] = GameRules.event_recommended_specialties(event)
	if not specialties.is_empty():
		lines.append(TextDB.format_text("ui.event_rules.specialties", [_join_specialty_labels(specialties)]))
	var required_resources: Array[String] = _required_resource_ids(event)
	if not required_resources.is_empty():
		lines.append(TextDB.format_text("ui.event_rules.required_resources", [_join_resource_labels(required_resources)]))
	var recommended_resources: Array[String] = _recommended_resource_ids(event)
	if not recommended_resources.is_empty():
		lines.append(TextDB.format_text("ui.event_rules.resources", [_join_resource_labels(recommended_resources)]))
	var pressure_delta: int = adjusted_dc - event.difficulty_class
	if pressure_delta > 0:
		lines.append(TextDB.format_text("ui.event_rules.pressure", [pressure_delta]))
	return "\n".join(lines)

func _clear_event(run_state: RunState, event_id: String) -> void:
	run_state.active_event_ids.erase(event_id)
	run_state.active_event_states.erase(event_id)

func _can_activate(event: EventData, run_state: RunState) -> bool:
	if run_state.stage_index < event.stage_min or run_state.stage_index > event.stage_max:
		return false
	for flag_variant in event.required_flags:
		var flag: String = str(flag_variant)
		if not bool(run_state.flags.get(flag, false)):
			return false
	for flag_variant in event.blocked_flags:
		var blocked_flag: String = str(flag_variant)
		if bool(run_state.flags.get(blocked_flag, false)):
			return false
	match event.trigger_type:
		"time":
			return event.trigger_turn == run_state.turn_index
		"condition":
			return _check_condition_trigger(event, run_state)
	return false

func _check_condition_trigger(event: EventData, run_state: RunState) -> bool:
	var spawn_flag: String = "%s_spawned" % event.id
	if bool(run_state.flags.get(spawn_flag, false)):
		return false
	var condition_id: String = event.trigger_condition_id if not event.trigger_condition_id.is_empty() else event.id
	match condition_id:
		"guojia_relapse":
			return false
		"jingzhou_whispers":
			return bool(run_state.flags.get("jingzhou_rumor_active", false))
		"ember_dream":
			return bool(run_state.flags.get("ember_dream_ready", false)) and not bool(run_state.flags.get("dream_seen_once", false))
		"xun_yu_letters":
			if not run_state.roster_ids.has("xun_yu"):
				return false
			var xun_yu_state: Dictionary = run_state.relation_states.get("xun_yu", {})
			return run_state.fire_progress >= 4 and int(xun_yu_state.get("favor", 0)) <= 1
		"camp_fever":
			return false
	return false

func _event_timeout(event: EventData) -> int:
	if event.timeout_turns > 0:
		return event.timeout_turns
	match event.category:
		"relation":
			return 5
		"character", "crisis":
			return 2
		_:
			return 3

func _effective_dc(event: EventData, run_state: RunState) -> int:
	return event.difficulty_class + GameRules.fire_pressure_modifier(run_state.fire_progress)

func _evaluate_assignment(run_state: RunState, event: EventData, assigned_cards: Array, character_defs: Dictionary, resource_defs: Dictionary) -> Dictionary:
	var attribute_total_float: float = 0.0
	var specialty_bonus_float: float = 0.0
	var resource_bonus: int = 0
	var character_count: int = 0
	var resource_count: int = 0
	var assigned_specialties: Array[String] = []
	var attribute_keys: Array[String] = GameRules.event_attribute_keys(event)
	var character_cards: Array = []
	for card_variant in assigned_cards:
		var card: Dictionary = card_variant as Dictionary
		var card_type: String = str(card.get("card_type", ""))
		var card_id: String = str(card.get("id", ""))
		if card_type == "character":
			character_count += 1
			character_cards.append(card)
		elif card_type == "resource":
			resource_count += 1
			if resource_defs.has(card_id):
				var resource: ResourceCardData = resource_defs[card_id] as ResourceCardData
				resource_bonus += _resource_score(resource, event)
	for index in range(character_cards.size()):
		var card: Dictionary = character_cards[index] as Dictionary
		var card_id: String = str(card.get("id", ""))
		var weight: float = 1.0 if index == 0 else 0.5
		if character_defs.has(card_id):
			var character: CharacterData = character_defs[card_id] as CharacterData
			var character_state: Dictionary = run_state.active_character_states.get(card_id, {})
			attribute_total_float += float(GameRules.character_attribute_total(character, character_state, attribute_keys)) * weight
			specialty_bonus_float += float(_character_specialty_bonus(character, event)) * weight
			for specialty in character.specialty_tags:
				var specialty_id: String = str(specialty)
				if not assigned_specialties.has(specialty_id):
					assigned_specialties.append(specialty_id)
		else:
			attribute_total_float += 1.0 * weight
	var attribute_total: int = int(floor(attribute_total_float))
	var specialty_bonus: int = int(floor(specialty_bonus_float))
	var qualified: bool = _meets_event_qualification(event, assigned_cards, assigned_specialties)
	var effective_total: int = attribute_total + resource_bonus + specialty_bonus
	if not qualified and event.minimum_requirement > 0:
		effective_total = mini(effective_total, event.minimum_requirement - 1)
	return {
		"qualified": qualified,
		"character_count": character_count,
		"resource_count": resource_count,
		"attribute_total": attribute_total,
		"resource_bonus": resource_bonus,
		"specialty_bonus": specialty_bonus,
		"effective_total": effective_total
	}

func _character_specialty_bonus(character: CharacterData, event: EventData) -> int:
	var bonus: int = 0
	var expected_specialties: Array[String] = GameRules.event_recommended_specialties(event)
	for specialty in character.specialty_tags:
		var specialty_id: String = str(specialty)
		if not expected_specialties.has(specialty_id):
			continue
		bonus += 2 if specialty_id == "medical" and _event_has_any_tag(event, ["medicine", "rest"]) else 1
	match character.id:
		"cao_cao":
			if _event_has_any_tag(event, ["governance", "relation"]):
				bonus += 1
		"guo_jia":
			if _event_has_any_tag(event, ["research", "scheme", "document", "secret_report"]):
				bonus += 1
		"xun_yu":
			if _event_has_any_tag(event, ["governance", "relation", "document"]):
				bonus += 1
		"zhang_liao", "yu_jin":
			if _event_has_any_tag(event, ["military", "governance", "naval"]):
				bonus += 1
		"hua_tuo":
			if _event_has_any_tag(event, ["medicine", "rest"]):
				bonus += 2
	return bonus

func _resource_score(resource: ResourceCardData, event: EventData) -> int:
	match resource.id:
		"silver_pack":
			return 4 if _event_has_any_tag(event, ["governance", "relation", "recruit", "rest"]) else 1
		"herbal_tonic":
			return 5 if _event_has_any_tag(event, ["medicine", "rest"]) else 1
		"spy_report":
			return 4 if _event_has_any_tag(event, ["research", "scheme", "relation", "document", "secret_report", "search"]) else 1
		"recruit_writ":
			return 5 if _event_has_any_tag(event, ["recruit", "search", "relation"]) else 1
		"gift":
			return 4 if _event_has_any_tag(event, ["relation", "rumor", "gift"]) else 1
		"naval_chart":
			return 5 if _event_has_any_tag(event, ["naval", "military", "research", "search"]) else 1
		"sealed_letter":
			return 4 if _event_has_any_tag(event, ["relation", "research", "document", "rumor", "secret_report"]) else 1
		"calming_incense":
			return 5 if _event_has_any_tag(event, ["rest", "mind", "relation"]) else 1
	var score: int = 0
	if _has_any_tag(resource.tags, event.tags):
		score += 1
	if _has_any_tag(resource.tags, event.recommended_tags):
		score += 1
	return score

func _meets_event_qualification(event: EventData, assigned_cards: Array, assigned_specialties: Array[String]) -> bool:
	var required_resources: Array[String] = _required_resource_ids(event)
	if not required_resources.is_empty() and not _assigned_has_all_resources(assigned_cards, required_resources):
		return false
	if _event_has_any_tag(event, ["medicine"]):
		if assigned_specialties.has("medical"):
			return true
		if _assigned_has_resource(assigned_cards, ["herbal_tonic"]):
			return true
		for card_variant in assigned_cards:
			var card: Dictionary = card_variant as Dictionary
			if str(card.get("card_type", "")) == "character" and str(card.get("id", "")) == "hua_tuo":
				return true
		return false
	if _event_has_any_tag(event, ["rest", "mind"]):
		if assigned_specialties.has("medical"):
			return true
		if _assigned_has_resource(assigned_cards, ["herbal_tonic", "calming_incense", "silver_pack"]):
			return true
		for card_variant in assigned_cards:
			var card: Dictionary = card_variant as Dictionary
			if str(card.get("card_type", "")) == "character" and str(card.get("id", "")) == "hua_tuo":
				return true
		return false
	if _event_has_any_tag(event, ["recruit", "search"]):
		if _has_any_specialty_id(assigned_specialties, ["search", "negotiation"]):
			return true
		return _assigned_has_resource(assigned_cards, ["silver_pack", "recruit_writ", "sealed_letter"])
	if _event_has_any_tag(event, ["naval"]):
		if _has_any_specialty_id(assigned_specialties, ["command", "stratagem", "search"]):
			return true
		return _assigned_has_resource(assigned_cards, ["naval_chart", "spy_report"])
	if _event_has_any_tag(event, ["relation", "rumor"]):
		if _has_any_specialty_id(assigned_specialties, ["negotiation", "deception", "intimidation"]):
			return true
		return _assigned_has_resource(assigned_cards, ["gift", "silver_pack", "sealed_letter", "calming_incense"])
	return true

func _assigned_has_resource(assigned_cards: Array, resource_ids: Array[String]) -> bool:
	for card_variant in assigned_cards:
		var card: Dictionary = card_variant as Dictionary
		if str(card.get("card_type", "")) != "resource":
			continue
		if resource_ids.has(str(card.get("id", ""))):
			return true
	return false

func _assigned_has_all_resources(assigned_cards: Array, resource_ids: Array[String]) -> bool:
	for resource_id in resource_ids:
		if not _assigned_has_resource(assigned_cards, [resource_id]):
			return false
	return true

func _has_any_specialty_id(assigned_specialties: Array[String], specialty_ids: Array[String]) -> bool:
	for specialty_id in specialty_ids:
		if assigned_specialties.has(specialty_id):
			return true
	return false

func _join_attribute_labels(attribute_keys: Array[String]) -> String:
	var labels: Array[String] = []
	for key in attribute_keys:
		labels.append(TextDB.get_text("system.attributes.%s" % key, key))
	return TextDB.get_text("ui.list_separator").join(labels)

func _join_specialty_labels(specialties: Array[String]) -> String:
	var labels: Array[String] = []
	for specialty in specialties:
		labels.append(TextDB.get_text("system.specialties.%s" % specialty, specialty))
	return TextDB.get_text("ui.list_separator").join(labels)

func _join_resource_labels(resource_ids: Array[String]) -> String:
	var labels: Array[String] = []
	for resource_id in resource_ids:
		labels.append(TextDB.get_text("resources.%s.name" % resource_id, resource_id))
	return TextDB.get_text("ui.list_separator").join(labels)

func _required_resource_ids(event: EventData) -> Array[String]:
	var result: Array[String] = []
	for resource_id_variant in event.required_resource_ids:
		var resource_id: String = str(resource_id_variant)
		if not resource_id.is_empty() and not result.has(resource_id):
			result.append(resource_id)
	return result

func _recommended_resource_ids(event: EventData) -> Array[String]:
	var result: Array[String] = []
	for resource_id_variant in event.recommended_resource_ids:
		var resource_id: String = str(resource_id_variant)
		if not resource_id.is_empty() and not result.has(resource_id):
			result.append(resource_id)
	if not result.is_empty():
		return result
	if _event_has_any_tag(event, ["medicine"]):
		result.append_array(["herbal_tonic", "silver_pack"])
	if _event_has_any_tag(event, ["rest", "mind"]):
		for resource_id in ["calming_incense", "silver_pack"]:
			if not result.has(resource_id):
				result.append(resource_id)
	if _event_has_any_tag(event, ["research", "intel", "document", "secret_report"]):
		for resource_id in ["spy_report", "sealed_letter"]:
			if not result.has(resource_id):
				result.append(resource_id)
	if _event_has_any_tag(event, ["recruit", "search"]):
		for resource_id in ["silver_pack", "recruit_writ"]:
			if not result.has(resource_id):
				result.append(resource_id)
	if _event_has_any_tag(event, ["relation", "rumor"]):
		for resource_id in ["gift", "sealed_letter", "silver_pack"]:
			if not result.has(resource_id):
				result.append(resource_id)
	if _event_has_any_tag(event, ["naval"]):
		for resource_id in ["naval_chart", "spy_report"]:
			if not result.has(resource_id):
				result.append(resource_id)
	return result

func _event_has_any_tag(event: EventData, candidates: Array[String]) -> bool:
	for candidate in candidates:
		if event.tags.has(candidate) or event.recommended_tags.has(candidate):
			return true
	return false

func _has_any_tag(source_tags: Array[String], target_tags: Array[String]) -> bool:
	for tag in source_tags:
		if target_tags.has(tag):
			return true
	return false

func _activate_followups(run_state: RunState, event: EventData) -> void:
	for next_id_variant in event.next_event_ids:
		var next_id: String = str(next_id_variant)
		if next_id == "ember_dream":
			run_state.flags["ember_dream_ready"] = true

func _apply_effect(run_state: RunState, effect_id: String, relation_manager: RelationManager) -> void:
	match effect_id:
		"gain_supply":
			run_state.money += 6
			run_state.resource_states["silver_pack"] = int(run_state.resource_states.get("silver_pack", 0)) + 1
			run_state.morale += 1
			run_state.jingzhou_stability += 1
		"gain_correspondence_cache":
			run_state.resource_states["spy_report"] = int(run_state.resource_states.get("spy_report", 0)) + 1
			run_state.resource_states["sealed_letter"] = int(run_state.resource_states.get("sealed_letter", 0)) + 1
			run_state.flags["scheme_counter_ready"] = true
		"gain_harbor_chart":
			run_state.resource_states["naval_chart"] = int(run_state.resource_states.get("naval_chart", 0)) + 1
			run_state.resource_states["spy_report"] = int(run_state.resource_states.get("spy_report", 0)) + 1
			run_state.naval_readiness += 1
			run_state.flags["east_wind_event_established"] = true
		"gain_market_gift":
			run_state.resource_states["gift"] = int(run_state.resource_states.get("gift", 0)) + 1
			run_state.morale += 1
		"gain_recruit_lead":
			run_state.resource_states["recruit_writ"] = int(run_state.resource_states.get("recruit_writ", 0)) + 1
			run_state.resource_states["sealed_letter"] = int(run_state.resource_states.get("sealed_letter", 0)) + 1
		"stabilize_camp_fever":
			run_state.risk_states["miasma"] = maxi(0, int(run_state.risk_states.get("miasma", 0)) - 1)
			run_state.resource_states["herbal_tonic"] = int(run_state.resource_states.get("herbal_tonic", 0)) + 1
			run_state.morale += 1
			if run_state.roster_ids.has("guo_jia"):
				relation_manager.apply_favor(run_state, "guo_jia", 1)
		"fire_and_risk":
			run_state.fire_progress += 2
			run_state.risk_states["alienation"] = int(run_state.risk_states.get("alienation", 0)) + 1
		"naval_chart":
			run_state.resource_states["naval_chart"] = int(run_state.resource_states.get("naval_chart", 0)) + 1
			run_state.naval_readiness += 2
			run_state.flags["ember_dream_ready"] = true
			run_state.flags["east_wind_event_established"] = true
		"seasick_risk":
			run_state.risk_states["seasick"] = int(run_state.risk_states.get("seasick", 0)) + 1
			run_state.fire_progress += 1
			run_state.flags["iron_chain_event_established"] = true
		"heal_guojia":
			if run_state.active_character_states.has("guo_jia"):
				var guo_stage: int = maxi(1, int(run_state.active_character_states["guo_jia"].get("sick_stage", 1)) - 1)
				run_state.active_character_states["guo_jia"]["sick_stage"] = guo_stage
				run_state.flags["guojia_sick_stage_1"] = guo_stage == 1
				run_state.flags["guojia_sick_stage_2"] = guo_stage == 2
				run_state.flags["guojia_sick_stage_3"] = guo_stage == 3
				relation_manager.apply_favor(run_state, "guo_jia", 1)
		"miasma_risk":
			run_state.risk_states["miasma"] = int(run_state.risk_states.get("miasma", 0)) + 1
			run_state.fire_progress += 1
		"rumor_cleared":
			run_state.jingzhou_stability += 1
			run_state.risk_states["rumor"] = maxi(0, int(run_state.risk_states.get("rumor", 0)) - 1)
			run_state.flags["jingzhou_rumor_active"] = false
		"rumor_risk":
			run_state.risk_states["rumor"] = int(run_state.risk_states.get("rumor", 0)) + 1
			run_state.flags["jingzhou_rumor_active"] = true
		"dream_calm":
			run_state.cao_mind += 2
			run_state.fire_progress = maxi(0, run_state.fire_progress - 1)
			run_state.flags["dream_seen_once"] = true
			run_state.flags["ember_dream_ready"] = false
			run_state.flags["east_wind_event_established"] = true
		"headwind_risk":
			run_state.risk_states["headwind"] = int(run_state.risk_states.get("headwind", 0)) + 1
			run_state.fire_progress += 1
			run_state.flags["dream_seen_once"] = true
			run_state.flags["ember_dream_ready"] = false
		"trust_secured":
			run_state.jingzhou_stability += 1
			relation_manager.apply_favor(run_state, "xun_yu", 2)
			relation_manager.add_rumor_risk(run_state, "xun_yu", -1)
			run_state.flags["scheme_counter_ready"] = true
		"trust_cracked":
			run_state.risk_states["alienation"] = int(run_state.risk_states.get("alienation", 0)) + 1
			run_state.fire_progress += 1
			relation_manager.apply_favor(run_state, "xun_yu", -2)
			relation_manager.add_rumor_risk(run_state, "xun_yu", 1)
		"tutorial_patrol_secured":
			run_state.jingzhou_stability += 1
			run_state.morale += 1
			run_state.fire_progress = maxi(0, run_state.fire_progress - 1)
