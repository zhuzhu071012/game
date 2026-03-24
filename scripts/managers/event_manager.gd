extends Node
class_name EventManager

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
			run_state.active_event_ids.append(event_id)
			run_state.active_event_states[event_id] = {"turns_left": event.timeout_turns}
			spawned.append(event_id)
			if event.trigger_type == "condition":
				run_state.flags["%s_spawned" % event_id] = true
	emit_signal("events_changed")
	return spawned

func resolve_event(run_state: RunState, event_id: String, assigned_cards: Array, relation_manager: RelationManager) -> Array[String]:
	if not event_defs.has(event_id):
		return []
	var event: EventData = event_defs[event_id] as EventData
	var score: int = 0
	var has_character: bool = false
	var has_resource: bool = false
	for card_variant in assigned_cards:
		var card: Dictionary = card_variant as Dictionary
		if str(card.get("card_type", "")) == "character":
			has_character = true
			score += _character_score(card)
		elif str(card.get("card_type", "")) == "resource":
			has_resource = true
			score += 1
	var logs: Array[String] = []
	if has_character and score >= 2:
		_apply_effect(run_state, event.success_effect_id, relation_manager)
		logs.append(TextDB.format_text("logs.events.success", [event.title]))
	elif has_character or has_resource:
		run_state.fire_progress += 1
		logs.append(TextDB.format_text("logs.events.partial", [event.title]))
	else:
		_apply_effect(run_state, event.fail_effect_id, relation_manager)
		logs.append(TextDB.format_text("logs.events.fail", [event.title]))
	_clear_event(run_state, event_id)
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
			if event.id == "guojia_relapse":
				return run_state.roster_ids.has("guo_jia") and int(run_state.active_character_states["guo_jia"]["sick_stage"]) >= 2 and not bool(run_state.flags.get("guojia_relapse_spawned", false))
			if event.id == "jingzhou_whispers":
				return run_state.jingzhou_stability <= 4 and not bool(run_state.flags.get("jingzhou_whispers_spawned", false))
			if event.id == "ember_dream":
				return bool(run_state.flags.get("ember_dream_ready", false)) and not bool(run_state.flags.get("dream_seen_once", false))
	return false

func _character_score(card: Dictionary) -> int:
	var tags: Array = card.get("tags", [])
	if "scheme" in tags or "steady" in tags or "military" in tags or "relation" in tags or "medicine" in tags:
		return 2
	return 1

func _apply_effect(run_state: RunState, effect_id: String, relation_manager: RelationManager) -> void:
	match effect_id:
		"gain_supply":
			run_state.money += 8
			run_state.morale += 1
		"fire_and_risk":
			run_state.fire_progress += 2
			run_state.risk_states["alienation"] += 1
		"naval_chart":
			run_state.resource_states["naval_chart"] += 1
			run_state.naval_readiness += 2
		"seasick_risk":
			run_state.risk_states["seasick"] += 1
			run_state.fire_progress += 1
		"heal_guojia":
			run_state.active_character_states["guo_jia"]["sick_stage"] = maxi(1, int(run_state.active_character_states["guo_jia"]["sick_stage"]) - 1)
			run_state.flags["guojia_sick_stage_2"] = false
			run_state.flags["guojia_sick_stage_1"] = true
			relation_manager.apply_favor(run_state, "guo_jia", 1)
		"miasma_risk":
			run_state.risk_states["miasma"] += 1
			run_state.fire_progress += 1
		"rumor_cleared":
			run_state.jingzhou_stability += 1
			run_state.risk_states["rumor"] = maxi(0, int(run_state.risk_states["rumor"]) - 1)
			run_state.flags["jingzhou_rumor_active"] = false
		"rumor_risk":
			run_state.risk_states["rumor"] += 1
			run_state.flags["jingzhou_rumor_active"] = true
		"dream_calm":
			run_state.cao_mind += 2
			run_state.flags["dream_seen_once"] = true
			run_state.flags["ember_dream_ready"] = false
		"headwind_risk":
			run_state.risk_states["headwind"] += 1
			run_state.flags["dream_seen_once"] = true
			run_state.flags["ember_dream_ready"] = false
