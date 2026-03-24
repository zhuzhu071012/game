extends Resource
class_name RelationData

# Base relation rules between Cao Cao and a character.
@export var character_id: String = ""
@export var relation_type: String = "minister"
@export var favor_thresholds: Dictionary = {}
@export var rumor_risk: int = 0
@export var jealousy_targets: Array[String] = []
@export var special_event_ids: Array[String] = []
