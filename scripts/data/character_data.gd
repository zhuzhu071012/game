extends Resource
class_name CharacterData

# 人物静态定义资源。
# 文本描述由 TextDB 提供；这里主要保存数值、标签、专长和卡面资源路径。
@export var id: String = ""
@export var display_name: String = ""
@export var role_type: String = ""
@export var faction: String = ""
@export var tags: Array[String] = []
@export var specialty_tags: Array[String] = []
@export var loyalty: int = 0
@export var favor: int = 0

# 六维基础属性。
@export var strength: int = 0
@export var agility: int = 0
@export var constitution: int = 0
@export var intelligence: int = 0
@export var perception: int = 0
@export var charisma: int = 0

# 兼容旧字段，方便后续扩展不同判定体系。
@export var execution: int = 0
@export var insight: int = 0
@export var martial: int = 0
@export var charm: int = 0
@export var medicine: int = 0

# 初始状态值。
@export var health_state: int = 0
@export var mental_state: int = 0
@export var fatigue: int = 0

# 行为钩子与资源入口。
@export var passive_id: String = ""
@export var unique_event_ids: Array[String] = []
@export var art_path: String = ""
