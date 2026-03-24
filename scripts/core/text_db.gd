extends RefCounted
class_name TextDB

const TEXT_ROOT: String = "res://data/texts"

static var _loaded: bool = false
static var _root: Dictionary = {}

static func reload_texts() -> void:
	_loaded = false
	_root.clear()
	_ensure_loaded()

static func get_value(path: String, fallback: Variant = null) -> Variant:
	_ensure_loaded()
	var current: Variant = _root
	for part in path.split("."):
		if not (current is Dictionary):
			return fallback
		var current_dict: Dictionary = current as Dictionary
		if not current_dict.has(part):
			return fallback
		current = current_dict[part]
	return current

static func get_text(path: String, fallback: String = "") -> String:
	var value: Variant = get_value(path, fallback)
	return str(value) if value != null else fallback

static func get_dict(path: String) -> Dictionary:
	var value: Variant = get_value(path, {})
	return value if value is Dictionary else {}

static func get_array(path: String) -> Array:
	var value: Variant = get_value(path, [])
	return value if value is Array else []

static func format_text(path: String, args: Array = [], named: Dictionary = {}, fallback: String = "") -> String:
	var template: String = get_text(path, fallback)
	for key_variant in named.keys():
		var key: String = str(key_variant)
		template = template.replace("{" + key + "}", str(named[key_variant]))
	if not args.is_empty():
		template = template % args
	return template

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_root.clear()
	var dir: DirAccess = DirAccess.open(TEXT_ROOT)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var file_name: String = dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir():
			continue
		if file_name.get_extension().to_lower() != "json":
			continue
		var full_path: String = "%s/%s" % [TEXT_ROOT, file_name]
		var parsed: Variant = _load_json(full_path)
		if parsed is Dictionary:
			_root[file_name.get_basename()] = parsed
	dir.list_dir_end()

static func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return {}
	var raw: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(raw)
	return parsed if parsed != null else {}
