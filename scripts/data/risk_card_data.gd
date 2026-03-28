extends Resource
class_name RiskCardData

# Hidden risk definition and penalty ladder.
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var mild_penalty: Dictionary = {}
@export var severe_penalty: Dictionary = {}
@export var bad_ending_id: String = ""
@export var art_path: String = ""
