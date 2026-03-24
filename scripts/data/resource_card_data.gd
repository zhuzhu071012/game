extends Resource
class_name ResourceCardData

# Resource or task card definition.
@export var id: String = ""
@export var display_name: String = ""
@export var category: String = ""
@export_multiline var description: String = ""
@export var tags: Array[String] = []
@export var value: int = 0
@export var consumable: bool = true
@export var art_path: String = ""