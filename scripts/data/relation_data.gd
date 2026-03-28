extends Resource
class_name RelationData

# 关系模板资源。
# 这里只保存初始规则；运行中的好感、流言风险等动态值会复制到 RunState 里。
@export var character_id: String = ""
@export var relation_type: String = "minister"
@export var favor_thresholds: Dictionary = {}
@export var rumor_risk: int = 0
@export var jealousy_targets: Array[String] = []
@export var special_event_ids: Array[String] = []
