extends Control
class_name DicePreview

const DICE_ROLLER_CONTROL_SCRIPT := preload("res://addons/dice_roller/dice_roller_control/dice_roller_control.gd")
const DICE_DEF_SCRIPT := preload("res://addons/dice_roller/dice_def.gd")
const DICE_SHAPE_SCRIPT := preload("res://addons/dice_roller/dice_shape.gd")
const BODY_FONT_RESOURCE := preload("res://assets/fonts/ZhuqueFangsong-Regular.ttf")
const TITLE_FONT_RESOURCE := preload("res://assets/fonts/ZhuqueFangsong-Regular.ttf")
const DICE_VIEW_SIZE := Vector2(560.0, 260.0)

@onready var title_label: Label = $Center/Panel/Margin/VBox/Title
@onready var subtitle_label: Label = $Center/Panel/Margin/VBox/Subtitle
@onready var dice_holder: CenterContainer = $Center/Panel/Margin/VBox/DiceFrame/DiceHolder
@onready var die_a_label: Label = $Center/Panel/Margin/VBox/ControlFrame/ControlMargin/ControlVBox/SpinRow/DieALabel
@onready var die_b_label: Label = $Center/Panel/Margin/VBox/ControlFrame/ControlMargin/ControlVBox/SpinRow/DieBLabel
@onready var die_a_spin: SpinBox = $Center/Panel/Margin/VBox/ControlFrame/ControlMargin/ControlVBox/SpinRow/DieASpin
@onready var die_b_spin: SpinBox = $Center/Panel/Margin/VBox/ControlFrame/ControlMargin/ControlVBox/SpinRow/DieBSpin
@onready var show_button: Button = $Center/Panel/Margin/VBox/ControlFrame/ControlMargin/ControlVBox/ActionRow/ShowButton
@onready var random_button: Button = $Center/Panel/Margin/VBox/ControlFrame/ControlMargin/ControlVBox/ActionRow/RandomButton
@onready var reset_button: Button = $Center/Panel/Margin/VBox/ControlFrame/ControlMargin/ControlVBox/ActionRow/ResetButton
@onready var summary_label: Label = $Center/Panel/Margin/VBox/ControlFrame/ControlMargin/ControlVBox/Summary

var dice_control = null

func _ready() -> void:
	randomize()
	_apply_theme()
	_apply_texts()
	_build_dice_control()
	show_button.pressed.connect(_on_show_pressed)
	random_button.pressed.connect(_on_random_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	die_a_spin.value_changed.connect(_on_spin_value_changed)
	die_b_spin.value_changed.connect(_on_spin_value_changed)
	await get_tree().process_frame
	_reset_dice()

func _apply_theme() -> void:
	var scene_theme := Theme.new()
	scene_theme.default_font = BODY_FONT_RESOURCE
	scene_theme.default_font_size = 22
	theme = scene_theme
	title_label.add_theme_font_override("font", TITLE_FONT_RESOURCE)
	title_label.add_theme_font_size_override("font_size", 34)
	subtitle_label.add_theme_font_size_override("font_size", 18)
	summary_label.add_theme_font_size_override("font_size", 20)

func _apply_texts() -> void:
	title_label.text = TextDB.get_text("ui.debug_dice.title")
	subtitle_label.text = TextDB.get_text("ui.debug_dice.subtitle")
	die_a_label.text = TextDB.get_text("ui.debug_dice.die_a")
	die_b_label.text = TextDB.get_text("ui.debug_dice.die_b")
	show_button.text = TextDB.get_text("ui.debug_dice.show")
	random_button.text = TextDB.get_text("ui.debug_dice.random")
	reset_button.text = TextDB.get_text("ui.debug_dice.reset")
	_refresh_idle_summary()

func _build_dice_control() -> void:
	if is_instance_valid(dice_control):
		dice_control.queue_free()
	dice_control = DICE_ROLLER_CONTROL_SCRIPT.new()
	dice_control.name = "PreviewDiceRoller"
	dice_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dice_control.focus_mode = Control.FOCUS_NONE
	dice_control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dice_control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dice_control.custom_minimum_size = DICE_VIEW_SIZE
	var preview_dice_set: Array[Resource] = []
	preview_dice_set.append(_make_die("left", Color(0.95, 0.92, 0.84, 1.0)))
	preview_dice_set.append(_make_die("right", Color(0.95, 0.92, 0.84, 1.0)))
	dice_control.configure_runtime(preview_dice_set, Color(0.09, 0.10, 0.12, 1.0), Vector3(8.6, 8.0, 5.2), false)
	dice_holder.add_child(dice_control)
	dice_control.roll_started.connect(_on_roll_started)
	dice_control.roll_finnished.connect(_on_roll_finished)

func _make_die(die_name: String, die_color: Color):
	var die_def = DICE_DEF_SCRIPT.new()
	die_def.name = die_name
	die_def.color = die_color
	die_def.shape = DICE_SHAPE_SCRIPT.new("D6")
	return die_def

func _is_rolling() -> bool:
	if not is_instance_valid(dice_control):
		return false
	var roller = dice_control.get("roller")
	return roller != null and bool(roller.get("rolling"))

func _prepare_roller() -> bool:
	if not is_instance_valid(dice_control):
		return false
	var roller = dice_control.get("roller")
	if roller == null or bool(roller.get("rolling")):
		return false
	roller.call("prepare")
	return true

func _set_controls_locked(locked: bool) -> void:
	die_a_spin.editable = not locked
	die_b_spin.editable = not locked
	show_button.disabled = locked
	random_button.disabled = locked
	reset_button.disabled = locked

func _reset_dice() -> void:
	if not is_instance_valid(dice_control):
		return
	var roller = dice_control.get("roller")
	if roller != null and not bool(roller.get("rolling")):
		roller.call("prepare")
	_set_controls_locked(false)
	_refresh_idle_summary()

func _on_show_pressed() -> void:
	if not _prepare_roller():
		return
	_set_controls_locked(true)
	summary_label.text = TextDB.get_text("ui.debug_dice.rolling")
	await get_tree().process_frame
	var faces: Array[int] = []
	faces.append(int(die_a_spin.value))
	faces.append(int(die_b_spin.value))
	dice_control.show_faces(faces)

func _on_random_pressed() -> void:
	if not _prepare_roller():
		return
	_set_controls_locked(true)
	summary_label.text = TextDB.get_text("ui.debug_dice.random_wait")
	await get_tree().process_frame
	dice_control.quick_roll()

func _on_reset_pressed() -> void:
	if _is_rolling():
		return
	_reset_dice()

func _on_roll_started() -> void:
	_set_controls_locked(true)

func _on_roll_finished(_value: int) -> void:
	_set_controls_locked(false)
	_refresh_result_summary()

func _refresh_idle_summary() -> void:
	var die_a: int = int(die_a_spin.value)
	var die_b: int = int(die_b_spin.value)
	summary_label.text = TextDB.format_text("ui.debug_dice.idle", [die_a, die_b, die_a + die_b])

func _refresh_result_summary() -> void:
	if not is_instance_valid(dice_control):
		_refresh_idle_summary()
		return
	var result: Dictionary = dice_control.per_dice_result()
	var die_a: int = int(result.get("left", int(die_a_spin.value)))
	var die_b: int = int(result.get("right", int(die_b_spin.value)))
	summary_label.text = TextDB.format_text("ui.debug_dice.summary", [die_a, die_b, die_a + die_b])

func _on_spin_value_changed(_value: float) -> void:
	if _is_rolling():
		return
	_refresh_idle_summary()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
