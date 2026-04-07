extends RefCounted
class_name GameRules

# 集中放置可复用的判定规则、槽位规则与终局规则。
# 这样 UI 只负责展示，数值与判定仍留在规则层。

const SLOT_CAPACITY: Dictionary = {
	"governance": {"character": 2},
	"audience": {"character": 2, "resource": 2, "risk": 1},
	"research": {"character": 2, "resource": 2, "event": 1},
	"recruit": {"character": 2, "resource": 2},
	"rest": {"character": 2, "resource": 2, "risk": 1}
}

const SLOT_TAG_REQUIREMENTS: Dictionary = {
	"governance": {"character": []},
	"audience": {"character": [], "resource": ["gift", "relation", "support", "mind", "money", "document"], "risk": ["rumor", "alienation"]},
	"research": {"character": [], "resource": ["research", "intel", "document", "secret_report", "naval", "gift", "money"]},
	"recruit": {"character": [], "resource": ["task", "recruit", "money", "document"]},
	"rest": {"character": [], "resource": ["rest", "medicine", "care", "mind", "money"], "risk": ["headwind", "miasma"]}
}

const SLOT_TAG_PREFERENCES: Dictionary = {
	"governance": ["leader", "politics", "governance", "military", "discipline", "steady", "camp"],
	"audience": ["relation", "gift", "support", "mind", "rumor", "charm", "money", "document"],
	"research": ["research", "intel", "document", "secret_report", "scheme", "naval", "mind", "gift", "money"],
	"recruit": ["leader", "recruit", "task", "money", "document", "scheme", "relation", "governance"],
	"rest": ["rest", "medicine", "care", "support", "mind", "relation", "money", "headwind"]
}

const SLOT_RESOLUTION_ORDER: Array[String] = ["governance", "audience", "research", "recruit", "rest"]
const SLOT_ATTRIBUTE_KEYS: Dictionary = {
	"governance": ["constitution", "intelligence"],
	"audience": ["perception", "charisma"],
	"research": ["intelligence", "perception"],
	"recruit": ["constitution", "charisma"]
}
const SLOT_SPECIALTY_BONUSES: Dictionary = {
	"governance": ["command"],
	"audience": ["negotiation", "deception", "intimidation"],
	"research": ["stratagem", "search", "medical"],
	"recruit": ["search", "negotiation", "command"],
	"rest": ["medical"]
}

const PLAYABLE_TURNS: int = 32
const SETTLEMENT_TURN: int = 33
const MAX_FIRE_PROGRESS: int = 12

static func slot_attribute_keys(slot_id: String) -> Array[String]:
	var result: Array[String] = []
	var raw_keys: Array = SLOT_ATTRIBUTE_KEYS.get(slot_id, [])
	for key_variant in raw_keys:
		result.append(str(key_variant))
	return result

static func slot_specialty_bonus(slot_id: String, specialty_tags: Array[String]) -> int:
	var bonus: int = 0
	var raw_tags: Array = SLOT_SPECIALTY_BONUSES.get(slot_id, [])
	for tag_variant in raw_tags:
		if specialty_tags.has(str(tag_variant)):
			bonus += 1
	return bonus

static func current_character_attributes(character: CharacterData, character_state: Dictionary = {}) -> Dictionary:
	var attrs: Dictionary = {
		"strength": character.strength,
		"agility": character.agility,
		"constitution": character.constitution,
		"intelligence": character.intelligence,
		"perception": character.perception,
		"charisma": character.charisma
	}
	var fatigue: int = int(character_state.get("fatigue", character.fatigue))
	if fatigue >= 2:
		attrs["agility"] = int(attrs["agility"]) - 1
		attrs["intelligence"] = int(attrs["intelligence"]) - 1
		attrs["perception"] = int(attrs["perception"]) - 1
	if fatigue >= 4:
		attrs["constitution"] = int(attrs["constitution"]) - 1
	var health_value: int = int(character_state.get("health_state", character.health_state))
	if health_value <= 6:
		attrs["strength"] = int(attrs["strength"]) - 1
		attrs["agility"] = int(attrs["agility"]) - 1
		attrs["constitution"] = int(attrs["constitution"]) - 1
	if health_value <= 3:
		attrs["strength"] = int(attrs["strength"]) - 1
		attrs["constitution"] = int(attrs["constitution"]) - 1
	var mental_value: int = int(character_state.get("mental_state", character.mental_state))
	if mental_value <= 6:
		attrs["intelligence"] = int(attrs["intelligence"]) - 1
		attrs["perception"] = int(attrs["perception"]) - 1
		attrs["charisma"] = int(attrs["charisma"]) - 1
	if mental_value <= 3:
		attrs["intelligence"] = int(attrs["intelligence"]) - 1
		attrs["charisma"] = int(attrs["charisma"]) - 1
	for bonus_key_variant in ["strength", "agility", "constitution", "intelligence", "perception", "charisma"]:
		var bonus_key: String = str(bonus_key_variant)
		attrs[bonus_key] = int(attrs.get(bonus_key, 0)) + int(character_state.get("bonus_%s" % bonus_key, 0))
	for key_variant in attrs.keys():
		var key: String = str(key_variant)
		attrs[key] = clampi(int(attrs[key]), 0, 12)
	return attrs

static func character_attribute_total(character: CharacterData, character_state: Dictionary, attribute_keys: Array[String]) -> int:
	var attrs: Dictionary = current_character_attributes(character, character_state)
	var total: int = 0
	for key in attribute_keys:
		total += int(attrs.get(key, 0))
	return total

static func slot_attribute_total(slot_id: String, character: CharacterData, character_state: Dictionary) -> int:
	return character_attribute_total(character, character_state, slot_attribute_keys(slot_id))

static func event_attribute_keys(event: EventData) -> Array[String]:
	var tags: Array[String] = []
	for tag_variant in event.tags:
		tags.append(str(tag_variant))
	if tags.has("rest") or tags.has("medicine") or event.category in ["character", "dream"]:
		return []
	if tags.has("military") or tags.has("swift") or tags.has("discipline"):
		return ["strength", "agility"]
	if tags.has("naval"):
		return ["intelligence", "perception"] if event.category in ["omen", "relation"] else ["strength", "agility"]
	if tags.has("research") or tags.has("intel") or tags.has("document") or tags.has("secret_report") or event.category == "omen":
		return ["intelligence", "perception"]
	if tags.has("recruit") or tags.has("search"):
		return ["constitution", "charisma"]
	if tags.has("relation") or tags.has("rumor") or event.category in ["relation", "rumor"]:
		return ["perception", "charisma"]
	return ["constitution", "intelligence"]

static func event_recommended_specialties(event: EventData) -> Array[String]:
	var result: Array[String] = []
	var tags: Array[String] = []
	for tag_variant in event.tags:
		tags.append(str(tag_variant))
	for tag_variant in event.recommended_tags:
		var recommended_tag: String = str(tag_variant)
		if not tags.has(recommended_tag):
			tags.append(recommended_tag)
	if tags.has("medicine") or tags.has("rest"):
		result.append("medical")
	if tags.has("research") or tags.has("intel") or tags.has("document") or tags.has("secret_report") or tags.has("scheme"):
		result.append("stratagem")
	if tags.has("search") or tags.has("recruit"):
		result.append("search")
	if tags.has("relation"):
		result.append("negotiation")
	if tags.has("rumor") or tags.has("scheme"):
		result.append("deception")
	if tags.has("military") or tags.has("discipline") or tags.has("rumor"):
		result.append("intimidation")
	if tags.has("governance") or tags.has("logistics") or tags.has("military") or tags.has("naval"):
		result.append("command")
	var unique_result: Array[String] = []
	for specialty in result:
		if not unique_result.has(specialty):
			unique_result.append(specialty)
	return unique_result

static func roll_2d6() -> int:
	return randi_range(1, 6) + randi_range(1, 6)

static func playable_turns() -> int:
	return PLAYABLE_TURNS

static func settlement_turn() -> int:
	return SETTLEMENT_TURN

static func max_turns() -> int:
	return playable_turns()

static func is_settlement_turn(turn_index: int) -> bool:
	return turn_index >= settlement_turn()

static func current_term_name(turn_index: int) -> String:
	if is_settlement_turn(turn_index):
		return TextDB.get_text("system.settlement_term", "Settlement")
	var terms: Array = TextDB.get_array("system.terms")
	var safe_turn: int = clampi(turn_index, 1, playable_turns())
	if terms.is_empty():
		return TextDB.format_text("system.turn_fallback", [safe_turn], {}, "Turn %d")
	if terms.size() >= playable_turns():
		var direct_index: int = clampi(safe_turn - 1, 0, terms.size() - 1)
		return str(terms[direct_index])
	var turns_per_term: int = maxi(1, int(ceil(float(playable_turns()) / float(terms.size()))))
	var safe_index: int = clampi(int((safe_turn - 1) / turns_per_term), 0, terms.size() - 1)
	return str(terms[safe_index])

static func stage_for_turn(turn_index: int) -> int:
	var total_turns: int = maxi(1, playable_turns())
	var clamped_turn: int = clampi(turn_index, 1, total_turns)
	var progress: float = float(maxi(clamped_turn - 1, 0)) / float(maxi(total_turns - 1, 1))
	if progress < 0.34:
		return 1
	if progress < 0.67:
		return 2
	return 3

static func fire_level_text(fire_progress: int) -> String:
	if fire_progress >= 8:
		return TextDB.get_text("system.fire_levels.high")
	if fire_progress >= 4:
		return TextDB.get_text("system.fire_levels.medium")
	return TextDB.get_text("system.fire_levels.low")

static func fire_pressure_modifier(fire_progress: int) -> int:
	if fire_progress >= 8:
		return 2
	if fire_progress >= 4:
		return 1
	return 0

static func check_immediate_risk_endings(run_state: RunState, risk_defs: Dictionary) -> Array[String]:
	if run_state.game_over:
		return []
	for risk_id_variant in run_state.risk_states.keys():
		var risk_id: String = str(risk_id_variant)
		var count: int = int(run_state.risk_states[risk_id])
		if count < 3:
			continue
		var risk: RiskCardData = risk_defs[risk_id] as RiskCardData
		set_bad_ending(run_state, risk.bad_ending_id)
		return [TextDB.format_text("logs.risk.ending", [risk.bad_ending_id])]
	return []

static func set_bad_ending(run_state: RunState, ending_text: String) -> void:
	run_state.game_over = true
	run_state.ending_id = ending_text
	run_state.flags["ending_tier"] = "bad"

static func conclude_run_by_time(run_state: RunState, character_defs: Dictionary) -> void:
	var camp: Dictionary = current_camp_attributes(run_state, character_defs)
	var working_camp: Dictionary = {
		"supplies": int(camp.get("supplies", 0)),
		"forces": int(camp.get("forces", 0)),
		"cohesion": int(camp.get("cohesion", 0)),
		"strategy": int(camp.get("strategy", 0))
	}
	var settlement_lines: Array[String] = []
	var settlement_pages: Array = []
	var victory_points: int = 0
	var battle_phase_bonus: int = 0

	var preparation_lines: Array[String] = []
	var preparation_delta: int = 1 if int(working_camp.get("supplies", 0)) >= 6 else -1
	if int(working_camp.get("cohesion", 0)) <= 4:
		preparation_delta -= 1
	victory_points += preparation_delta
	preparation_lines.append(TextDB.format_text("ui.finale.preparation_line", [int(working_camp.get("supplies", 0)), int(working_camp.get("cohesion", 0)), _signed_value_text(preparation_delta)]))
	settlement_lines.append_array(preparation_lines)
	settlement_pages.append({
		"title": TextDB.get_text("system.finale.phases.preparation"),
		"body": "\n".join(preparation_lines)
	})

	var fire_lines: Array[String] = []
	var fire_dc: int = 13
	var iron_chain_active: bool = bool(run_state.flags.get("iron_chain_event_established", false)) or int(run_state.risk_states.get("seasick", 0)) >= 1
	var east_wind_active: bool = bool(run_state.flags.get("east_wind_event_established", false)) or (run_state.fire_progress >= 7 and not bool(run_state.flags.get("dream_seen_once", false)))
	if iron_chain_active:
		fire_dc += 2
	if east_wind_active:
		fire_dc += 2
	if iron_chain_active and east_wind_active:
		fire_dc += 1
	var fire_bonus: int = camp_attribute_modifier(int(working_camp.get("strategy", 0)))
	fire_bonus += _weighted_resource_bonus(run_state, {"spy_report": 2, "naval_chart": 2, "sealed_letter": 1}, 5)
	fire_bonus += mini(3, int(camp.get("strategist_units", 0)))
	var fire_result: Dictionary = _finale_roll(fire_bonus, fire_dc)
	fire_lines.append(TextDB.format_text("ui.finale.roll_line", [TextDB.get_text("system.finale.phases.fire"), _finale_outcome_text(str(fire_result.get("outcome", "fail"))), int(fire_result.get("roll", 0)), int(fire_result.get("total", 0)), fire_dc]))
	match str(fire_result.get("outcome", "fail")):
		"fail":
			working_camp["forces"] = maxi(0, int(working_camp.get("forces", 0)) - 2)
			fire_lines.append(TextDB.format_text("ui.finale.fire_penalty", [2]))
		"major_fail":
			working_camp["forces"] = maxi(0, int(working_camp.get("forces", 0)) - 3)
			victory_points -= 1
			fire_lines.append(TextDB.format_text("ui.finale.fire_penalty", [3]))
	settlement_lines.append_array(fire_lines)
	settlement_pages.append({
		"title": TextDB.get_text("system.finale.phases.fire"),
		"body": "\n".join(fire_lines)
	})

	var ruse_lines: Array[String] = []
	var ruse_dc: int = 13
	var ruse_bonus: int = camp_attribute_modifier(int(working_camp.get("strategy", 0)))
	ruse_bonus += _weighted_resource_bonus(run_state, {"spy_report": 2, "sealed_letter": 2, "naval_chart": 1}, 5)
	ruse_bonus += mini(3, int(camp.get("strategist_units", 0)))
	if bool(run_state.flags.get("scheme_counter_ready", false)):
		ruse_bonus += 1
	var ruse_result: Dictionary = _finale_roll(ruse_bonus, ruse_dc)
	ruse_lines.append(TextDB.format_text("ui.finale.roll_line", [TextDB.get_text("system.finale.phases.ruse"), _finale_outcome_text(str(ruse_result.get("outcome", "fail"))), int(ruse_result.get("roll", 0)), int(ruse_result.get("total", 0)), ruse_dc]))
	match str(ruse_result.get("outcome", "fail")):
		"success":
			victory_points += 1
		"major_success":
			victory_points += 1
			battle_phase_bonus += 1
			ruse_lines.append(TextDB.format_text("ui.finale.battle_bonus", [battle_phase_bonus]))
		"major_fail":
			victory_points -= 1
	settlement_lines.append_array(ruse_lines)
	settlement_pages.append({
		"title": TextDB.get_text("system.finale.phases.ruse"),
		"body": "\n".join(ruse_lines)
	})

	var battle_lines: Array[String] = []
	var battle_dc: int = 16
	var battle_bonus: int = camp_attribute_modifier(int(working_camp.get("supplies", 0)))
	battle_bonus += camp_attribute_modifier(int(working_camp.get("forces", 0)))
	battle_bonus += camp_attribute_modifier(int(working_camp.get("cohesion", 0)))
	battle_bonus += camp_attribute_modifier(int(working_camp.get("strategy", 0)))
	battle_bonus += mini(4, int(camp.get("military_units", 0)) + int(camp.get("command_units", 0)))
	battle_bonus += _weighted_resource_bonus(run_state, {"silver_pack": 1, "recruit_writ": 2, "naval_chart": 1}, 5)
	battle_bonus += battle_phase_bonus
	var battle_result: Dictionary = _finale_roll(battle_bonus, battle_dc)
	battle_lines.append(TextDB.format_text("ui.finale.roll_line", [TextDB.get_text("system.finale.phases.battle"), _finale_outcome_text(str(battle_result.get("outcome", "fail"))), int(battle_result.get("roll", 0)), int(battle_result.get("total", 0)), battle_dc]))
	match str(battle_result.get("outcome", "fail")):
		"success":
			victory_points += 2
		"major_success":
			victory_points += 3
		"fail":
			victory_points -= 2
		"major_fail":
			victory_points -= 3
	settlement_lines.append_array(battle_lines)
	settlement_pages.append({
		"title": TextDB.get_text("system.finale.phases.battle"),
		"body": "\n".join(battle_lines)
	})

	run_state.victory_points = victory_points
	run_state.settlement_snapshot = {
		"supplies": int(working_camp.get("supplies", 0)),
		"forces": int(working_camp.get("forces", 0)),
		"cohesion": int(working_camp.get("cohesion", 0)),
		"strategy": int(working_camp.get("strategy", 0))
	}
	settlement_lines.append(TextDB.format_text("ui.finale.camp_line", [run_state.settlement_snapshot["supplies"], run_state.settlement_snapshot["forces"], run_state.settlement_snapshot["cohesion"], run_state.settlement_snapshot["strategy"]]))
	settlement_lines.append(TextDB.format_text("ui.finale.score_line", [victory_points]))
	run_state.settlement_report = settlement_lines
	run_state.personal_epilogues = _build_personal_epilogues(run_state, character_defs)

	if victory_points >= 4:
		run_state.flags["ending_tier"] = "good"
		run_state.ending_id = TextDB.get_text("system.endings.good")
	elif victory_points >= 2:
		run_state.flags["ending_tier"] = "favorable"
		run_state.ending_id = TextDB.get_text("system.endings.favorable")
	elif victory_points >= -1:
		run_state.flags["ending_tier"] = "normal"
		run_state.ending_id = TextDB.get_text("system.endings.normal")
	elif victory_points >= -3:
		run_state.flags["ending_tier"] = "defeat"
		run_state.ending_id = TextDB.get_text("system.endings.defeat")
	else:
		run_state.flags["ending_tier"] = "bad"
		run_state.ending_id = TextDB.get_text("system.endings.final_bad")

	var summary_lines: Array[String] = []
	summary_lines.append(TextDB.format_text("ui.finale.camp_line", [run_state.settlement_snapshot["supplies"], run_state.settlement_snapshot["forces"], run_state.settlement_snapshot["cohesion"], run_state.settlement_snapshot["strategy"]]))
	summary_lines.append(TextDB.format_text("ui.finale.score_line", [victory_points]))
	summary_lines.append(TextDB.format_text("ui.finale.result_line", [run_state.ending_id]))
	settlement_pages.append({
		"title": TextDB.get_text("ui.finale.report_title"),
		"body": "\n".join(summary_lines)
	})

	var personal_lines: Array[String] = []
	if run_state.personal_epilogues.is_empty():
		personal_lines.append(TextDB.get_text("ui.finale.no_personal"))
	else:
		for line_variant in run_state.personal_epilogues:
			personal_lines.append(str(line_variant))
	settlement_pages.append({
		"title": TextDB.get_text("ui.finale.personal_title"),
		"body": "\n".join(personal_lines)
	})
	run_state.settlement_pages = settlement_pages
	run_state.game_over = true

static func current_camp_attributes(run_state: RunState, character_defs: Dictionary) -> Dictionary:
	var military_units: int = 0
	var strategist_units: int = 0
	var command_units: int = 0
	for character_id_variant in run_state.roster_ids:
		var character_id: String = str(character_id_variant)
		if not character_defs.has(character_id):
			continue
		var character: CharacterData = character_defs[character_id] as CharacterData
		if _character_has_any_tag(character, ["military", "discipline", "swift", "camp"]):
			military_units += 1
		if character.specialty_tags.has("stratagem"):
			strategist_units += 1
		if character.specialty_tags.has("command"):
			command_units += 1
	military_units += int(run_state.resource_states.get("northern_corps", 0))
	var supplies: int = int(run_state.flags.get("camp_supplies_base", 3))
	var forces: int = int(run_state.flags.get("camp_forces_base", 1))
	var cohesion: int = int(run_state.flags.get("camp_cohesion_base", 1))
	var strategy: int = int(run_state.flags.get("camp_strategy_base", 1))

	return {
		"supplies": clampi(supplies, 0, 12),
		"forces": clampi(forces, 0, 12),
		"cohesion": clampi(cohesion, 0, 12),
		"strategy": clampi(strategy, 0, 12),
		"military_units": military_units,
		"strategist_units": strategist_units,
		"command_units": command_units
	}

static func camp_attribute_modifier(value: int) -> int:
	if value <= 2:
		return -2
	if value <= 4:
		return 0
	if value <= 6:
		return 1
	if value <= 8:
		return 2
	if value <= 10:
		return 3
	return 4

static func _weighted_resource_bonus(run_state: RunState, weights: Dictionary, max_bonus: int = 99) -> int:
	var total: int = 0
	for resource_id_variant in weights.keys():
		var resource_id: String = str(resource_id_variant)
		total += int(run_state.resource_states.get(resource_id, 0)) * int(weights[resource_id_variant])
	return mini(total, max_bonus)

static func _finale_roll(bonus: int, dc: int) -> Dictionary:
	var roll_value: int = roll_2d6()
	var total: int = roll_value + bonus
	var tier_score: int = -1
	if total >= dc + 5:
		tier_score = 2
	elif total >= dc:
		tier_score = 1
	elif total <= dc - 5:
		tier_score = -2
	if roll_value == 12:
		tier_score = mini(2, tier_score + 1)
		if tier_score < 2:
			tier_score = 2
	elif roll_value == 2:
		tier_score = maxi(-2, tier_score - 1)
		if tier_score > -2:
			tier_score = -2
	var outcome: String = "fail"
	match tier_score:
		2:
			outcome = "major_success"
		1:
			outcome = "success"
		-2:
			outcome = "major_fail"
		_:
			outcome = "fail"
	return {"roll": roll_value, "total": total, "outcome": outcome}

static func _finale_outcome_text(outcome_id: String) -> String:
	return TextDB.get_text("system.finale.outcomes.%s" % outcome_id, outcome_id)

static func _signed_value_text(value: int) -> String:
	return "+%d" % value if value > 0 else str(value)

static func _character_has_any_tag(character: CharacterData, tag_ids: Array[String]) -> bool:
	for tag_id in tag_ids:
		if character.tags.has(tag_id):
			return true
	return false

static func _build_personal_epilogues(run_state: RunState, character_defs: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var order: Array[String] = ["guo_jia", "xun_yu", "zhang_liao", "yu_jin", "cao_pi", "cao_zhi", "hua_tuo"]
	for character_id in order:
		if not character_defs.has(character_id):
			continue
		var character: CharacterData = character_defs[character_id] as CharacterData
		var display_name: String = character.display_name
		if not run_state.roster_ids.has(character_id):
			lines.append(TextDB.format_text("ui.messages.personal_missing", [display_name]))
			continue
		var character_state: Dictionary = run_state.active_character_states.get(character_id, {})
		var relation_state: Dictionary = run_state.relation_states.get(character_id, {})
		var favor: int = int(relation_state.get("favor", 0))
		var rumor_risk: int = int(relation_state.get("rumor_risk", 0))
		if int(character_state.get("health_state", 1)) <= 0 or int(character_state.get("mental_state", 1)) <= 0:
			lines.append(TextDB.format_text("ui.messages.personal_lost", [display_name]))
			continue
		if favor >= 4:
			lines.append(TextDB.format_text("ui.messages.personal_trusted", [display_name]))
		elif favor < 0 or rumor_risk >= 2:
			lines.append(TextDB.format_text("ui.messages.personal_strained", [display_name]))
		else:
			lines.append(TextDB.format_text("ui.messages.personal_joined", [display_name]))
		if character_id == "guo_jia" and bool(run_state.flags.get("guojia_personal_line_seen", false)):
			lines.append(TextDB.format_text("ui.messages.personal_progressed", [display_name]))
		elif character_id == "xun_yu" and bool(run_state.flags.get("xun_yu_personal_line_seen", false)):
			lines.append(TextDB.format_text("ui.messages.personal_progressed", [display_name]))
	return lines

static func can_drop_on_slot(slot_id: String, payload: Dictionary, current_cards: Array = []) -> bool:
	if payload.is_empty():
		return false
	var card_type: String = str(payload.get("card_type", ""))
	var card_id: String = str(payload.get("id", ""))
	if card_type == "event" and slot_id != "research":
		return false
	if not SLOT_CAPACITY.has(slot_id):
		return false
	if slot_id == "rest":
		return _can_drop_on_rest_slot(payload, current_cards)
	var capacity_by_type: Dictionary = SLOT_CAPACITY[slot_id]
	var limit: int = int(capacity_by_type.get(card_type, 0))
	if limit <= 0:
		return false
	if _count_card_type(current_cards, card_type) >= limit:
		return false
	if slot_id == "research" and card_type == "event":
		return true
	if slot_id == "research" and card_type == "resource" and card_id == "silver_pack":
		return true
	if card_type == "character" and card_id == "cao_cao" and slot_id in ["governance", "recruit", "audience"]:
		return true
	if slot_id == "recruit" and _is_recruit_resource(payload):
		return true
	if slot_id == "audience" and card_type == "resource":
		if _payload_has_any_tag(payload, ["gift"]) and _count_cards_with_any_tag(current_cards, ["gift"]) >= 1:
			return false
		if _is_audience_resource(payload):
			return true
	return _matches_slot_requirements(slot_id, card_type, payload)

static func _can_drop_on_rest_slot(payload: Dictionary, current_cards: Array = []) -> bool:
	var card_type: String = str(payload.get("card_type", ""))
	var card_id: String = str(payload.get("id", ""))
	var character_ids: Array[String] = []
	var resource_ids: Array[String] = []
	var risk_ids: Array[String] = []
	for card_variant in current_cards:
		var card: Dictionary = card_variant as Dictionary
		match str(card.get("card_type", "")):
			"character":
				character_ids.append(str(card.get("id", "")))
			"resource":
				resource_ids.append(str(card.get("id", "")))
			"risk":
				risk_ids.append(str(card.get("id", "")))
	var target_present: bool = not character_ids.is_empty()
	var caregiver_present: bool = character_ids.size() >= 2
	var has_headwind: bool = risk_ids.has("headwind")
	var support_resource_id: String = ""
	for resource_id in resource_ids:
		if resource_id in ["silver_pack", "herbal_tonic", "calming_incense"]:
			support_resource_id = resource_id
			break
	var has_support_resource: bool = not support_resource_id.is_empty()
	if card_type == "character":
		if not target_present:
			return true
		if caregiver_present:
			return false
		if has_headwind:
			return false
		return support_resource_id in ["silver_pack", "herbal_tonic"]
	if card_type == "resource":
		if has_support_resource:
			return false
		if card_id == "calming_incense":
			return not caregiver_present and (has_headwind or not caregiver_present)
		if card_id in ["silver_pack", "herbal_tonic"]:
			return not has_headwind
		return false
	if card_type == "risk":
		if card_id != "headwind":
			return false
		if has_headwind or caregiver_present:
			return false
		return support_resource_id.is_empty() or support_resource_id == "calming_incense"
	return false

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
	if slot_id == "recruit" and _is_recruit_resource(payload):
		score += 8
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
			set_bad_ending(run_state, risk.bad_ending_id)
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

static func _count_cards_with_any_tag(cards: Array, required_tags: Array[String]) -> int:
	var total: int = 0
	for card_variant in cards:
		var card: Dictionary = card_variant as Dictionary
		if _payload_has_any_tag(card, required_tags):
			total += 1
	return total

static func _payload_has_any_tag(payload: Dictionary, required_tags: Array[String]) -> bool:
	var tags: Array[String] = _payload_tags(payload)
	for required_tag in required_tags:
		if tags.has(required_tag):
			return true
	return false

static func _is_recruit_resource(payload: Dictionary) -> bool:
	if str(payload.get("card_type", "")) != "resource":
		return false
	var card_id: String = str(payload.get("id", ""))
	if card_id in ["silver_pack", "recruit_writ"]:
		return true
	var tags: Array[String] = _payload_tags(payload)
	for required_tag_variant in ["task", "recruit", "money", "document"]:
		var required_tag: String = str(required_tag_variant)
		if tags.has(required_tag):
			return true
	return false

static func _is_audience_resource(payload: Dictionary) -> bool:
	if str(payload.get("card_type", "")) != "resource":
		return false
	var card_id: String = str(payload.get("id", ""))
	if card_id in ["gift", "sanjian_dao", "silver_pack", "sealed_letter", "yecheng_letter", "calming_incense"]:
		return true
	var tags: Array[String] = _payload_tags(payload)
	for required_tag_variant in ["gift", "relation", "support", "mind", "money", "document"]:
		var required_tag: String = str(required_tag_variant)
		if tags.has(required_tag):
			return true
	return false

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
	run_state.fire_progress = clampi(run_state.fire_progress, 0, MAX_FIRE_PROGRESS)
	if run_state.fire_progress >= MAX_FIRE_PROGRESS and not run_state.game_over:
		run_state.flags["force_conclusion"] = true
	if run_state.cao_health <= 0 or run_state.cao_mind <= 0:
		set_bad_ending(run_state, TextDB.get_text("system.endings.fire"))
