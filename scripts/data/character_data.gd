extends Resource
class_name CharacterData

# Static character definition used by the prototype.
@export var id: String = ""
@export var display_name: String = ""
@export var role_type: String = ""
@export var faction: String = ""
@export var tags: Array[String] = []
@export var loyalty: int = 0
@export var favor: int = 0
@export var execution: int = 0
@export var insight: int = 0
@export var martial: int = 0
@export var charm: int = 0
@export var medicine: int = 0
@export var health_state: int = 0
@export var mental_state: int = 0
@export var fatigue: int = 0
@export var passive_id: String = ""
@export var unique_event_ids: Array[String] = []
@export var art_path: String = ""