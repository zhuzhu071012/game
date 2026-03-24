extends Node
class_name TurnManager

const RECRUIT_CHARACTER_CHANCE: float = 1.0

signal turn_finished

func resolve_turn(run_state: RunState, board_manager: BoardManager, event_manager: EventManager, relation_manager: RelationManager, characters: Dictionary, resources: Dictionary) -> Array[String]:
	var logs: Array[String] = []
	logs.append(TextDB.format_text("logs.turn.start", [run_state.turn_index]))
	logs.append_array(_resolve_slots(run_state, board_manager, relation_manager, characters, resources))
	for event_id_variant in run_state.active_event_ids.duplicate():
		var event_id: String = str(event_id_variant)
		logs.append_array(event_manager.resolve_event(run_state, event_id, board_manager.get_event_cards(event_id), relation_manager))
	logs.append_array(_consume_committed_resources(run_state, board_manager, resources))
	logs.append_array(event_manager.advance_unresolved_events(run_state, relation_manager))
	logs.append_array(_advance_guojia_condition(run_state))
	if int(run_state.risk_states.get("headwind", 0)) > 0:
		run_state.flags["first_headwind_seen"] = true
	_sync_risk_flags(run_state)
	logs.append_array(GameRules.apply_risk_penalties(run_state, GameData.create_risks()))
	GameRules.clamp_stats(run_state)
	run_state.turn_index += 1
	if run_state.turn_index in [3, 5]:
		run_state.stage_index += 1
	var spawned: Array[String] = event_manager.spawn_events_for_turn(run_state)
	for event_id in spawned:
		var event: EventData = event_manager.event_defs[event_id] as EventData
		logs.append(TextDB.format_text("logs.turn.spawned", [event.title]))
	board_manager.reset_turn_targets(run_state.active_event_ids)
	run_state.log_entries.append_array(logs)
	emit_signal("turn_finished")
	return logs

func _resolve_slots(run_state: RunState, board_manager: BoardManager, relation_manager: RelationManager, characters: Dictionary, resources: Dictionary) -> Array[String]:
	var logs: Array[String] = []
	logs.append_array(_resolve_governance(run_state, board_manager.get_slot_cards("governance"), relation_manager))
	logs.append_array(_resolve_audience(run_state, board_manager.get_slot_cards("audience"), relation_manager))
	logs.append_array(_resolve_research(run_state, board_manager.get_slot_cards("research"), relation_manager))
	logs.append_array(_resolve_recruit(run_state, board_manager.get_slot_cards("recruit"), relation_manager, characters, resources))
	logs.append_array(_resolve_rest(run_state, board_manager.get_slot_cards("rest"), relation_manager))
	return logs

func _resolve_governance(run_state: RunState, cards: Array, relation_manager: RelationManager) -> Array[String]:
	var logs: Array[String] = []
	var used_governance: bool = false
	for card_variant in cards:
		var card: Dictionary = card_variant as Dictionary
		if str(card.get("card_type", "")) != "character":
			continue
		used_governance = true
		var character_id: String = str(card.get("id", ""))
		match character_id:
			"cao_cao":
				run_state.money += 12
				run_state.cao_mind -= 1
				logs.append(TextDB.get_text("logs.slots.governance.cao_cao"))
			"zhang_liao":
				run_state.morale += 2
				logs.append(TextDB.get_text("logs.slots.governance.zhang_liao"))
			"yu_jin":
				run_state.jingzhou_stability += 1
				run_state.morale += 1
				logs.append(TextDB.get_text("logs.slots.governance.yu_jin"))
			"xun_you":
				run_state.money += 5
				run_state.jingzhou_stability += 1
				logs.append(TextDB.get_text("logs.slots.governance.xun_you"))
			_:
				run_state.money += 3
				logs.append(TextDB.get_text("logs.slots.governance.other"))
		if character_id != "cao_cao":
			relation_manager.apply_favor(run_state, character_id, 1)
	if used_governance and not bool(run_state.flags.get("first_governance_done", false)):
		run_state.flags["first_governance_done"] = true
		run_state.resource_states["sealed_letter"] = int(run_state.resource_states.get("sealed_letter", 0)) + 1
		logs.append(TextDB.get_text("logs.slots.governance.first"))
	return logs

func _resolve_audience(run_state: RunState, cards: Array, relation_manager: RelationManager) -> Array[String]:
	var logs: Array[String] = []
	var has_cao: bool = false
	var partner_id: String = ""
	var used_resource: bool = false
	for card_variant in cards:
		var card: Dictionary = card_variant as Dictionary
		var card_type: String = str(card.get("card_type", ""))
		var card_id: String = str(card.get("id", ""))
		if card_type == "character" and card_id == "cao_cao":
			has_cao = true
		elif card_type == "character":
			partner_id = card_id
		elif card_type == "resource":
			used_resource = true
	if has_cao and not partner_id.is_empty():
		match partner_id:
			"guo_jia":
				relation_manager.apply_favor(run_state, partner_id, 2)
				run_state.cao_mind -= 1
			"jia_xu":
				relation_manager.apply_favor(run_state, partner_id, 1)
				run_state.risk_states["rumor"] = maxi(0, int(run_state.risk_states["rumor"]) - 1)
			"bian_furen":
				relation_manager.apply_favor(run_state, partner_id, 2)
				run_state.cao_mind += 1
				run_state.flags["jingzhou_rumor_active"] = false
			_:
				relation_manager.apply_favor(run_state, partner_id, 1)
		logs.append(TextDB.get_text("logs.slots.audience.success"))
		if used_resource:
			run_state.money -= 2
			relation_manager.apply_favor(run_state, partner_id, 1)
			logs.append(TextDB.get_text("logs.slots.audience.gift"))
	elif not cards.is_empty():
		run_state.fire_progress += 1
		logs.append(TextDB.get_text("logs.slots.audience.misfire"))
	return logs

func _resolve_research(run_state: RunState, cards: Array, relation_manager: RelationManager) -> Array[String]:
	var logs: Array[String] = []
	var has_person: bool = false
	var discovered: bool = false
	for card_variant in cards:
		var card: Dictionary = card_variant as Dictionary
		var card_type: String = str(card.get("card_type", ""))
		var card_id: String = str(card.get("id", ""))
		if card_type == "character":
			has_person = true
			if card_id in ["guo_jia", "xun_you"]:
				discovered = true
		if card_type == "resource" and card_id in ["spy_report", "sealed_letter"]:
			discovered = true
	if has_person:
		if discovered and int(run_state.resource_states["naval_chart"]) == 0:
			run_state.resource_states["naval_chart"] = 1
			run_state.naval_readiness += 1
			logs.append(TextDB.get_text("logs.slots.research.discovery"))
		else:
			run_state.money += 2
			logs.append(TextDB.get_text("logs.slots.research.routine"))
		for card_variant in cards:
			var card2: Dictionary = card_variant as Dictionary
			if str(card2.get("card_type", "")) == "character" and str(card2.get("id", "")) != "cao_cao":
				relation_manager.apply_favor(run_state, str(card2.get("id", "")), 1)
	return logs

func _resolve_recruit(run_state: RunState, cards: Array, relation_manager: RelationManager, characters: Dictionary, resources: Dictionary) -> Array[String]:
	var logs: Array[String] = []
	var has_money: bool = false
	var has_task: bool = false
	var extra_help: bool = false
	for card_variant in cards:
		var card: Dictionary = card_variant as Dictionary
		var card_type: String = str(card.get("card_type", ""))
		var card_id: String = str(card.get("id", ""))
		if card_type == "resource" and card_id == "silver_pack":
			has_money = true
		if card_type == "resource" and card_id == "recruit_writ":
			has_task = true
		if card_type == "character" and card_id in ["cao_cao", "jia_xu"]:
			extra_help = true
	if has_money and has_task and run_state.money >= 10 and not run_state.locked_character_ids.is_empty():
		run_state.money -= 10
		var found_character: bool = randf() <= RECRUIT_CHARACTER_CHANCE
		if found_character:
			var pick_index: int = randi() % run_state.locked_character_ids.size()
			var new_id: String = str(run_state.locked_character_ids[pick_index])
			run_state.locked_character_ids.remove_at(pick_index)
			run_state.roster_ids.append(new_id)
			if new_id == "guo_jia":
				relation_manager.apply_favor(run_state, new_id, 1)
			if extra_help:
				run_state.resource_states["spy_report"] += 1
			if not bool(run_state.flags.get("first_recruit_done", false)):
				run_state.flags["first_recruit_done"] = true
			var joined: CharacterData = characters[new_id] as CharacterData
			logs.append(TextDB.format_text("logs.slots.recruit.success", [joined.display_name]))
		else:
			var reward_id_fail: String = "spy_report" if int(run_state.resource_states["spy_report"]) < 2 else "herbal_tonic"
			run_state.resource_states[reward_id_fail] += 1
			var reward_name_fail: String = TextDB.get_text("resources.%s.name" % reward_id_fail, reward_id_fail)
			logs.append(TextDB.format_text("logs.slots.recruit.lead", [reward_name_fail]))
	elif has_money or has_task:
		var reward_id: String = "spy_report" if int(run_state.resource_states["spy_report"]) < 2 else "herbal_tonic"
		run_state.resource_states[reward_id] += 1
		var reward_name: String = TextDB.get_text("resources.%s.name" % reward_id, reward_id)
		logs.append(TextDB.format_text("logs.slots.recruit.lead", [reward_name]))
	elif not cards.is_empty():
		logs.append(TextDB.get_text("logs.slots.recruit.failed"))
	return logs

func _resolve_rest(run_state: RunState, cards: Array, relation_manager: RelationManager) -> Array[String]:
	var logs: Array[String] = []
	var used_tonic: bool = false
	for card_variant in cards:
		var card: Dictionary = card_variant as Dictionary
		if str(card.get("card_type", "")) == "resource" and str(card.get("id", "")) in ["herbal_tonic", "calming_incense"]:
			used_tonic = true
	for card_variant in cards:
		var card2: Dictionary = card_variant as Dictionary
		if str(card2.get("card_type", "")) != "character":
			continue
		match str(card2.get("id", "")):
			"cao_cao":
				run_state.cao_health += 2
				if used_tonic:
					run_state.cao_mind += 1
				if run_state.turn_index >= 2 and not bool(run_state.flags["dream_seen_once"]):
					run_state.flags["ember_dream_ready"] = true
			"guo_jia":
				run_state.active_character_states["guo_jia"]["sick_stage"] = maxi(1, int(run_state.active_character_states["guo_jia"]["sick_stage"]) - 1)
				relation_manager.apply_favor(run_state, "guo_jia", 1)
			"physician":
				run_state.active_character_states["guo_jia"]["guarded"] = true
			"bian_furen":
				run_state.cao_mind += 1
				run_state.risk_states["headwind"] = maxi(0, int(run_state.risk_states["headwind"]) - 1)
	if not cards.is_empty():
		logs.append(TextDB.get_text("logs.slots.rest.done"))
	return logs

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
	run_state.resource_states[resource_id] = maxi(0, int(run_state.resource_states[resource_id]) - 1)
	return [TextDB.format_text("logs.resources.consumed", [resource.display_name])]

func _advance_guojia_condition(run_state: RunState) -> Array[String]:
	var logs: Array[String] = []
	if not run_state.roster_ids.has("guo_jia"):
		return logs
	var state: Dictionary = run_state.active_character_states["guo_jia"]
	if bool(state.get("guarded", false)):
		state["guarded"] = false
		run_state.active_character_states["guo_jia"] = state
		return logs
	state["sick_stage"] = clampi(int(state.get("sick_stage", 1)) + 1, 1, 3)
	run_state.active_character_states["guo_jia"] = state
	run_state.flags["guojia_sick_stage_1"] = int(state["sick_stage"]) == 1
	run_state.flags["guojia_sick_stage_2"] = int(state["sick_stage"]) == 2
	run_state.flags["guojia_sick_stage_3"] = int(state["sick_stage"]) == 3
	if int(state["sick_stage"]) >= 2:
		logs.append(TextDB.format_text("logs.guojia.stage_up", [int(state["sick_stage"])]))
	if int(state["sick_stage"]) == 3:
		run_state.risk_states["miasma"] += 1
		logs.append(TextDB.get_text("logs.guojia.miasma"))
	return logs

func _sync_risk_flags(run_state: RunState) -> void:
	for risk_id_variant in run_state.risk_states.keys():
		var risk_id: String = str(risk_id_variant)
		for level in [1, 2, 3]:
			run_state.flags["risk_%s_%d" % [risk_id, level]] = int(run_state.risk_states[risk_id]) == level
