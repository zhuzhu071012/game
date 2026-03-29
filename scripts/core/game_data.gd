extends RefCounted
class_name GameData

# GameData 负责拼装原型运行时需要的静态数据入口。
# 文案继续走 TextDB / data/texts，数值定义则拆到 data/definitions，方便后续人工维护。
const CHARACTER_DEFINITIONS_PATH: String = "res://data/definitions/characters.json"
const CHARACTER_SCENE_ORDER: Array[String] = ["cao_cao", "xun_yu", "guo_jia", "zhang_liao", "yu_jin", "cao_pi", "cao_zhi", "hua_tuo"]

# 初始化一局的起始状态，包括初始队伍、资源、关系与风险计数。
static func create_run_state() -> RunState:
	var run_state: RunState = RunState.new()
	run_state.turn_index = 1
	run_state.stage_index = 1
	run_state.cao_health = 10
	run_state.cao_mind = 9
	run_state.money = 16
	run_state.morale = 5
	run_state.jingzhou_stability = 6
	run_state.naval_readiness = 1
	run_state.alliance_strength = 4
	run_state.fire_progress = 0
	run_state.roster_ids = ["cao_cao"]
	run_state.locked_character_ids = ["xun_yu", "guo_jia", "zhang_liao", "yu_jin", "cao_pi", "cao_zhi", "hua_tuo"]
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
		"guojia_overworked_this_turn": false,
		"first_governance_done": false,
		"first_recruit_done": false,
		"first_headwind_seen": false,
		"unlocked_research": false,
		"unlocked_recruit": false,
		"unlocked_audience": false,
		"unlocked_rest": false,
		"guojia_personal_line_seen": false,
		"xun_yu_personal_line_seen": false,
		"iron_chain_event_established": false,
		"east_wind_event_established": false,
		"scheme_counter_ready": false,
		"force_conclusion": false,
		"ending_tier": "",
		"tutorial_step": 1,
		"tutorial_completed": false,
		"tutorial_last_report_step": 0,
		"tutorial_pending_popup": ""
	}
	run_state.resource_states = {
		"silver_pack": 0,
		"herbal_tonic": 0,
		"spy_report": 0,
		"recruit_writ": 0,
		"gift": 0,
		"naval_chart": 0,
		"calming_incense": 0,
		"sealed_letter": 0,
		"yecheng_letter": 0,
		"sanjian_dao": 0,
		"night_watch_roll": 0
	}
	for relation_variant in create_relations():
		var relation: RelationData = relation_variant as RelationData
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

# 人物基础数值从 definitions 读取；姓名与简介仍由 TextDB 提供。
static func create_characters() -> Dictionary:
	var map: Dictionary = {}
	var definitions: Dictionary = _load_character_definitions()
	for character_id in CHARACTER_SCENE_ORDER:
		if not definitions.has(character_id):
			push_warning("Missing character definition: %s" % character_id)
			continue
		var spec: Dictionary = definitions[character_id] as Dictionary
		map[character_id] = _make_character({
			"id": character_id,
			"display_name": TextDB.get_text("characters.%s.name" % character_id, character_id),
			"role_type": str(spec.get("role_type", "")),
			"faction": str(spec.get("faction", "")),
			"tags": _to_string_array(spec.get("tags", [])),
			"specialty_tags": _to_string_array(spec.get("specialty_tags", [])),
			"loyalty": int(spec.get("loyalty", 0)),
			"favor": int(spec.get("favor", 0)),
			"strength": int(spec.get("strength", 0)),
			"agility": int(spec.get("agility", 0)),
			"constitution": int(spec.get("constitution", 0)),
			"intelligence": int(spec.get("intelligence", 0)),
			"perception": int(spec.get("perception", 0)),
			"charisma": int(spec.get("charisma", 0)),
			"execution": int(spec.get("execution", 0)),
			"insight": int(spec.get("insight", 0)),
			"martial": int(spec.get("martial", 0)),
			"charm": int(spec.get("charm", 0)),
			"medicine": int(spec.get("medicine", 0)),
			"health_state": int(spec.get("health_state", 0)),
			"mental_state": int(spec.get("mental_state", 0)),
			"fatigue": int(spec.get("fatigue", 0)),
			"passive_id": str(spec.get("passive_id", "")),
			"unique_event_ids": _to_string_array(spec.get("unique_event_ids", [])),
			"art_path": str(spec.get("art_path", ""))
		})
	return map

static func create_relations() -> Array[RelationData]:
	var list: Array[RelationData] = []
	var relation_specs: Dictionary = {
		"xun_yu": {"relation_type": "minister", "rumor_risk": 1, "special_event_ids": ["xun_yu_letters"]},
		"guo_jia": {"relation_type": "minister", "rumor_risk": 0, "special_event_ids": ["guojia_relapse"]},
		"zhang_liao": {"relation_type": "general", "rumor_risk": 0, "special_event_ids": []},
		"yu_jin": {"relation_type": "general", "rumor_risk": 0, "special_event_ids": []},
		"cao_pi": {"relation_type": "family", "rumor_risk": 1, "special_event_ids": []},
		"cao_zhi": {"relation_type": "family", "rumor_risk": 1, "special_event_ids": []},
		"hua_tuo": {"relation_type": "guest", "rumor_risk": 0, "special_event_ids": ["guojia_relapse"]}
	}
	for character_id_variant in relation_specs.keys():
		var character_id: String = str(character_id_variant)
		var spec: Dictionary = relation_specs[character_id]
		var relation: RelationData = RelationData.new()
		relation.character_id = character_id
		relation.relation_type = str(spec.get("relation_type", "minister"))
		relation.favor_thresholds = {"cold": -3, "steady": 0, "trusted": 4, "bonded": 8}
		relation.rumor_risk = int(spec.get("rumor_risk", 0))
		relation.jealousy_targets.clear()
		for jealousy_target_variant in _to_string_array(spec.get("jealousy_targets", [])):
			relation.jealousy_targets.append(jealousy_target_variant)
		relation.special_event_ids.clear()
		for event_id_variant in _to_string_array(spec.get("special_event_ids", [])):
			relation.special_event_ids.append(event_id_variant)
		list.append(relation)
	return list

# 从独立 JSON 文件读取人物定义，方便手动调数值而不碰脚本文案。
static func _load_character_definitions() -> Dictionary:
	var root: Dictionary = _load_json_dictionary(CHARACTER_DEFINITIONS_PATH)
	var definitions: Variant = root.get("characters", {})
	return definitions if definitions is Dictionary else {}

static func _load_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var raw: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(raw)
	return parsed if parsed is Dictionary else {}

static func _to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result

# 资源与事件暂时仍保留在代码里，后续若扩容也可以按同样方式继续拆到 definitions。
static func create_resources() -> Dictionary:
	var map: Dictionary = {}
	map["silver_pack"] = _make_resource({
		"id": "silver_pack",
		"display_name": TextDB.get_text("resources.silver_pack.name"),
		"category": "money",
		"description": TextDB.get_text("resources.silver_pack.description"),
		"tags": ["money"],
		"value": 1,
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
		"consumable": true,
		"art_path": "res://assets/cards/resource_placeholder.svg"
	})
	map["gift"] = _make_resource({
		"id": "gift",
		"display_name": TextDB.get_text("resources.gift.name"),
		"category": "gift",
		"description": TextDB.get_text("resources.gift.description"),
		"tags": ["gift", "relation"],
		"value": 1,
		"consumable": true,
		"art_path": "res://assets/cards/resource_placeholder.svg"
	})
	map["naval_chart"] = _make_resource({
		"id": "naval_chart",
		"display_name": TextDB.get_text("resources.naval_chart.name"),
		"category": "intel",
		"description": TextDB.get_text("resources.naval_chart.description"),
		"tags": ["naval", "research", "document"],
		"value": 1,
		"consumable": true,
		"art_path": "res://assets/cards/resource_placeholder.svg"
	})
	map["calming_incense"] = _make_resource({
		"id": "calming_incense",
		"display_name": TextDB.get_text("resources.calming_incense.name"),
		"category": "rest",
		"description": TextDB.get_text("resources.calming_incense.description"),
		"tags": ["rest", "relation", "mind", "care"],
		"value": 1,
		"consumable": true,
		"art_path": "res://assets/cards/resource_placeholder.svg"
	})
	map["sealed_letter"] = _make_resource({
		"id": "sealed_letter",
		"display_name": TextDB.get_text("resources.sealed_letter.name"),
		"category": "intel",
		"description": TextDB.get_text("resources.sealed_letter.description"),
		"tags": ["relation", "document", "secret_report", "intel"],
		"value": 1,
		"consumable": true,
		"art_path": "res://assets/cards/resource_placeholder.svg"
	})
	map["yecheng_letter"] = _make_resource({
		"id": "yecheng_letter",
		"display_name": TextDB.get_text("resources.yecheng_letter.name"),
		"category": "intel",
		"description": TextDB.get_text("resources.yecheng_letter.description"),
		"tags": ["document", "relation", "intel"],
		"value": 1,
		"consumable": false,
		"art_path": "res://assets/cards/resource_placeholder.svg"
	})
	map["sanjian_dao"] = _make_resource({
		"id": "sanjian_dao",
		"display_name": TextDB.get_text("resources.sanjian_dao.name"),
		"category": "gift",
		"description": TextDB.get_text("resources.sanjian_dao.description"),
		"tags": ["gift", "relation"],
		"value": 1,
		"consumable": true,
		"art_path": "res://assets/cards/resource_placeholder.svg"
	})
	map["night_watch_roll"] = _make_resource({
		"id": "night_watch_roll",
		"display_name": TextDB.get_text("resources.night_watch_roll.name"),
		"category": "intel",
		"description": TextDB.get_text("resources.night_watch_roll.description"),
		"tags": ["document", "intel", "task"],
		"value": 1,
		"consumable": true,
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

# 临时事件定义集中在这里，避免散落到 UI 层。
static func create_events() -> Dictionary:
	var map: Dictionary = {}
	map["grain_shortage"] = _make_event({
		"id": "grain_shortage",
		"title": TextDB.get_text("events.grain_shortage.title"),
		"description": TextDB.get_text("events.grain_shortage.description"),
		"category": "crisis",
		"tags": ["governance", "logistics", "influence"],
		"stage_min": 1,
		"stage_max": 3,
		"weight": 2,
		"timeout_turns": 3,
		"minimum_requirement": 6,
		"success_threshold": 14,
		"difficulty_class": 15,
		"recommended_tags": ["governance", "military", "steady"],
		"recommended_resource_ids": ["silver_pack", "sealed_letter"],
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
		"stage_max": 3,
		"weight": 1,
		"timeout_turns": 3,
		"minimum_requirement": 6,
		"success_threshold": 14,
		"difficulty_class": 16,
		"recommended_tags": ["research", "scheme", "naval"],
		"recommended_resource_ids": ["spy_report", "naval_chart"],
		"success_effect_id": "naval_chart",
		"fail_effect_id": "seasick_risk",
		"expire_effect_id": "seasick_risk",
		"next_event_ids": ["ember_dream"],
		"trigger_type": "time",
		"trigger_turn": 4,
		"art_path": "res://assets/cards/event_placeholder.svg"
	})
	map["guojia_relapse"] = _make_event({
		"id": "guojia_relapse",
		"title": TextDB.get_text("events.guojia_relapse.title"),
		"description": TextDB.get_text("events.guojia_relapse.description"),
		"category": "character",
		"tags": ["rest", "medicine", "relation", "influence"],
		"stage_min": 1,
		"stage_max": 3,
		"weight": 2,
		"timeout_turns": 2,
		"minimum_requirement": 6,
		"success_threshold": 13,
		"difficulty_class": 15,
		"required_flags": ["guojia_sick_stage_2"],
		"recommended_tags": ["rest", "medicine", "relation"],
		"recommended_resource_ids": ["herbal_tonic", "calming_incense", "silver_pack"],
		"success_effect_id": "heal_guojia",
		"fail_effect_id": "miasma_risk",
		"expire_effect_id": "miasma_risk",
		"trigger_type": "condition",
		"trigger_condition_id": "guojia_relapse",
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
		"stage_max": 3,
		"weight": 2,
		"timeout_turns": 3,
		"minimum_requirement": 5,
		"success_threshold": 13,
		"difficulty_class": 15,
		"required_flags": ["jingzhou_rumor_active"],
		"recommended_tags": ["relation", "scheme", "charm"],
		"recommended_resource_ids": ["gift", "sealed_letter", "silver_pack"],
		"success_effect_id": "rumor_cleared",
		"fail_effect_id": "rumor_risk",
		"expire_effect_id": "rumor_risk",
		"trigger_type": "condition",
		"trigger_condition_id": "jingzhou_whispers",
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
		"stage_max": 3,
		"weight": 1,
		"timeout_turns": 3,
		"minimum_requirement": 4,
		"success_threshold": 11,
		"difficulty_class": 14,
		"recommended_tags": ["rest", "mind", "relation"],
		"recommended_resource_ids": ["calming_incense", "silver_pack"],
		"success_effect_id": "dream_calm",
		"fail_effect_id": "headwind_risk",
		"expire_effect_id": "headwind_risk",
		"trigger_type": "condition",
		"trigger_condition_id": "ember_dream",
		"trigger_turn": -1,
		"art_path": "res://assets/cards/event_placeholder.svg"
	})
	map["xun_yu_letters"] = _make_event({
		"id": "xun_yu_letters",
		"title": TextDB.get_text("events.xun_yu_letters.title"),
		"description": TextDB.get_text("events.xun_yu_letters.description"),
		"category": "relation",
		"tags": ["relation", "governance", "rumor"],
		"stage_min": 2,
		"stage_max": 3,
		"weight": 1,
		"timeout_turns": 5,
		"minimum_requirement": 6,
		"success_threshold": 14,
		"difficulty_class": 16,
		"recommended_tags": ["relation", "governance", "steady"],
		"recommended_resource_ids": ["gift", "sealed_letter", "silver_pack"],
		"success_effect_id": "trust_secured",
		"fail_effect_id": "trust_cracked",
		"expire_effect_id": "trust_cracked",
		"trigger_type": "condition",
		"trigger_condition_id": "xun_yu_letters",
		"trigger_turn": -1,
		"art_path": "res://assets/cards/event_placeholder.svg"
	})
	map["camp_fever"] = _make_event({
		"id": "camp_fever",
		"title": TextDB.get_text("events.camp_fever.title"),
		"description": TextDB.get_text("events.camp_fever.description"),
		"category": "crisis",
		"tags": ["rest", "medicine", "influence"],
		"stage_min": 1,
		"stage_max": 3,
		"weight": 2,
		"timeout_turns": 2,
		"minimum_requirement": 5,
		"success_threshold": 12,
		"difficulty_class": 15,
		"recommended_tags": ["medicine", "rest", "care"],
		"recommended_resource_ids": ["herbal_tonic", "silver_pack"],
		"success_effect_id": "stabilize_camp_fever",
		"fail_effect_id": "miasma_risk",
		"expire_effect_id": "miasma_risk",
		"trigger_type": "condition",
		"trigger_condition_id": "camp_fever",
		"trigger_turn": -1,
		"art_path": "res://assets/cards/event_placeholder.svg"
	})
	map["hidden_correspondence"] = _make_event({
		"id": "hidden_correspondence",
		"title": TextDB.get_text("events.hidden_correspondence.title"),
		"description": TextDB.get_text("events.hidden_correspondence.description"),
		"category": "omen",
		"tags": ["research", "document", "secret_report", "relation", "influence"],
		"stage_min": 1,
		"stage_max": 3,
		"weight": 1,
		"timeout_turns": 3,
		"minimum_requirement": 5,
		"success_threshold": 13,
		"difficulty_class": 15,
		"recommended_tags": ["research", "scheme", "document"],
		"recommended_resource_ids": ["spy_report", "sealed_letter"],
		"success_effect_id": "gain_correspondence_cache",
		"fail_effect_id": "rumor_risk",
		"expire_effect_id": "rumor_risk",
		"trigger_type": "time",
		"trigger_turn": 6,
		"art_path": "res://assets/cards/event_placeholder.svg"
	})
	map["harbor_survey"] = _make_event({
		"id": "harbor_survey",
		"title": TextDB.get_text("events.harbor_survey.title"),
		"description": TextDB.get_text("events.harbor_survey.description"),
		"category": "omen",
		"tags": ["research", "naval", "search", "influence"],
		"stage_min": 1,
		"stage_max": 3,
		"weight": 1,
		"timeout_turns": 3,
		"minimum_requirement": 6,
		"success_threshold": 14,
		"difficulty_class": 16,
		"recommended_tags": ["research", "naval", "search"],
		"recommended_resource_ids": ["naval_chart", "spy_report"],
		"success_effect_id": "gain_harbor_chart",
		"fail_effect_id": "seasick_risk",
		"expire_effect_id": "seasick_risk",
		"trigger_type": "time",
		"trigger_turn": 8,
		"art_path": "res://assets/cards/event_placeholder.svg"
	})
	map["tribute_market"] = _make_event({
		"id": "tribute_market",
		"title": TextDB.get_text("events.tribute_market.title"),
		"description": TextDB.get_text("events.tribute_market.description"),
		"category": "relation",
		"tags": ["relation", "gift", "search", "influence"],
		"stage_min": 1,
		"stage_max": 3,
		"weight": 1,
		"timeout_turns": 3,
		"minimum_requirement": 4,
		"success_threshold": 12,
		"difficulty_class": 14,
		"recommended_tags": ["relation", "gift", "search"],
		"recommended_resource_ids": ["silver_pack", "gift"],
		"success_effect_id": "gain_market_gift",
		"fail_effect_id": "rumor_risk",
		"expire_effect_id": "rumor_risk",
		"trigger_type": "time",
		"trigger_turn": 10,
		"art_path": "res://assets/cards/event_placeholder.svg"
	})
	map["talent_trace"] = _make_event({
		"id": "talent_trace",
		"title": TextDB.get_text("events.talent_trace.title"),
		"description": TextDB.get_text("events.talent_trace.description"),
		"category": "relation",
		"tags": ["recruit", "search", "relation", "document", "influence"],
		"stage_min": 1,
		"stage_max": 3,
		"weight": 1,
		"timeout_turns": 3,
		"minimum_requirement": 5,
		"success_threshold": 13,
		"difficulty_class": 15,
		"recommended_tags": ["recruit", "search", "relation"],
		"recommended_resource_ids": ["silver_pack", "recruit_writ", "sealed_letter"],
		"success_effect_id": "gain_recruit_lead",
		"fail_effect_id": "rumor_risk",
		"expire_effect_id": "rumor_risk",
		"trigger_type": "time",
		"trigger_turn": 12,
		"art_path": "res://assets/cards/event_placeholder.svg"
	})
	map["tutorial_patrol_gap"] = _make_event({
		"id": "tutorial_patrol_gap",
		"title": TextDB.get_text("events.tutorial_patrol_gap.title"),
		"description": TextDB.get_text("events.tutorial_patrol_gap.description"),
		"category": "crisis",
		"tags": ["military", "discipline", "influence"],
		"stage_min": 1,
		"stage_max": 3,
		"weight": 0,
		"timeout_turns": 3,
		"minimum_requirement": 6,
		"success_threshold": 12,
		"difficulty_class": 14,
		"recommended_tags": ["military", "discipline"],
		"recommended_resource_ids": ["night_watch_roll"],
		"required_resource_ids": ["night_watch_roll"],
		"success_effect_id": "tutorial_patrol_secured",
		"fail_effect_id": "fire_and_risk",
		"expire_effect_id": "fire_and_risk",
		"trigger_type": "condition",
		"trigger_condition_id": "",
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
