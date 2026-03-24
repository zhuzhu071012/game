extends Node
class_name BoardManager

signal board_changed

var slot_assignments: Dictionary = {}
var event_assignments: Dictionary = {}
var committed_cards: Dictionary = {}

func reset_turn_targets(event_ids: Array[String]) -> void:
	slot_assignments = {
		"governance": [],
		"audience": [],
		"research": [],
		"recruit": [],
		"rest": []
	}
	event_assignments.clear()
	for event_id in event_ids:
		event_assignments[event_id] = {"character": [], "resource": []}
	committed_cards.clear()
	emit_signal("board_changed")

func assign_to_slot(slot_id: String, payload: Dictionary) -> bool:
	if payload.is_empty() or committed_cards.has(payload.get("uid", "")):
		return false
	if not slot_assignments.has(slot_id):
		slot_assignments[slot_id] = []
	var current_cards: Array = slot_assignments[slot_id]
	if not GameRules.can_drop_on_slot(slot_id, payload, current_cards):
		return false
	current_cards.append(payload)
	slot_assignments[slot_id] = current_cards
	committed_cards[payload["uid"]] = slot_id
	emit_signal("board_changed")
	return true

func assign_to_event(event_id: String, payload: Dictionary, slot_type: String = "") -> bool:
	if payload.is_empty() or committed_cards.has(payload.get("uid", "")):
		return false
	if not event_assignments.has(event_id):
		event_assignments[event_id] = {"character": [], "resource": []}
	var target_slot: String = slot_type
	if target_slot.is_empty():
		target_slot = str(payload.get("card_type", ""))
	if not event_assignments[event_id].has(target_slot):
		return false
	var current_cards: Array = event_assignments[event_id][target_slot]
	if not GameRules.can_drop_on_event_slot(target_slot, payload, current_cards):
		return false
	current_cards.append(payload)
	event_assignments[event_id][target_slot] = current_cards
	committed_cards[payload["uid"]] = "%s:%s" % [event_id, target_slot]
	emit_signal("board_changed")
	return true

func is_committed(card_uid: String) -> bool:
	return committed_cards.has(card_uid)

func get_slot_cards(slot_id: String) -> Array:
	return slot_assignments.get(slot_id, [])

func get_event_cards(event_id: String) -> Array:
	if not event_assignments.has(event_id):
		return []
	var merged: Array = []
	merged.append_array(event_assignments[event_id].get("character", []))
	merged.append_array(event_assignments[event_id].get("resource", []))
	return merged

func get_event_slot_cards(event_id: String, slot_type: String) -> Array:
	if not event_assignments.has(event_id):
		return []
	return event_assignments[event_id].get(slot_type, [])


func unassign_card(card_uid: String) -> bool:
	if card_uid.is_empty() or not committed_cards.has(card_uid):
		return false
	var location: String = str(committed_cards[card_uid])
	var removed: bool = false
	if location.contains(":"):
		var event_id: String = location.get_slice(":", 0)
		var slot_type: String = location.get_slice(":", 1)
		if event_assignments.has(event_id) and event_assignments[event_id].has(slot_type):
			var cards: Array = event_assignments[event_id][slot_type]
			removed = _remove_uid_from_cards(cards, card_uid)
			event_assignments[event_id][slot_type] = cards
	else:
		if slot_assignments.has(location):
			var slot_cards: Array = slot_assignments[location]
			removed = _remove_uid_from_cards(slot_cards, card_uid)
			slot_assignments[location] = slot_cards
	if not removed:
		return false
	committed_cards.erase(card_uid)
	emit_signal("board_changed")
	return true

func _remove_uid_from_cards(cards: Array, card_uid: String) -> bool:
	for index in range(cards.size() - 1, -1, -1):
		var card: Dictionary = cards[index] as Dictionary
		if str(card.get("uid", "")) == card_uid:
			cards.remove_at(index)
			return true
	return false
