extends RefCounted
class_name GameRules

const SLOT_CAPACITY: Dictionary = {
	"governance": {"character": 2},
	"audience": {"character": 2, "resource": 1},
	"research": {"character": 1, "resource": 2},
	"recruit": {"character": 1, "resource": 2},
	"rest": {"character": 2, "resource": 2}
}

const SLOT_TAG_REQUIREMENTS: Dictionary = {
	"governance": {"character": ["leader", "politics", "governance", "military", "discipline", "steady", "camp"]},
	"audience": {"resource": ["gift", "relation", "support", "mind"]},
	"research": {"character": ["research", "scheme", "steady", "medicine", "mind"], "resource": ["research", "intel", "document", "secret_report", "naval"]},
	"recruit": {"character": ["scheme", "captives", "relation", "support"], "resource": ["task", "recruit", "money", "document"]},
	"rest": {"character": ["rest", "medicine", "support", "relation", "mind"], "resource": ["rest", "medicine", "care", "mind"]}
}

const SLOT_TAG_PREFERENCES: Dictionary = {
	"governance": ["leader", "politics", "governance", "military", "discipline", "steady", "camp"],
	"audience": ["relation", "gift", "support", "mind", "rumor", "charm"],
	"research": ["research", "intel", "document", "secret_report", "scheme", "naval", "mind"],
	"recruit": ["recruit", "task", "money", "document", "scheme", "relation"],
	"rest": ["rest", "medicine", "care", "support", "mind", "relation"]
}

static func can_drop_on_slot(slot_id: String, payload: Dictionary, current_cards: Array = []) -> bool:
	if payload.is_empty():
		return false
	var card_type: String = str(payload.get("card_type", ""))
	if card_type == "event":
		return false
	if not SLOT_CAPACITY.has(slot_id):
		return false
	var capacity_by_type: Dictionary = SLOT_CAPACITY[slot_id]
	var limit: int = int(capacity_by_type.get(card_type, 0))
	if limit <= 0:
		return false
	if _count_card_type(current_cards, card_type) >= limit:
		return false
	if slot_id == "governance" and card_type == "character" and str(payload.get("id", "")) == "cao_cao":
		return true
	return _matches_slot_requirements(slot_id, card_type, payload)

static func can_drop_on_event(payload: Dictionary) -> bool:
	if payload.is_empty():
		return false
	return str(payload.get("card_type", "")) in ["character", "resource"]

static func can_drop_on_event_slot(slot_type: String, payload: Dictionary, current_cards: Array = []) -> bool:
	if payload.is_empty():
		return false
	if str(payload.get("card_type", "")) != slot_type:
		return false
	return current_cards.size() < 1

static func quick_assign_score(slot_id: String, payload: Dictionary, current_cards: Array = []) -> int:
	if not can_drop_on_slot(slot_id, payload, current_cards):
		return -1
	var score: int = 10
	var tags: Array[String] = _payload_tags(payload)
	var preferred: Array = SLOT_TAG_PREFERENCES.get(slot_id, [])
	for tag_variant in preferred:
		var tag: String = str(tag_variant)
		if tags.has(tag):
			score += 4
	if str(payload.get("id", "")) == "cao_cao" and slot_id == "governance":
		score += 3
	if slot_id == "audience" and str(payload.get("card_type", "")) == "resource":
		score += 2
	if slot_id == "rest" and tags.has("medicine"):
		score += 3
	score -= current_cards.size()
	return score

static func relation_label(favor: int) -> String:
	if favor >= 8:
		return TextDB.get_text("system.relations.bonded")
	if favor >= 4:
		return TextDB.get_text("system.relations.trusted")
	if favor >= 0:
		return TextDB.get_text("system.relations.steady")
	return TextDB.get_text("system.relations.cold")

static func apply_risk_penalties(run_state: RunState, risk_defs: Dictionary) -> Array[String]:
	var logs: Array[String] = []
	for risk_id_variant in run_state.risk_states.keys():
		var risk_id: String = str(risk_id_variant)
		var count: int = int(run_state.risk_states[risk_id])
		if count <= 0:
			continue
		var risk: RiskCardData = risk_defs[risk_id] as RiskCardData
		var penalty: Dictionary = risk.mild_penalty if count == 1 else risk.severe_penalty
		_apply_penalty_dictionary(run_state, penalty)
		logs.append(TextDB.format_text("logs.risk.penalty", [risk.display_name, count]))
		if count >= 3:
			run_state.game_over = true
			run_state.ending_id = risk.bad_ending_id
			logs.append(TextDB.format_text("logs.risk.ending", [risk.bad_ending_id]))
			return logs
	return logs

static func _matches_slot_requirements(slot_id: String, card_type: String, payload: Dictionary) -> bool:
	var slot_rules: Dictionary = SLOT_TAG_REQUIREMENTS.get(slot_id, {})
	if not slot_rules.has(card_type):
		return true
	var required_tags: Array = slot_rules[card_type]
	if required_tags.is_empty():
		return true
	var tags: Array[String] = _payload_tags(payload)
	for tag_variant in required_tags:
		if tags.has(str(tag_variant)):
			return true
	return false

static func _payload_tags(payload: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var raw_tags: Array = payload.get("tags", [])
	for tag_variant in raw_tags:
		result.append(str(tag_variant))
	return result

static func _count_card_type(cards: Array, card_type: String) -> int:
	var total: int = 0
	for card_variant in cards:
		var card: Dictionary = card_variant as Dictionary
		if str(card.get("card_type", "")) == card_type:
			total += 1
	return total

static func _apply_penalty_dictionary(run_state: RunState, penalty: Dictionary) -> void:
	for key_variant in penalty.keys():
		var key: String = str(key_variant)
		match key:
			"mind":
				run_state.cao_mind += int(penalty[key])
			"health":
				run_state.cao_health += int(penalty[key])
			"morale":
				run_state.morale += int(penalty[key])
			"stability":
				run_state.jingzhou_stability += int(penalty[key])
			"naval":
				run_state.naval_readiness += int(penalty[key])
			"alliance":
				run_state.alliance_strength += int(penalty[key])
			"fire":
				run_state.fire_progress += int(penalty[key])

static func clamp_stats(run_state: RunState) -> void:
	run_state.cao_health = clampi(run_state.cao_health, 0, 12)
	run_state.cao_mind = clampi(run_state.cao_mind, 0, 12)
	run_state.money = maxi(run_state.money, 0)
	run_state.morale = clampi(run_state.morale, 0, 12)
	run_state.jingzhou_stability = clampi(run_state.jingzhou_stability, 0, 12)
	run_state.naval_readiness = clampi(run_state.naval_readiness, 0, 12)
	run_state.alliance_strength = clampi(run_state.alliance_strength, 0, 12)
	run_state.fire_progress = clampi(run_state.fire_progress, 0, 12)
	if run_state.fire_progress >= 12 or run_state.cao_health <= 0 or run_state.cao_mind <= 0:
		run_state.game_over = true
		if run_state.ending_id.is_empty():
			run_state.ending_id = TextDB.get_text("system.endings.fire")
