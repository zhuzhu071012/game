extends Resource
class_name EventData

# Event definition for temporary board cards.
@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var category: String = ""
@export var tags: Array[String] = []
@export var stage_min: int = 1
@export var stage_max: int = 99
@export var weight: int = 1
@export var timeout_turns: int = 3
@export var minimum_requirement: int = 4
@export var success_threshold: int = 7
@export var difficulty_class: int = 14
@export var required_flags: Array[String] = []
@export var blocked_flags: Array[String] = []
@export var recommended_tags: Array[String] = []
@export var recommended_resource_ids: Array[String] = []
@export var required_resource_ids: Array[String] = []
@export var success_effect_id: String = ""
@export var fail_effect_id: String = ""
@export var expire_effect_id: String = ""
@export var next_event_ids: Array[String] = []
@export var trigger_type: String = "time"
@export var trigger_condition_id: String = ""
@export var trigger_turn: int = -1
@export var art_path: String = ""
