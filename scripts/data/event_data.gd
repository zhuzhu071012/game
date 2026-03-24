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
@export var timeout_turns: int = 2
@export var required_flags: Array[String] = []
@export var blocked_flags: Array[String] = []
@export var recommended_tags: Array[String] = []
@export var success_effect_id: String = ""
@export var fail_effect_id: String = ""
@export var expire_effect_id: String = ""
@export var next_event_ids: Array[String] = []
@export var trigger_type: String = "time"
@export var trigger_turn: int = -1
@export var art_path: String = ""