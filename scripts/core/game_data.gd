extends RefCounted
class_name GameData

const CHARACTER_SCENE_ORDER: Array[String] = [
	"cao_cao",
	"guo_jia",
	"jia_xu",
	"xun_you",
	"zhang_liao",
	"yu_jin",
	"bian_furen",
	"physician"
]

static func create_run_state() -> RunState:
	var run_state: RunState = RunState.new()
	run_state.roster_ids = ["cao_cao"]
	run_state.locked_character_ids = ["guo_jia", "jia_xu", "xun_you", "zhang_liao", "yu_jin", "bian_furen", "physician"]
	run_state.flags = {
		"guojia_sick_stage_1": true,
		"guojia_sick_stage_2": false,
		"guojia_sick_stage_3": false,
		"romance_suheng_started": false,
		"jingzhou_rumor_active": false,
		"alliance_forming": true,
		"guojia_meet_scene": false,
		"dream_seen_once": false,
		"ember_dream_ready": false,
		"first_governance_done": false,
		"first_recruit_done": false,
		"first_headwind_seen": false,
		"unlocked_research": false,
		"unlocked_recruit": false,
		"unlocked_audience": false,
		"unlocked_rest": false
	}
	run_state.resource_states = {
		"silver_pack": 2,
		"herbal_tonic": 1,
		"spy_report": 1,
		"recruit_writ": 1,
		"naval_chart": 0,
		"calming_incense": 1,
		"sealed_letter": 0
	}
	for relation in create_relations():
		run_state.relation_states[relation.character_id] = {
			"favor": 0,
			"rumor_risk": relation.rumor_risk,
			"relation_type": relation.relation_type,
			"stage_label": GameRules.relation_label(0),
			"special_flags": {}
		}
	var all_characters: Dictionary = create_characters()
	for character_variant in all_characters.values():
		var character: CharacterData = character_variant as CharacterData
		run_state.active_character_states[character.id] = {
			"health_state": character.health_state,
			"mental_state": character.mental_state,
			"fatigue": character.fatigue,
			"busy": false,
			"sick_stage": 0,
			"guarded": false
		}
	run_state.active_character_states["guo_jia"]["sick_stage"] = 1
	for risk_id_variant in create_risks().keys():
		var risk_id: String = str(risk_id_variant)
		run_state.risk_states[risk_id] = 0
	run_state.log_entries.append(TextDB.get_text("logs.run.intro"))
	return run_state

static func create_characters() -> Dictionary:
	var map: Dictionary = {}
	map["cao_cao"] = _make_character({
		"id": "cao_cao",
		"display_name": TextDB.get_text("characters.cao_cao.name"),
		"role_type": "lord",
		"faction": "wei",
		"tags": ["leader", "politics", "governance", "relation"],
		"loyalty": 100,
		"favor": 0,
		"execution": 8,
		"insight": 8,
		"martial": 6,
		"charm": 8,
		"medicine": 0,
		"health_state": 10,
		"mental_state": 10,
		"fatigue": 0,
		"passive_id": "lord_overdrive",
		"unique_event_ids": ["ember_dream"],
		"art_path": "res://assets/cards/characters/cao_cao.svg"
	})
	map["guo_jia"] = _make_character({
		"id": "guo_jia",
		"display_name": TextDB.get_text("characters.guo_jia.name"),
		"role_type": "strategist",
		"faction": "wei",
		"tags": ["scheme", "research", "mind"],
		"loyalty": 72,
		"favor": 1,
		"execution": 5,
		"insight": 9,
		"martial": 1,
		"charm": 6,
		"medicine": 0,
		"health_state": 6,
		"mental_state": 8,
		"fatigue": 0,
		"passive_id": "fragile_genius",
		"unique_event_ids": ["guojia_relapse"],
		"art_path": "res://assets/cards/characters/guo_jia.png"
	})
	map["jia_xu"] = _make_character({
		"id": "jia_xu",
		"display_name": TextDB.get_text("characters.jia_xu.name"),
		"role_type": "strategist",
		"faction": "wei",
		"tags": ["scheme", "crisis", "rumor", "relation"],
		"loyalty": 76,
		"favor": 0,
		"execution": 7,
		"insight": 8,
		"martial": 1,
		"charm": 7,
		"medicine": 0,
		"health_state": 8,
		"mental_state": 8,
		"fatigue": 0,
		"passive_id": "cold_suppression",
		"unique_event_ids": ["river_rumor"],
		"art_path": "res://assets/cards/characters/jia_xu.svg"
	})
	map["xun_you"] = _make_character({
		"id": "xun_you",
		"display_name": TextDB.get_text("characters.xun_you.name"),
		"role_type": "advisor",
		"faction": "wei",
		"tags": ["steady", "research", "governance"],
		"loyalty": 84,
		"favor": 0,
		"execution": 7,
		"insight": 8,
		"martial": 1,
		"charm": 5,
		"medicine": 0,
		"health_state": 8,
		"mental_state": 9,
		"fatigue": 0,
		"passive_id": "careful_design",
		"unique_event_ids": ["archive_findings"],
		"art_path": "res://assets/cards/characters/xun_you.svg"
	})
	map["zhang_liao"] = _make_character({
		"id": "zhang_liao",
		"display_name": TextDB.get_text("characters.zhang_liao.name"),
		"role_type": "general",
		"faction": "wei",
		"tags": ["military", "discipline", "swift", "governance"],
		"loyalty": 82,
		"favor": 0,
		"execution": 8,
		"insight": 4,
		"martial": 9,
		"charm": 4,
		"medicine": 0,
		"health_state": 9,
		"mental_state": 7,
		"fatigue": 0,
		"passive_id": "rapid_quell",
		"unique_event_ids": ["camp_sweep"],
		"art_path": "res://assets/cards/characters/zhang_liao.svg"
	})
	map["yu_jin"] = _make_character({
		"id": "yu_jin",
		"display_name": TextDB.get_text("characters.yu_jin.name"),
		"role_type": "general",
		"faction": "wei",
		"tags": ["military", "discipline", "camp", "governance"],
		"loyalty": 80,
		"favor": 0,
		"execution": 7,
		"insight": 4,
		"martial": 7,
		"charm": 3,
		"medicine": 0,
		"health_state": 8,
		"mental_state": 7,
		"fatigue": 0,
		"passive_id": "strict_camp",
		"unique_event_ids": ["camp_repair"],
		"art_path": "res://assets/cards/characters/yu_jin.svg"
	})
	map["bian_furen"] = _make_character({
		"id": "bian_furen",
		"display_name": TextDB.get_text("characters.bian_furen.name"),
		"role_type": "consort",
		"faction": "wei",
		"tags": ["relation", "rest", "support", "mind"],
		"loyalty": 95,
		"favor": 2,
		"execution": 4,
		"insight": 6,
		"martial": 0,
		"charm": 8,
		"medicine": 0,
		"health_state": 8,
		"mental_state": 9,
		"fatigue": 0,
		"passive_id": "gentle_calm",
		"unique_event_ids": ["quiet_chamber"],
		"art_path": "res://assets/cards/characters/bian_furen.svg"
	})
	map["physician"] = _make_character({
		"id": "physician",
		"display_name": TextDB.get_text("characters.physician.name"),
		"role_type": "retainer",
		"faction": "neutral",
		"tags": ["medicine", "rest", "support", "care"],
		"loyalty": 60,
		"favor": 0,
		"execution": 4,
		"insight": 4,
		"martial": 0,
		"charm": 3,
		"medicine": 8,
		"health_state": 8,
		"mental_state": 7,
		"fatigue": 0,
		"passive_id": "ward_care",
		"unique_event_ids": ["medicine_run"],
		"art_path": "res://assets/cards/characters/physician.svg"
	})
	return map

static func create_relations() -> Array[RelationData]:
	var list: Array[RelationData] = []
	for character_id in ["guo_jia", "jia_xu", "xun_you", "zhang_liao", "yu_jin", "bian_furen", "physician"]:
		var relation: RelationData = RelationData.new()
		relation.character_id = character_id
		relation.relation_type = "minister"
		relation.favor_thresholds = {"cold": -3, "steady": 0, "trusted": 4, "bonded": 8}
		relation.rumor_risk = 0 if character_id != "bian_furen" else 1
		if character_id == "guo_jia":
			relation.special_event_ids = ["guojia_relapse", "guojia_confession"]
		list.append(relation)
	return list

static func create_resources() -> Dictionary:
	var map: Dictionary = {}
	map["silver_pack"] = _make_resource({
		"id": "silver_pack",
		"display_name": TextDB.get_text("resources.silver_pack.name"),
		"category": "money",
		"description": TextDB.get_text("resources.silver_pack.description"),
		"tags": ["money", "gift"],
		"value": 10,
		"consumable": true,
		"art_path": "res://assets/cards/resource_placeholder.svg"
	})
	map["herbal_tonic"] = _make_resource({
		"id": "herbal_tonic",
		"display_name": TextDB.get_text("resources.herbal_tonic.name"),
		"category": "medicine",
		"description": TextDB.get_text("resources.herbal_tonic.description"),
		"tags": ["medicine", "rest", "care"],
		"value": 1,
		"consumable": true,
		"art_path": "res://assets/cards/resource_placeholder.svg"
	})
	map["spy_report"] = _make_resource({
		"id": "spy_report",
		"display_name": TextDB.get_text("resources.spy_report.name"),
		"category": "intel",
		"description": TextDB.get_text("resources.spy_report.description"),
		"tags": ["intel", "research", "secret_report", "influence"],
		"value": 1,
		"consumable": true,
		"art_path": "res://assets/cards/resource_placeholder.svg"
	})
	map["recruit_writ"] = _make_resource({
		"id": "recruit_writ",
		"display_name": TextDB.get_text("resources.recruit_writ.name"),
		"category": "task",
		"description": TextDB.get_text("resources.recruit_writ.description"),
		"tags": ["task", "recruit", "document"],
		"value": 1,
		"consumable": false,
		"art_path": "res://assets/cards/resource_placeholder.svg"
	})
	map["naval_chart"] = _make_resource({
		"id": "naval_chart",
		"display_name": TextDB.get_text("resources.naval_chart.name"),
		"category": "intel",
		"description": TextDB.get_text("resources.naval_chart.description"),
		"tags": ["naval", "research", "document"],
		"value": 1,
		"consumable": false,
		"art_path": "res://assets/cards/resource_placeholder.svg"
	})
	map["calming_incense"] = _make_resource({
		"id": "calming_incense",
		"display_name": TextDB.get_text("resources.calming_incense.name"),
		"category": "rest",
		"description": TextDB.get_text("resources.calming_incense.description"),
		"tags": ["rest", "relation", "mind"],
		"value": 1,
		"consumable": true,
		"art_path": "res://assets/cards/resource_placeholder.svg"
	})
	map["sealed_letter"] = _make_resource({
		"id": "sealed_letter",
		"display_name": TextDB.get_text("resources.sealed_letter.name"),
		"category": "intel",
		"description": TextDB.get_text("resources.sealed_letter.description"),
		"tags": ["intel", "research", "task", "document", "secret_report"],
		"value": 1,
		"consumable": false,
		"art_path": "res://assets/cards/resource_placeholder.svg"
	})
	return map

static func create_risks() -> Dictionary:
	var map: Dictionary = {}
	map["headwind"] = _make_risk({
		"id": "headwind",
		"display_name": TextDB.get_text("risks.headwind.name"),
		"description": TextDB.get_text("risks.headwind.description"),
		"mild_penalty": {"mind": -1},
		"severe_penalty": {"mind": -2, "morale": -1},
		"bad_ending_id": TextDB.get_text("system.endings.headwind"),
		"art_path": "res://assets/cards/risk_placeholder.svg"
	})
	map["alienation"] = _make_risk({
		"id": "alienation",
		"display_name": TextDB.get_text("risks.alienation.name"),
		"description": TextDB.get_text("risks.alienation.description"),
		"mild_penalty": {"morale": -1},
		"severe_penalty": {"morale": -2, "stability": -1},
		"bad_ending_id": TextDB.get_text("system.endings.alienation"),
		"art_path": "res://assets/cards/risk_placeholder.svg"
	})
	map["miasma"] = _make_risk({
		"id": "miasma",
		"display_name": TextDB.get_text("risks.miasma.name"),
		"description": TextDB.get_text("risks.miasma.description"),
		"mild_penalty": {"health": -1},
		"severe_penalty": {"health": -2, "morale": -1},
		"bad_ending_id": TextDB.get_text("system.endings.miasma"),
		"art_path": "res://assets/cards/risk_placeholder.svg"
	})
	map["rumor"] = _make_risk({
		"id": "rumor",
		"display_name": TextDB.get_text("risks.rumor.name"),
		"description": TextDB.get_text("risks.rumor.description"),
		"mild_penalty": {"stability": -1},
		"severe_penalty": {"stability": -2, "alliance": 1},
		"bad_ending_id": TextDB.get_text("system.endings.rumor"),
		"art_path": "res://assets/cards/risk_placeholder.svg"
	})
	map["seasick"] = _make_risk({
		"id": "seasick",
		"display_name": TextDB.get_text("risks.seasick.name"),
		"description": TextDB.get_text("risks.seasick.description"),
		"mild_penalty": {"naval": -1},
		"severe_penalty": {"naval": -2, "fire": 1},
		"bad_ending_id": TextDB.get_text("system.endings.seasick"),
		"art_path": "res://assets/cards/risk_placeholder.svg"
	})
	return map

static func create_events() -> Dictionary:
	var map: Dictionary = {}
	map["grain_shortage"] = _make_event({
		"id": "grain_shortage",
		"title": TextDB.get_text("events.grain_shortage.title"),
		"description": TextDB.get_text("events.grain_shortage.description"),
		"category": "crisis",
		"tags": ["governance", "logistics", "influence"],
		"stage_min": 1,
		"stage_max": 5,
		"weight": 2,
		"timeout_turns": 2,
		"recommended_tags": ["governance", "military", "steady"],
		"success_effect_id": "gain_supply",
		"fail_effect_id": "fire_and_risk",
		"expire_effect_id": "fire_and_risk",
		"trigger_type": "time",
		"trigger_turn": 2,
		"art_path": "res://assets/cards/event_placeholder.svg"
	})
	map["river_omens"] = _make_event({
		"id": "river_omens",
		"title": TextDB.get_text("events.river_omens.title"),
		"description": TextDB.get_text("events.river_omens.description"),
		"category": "omen",
		"tags": ["research", "naval", "influence"],
		"stage_min": 1,
		"stage_max": 5,
		"weight": 1,
		"timeout_turns": 2,
		"recommended_tags": ["research", "scheme", "naval"],
		"success_effect_id": "naval_chart",
		"fail_effect_id": "seasick_risk",
		"expire_effect_id": "seasick_risk",
		"next_event_ids": ["ember_dream"],
		"trigger_type": "time",
		"trigger_turn": 3,
		"art_path": "res://assets/cards/event_placeholder.svg"
	})
	map["guojia_relapse"] = _make_event({
		"id": "guojia_relapse",
		"title": TextDB.get_text("events.guojia_relapse.title"),
		"description": TextDB.get_text("events.guojia_relapse.description"),
		"category": "character",
		"tags": ["rest", "medicine", "relation", "influence"],
		"stage_min": 1,
		"stage_max": 5,
		"weight": 2,
		"timeout_turns": 1,
		"required_flags": ["guojia_sick_stage_2"],
		"recommended_tags": ["rest", "medicine", "relation"],
		"success_effect_id": "heal_guojia",
		"fail_effect_id": "miasma_risk",
		"expire_effect_id": "miasma_risk",
		"trigger_type": "condition",
		"trigger_turn": -1,
		"art_path": "res://assets/cards/event_placeholder.svg"
	})
	map["jingzhou_whispers"] = _make_event({
		"id": "jingzhou_whispers",
		"title": TextDB.get_text("events.jingzhou_whispers.title"),
		"description": TextDB.get_text("events.jingzhou_whispers.description"),
		"category": "rumor",
		"tags": ["relation", "rumor", "influence"],
		"stage_min": 1,
		"stage_max": 5,
		"weight": 2,
		"timeout_turns": 2,
		"required_flags": ["jingzhou_rumor_active"],
		"recommended_tags": ["relation", "scheme", "charm"],
		"success_effect_id": "rumor_cleared",
		"fail_effect_id": "rumor_risk",
		"expire_effect_id": "rumor_risk",
		"trigger_type": "condition",
		"trigger_turn": -1,
		"art_path": "res://assets/cards/event_placeholder.svg"
	})
	map["ember_dream"] = _make_event({
		"id": "ember_dream",
		"title": TextDB.get_text("events.ember_dream.title"),
		"description": TextDB.get_text("events.ember_dream.description"),
		"category": "dream",
		"tags": ["rest", "mind", "influence"],
		"stage_min": 1,
		"stage_max": 5,
		"weight": 1,
		"timeout_turns": 1,
		"recommended_tags": ["rest", "mind", "relation"],
		"success_effect_id": "dream_calm",
		"fail_effect_id": "headwind_risk",
		"expire_effect_id": "headwind_risk",
		"trigger_type": "condition",
		"trigger_turn": -1,
		"art_path": "res://assets/cards/event_placeholder.svg"
	})
	return map

static func _make_character(values: Dictionary) -> CharacterData:
	var data: CharacterData = CharacterData.new()
	for key_variant in values.keys():
		data.set(str(key_variant), values[key_variant])
	return data

static func _make_event(values: Dictionary) -> EventData:
	var data: EventData = EventData.new()
	for key_variant in values.keys():
		data.set(str(key_variant), values[key_variant])
	return data

static func _make_resource(values: Dictionary) -> ResourceCardData:
	var data: ResourceCardData = ResourceCardData.new()
	for key_variant in values.keys():
		data.set(str(key_variant), values[key_variant])
	return data

static func _make_risk(values: Dictionary) -> RiskCardData:
	var data: RiskCardData = RiskCardData.new()
	for key_variant in values.keys():
		data.set(str(key_variant), values[key_variant])
	return data
