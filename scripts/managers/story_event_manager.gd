extends RefCounted
class_name StoryEventManager

const DEFINITIONS_PATH := "res://data/definitions/story_events.json"
const DEFAULT_PARTIAL_MARGIN := 2

var _event_order: Array[String] = []
var _event_defs: Dictionary = {}

func setup() -> void:
	var root: Dictionary = _load_json_dictionary(DEFINITIONS_PATH)
	_event_order.clear()
	_event_defs.clear()
	for event_id_variant in _to_string_array(root.get("event_order", [])):
		_event_order.append(event_id_variant)
	var defs: Variant = root.get("events", {})
	if defs is Dictionary:
		_event_defs = (defs as Dictionary).duplicate(true)
	if _event_order.is_empty():
		for event_id_variant in _event_defs.keys():
			_event_order.append(str(event_id_variant))

func has_pending_events(run_state: RunState) -> bool:
	_ensure_story_state(run_state)
	return not run_state.story_event_queue.is_empty()

func pending_count(run_state: RunState) -> int:
	_ensure_story_state(run_state)
	var count: int = 0
	for item_variant in run_state.story_event_queue:
		var item: Dictionary = item_variant as Dictionary
		var event_id: String = str(item.get("event_id", ""))
		if bool(item.get("board_active", false)):
			continue
		if is_story_board_event(run_state, event_id):
			continue
		count += 1
	return count

func queue_events_after_turn(run_state: RunState, resolved_turn_index: int) -> Array[Dictionary]:
	_ensure_story_state(run_state)
	var queued: Array[Dictionary] = []
	if run_state == null or run_state.game_over:
		return queued
	if not bool(run_state.flags.get("tutorial_completed", false)):
		return queued
	for event_id in _event_order:
		if not _event_defs.has(event_id):
			continue
		if _is_resolved_or_queued(run_state, event_id):
			continue
		var event_def: Dictionary = _event_defs[event_id] as Dictionary
		if not _matches_trigger(run_state, event_def, resolved_turn_index):
			continue
		var instance: Dictionary = {
			"event_id": event_id,
			"remaining_turns": int(event_def.get("time_limit_turns", 1)),
			"queued_turn": resolved_turn_index
		}
		run_state.story_event_queue.append(instance)
		if event_skips_choice(event_id):
			var default_plan_id: String = _default_plan_id(event_id)
			if not default_plan_id.is_empty():
				_activate_board_event_instance(run_state, event_id, default_plan_id, int(instance.get("remaining_turns", 1)))
				var queue_index: int = _find_event_instance_index(run_state, event_id)
				if queue_index >= 0:
					instance = run_state.story_event_queue[queue_index] as Dictionary
		queued.append(instance.duplicate(true))
	return queued

func current_event_instance(run_state: RunState) -> Dictionary:
	_ensure_story_state(run_state)
	for item_variant in run_state.story_event_queue:
		var item: Dictionary = item_variant as Dictionary
		var event_id: String = str(item.get("event_id", ""))
		if bool(item.get("board_active", false)):
			continue
		if is_story_board_event(run_state, event_id):
			continue
		return item.duplicate(true)
	return {}

func current_event_id(run_state: RunState) -> String:
	var instance: Dictionary = current_event_instance(run_state)
	return str(instance.get("event_id", ""))

func event_title(event_id: String) -> String:
	return TextDB.get_text("story_events.events.%s.title" % event_id, event_id)

func board_event_title(run_state: RunState, event_id: String) -> String:
	var base_title: String = event_title(event_id)
	var plan_id: String = _resolved_plan_id(run_state, event_id)
	if plan_id.is_empty():
		return base_title
	return "%s：%s" % [base_title, plan_title(event_id, plan_id)]

func event_definition(event_id: String) -> Dictionary:
	return (_event_defs.get(event_id, {}) as Dictionary).duplicate(true)

func event_skips_choice(event_id: String) -> bool:
	var event_def: Dictionary = _event_defs.get(event_id, {}) as Dictionary
	return bool(event_def.get("skip_choice", false))

func plan_ids(event_id: String) -> Array[String]:
	var result: Array[String] = []
	var event_def: Dictionary = _event_defs.get(event_id, {}) as Dictionary
	var plans: Dictionary = event_def.get("plans", {}) as Dictionary
	for plan_id_variant in plans.keys():
		result.append(str(plan_id_variant))
	return result

func plan_title(event_id: String, plan_id: String) -> String:
	return TextDB.get_text("story_events.events.%s.plans.%s.title" % [event_id, plan_id], plan_id)

func plan_summary(event_id: String, plan_id: String) -> String:
	return TextDB.get_text("story_events.events.%s.plans.%s.summary" % [event_id, plan_id], "")

func plan_camp_preview(event_id: String, plan_id: String) -> Dictionary:
	var preview: Dictionary = {}
	var score_by_key: Dictionary = {}
	var positive_by_key: Dictionary = {}
	var negative_by_key: Dictionary = {}
	var plan_def: Dictionary = _plan_definition(event_id, plan_id)
	if plan_def.is_empty():
		return preview
	var effects_root: Dictionary = plan_def.get("effects", {}) as Dictionary
	for outcome_id in ["success", "partial_success", "failure"]:
		for effect_variant in effects_root.get(outcome_id, []):
			if effect_variant is not Dictionary:
				continue
			var effect: Dictionary = effect_variant as Dictionary
			if str(effect.get("type", "")) != "camp_delta":
				continue
			var key: String = str(effect.get("key", ""))
			var value: int = int(effect.get("value", 0))
			if key.is_empty() or value == 0:
				continue
			score_by_key[key] = int(score_by_key.get(key, 0)) + sign(value)
			if value > 0:
				positive_by_key[key] = true
			elif value < 0:
				negative_by_key[key] = true
	for key_variant in score_by_key.keys():
		var key: String = str(key_variant)
		var has_positive: bool = bool(positive_by_key.get(key, false))
		var has_negative: bool = bool(negative_by_key.get(key, false))
		var direction: int = 0
		if has_positive and not has_negative:
			direction = 1
		elif has_negative and not has_positive:
			direction = -1
		else:
			var score: int = int(score_by_key.get(key, 0))
			direction = 1 if score > 0 else (-1 if score < 0 else 0)
		if direction != 0:
			preview[key] = direction
	return preview

func board_requirement_lines(event_id: String, plan_id: String) -> Array[String]:
	var plan_def: Dictionary = _plan_definition(event_id, plan_id)
	var lines: Array[String] = []
	if _character_required(plan_def):
		var character_ids: Array[String] = _required_character_ids(plan_def)
		if not character_ids.is_empty():
			var character_names: Array[String] = []
			for character_id in character_ids:
				character_names.append(TextDB.get_text("characters.%s.name" % character_id, character_id))
			lines.append("%s：%s" % [TextDB.get_text("story_events.ui.board_need_character"), TextDB.get_text("ui.list_separator").join(character_names)])
		else:
			lines.append(TextDB.get_text("story_events.ui.board_need_character"))
	var required_resources: Dictionary = _resource_requirements(plan_def)
	if not required_resources.is_empty():
		for resource_id_variant in required_resources.keys():
			var resource_id: String = str(resource_id_variant)
			lines.append("%s ×%d" % [TextDB.get_text("resources.%s.name" % resource_id, resource_id), int(required_resources.get(resource_id, 0))])
		return lines
	var allowed_resources: Array[String] = _allowed_resource_ids(plan_def)
	if not allowed_resources.is_empty():
		lines.append(TextDB.format_text("story_events.ui.board_optional_resources", [_join_resource_names(allowed_resources)]))
	return lines

func board_requirement_text(event_id: String, plan_id: String) -> String:
	return TextDB.get_text("ui.list_separator").join(board_requirement_lines(event_id, plan_id))

func build_current_event_view(run_state: RunState) -> Dictionary:
	var instance: Dictionary = current_event_instance(run_state)
	if instance.is_empty():
		return {}
	var event_id: String = str(instance.get("event_id", ""))
	var event_def: Dictionary = _event_defs.get(event_id, {}) as Dictionary
	if event_def.is_empty():
		return {}
	var tags: Array[String] = []
	for tag_id_variant in _to_string_array(event_def.get("tag_ids", [])):
		var tag_id: String = str(tag_id_variant)
		tags.append(TextDB.get_text("story_events.meta.tags.%s" % tag_id, tag_id))
	var plans: Array[Dictionary] = []
	for plan_id in plan_ids(event_id):
		var plan_def: Dictionary = (event_def.get("plans", {}) as Dictionary).get(plan_id, {}) as Dictionary
		plans.append({
			"id": plan_id,
			"title": TextDB.get_text("story_events.events.%s.plans.%s.title" % [event_id, plan_id], plan_id),
			"summary": TextDB.get_text("story_events.events.%s.plans.%s.summary" % [event_id, plan_id], ""),
			"dc": int(plan_def.get("dc", 12)),
			"camp_preview": plan_camp_preview(event_id, plan_id)
		})
	return {
		"event_id": event_id,
		"title": event_title(event_id),
		"description": TextDB.get_text("story_events.events.%s.description" % event_id, ""),
		"tags": tags,
		"remaining_turns": int(instance.get("remaining_turns", int(event_def.get("time_limit_turns", 1)))),
		"plans": plans
	}

func available_characters(run_state: RunState, character_defs: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if run_state == null:
		return result
	for character_id_variant in run_state.roster_ids:
		var character_id: String = str(character_id_variant)
		var character: CharacterData = character_defs.get(character_id) as CharacterData
		if character == null:
			continue
		result.append({
			"id": character_id,
			"name": character.display_name
		})
	return result

func available_resources(run_state: RunState, event_id: String, plan_id: String, resource_defs: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var plan_def: Dictionary = _plan_definition(event_id, plan_id)
	if plan_def.is_empty():
		return result
	var seen: Array[String] = []
	for resource_id in _allowed_resource_ids(plan_def):
		if seen.has(resource_id):
			continue
		seen.append(resource_id)
		var available_amount: int = int(run_state.resource_states.get(resource_id, 0))
		var resource: ResourceCardData = resource_defs.get(resource_id) as ResourceCardData
		var display_name: String = resource.display_name if resource != null else resource_id
		result.append({
			"id": resource_id,
			"name": display_name,
			"available": available_amount,
			"required": int((_resource_requirements(plan_def) as Dictionary).get(resource_id, 0)),
			"max_assign": mini(available_amount, _resource_cap(plan_def, resource_id, available_amount))
		})
	return result

func preview_current_event(
	run_state: RunState,
	plan_id: String,
	character_id: String,
	resource_allocations: Dictionary,
	character_defs: Dictionary,
	resource_defs: Dictionary
) -> Dictionary:
	var event_id: String = current_event_id(run_state)
	return preview_event(run_state, event_id, plan_id, character_id, resource_allocations, character_defs, resource_defs)

func preview_event(
	run_state: RunState,
	event_id: String,
	plan_id: String,
	character_id: String,
	resource_allocations: Dictionary,
	character_defs: Dictionary,
	resource_defs: Dictionary
) -> Dictionary:
	var plan_def: Dictionary = _plan_definition(event_id, plan_id)
	var event_def: Dictionary = _event_defs.get(event_id, {}) as Dictionary
	var normalized_resources: Dictionary = _normalize_resource_allocations(run_state, plan_def, resource_allocations)
	var errors: Array[String] = []
	var attribute_modifier: int = 0
	var specialty_modifier: int = 0
	var resource_modifier: int = _resource_modifier(plan_def, normalized_resources)
	var plan_modifier: int = int(plan_def.get("plan_modifier", 0))
	var state_modifier: int = 0
	var environment_modifier: int = _environment_modifier(run_state, event_def)
	var character_required: bool = _character_required(plan_def)
	var required_character_ids: Array[String] = _required_character_ids(plan_def)
	if character_required and character_id.is_empty():
		errors.append(TextDB.get_text("story_events.ui.errors.character_required"))
	elif not character_id.is_empty():
		var character: CharacterData = character_defs.get(character_id) as CharacterData
		if character == null:
			errors.append(TextDB.get_text("story_events.ui.errors.character_required"))
		else:
			if not required_character_ids.is_empty() and not required_character_ids.has(character_id):
				errors.append(TextDB.get_text("story_events.ui.errors.character_required"))
			attribute_modifier = _attribute_modifier_sum(character, _to_string_array(plan_def.get("attribute_keys", [])))
			specialty_modifier = _specialty_modifier(character, _to_string_array(plan_def.get("specialty_tags", [])))
			state_modifier = _state_modifier(character, run_state.active_character_states.get(character_id, {}) as Dictionary)
	var required_resources: Dictionary = _resource_requirements(plan_def)
	for resource_id_variant in required_resources.keys():
		var resource_id: String = str(resource_id_variant)
		var required_amount: int = int(required_resources.get(resource_id, 0))
		var assigned_amount: int = int(normalized_resources.get(resource_id, 0))
		if assigned_amount < required_amount:
			var resource_name: String = _resource_display_name(resource_id, resource_defs)
			errors.append(TextDB.format_text("story_events.ui.errors.resource_required", [resource_name]))
	for resource_id_variant in normalized_resources.keys():
		var resource_id: String = str(resource_id_variant)
		var assigned_amount: int = int(normalized_resources.get(resource_id, 0))
		var available_amount: int = int(run_state.resource_states.get(resource_id, 0))
		if assigned_amount > available_amount:
			var resource_name: String = _resource_display_name(resource_id, resource_defs)
			errors.append(TextDB.format_text("story_events.ui.errors.resource_overflow", [resource_name]))
	var total_modifier: int = attribute_modifier + specialty_modifier + resource_modifier + plan_modifier + state_modifier + environment_modifier
	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"event_id": event_id,
		"plan_id": plan_id,
		"character_id": character_id,
		"resource_allocations": normalized_resources,
		"dc": int(plan_def.get("dc", 12)),
		"partial_margin": int(plan_def.get("partial_margin", DEFAULT_PARTIAL_MARGIN)),
		"attribute_modifier": attribute_modifier,
		"specialty_modifier": specialty_modifier,
		"resource_modifier": resource_modifier,
		"plan_modifier": plan_modifier,
		"state_modifier": state_modifier,
		"environment_modifier": environment_modifier,
		"total_modifier": total_modifier
	}

func resolve_current_event(
	run_state: RunState,
	plan_id: String,
	character_id: String,
	resource_allocations: Dictionary,
	character_defs: Dictionary,
	resource_defs: Dictionary
) -> Dictionary:
	_ensure_story_state(run_state)
	var event_id: String = current_event_id(run_state)
	if event_id.is_empty():
		return {"ok": false}
	var preview: Dictionary = preview_event(run_state, event_id, plan_id, character_id, resource_allocations, character_defs, resource_defs)
	if not bool(preview.get("valid", false)):
		return {
			"ok": false,
			"errors": preview.get("errors", [])
		}
	var roll_value: int = GameRules.roll_2d6()
	var dc: int = int(preview.get("dc", 12))
	var final_score: int = roll_value + int(preview.get("total_modifier", 0))
	var partial_margin: int = int(preview.get("partial_margin", DEFAULT_PARTIAL_MARGIN))
	var outcome: String = _classify_outcome(final_score, dc, partial_margin)
	var consumed: Array[Dictionary] = _consume_resources(run_state, preview.get("resource_allocations", {}) as Dictionary)
	var effect_summaries: Array[String] = _apply_outcome_effects(run_state, event_id, plan_id, outcome)
	_mark_event_resolved(run_state, event_id)
	var plan_title: String = TextDB.get_text("story_events.events.%s.plans.%s.title" % [event_id, plan_id], plan_id)
	var outcome_label: String = TextDB.get_text("story_events.ui.outcome_%s" % outcome, outcome)
	var result_text: String = _build_result_text(event_id, plan_id, outcome, roll_value, final_score, int(preview.get("total_modifier", 0)), dc, effect_summaries, consumed)
	var report_line: String = TextDB.format_text("story_events.logs.resolved", [event_title(event_id), plan_title, outcome_label])
	return {
		"ok": true,
		"event_id": event_id,
		"plan_id": plan_id,
		"plan_title": plan_title,
		"outcome": outcome,
		"roll": roll_value,
		"dc": dc,
		"final_score": final_score,
		"total_modifier": int(preview.get("total_modifier", 0)),
		"effect_summaries": effect_summaries,
		"consumed": consumed,
		"result_text": result_text,
		"report_lines": [report_line]
	}

func current_event_requires_choice(run_state: RunState) -> bool:
	_ensure_story_state(run_state)
	var instance: Dictionary = current_event_instance(run_state)
	if instance.is_empty():
		return false
	var event_id: String = str(instance.get("event_id", ""))
	if event_id.is_empty():
		return false
	return not is_story_board_event(run_state, event_id)

func is_story_board_event(run_state: RunState, event_id: String) -> bool:
	if run_state == null or event_id.is_empty():
		return false
	var state: Dictionary = run_state.active_event_states.get(event_id, {}) as Dictionary
	return bool(state.get("story_event", false))

func sync_active_board_events(run_state: RunState, event_defs: Dictionary) -> void:
	if run_state == null:
		return
	for event_id_variant in run_state.active_event_ids:
		var event_id: String = str(event_id_variant)
		if not is_story_board_event(run_state, event_id):
			continue
		var runtime_event: EventData = build_board_event_data(run_state, event_id)
		if runtime_event != null:
			event_defs[event_id] = runtime_event

func build_board_event_data(run_state: RunState, event_id: String) -> EventData:
	var event_def: Dictionary = _event_defs.get(event_id, {}) as Dictionary
	if event_def.is_empty():
		return null
	var plan_id: String = _resolved_plan_id(run_state, event_id)
	var plan_def: Dictionary = _plan_definition(event_id, plan_id)
	var runtime_event: EventData = EventData.new()
	runtime_event.id = event_id
	runtime_event.title = event_title(event_id)
	runtime_event.description = TextDB.get_text("story_events.events.%s.description" % event_id, "")
	runtime_event.category = "story"
	runtime_event.tags = _to_string_array(event_def.get("tag_ids", []))
	runtime_event.timeout_turns = int((run_state.active_event_states.get(event_id, {}) as Dictionary).get("timeout_total", int(event_def.get("time_limit_turns", 1))))
	runtime_event.minimum_requirement = 1
	runtime_event.success_threshold = 99
	runtime_event.difficulty_class = int(plan_def.get("dc", 12))
	runtime_event.art_path = "res://assets/cards/event_placeholder.svg"
	return runtime_event

func describe_board_event(run_state: RunState, event_id: String) -> String:
	var sections: Array[String] = []
	var description: String = TextDB.get_text("story_events.events.%s.description" % event_id, "")
	if not description.strip_edges().is_empty():
		sections.append(description)
	var plan_id: String = _resolved_plan_id(run_state, event_id)
	var attribute_hint: String = _board_attribute_hint(event_id, plan_id)
	if not attribute_hint.strip_edges().is_empty():
		sections.append(attribute_hint)
	return "\n\n".join(sections)

func can_assign_to_board_event(run_state: RunState, event_id: String, payload: Dictionary, slot_type: String = "") -> bool:
	if not is_story_board_event(run_state, event_id):
		return true
	if payload.is_empty():
		return false
	var target_slot: String = slot_type if not slot_type.is_empty() else str(payload.get("card_type", ""))
	var state: Dictionary = run_state.active_event_states.get(event_id, {}) as Dictionary
	var filters: Dictionary = state.get("story_event_slot_filters", {}) as Dictionary
	if not filters.has(target_slot):
		return false
	var filter: Dictionary = filters[target_slot] as Dictionary
	var payload_type: String = str(payload.get("card_type", ""))
	if payload_type != target_slot:
		return false
	var payload_id: String = str(payload.get("id", ""))
	var allowed_types: Array = filter.get("allowed_card_types", [])
	if not allowed_types.is_empty() and not allowed_types.has(payload_type):
		return false
	var allowed_ids: Array = filter.get("allowed_card_ids", [])
	if not allowed_ids.is_empty() and not allowed_ids.has(payload_id):
		return false
	var blocked_ids: Array = filter.get("blocked_card_ids", [])
	if blocked_ids.has(payload_id):
		return false
	var required_tags: Array = filter.get("required_tags", [])
	if required_tags.is_empty():
		return true
	var tags: Array = payload.get("tags", [])
	for tag_variant in required_tags:
		if tags.has(tag_variant):
			return true
	return false

func commit_current_event_plan(run_state: RunState, plan_id: String) -> Dictionary:
	_ensure_story_state(run_state)
	var instance: Dictionary = current_event_instance(run_state)
	if instance.is_empty():
		return {"ok": false}
	var event_id: String = str(instance.get("event_id", ""))
	var plan_def: Dictionary = _plan_definition(event_id, plan_id)
	if event_id.is_empty() or plan_def.is_empty():
		return {"ok": false}
	var remaining_turns: int = int(instance.get("remaining_turns", 1))
	var state: Dictionary = _activate_board_event_instance(run_state, event_id, plan_id, remaining_turns, false)
	if bool(plan_def.get("instant_resolve", false)):
		var outcome: String = str(plan_def.get("instant_outcome", "success"))
		var effect_summaries: Array[String] = _apply_outcome_effects(run_state, event_id, plan_id, outcome)
		var result_text: String = _build_result_text(event_id, plan_id, outcome, -1, -1, 0, 0, effect_summaries, [])
		_mark_event_resolved(run_state, event_id)
		return {
			"ok": true,
			"event_id": event_id,
			"plan_id": plan_id,
			"plan_title": plan_title(event_id, plan_id),
			"instant_resolved": true,
			"outcome": outcome,
			"result_text": result_text,
			"report_lines": [TextDB.format_text("story_events.logs.resolved", [event_title(event_id), plan_title(event_id, plan_id), TextDB.get_text("story_events.ui.outcome_%s" % outcome, outcome)])]
		}
	run_state.active_event_states[event_id] = state
	if not run_state.active_event_ids.has(event_id):
		run_state.active_event_ids.append(event_id)
	var index: int = _find_event_instance_index(run_state, event_id)
	if index >= 0:
		instance["selected_plan_id"] = plan_id
		instance["board_active"] = true
		instance["remaining_turns"] = remaining_turns
		run_state.story_event_queue[index] = instance
	return {"ok": true, "event_id": event_id, "plan_id": plan_id, "plan_title": plan_title(event_id, plan_id)}

func resolve_board_event(
	run_state: RunState,
	event_id: String,
	assigned_cards: Array,
	character_defs: Dictionary,
	resource_defs: Dictionary
) -> Dictionary:
	var plan_id: String = _resolved_plan_id(run_state, event_id)
	if plan_id.is_empty():
		return {"resolved": false, "logs": []}
	var plan_def: Dictionary = _plan_definition(event_id, plan_id)
	var character_id: String = _primary_character_id(assigned_cards)
	var resource_allocations: Dictionary = _resource_allocations_from_cards(assigned_cards)
	var preview: Dictionary = preview_event(run_state, event_id, plan_id, character_id, resource_allocations, character_defs, resource_defs)
	var ready: bool = not _character_required(plan_def) or not character_id.is_empty()
	var required_resources: Dictionary = _resource_requirements(plan_def)
	for resource_id_variant in required_resources.keys():
		var resource_id: String = str(resource_id_variant)
		if int(resource_allocations.get(resource_id, 0)) < int(required_resources.get(resource_id, 0)):
			ready = false
			break
	if not ready or not bool(preview.get("valid", false)):
		var turns_left: int = int((run_state.active_event_states.get(event_id, {}) as Dictionary).get("turns_left", 1))
		if turns_left <= 1:
			return {"resolved": false, "logs": [], "presentation_lines": []}
		return {
			"resolved": false,
			"logs": [TextDB.format_text("story_events.logs.pending", [event_title(event_id)])],
			"presentation_lines": [TextDB.format_text("story_events.ui.pending_body", [event_title(event_id)])]
		}
	var dc: int = int(preview.get("dc", 12))
	var roll_value: int = -1
	var die_a: int = 0
	var die_b: int = 0
	var final_score: int = 0
	var outcome: String = "success"
	var dice_payload: Dictionary = {}
	if not bool(plan_def.get("always_success", false)):
		die_a = randi_range(1, 6)
		die_b = randi_range(1, 6)
		roll_value = die_a + die_b
		final_score = roll_value + int(preview.get("total_modifier", 0))
		var partial_margin: int = int(preview.get("partial_margin", DEFAULT_PARTIAL_MARGIN))
		outcome = _classify_outcome(final_score, dc, partial_margin)
		dice_payload = {
			"die_a": die_a,
			"die_b": die_b,
			"roll": roll_value,
			"modifier": int(preview.get("total_modifier", 0)),
			"final_score": final_score,
			"dc": dc,
			"outcome": outcome
		}
	var effect_summaries: Array[String] = _apply_outcome_effects(run_state, event_id, plan_id, outcome)
	var consumed: Array[Dictionary] = _assigned_consumed_resources(resource_allocations, resource_defs)
	var result_text: String = _build_result_text(event_id, plan_id, outcome, roll_value, final_score, int(preview.get("total_modifier", 0)), dc, effect_summaries, consumed)
	var resolved_plan_title: String = plan_title(event_id, plan_id)
	var outcome_label: String = TextDB.get_text("story_events.ui.outcome_%s" % outcome, outcome)
	_clear_board_event(run_state, event_id)
	_mark_event_resolved(run_state, event_id)
	return {"resolved": true, "event_id": event_id, "title": event_title(event_id), "logs": [TextDB.format_text("story_events.logs.resolved", [event_title(event_id), resolved_plan_title, outcome_label])], "presentation_lines": [result_text], "result_text": result_text, "outcome": outcome, "dice": dice_payload}

func advance_unresolved_board_events(run_state: RunState) -> Array[Dictionary]:
	_ensure_story_state(run_state)
	var expired_results: Array[Dictionary] = []
	for event_id_variant in run_state.active_event_ids.duplicate():
		var event_id: String = str(event_id_variant)
		if not is_story_board_event(run_state, event_id):
			continue
		var state: Dictionary = run_state.active_event_states.get(event_id, {}) as Dictionary
		if int(state.get("timeout_total", 1)) <= 0:
			continue
		state["turns_left"] = int(state.get("turns_left", 1)) - 1
		run_state.active_event_states[event_id] = state
		_sync_instance_turns(run_state, event_id, int(state.get("turns_left", 0)))
		if int(state.get("turns_left", 0)) > 0:
			continue
		var plan_id: String = _resolved_plan_id(run_state, event_id)
		var sections: Array[String] = [TextDB.format_text("story_events.ui.expired_body", [event_title(event_id)])]
		var effect_summaries: Array[String] = _apply_timeout_effects(run_state, event_id)
		var timeout_text: String = TextDB.get_text("story_events.events.%s.timeout" % event_id, "")
		if timeout_text.strip_edges().is_empty() and not plan_id.is_empty():
			timeout_text = TextDB.get_text("story_events.events.%s.plans.%s.result.failure" % [event_id, plan_id], "")
			if effect_summaries.is_empty():
				effect_summaries = _apply_outcome_effects(run_state, event_id, plan_id, "failure")
		if not timeout_text.strip_edges().is_empty():
			sections.append(timeout_text)
		if not effect_summaries.is_empty():
			sections.append("[b]%s[/b]\n%s" % [TextDB.get_text("story_events.ui.effect_header"), "\n".join(effect_summaries)])
		_clear_board_event(run_state, event_id)
		_mark_event_resolved(run_state, event_id)
		expired_results.append({"event_id": event_id, "title": event_title(event_id), "logs": [TextDB.format_text("story_events.logs.expired", [event_title(event_id)])], "presentation_lines": ["\n\n".join(sections)]})
	return expired_results

func _build_result_text(
	event_id: String,
	plan_id: String,
	outcome: String,
	roll_value: int,
	final_score: int,
	total_modifier: int,
	dc: int,
	effect_summaries: Array[String],
	consumed: Array[Dictionary]
) -> String:
	var sections: Array[String] = []
	var narrative: String = TextDB.get_text("story_events.events.%s.plans.%s.result.%s" % [event_id, plan_id, outcome], "")
	if not narrative.is_empty():
		sections.append(narrative)
	if roll_value >= 0 and dc > 0:
		sections.append(TextDB.format_text("story_events.ui.roll_summary", [roll_value, total_modifier, final_score, dc]))
	if not effect_summaries.is_empty():
		sections.append("[b]%s[/b]\n%s" % [TextDB.get_text("story_events.ui.effect_header"), "\n".join(effect_summaries)])
	if not consumed.is_empty():
		var consumed_lines: Array[String] = []
		for entry_variant in consumed:
			var entry: Dictionary = entry_variant as Dictionary
			consumed_lines.append(TextDB.format_text("story_events.logs.resource_line", [str(entry.get("name", "")), int(entry.get("amount", 0))]))
		sections.append("[b]%s[/b]\n%s" % [TextDB.get_text("story_events.ui.consumed_header"), "\n".join(consumed_lines)])
	return "\n\n".join(sections)

func _apply_outcome_effects(run_state: RunState, event_id: String, plan_id: String, outcome: String) -> Array[String]:
	var plan_def: Dictionary = _plan_definition(event_id, plan_id)
	var effects_root: Dictionary = plan_def.get("effects", {}) as Dictionary
	var effect_list: Array = effects_root.get(outcome, [])
	var summaries: Array[String] = []
	for effect_variant in effect_list:
		var effect: Dictionary = effect_variant as Dictionary
		var summary: String = _apply_effect(run_state, effect)
		if not summary.is_empty():
			summaries.append(summary)
	return summaries

func _apply_timeout_effects(run_state: RunState, event_id: String) -> Array[String]:
	var event_def: Dictionary = _event_defs.get(event_id, {}) as Dictionary
	var summaries: Array[String] = []
	for effect_variant in event_def.get("timeout_effects", []):
		if effect_variant is not Dictionary:
			continue
		var summary: String = _apply_effect(run_state, effect_variant as Dictionary)
		if not summary.is_empty():
			summaries.append(summary)
	return summaries

func _apply_effect(run_state: RunState, effect: Dictionary) -> String:
	var effect_type: String = str(effect.get("type", ""))
	match effect_type:
		"camp_delta":
			var key: String = str(effect.get("key", ""))
			var amount: int = int(effect.get("value", 0))
			var flag_key: String = "camp_%s_base" % key
			run_state.flags[flag_key] = clampi(int(run_state.flags.get(flag_key, 0)) + amount, 0, 12)
			return _signed_summary("story_events.meta.camp_keys.%s" % key, amount)
		"risk_delta":
			var risk_id: String = str(effect.get("risk_id", ""))
			var amount: int = int(effect.get("value", 0))
			run_state.risk_states[risk_id] = maxi(0, int(run_state.risk_states.get(risk_id, 0)) + amount)
			return _signed_summary("story_events.meta.risks.%s" % risk_id, amount)
		"resource_delta":
			var resource_id: String = str(effect.get("resource_id", ""))
			var amount: int = int(effect.get("value", 0))
			run_state.resource_states[resource_id] = maxi(0, int(run_state.resource_states.get(resource_id, 0)) + amount)
			return _signed_summary("resources.%s.name" % resource_id, amount)
		"flag_set":
			run_state.flags[str(effect.get("key", ""))] = effect.get("value")
			return ""
		"relation_delta":
			var character_id: String = str(effect.get("character_id", ""))
			var amount: int = int(effect.get("value", 0))
			if run_state.relation_states.has(character_id):
				var state: Dictionary = run_state.relation_states[character_id] as Dictionary
				state["favor"] = int(state.get("favor", 0)) + amount
				state["stage_label"] = GameRules.relation_label(int(state.get("favor", 0)))
				run_state.relation_states[character_id] = state
			return _signed_summary("characters.%s.name" % character_id, amount)
		"counter_delta":
			var counter_id: String = str(effect.get("counter_id", ""))
			run_state.story_event_counters[counter_id] = int(run_state.story_event_counters.get(counter_id, 0)) + int(effect.get("value", 0))
			return ""
		_:
			return ""

func _signed_summary(label_path: String, amount: int) -> String:
	var label: String = TextDB.get_text(label_path, label_path)
	if amount >= 0:
		return TextDB.format_text("story_events.logs.effect_gain", [label, amount])
	return TextDB.format_text("story_events.logs.effect_loss", [label, amount])

func _consume_resources(run_state: RunState, allocations: Dictionary) -> Array[Dictionary]:
	var consumed: Array[Dictionary] = []
	for resource_id_variant in allocations.keys():
		var resource_id: String = str(resource_id_variant)
		var amount: int = int(allocations.get(resource_id, 0))
		if amount <= 0:
			continue
		run_state.resource_states[resource_id] = maxi(0, int(run_state.resource_states.get(resource_id, 0)) - amount)
		consumed.append({
			"id": resource_id,
			"name": TextDB.get_text("resources.%s.name" % resource_id, resource_id),
			"amount": amount
		})
	return consumed

func _mark_event_resolved(run_state: RunState, event_id: String) -> void:
	var queue_index: int = _find_event_instance_index(run_state, event_id)
	if queue_index >= 0:
		run_state.story_event_queue.remove_at(queue_index)
	if not run_state.story_event_history.has(event_id):
		run_state.story_event_history.append(event_id)
	var event_def: Dictionary = _event_defs.get(event_id, {}) as Dictionary
	for counter_id_variant in _to_string_array(event_def.get("counter_tags", [])):
		var counter_id: String = str(counter_id_variant)
		run_state.story_event_counters[counter_id] = int(run_state.story_event_counters.get(counter_id, 0)) + 1

func _classify_outcome(final_score: int, dc: int, partial_margin: int) -> String:
	if final_score >= dc:
		return "success"
	if final_score >= dc - maxi(1, partial_margin):
		return "partial_success"
	return "failure"

func _attribute_modifier_sum(character: CharacterData, attribute_keys: Array[String]) -> int:
	var total: int = 0
	for attribute_key_variant in attribute_keys:
		var attribute_key: String = str(attribute_key_variant)
		total += _attribute_value_modifier(int(character.get(attribute_key)))
	return total

func _attribute_value_modifier(value: int) -> int:
	if value <= 1:
		return -1
	if value <= 3:
		return 0
	if value == 4:
		return 1
	return 2

func _specialty_modifier(character: CharacterData, specialty_tags: Array[String]) -> int:
	var bonus: int = 0
	for specialty_id_variant in specialty_tags:
		var specialty_id: String = str(specialty_id_variant)
		if character.specialty_tags.has(specialty_id):
			bonus += 1
	return bonus

func _state_modifier(character: CharacterData, character_state: Dictionary) -> int:
	var modifier: int = 0
	var fatigue: int = int(character_state.get("fatigue", character.fatigue))
	var health_state: int = int(character_state.get("health_state", character.health_state))
	var mental_state: int = int(character_state.get("mental_state", character.mental_state))
	if fatigue >= 2:
		modifier -= 1
	if fatigue >= 4:
		modifier -= 1
	if health_state <= 6:
		modifier -= 1
	if health_state <= 3:
		modifier -= 1
	if mental_state <= 6:
		modifier -= 1
	if mental_state <= 3:
		modifier -= 1
	return modifier

func _environment_modifier(run_state: RunState, event_def: Dictionary) -> int:
	var camp: Dictionary = GameRules.current_camp_attributes(run_state, {})
	var modifier: int = 0
	var tag_ids: Array[String] = _to_string_array(event_def.get("tag_ids", []))
	if tag_ids.has("logistics"):
		modifier += _camp_band_modifier(int(camp.get("supplies", 3)))
	if tag_ids.has("military") or tag_ids.has("army"):
		modifier += _camp_band_modifier(int(camp.get("forces", 3)))
	if tag_ids.has("court") or tag_ids.has("image"):
		modifier += _camp_band_modifier(int(camp.get("cohesion", 3)))
	if tag_ids.has("camp") or tag_ids.has("hebei"):
		modifier += _camp_band_modifier(int(camp.get("strategy", 3)))
	return clampi(modifier, -2, 2)

func _camp_band_modifier(value: int) -> int:
	if value <= 2:
		return -1
	if value >= 5:
		return 1
	return 0

func _resource_modifier(plan_def: Dictionary, allocations: Dictionary) -> int:
	var total: int = 0
	var bonus_map: Dictionary = plan_def.get("resource_bonus", {}) as Dictionary
	for resource_id_variant in allocations.keys():
		var resource_id: String = str(resource_id_variant)
		total += int(bonus_map.get(resource_id, 0)) * int(allocations.get(resource_id, 0))
	return total

func _normalize_resource_allocations(run_state: RunState, plan_def: Dictionary, resource_allocations: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	for resource_id in _allowed_resource_ids(plan_def):
		var available_amount: int = int(run_state.resource_states.get(resource_id, 0))
		var requested_amount: int = int(resource_allocations.get(resource_id, 0))
		normalized[resource_id] = clampi(requested_amount, 0, _resource_cap(plan_def, resource_id, available_amount))
	return normalized

func _resource_cap(plan_def: Dictionary, resource_id: String, fallback: int) -> int:
	var caps: Dictionary = plan_def.get("resource_caps", {}) as Dictionary
	if caps.has(resource_id):
		return maxi(0, int(caps[resource_id]))
	return maxi(0, fallback)

func _resource_requirements(plan_def: Dictionary) -> Dictionary:
	return (plan_def.get("required_resources", {}) as Dictionary).duplicate(true)

func _allowed_resource_ids(plan_def: Dictionary) -> Array[String]:
	var allowed: Array[String] = []
	for resource_id_variant in _to_string_array(plan_def.get("allowed_resource_ids", [])):
		if not allowed.has(resource_id_variant):
			allowed.append(resource_id_variant)
	var required: Dictionary = _resource_requirements(plan_def)
	for resource_id_variant in required.keys():
		var resource_id: String = str(resource_id_variant)
		if not allowed.has(resource_id):
			allowed.append(resource_id)
	var bonus_map: Dictionary = plan_def.get("resource_bonus", {}) as Dictionary
	for resource_id_variant in bonus_map.keys():
		var resource_id: String = str(resource_id_variant)
		if not allowed.has(resource_id):
			allowed.append(resource_id)
	return allowed

func _resource_display_name(resource_id: String, resource_defs: Dictionary) -> String:
	var resource: ResourceCardData = resource_defs.get(resource_id) as ResourceCardData
	return resource.display_name if resource != null else resource_id

func _plan_definition(event_id: String, plan_id: String) -> Dictionary:
	var event_def: Dictionary = _event_defs.get(event_id, {}) as Dictionary
	return ((event_def.get("plans", {}) as Dictionary).get(plan_id, {}) as Dictionary).duplicate(true)

func _is_resolved_or_queued(run_state: RunState, event_id: String) -> bool:
	if run_state.story_event_history.has(event_id):
		return true
	for item_variant in run_state.story_event_queue:
		var item: Dictionary = item_variant as Dictionary
		if str(item.get("event_id", "")) == event_id:
			return true
	return false

func _matches_trigger(run_state: RunState, event_def: Dictionary, resolved_turn_index: int) -> bool:
	var trigger: Dictionary = event_def.get("trigger", {}) as Dictionary
	if not _trigger_prerequisites_met(run_state, trigger):
		return false
	var trigger_type: String = str(trigger.get("type", ""))
	match trigger_type:
		"after_turn":
			return resolved_turn_index == int(trigger.get("turn", -1))
		"condition":
			return _matches_condition(run_state, trigger, resolved_turn_index)
		_:
			return false

func _matches_condition(run_state: RunState, trigger: Dictionary, resolved_turn_index: int) -> bool:
	var min_turn: int = int(trigger.get("min_turn", 1))
	if resolved_turn_index < min_turn:
		return false
	if trigger.has("any_of"):
		for part_variant in trigger.get("any_of", []):
			if part_variant is Dictionary and _matches_condition(run_state, part_variant as Dictionary, resolved_turn_index):
				return true
		return false
	if trigger.has("all_of"):
		for part_variant in trigger.get("all_of", []):
			if part_variant is Dictionary and not _matches_condition(run_state, part_variant as Dictionary, resolved_turn_index):
				return false
		return true
	var camp: Dictionary = GameRules.current_camp_attributes(run_state, {})
	match str(trigger.get("condition", "")):
		"supplies_below":
			return int(camp.get("supplies", 0)) < int(trigger.get("value", 0))
		"forces_below":
			return int(camp.get("forces", 0)) < int(trigger.get("value", 0))
		"risk_at_least":
			return int(run_state.risk_states.get(str(trigger.get("risk_id", "")), 0)) >= int(trigger.get("value", 0))
		"alienation_at_least":
			return int(run_state.risk_states.get("alienation", 0)) >= int(trigger.get("value", 0))
		"no_cao_governance_turns":
			var last_turn: int = int(run_state.flags.get("last_cao_governance_turn", 0))
			return resolved_turn_index - last_turn >= int(trigger.get("value", 0))
		"reward_debate":
			var military_count: int = int(run_state.story_event_counters.get("military", 0))
			return military_count >= 2 or int(camp.get("forces", 0)) < 4
		_:
			return false

func _board_event_slot_types(event_id: String, plan_id: String) -> Array[String]:
	var plan_def: Dictionary = _plan_definition(event_id, plan_id)
	var slot_types: Array[String] = []
	if _character_required(plan_def):
		slot_types.append("character")
	if not _allowed_resource_ids(plan_def).is_empty():
		slot_types.append("resource")
	return slot_types

func _board_event_slot_filters(event_id: String, plan_id: String) -> Dictionary:
	var plan_def: Dictionary = _plan_definition(event_id, plan_id)
	var filters: Dictionary = {}
	if _character_required(plan_def):
		var character_filter: Dictionary = {"allowed_card_types": ["character"]}
		var allowed_characters: Array[String] = _required_character_ids(plan_def)
		if not allowed_characters.is_empty():
			character_filter["allowed_card_ids"] = allowed_characters
		filters["character"] = character_filter
	var allowed_resources: Array[String] = _allowed_resource_ids(plan_def)
	if not allowed_resources.is_empty():
		filters["resource"] = {"allowed_card_types": ["resource"], "allowed_card_ids": allowed_resources}
	return filters

func _trigger_prerequisites_met(run_state: RunState, trigger: Dictionary) -> bool:
	var required_flag: String = str(trigger.get("requires_flag", ""))
	if not required_flag.is_empty() and not bool(run_state.flags.get(required_flag, false)):
		return false
	var required_roster_id: String = str(trigger.get("requires_roster_id", ""))
	if not required_roster_id.is_empty() and not run_state.roster_ids.has(required_roster_id):
		return false
	return true

func _character_required(plan_def: Dictionary) -> bool:
	return not bool(plan_def.get("character_optional", false))

func _required_character_ids(plan_def: Dictionary) -> Array[String]:
	return _to_string_array(plan_def.get("required_character_ids", []))

func _default_plan_id(event_id: String) -> String:
	var ids: Array[String] = plan_ids(event_id)
	if ids.is_empty():
		return ""
	return ids[0]

func _activate_board_event_instance(run_state: RunState, event_id: String, plan_id: String, remaining_turns: int, apply_to_run_state: bool = true) -> Dictionary:
	var plan_def: Dictionary = _plan_definition(event_id, plan_id)
	if event_id.is_empty() or plan_def.is_empty():
		return {}
	var state: Dictionary = run_state.active_event_states.get(event_id, {}) as Dictionary
	state["turns_left"] = remaining_turns
	state["timeout_total"] = remaining_turns
	state["story_event"] = true
	state["story_event_plan_id"] = plan_id
	state["story_event_slot_types"] = _board_event_slot_types(event_id, plan_id)
	state["story_event_slot_filters"] = _board_event_slot_filters(event_id, plan_id)
	state["story_event_required_resources"] = _resource_requirements(plan_def)
	state["story_event_allowed_resource_ids"] = _allowed_resource_ids(plan_def)
	if not apply_to_run_state:
		return state
	run_state.active_event_states[event_id] = state
	if not run_state.active_event_ids.has(event_id):
		run_state.active_event_ids.append(event_id)
	var queue_index: int = _find_event_instance_index(run_state, event_id)
	if queue_index >= 0:
		var instance: Dictionary = run_state.story_event_queue[queue_index] as Dictionary
		instance["selected_plan_id"] = plan_id
		instance["board_active"] = true
		instance["remaining_turns"] = remaining_turns
		run_state.story_event_queue[queue_index] = instance
	return state

func _find_event_instance_index(run_state: RunState, event_id: String) -> int:
	for index in range(run_state.story_event_queue.size()):
		var item: Dictionary = run_state.story_event_queue[index] as Dictionary
		if str(item.get("event_id", "")) == event_id:
			return index
	return -1

func _resolved_plan_id(run_state: RunState, event_id: String) -> String:
	var state: Dictionary = run_state.active_event_states.get(event_id, {}) as Dictionary
	var from_state: String = str(state.get("story_event_plan_id", ""))
	if not from_state.is_empty():
		return from_state
	var index: int = _find_event_instance_index(run_state, event_id)
	if index < 0:
		return ""
	var item: Dictionary = run_state.story_event_queue[index] as Dictionary
	return str(item.get("selected_plan_id", ""))

func _sync_instance_turns(run_state: RunState, event_id: String, turns_left: int) -> void:
	var index: int = _find_event_instance_index(run_state, event_id)
	if index < 0:
		return
	var item: Dictionary = run_state.story_event_queue[index] as Dictionary
	item["remaining_turns"] = turns_left
	run_state.story_event_queue[index] = item

func _clear_board_event(run_state: RunState, event_id: String) -> void:
	run_state.active_event_ids.erase(event_id)
	if run_state.active_event_states.has(event_id):
		run_state.active_event_states.erase(event_id)

func _primary_character_id(assigned_cards: Array) -> String:
	for card_variant in assigned_cards:
		var card: Dictionary = card_variant as Dictionary
		if str(card.get("card_type", "")) == "character":
			return str(card.get("id", ""))
	return ""

func _resource_allocations_from_cards(assigned_cards: Array) -> Dictionary:
	var allocations: Dictionary = {}
	for card_variant in assigned_cards:
		var card: Dictionary = card_variant as Dictionary
		if str(card.get("card_type", "")) != "resource":
			continue
		var resource_id: String = str(card.get("id", ""))
		allocations[resource_id] = int(allocations.get(resource_id, 0)) + 1
	return allocations

func _assigned_consumed_resources(allocations: Dictionary, resource_defs: Dictionary) -> Array[Dictionary]:
	var consumed: Array[Dictionary] = []
	for resource_id_variant in allocations.keys():
		var resource_id: String = str(resource_id_variant)
		var amount: int = int(allocations.get(resource_id, 0))
		if amount <= 0:
			continue
		var resource: ResourceCardData = resource_defs.get(resource_id) as ResourceCardData
		if resource == null or not resource.consumable:
			continue
		consumed.append({"id": resource_id, "name": resource.display_name, "amount": amount})
	return consumed

func _join_resource_names(resource_ids: Array[String]) -> String:
	var names: Array[String] = []
	for resource_id in resource_ids:
		names.append(TextDB.get_text("resources.%s.name" % resource_id, resource_id))
	return TextDB.get_text("ui.list_separator").join(names)

func _join_attribute_names(attribute_keys: Array[String]) -> String:
	var names: Array[String] = []
	for attribute_key in attribute_keys:
		names.append(TextDB.get_text("story_events.meta.attributes.%s" % attribute_key, attribute_key))
	return TextDB.get_text("ui.list_separator").join(names)

func _join_specialty_names(specialty_ids: Array[String]) -> String:
	var names: Array[String] = []
	for specialty_id in specialty_ids:
		names.append(TextDB.get_text("story_events.meta.specialties.%s" % specialty_id, specialty_id))
	return TextDB.get_text("ui.list_separator").join(names)

func _canonical_attribute_key(attribute_keys: Array[String]) -> String:
	var normalized: Array[String] = []
	for attribute_key in attribute_keys:
		var key: String = str(attribute_key)
		if key.is_empty():
			continue
		normalized.append(key)
	normalized.sort()
	return "_".join(normalized)

func _board_attribute_subject(attribute_keys: Array[String]) -> String:
	var canonical_key: String = _canonical_attribute_key(attribute_keys)
	if not canonical_key.is_empty():
		var path: String = "story_events.ui.board_attribute_subjects.%s" % canonical_key
		var subject_text: String = TextDB.get_text(path, "")
		if not subject_text.is_empty():
			return subject_text
	if attribute_keys.is_empty():
		return ""
	return TextDB.format_text("story_events.ui.board_attribute_hint_generic", [_join_attribute_names(attribute_keys)])

func _board_attribute_hint(event_id: String, plan_id: String) -> String:
	if plan_id.is_empty():
		return ""
	var plan_def: Dictionary = _plan_definition(event_id, plan_id)
	var attribute_keys: Array[String] = _to_string_array(plan_def.get("attribute_keys", []))
	var specialties: Array[String] = _to_string_array(plan_def.get("specialty_tags", []))
	var sections: Array[String] = []
	var subject_text: String = _board_attribute_subject(attribute_keys)
	if not subject_text.is_empty():
		sections.append(subject_text)
	if not specialties.is_empty():
		sections.append(TextDB.format_text("story_events.ui.board_specialty_hint", [_join_specialty_names(specialties)]))
	if sections.is_empty():
		return ""
	return "".join(sections)

func _ensure_story_state(run_state: RunState) -> void:
	if run_state == null:
		return
	if run_state.story_event_queue == null:
		run_state.story_event_queue = []
	if run_state.story_event_history == null:
		run_state.story_event_history = []
	if run_state.story_event_counters == null:
		run_state.story_event_counters = {}

func _load_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var raw: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(raw)
	return parsed if parsed is Dictionary else {}

func _to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result
