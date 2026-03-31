extends RefCounted
class_name SaveManager

const SAVE_DIR: String = "user://saves"
const SYSTEM_SLOT_INDEX: int = 0
const MANUAL_SLOT_COUNT: int = 24
const PAGE_SIZE: int = 6
const RUN_STATE_FIELDS: Array[String] = [
	"turn_index", "stage_index", "cao_health", "cao_mind", "money",
	"morale", "jingzhou_stability", "naval_readiness", "alliance_strength",
	"fire_progress", "active_event_ids", "active_character_states", "relation_states",
	"risk_states", "flags", "log_entries", "roster_ids", "locked_character_ids",
	"active_event_states", "resource_states", "victory_points", "settlement_snapshot",
	"settlement_report", "settlement_pages", "personal_epilogues", "game_over", "ending_id"
]

func has_system_save() -> bool:
	return FileAccess.file_exists(_slot_path(SYSTEM_SLOT_INDEX))

func has_any_save() -> bool:
	for slot_index in range(MANUAL_SLOT_COUNT + 1):
		if FileAccess.file_exists(_slot_path(slot_index)):
			return true
	return false

func save_system(run_state: RunState, board_manager: BoardManager) -> bool:
	return save_to_slot(SYSTEM_SLOT_INDEX, run_state, board_manager, TextDB.get_text("ui.save_slots.system_label", "System Save"), true)

func load_system() -> Dictionary:
	return load_from_slot(SYSTEM_SLOT_INDEX)

func save_to_slot(slot_index: int, run_state: RunState, board_manager: BoardManager, label: String = "", is_system_slot: bool = false) -> bool:
	if slot_index < 0 or slot_index > MANUAL_SLOT_COUNT:
		return false
	if run_state == null or board_manager == null:
		return false
	if not _ensure_save_dir():
		return false
	var file: FileAccess = FileAccess.open(_slot_path(slot_index), FileAccess.WRITE)
	if file == null:
		return false
	var metadata: Dictionary = _build_metadata(slot_index, run_state, label, is_system_slot)
	var snapshot: Dictionary = {
		"version": 2,
		"metadata": metadata,
		"run_state": _serialize_run_state(run_state),
		"board": board_manager.snapshot_state()
	}
	file.store_var(snapshot, true)
	return true

func load_from_slot(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index > MANUAL_SLOT_COUNT:
		return {}
	var snapshot: Dictionary = _read_snapshot(slot_index)
	if snapshot.is_empty():
		return {}
	var run_state_data: Dictionary = snapshot.get("run_state", {}) as Dictionary
	var board_data: Dictionary = snapshot.get("board", {}) as Dictionary
	if run_state_data.is_empty():
		return {}
	return {
		"metadata": (snapshot.get("metadata", {}) as Dictionary).duplicate(true),
		"run_state": _deserialize_run_state(run_state_data),
		"board": board_data.duplicate(true)
	}

func list_slots(page: int) -> Array[Dictionary]:
	var page_index: int = maxi(page, 0)
	var start_index: int = page_index * PAGE_SIZE
	var end_index: int = mini(start_index + PAGE_SIZE, MANUAL_SLOT_COUNT + 1)
	var slots: Array[Dictionary] = []
	for slot_index in range(start_index, end_index):
		var metadata: Dictionary = get_slot_metadata(slot_index)
		slots.append({
			"slot_index": slot_index,
			"is_system": slot_index == SYSTEM_SLOT_INDEX,
			"has_save": not metadata.is_empty(),
			"metadata": metadata
		})
	return slots

func get_slot_metadata(slot_index: int) -> Dictionary:
	var snapshot: Dictionary = _read_snapshot(slot_index)
	if snapshot.is_empty():
		return {}
	return (snapshot.get("metadata", {}) as Dictionary).duplicate(true)

func page_count() -> int:
	return int(ceil(float(MANUAL_SLOT_COUNT + 1) / float(PAGE_SIZE)))

func slot_display_name(slot_index: int) -> String:
	if slot_index == SYSTEM_SLOT_INDEX:
		return TextDB.get_text("ui.save_slots.system_slot", "System Slot")
	return TextDB.format_text("ui.save_slots.manual_slot", [slot_index], {}, "Slot %02d")

func _slot_path(slot_index: int) -> String:
	if slot_index == SYSTEM_SLOT_INDEX:
		return "%s/system_autosave.save" % SAVE_DIR
	return "%s/slot_%02d.save" % [SAVE_DIR, slot_index]

func _ensure_save_dir() -> bool:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return false
	if not dir.dir_exists("saves"):
		dir.make_dir_recursive("saves")
	return true

func _read_snapshot(slot_index: int) -> Dictionary:
	var path: String = _slot_path(slot_index)
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var snapshot: Variant = file.get_var(true)
	if snapshot is not Dictionary:
		return {}
	return (snapshot as Dictionary).duplicate(true)

func _build_metadata(slot_index: int, run_state: RunState, label: String, is_system_slot: bool) -> Dictionary:
	var final_label: String = label.strip_edges()
	if final_label.is_empty():
		final_label = slot_display_name(slot_index)
	var turn_index: int = int(run_state.turn_index)
	var term_name: String = GameRules.current_term_name(turn_index)
	return {
		"slot_index": slot_index,
		"label": final_label,
		"is_system": is_system_slot,
		"turn_index": turn_index,
		"term_name": term_name,
		"saved_at": Time.get_datetime_string_from_system(false, true),
		"game_over": bool(run_state.game_over)
	}

func _serialize_run_state(run_state: RunState) -> Dictionary:
	var data: Dictionary = {}
	for field in RUN_STATE_FIELDS:
		data[field] = run_state.get(field)
	return data

func _deserialize_run_state(data: Dictionary) -> RunState:
	var run_state: RunState = GameData.create_run_state()
	for field in RUN_STATE_FIELDS:
		if data.has(field):
			run_state.set(field, data[field])
	return run_state
