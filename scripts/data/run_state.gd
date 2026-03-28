extends Resource
class_name RunState

# 单局运行时状态。
# managers 在回合推进中会持续修改这里的内容，因此这里存放的是“会变”的数据。
@export var turn_index: int = 1
@export var stage_index: int = 1
@export var cao_health: int = 10
@export var cao_mind: int = 10
@export var money: int = 20
@export var morale: int = 6
@export var jingzhou_stability: int = 6
@export var naval_readiness: int = 2
@export var alliance_strength: int = 4
@export var fire_progress: int = 0
@export var active_event_ids: Array[String] = []
@export var active_character_states: Dictionary = {}
@export var relation_states: Dictionary = {}
@export var risk_states: Dictionary = {}
@export var flags: Dictionary = {}
@export var log_entries: Array[String] = []
@export var roster_ids: Array[String] = []
@export var locked_character_ids: Array[String] = []
@export var active_event_states: Dictionary = {}
@export var resource_states: Dictionary = {}
@export var victory_points: int = 0
@export var settlement_snapshot: Dictionary = {}
@export var settlement_report: Array[String] = []
@export var settlement_pages: Array = []
@export var personal_epilogues: Array[String] = []
@export var game_over: bool = false
@export var ending_id: String = ""
