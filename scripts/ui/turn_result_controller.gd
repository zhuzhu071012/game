extends Node
class_name TurnResultController

const UI_PALETTE := preload("res://scripts/ui/ui_palette.gd")
const CARD_METRICS := preload("res://scripts/ui/card_metrics.gd")

signal continue_requested

const DICE_ROLLER_CONTROL_SCRIPT := preload("res://addons/dice_roller/dice_roller_control/dice_roller_control.gd")
const DICE_DEF_SCRIPT := preload("res://addons/dice_roller/dice_def.gd")
const DICE_SHAPE_SCRIPT := preload("res://addons/dice_roller/dice_shape.gd")
const TURN_RESULT_CARD_WIDTH := CARD_METRICS.COMPACT_CARD_WIDTH
const TURN_RESULT_CARD_HEIGHT := CARD_METRICS.COMPACT_CARD_HEIGHT
const TURN_RESULT_CARD_ART_HEIGHT := CARD_METRICS.COMPACT_CARD_ART_HEIGHT
const TURN_RESULT_DICE_VIEW_SIZE := Vector2(300.0, 120.0)
const TURN_RESULT_PANEL_DESIRED_SIZE := CARD_METRICS.TURN_RESULT_PANEL_SIZE
const TURN_RESULT_PANEL_MARGIN := Vector2(96.0, 44.0)
const TURN_RESULT_DICE_PANEL_HEIGHT := 172.0
const TURN_RESULT_DICE_SUMMARY_HEIGHT := 96.0
const TURN_RESULT_BODY_MIN_HEIGHT := 168.0

var main
var result_dice_control = null

func setup(main_node) -> void:
	main = main_node

func build_if_needed() -> void:
	if main.turn_result_overlay != null:
		return
	main.turn_result_overlay = Control.new()
	main.turn_result_overlay.name = "TurnResultOverlay"
	main.turn_result_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.turn_result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	main.turn_result_overlay.z_as_relative = false
	main.turn_result_overlay.z_index = 1010
	main.turn_result_overlay.visible = false
	main.add_child(main.turn_result_overlay)
	var shade: ColorRect = ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = UI_PALETTE.alpha(UI_PALETTE.INK, 0.76)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.turn_result_overlay.add_child(shade)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.turn_result_overlay.add_child(center)
	main.turn_result_animation_layer = Control.new()
	main.turn_result_animation_layer.name = "TurnResultAnimationLayer"
	main.turn_result_animation_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.turn_result_animation_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.turn_result_overlay.add_child(main.turn_result_animation_layer)
	main.turn_result_panel = PanelContainer.new()
	main.turn_result_panel.custom_minimum_size = TURN_RESULT_PANEL_DESIRED_SIZE
	main.turn_result_panel.size = TURN_RESULT_PANEL_DESIRED_SIZE
	main.turn_result_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main.turn_result_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.INK, 0.985)
	panel_style.border_color = UI_PALETTE.alpha(UI_PALETTE.SLATE.lightened(0.12), 0.96)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	panel_style.shadow_size = 12
	main.turn_result_panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(main.turn_result_panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	main.turn_result_panel.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_BEGIN
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	box.add_child(header)
	var title_box: VBoxContainer = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 4)
	header.add_child(title_box)
	main.turn_result_title = Label.new()
	main.turn_result_title.add_theme_font_size_override("font_size", 30)
	title_box.add_child(main.turn_result_title)
	main.turn_result_subtitle = Label.new()
	main.turn_result_subtitle.modulate = UI_PALETTE.alpha(UI_PALETTE.PAPER, 0.82)
	main.turn_result_subtitle.add_theme_font_size_override("font_size", 15)
	title_box.add_child(main.turn_result_subtitle)
	main.turn_result_dice_panel = PanelContainer.new()
	main.turn_result_dice_panel.visible = false
	main.turn_result_dice_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.turn_result_dice_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	main.turn_result_dice_panel.custom_minimum_size = Vector2(0.0, TURN_RESULT_DICE_PANEL_HEIGHT)
	var dice_panel_style: StyleBoxFlat = StyleBoxFlat.new()
	dice_panel_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.SLATE.darkened(0.16), 0.96)
	dice_panel_style.border_color = UI_PALETTE.alpha(UI_PALETTE.SLATE, 0.94)
	dice_panel_style.border_width_left = 1
	dice_panel_style.border_width_top = 1
	dice_panel_style.border_width_right = 1
	dice_panel_style.border_width_bottom = 1
	dice_panel_style.corner_radius_top_left = 10
	dice_panel_style.corner_radius_top_right = 10
	dice_panel_style.corner_radius_bottom_left = 10
	dice_panel_style.corner_radius_bottom_right = 10
	main.turn_result_dice_panel.add_theme_stylebox_override("panel", dice_panel_style)
	box.add_child(main.turn_result_dice_panel)
	var dice_margin := MarginContainer.new()
	dice_margin.add_theme_constant_override("margin_left", 10)
	dice_margin.add_theme_constant_override("margin_top", 8)
	dice_margin.add_theme_constant_override("margin_right", 10)
	dice_margin.add_theme_constant_override("margin_bottom", 8)
	main.turn_result_dice_panel.add_child(dice_margin)
	var dice_box := VBoxContainer.new()
	dice_box.add_theme_constant_override("separation", 6)
	dice_margin.add_child(dice_box)
	main.turn_result_dice_title = Label.new()
	main.turn_result_dice_title.add_theme_font_size_override("font_size", 16)
	dice_box.add_child(main.turn_result_dice_title)
	var dice_content_row := HBoxContainer.new()
	dice_content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dice_content_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	dice_content_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	dice_content_row.add_theme_constant_override("separation", 14)
	dice_box.add_child(dice_content_row)
	main.turn_result_dice_row = HBoxContainer.new()
	main.turn_result_dice_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	main.turn_result_dice_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	main.turn_result_dice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	main.turn_result_dice_row.add_theme_constant_override("separation", 10)
	main.turn_result_dice_row.custom_minimum_size = TURN_RESULT_DICE_VIEW_SIZE
	dice_content_row.add_child(main.turn_result_dice_row)
	main.turn_result_die_labels.clear()
	_ensure_result_dice_control()
	main.turn_result_dice_summary = Label.new()
	main.turn_result_dice_summary.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.turn_result_dice_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	main.turn_result_dice_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main.turn_result_dice_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main.turn_result_dice_summary.clip_text = true
	main.turn_result_dice_summary.modulate = UI_PALETTE.alpha(UI_PALETTE.PAPER, 0.90)
	main.turn_result_dice_summary.add_theme_font_size_override("font_size", 14)
	main.turn_result_dice_summary.custom_minimum_size = Vector2(0.0, TURN_RESULT_DICE_SUMMARY_HEIGHT)
	var dice_summary_holder := Control.new()
	dice_summary_holder.clip_contents = true
	dice_summary_holder.custom_minimum_size = Vector2(260.0, TURN_RESULT_DICE_SUMMARY_HEIGHT)
	dice_summary_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dice_summary_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dice_summary_holder.add_child(main.turn_result_dice_summary)
	dice_content_row.add_child(dice_summary_holder)
	var body_panel: PanelContainer = PanelContainer.new()
	body_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_panel.custom_minimum_size = Vector2(0.0, TURN_RESULT_BODY_MIN_HEIGHT + 22.0)
	var body_style: StyleBoxFlat = StyleBoxFlat.new()
	body_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.SLATE.darkened(0.22), 0.94)
	body_style.border_color = UI_PALETTE.alpha(UI_PALETTE.SLATE, 0.95)
	body_style.border_width_left = 1
	body_style.border_width_top = 1
	body_style.border_width_right = 1
	body_style.border_width_bottom = 1
	body_style.corner_radius_top_left = 10
	body_style.corner_radius_top_right = 10
	body_style.corner_radius_bottom_left = 10
	body_style.corner_radius_bottom_right = 10
	body_panel.add_theme_stylebox_override("panel", body_style)
	box.add_child(body_panel)
	var body_margin: MarginContainer = MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 14)
	body_margin.add_theme_constant_override("margin_top", 12)
	body_margin.add_theme_constant_override("margin_right", 14)
	body_margin.add_theme_constant_override("margin_bottom", 12)
	body_panel.add_child(body_margin)
	main.turn_result_body = RichTextLabel.new()
	main.turn_result_body.bbcode_enabled = true
	main.turn_result_body.fit_content = false
	main.turn_result_body.scroll_active = true
	main.turn_result_body.custom_minimum_size = Vector2(0.0, TURN_RESULT_BODY_MIN_HEIGHT)
	main.turn_result_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.turn_result_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.turn_result_body.mouse_filter = Control.MOUSE_FILTER_STOP
	body_margin.add_child(main.turn_result_body)
	main.turn_result_reward_title = Label.new()
	main.turn_result_reward_title.add_theme_font_size_override("font_size", 18)
	box.add_child(main.turn_result_reward_title)
	main.turn_result_card_scroll = ScrollContainer.new()
	main.turn_result_card_scroll.custom_minimum_size = Vector2(0.0, TURN_RESULT_CARD_HEIGHT + 14.0)
	main.turn_result_card_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.turn_result_card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	main.turn_result_card_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(main.turn_result_card_scroll)
	main.turn_result_card_row = HBoxContainer.new()
	main.turn_result_card_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	main.turn_result_card_row.add_theme_constant_override("separation", 12)
	main.turn_result_card_scroll.add_child(main.turn_result_card_row)
	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	box.add_child(actions)
	main.turn_result_collect_button = Button.new()
	main.turn_result_collect_button.custom_minimum_size = Vector2(130.0, 42.0)
	main.turn_result_collect_button.pressed.connect(on_collect_pressed)
	actions.add_child(main.turn_result_collect_button)
	main._apply_accent_button_theme(main.turn_result_collect_button)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	main.turn_result_continue_button = Button.new()
	main.turn_result_continue_button.custom_minimum_size = Vector2(110.0, 42.0)
	main.turn_result_continue_button.pressed.connect(on_continue_pressed)
	actions.add_child(main.turn_result_continue_button)
	main._apply_accent_button_theme(main.turn_result_continue_button)
	main._apply_global_text_adjustments(main.turn_result_overlay)
	_apply_result_panel_size()

func _apply_result_panel_size() -> void:
	if main == null or main.turn_result_panel == null:
		return
	var viewport_size: Vector2 = main.get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return
	var panel_size := Vector2(
		minf(TURN_RESULT_PANEL_DESIRED_SIZE.x, maxf(840.0, viewport_size.x - TURN_RESULT_PANEL_MARGIN.x)),
		minf(TURN_RESULT_PANEL_DESIRED_SIZE.y, maxf(620.0, viewport_size.y - TURN_RESULT_PANEL_MARGIN.y))
	)
	main.turn_result_panel.custom_minimum_size = panel_size
	main.turn_result_panel.size = panel_size

func _make_result_die(die_name: String, die_color: Color):
	var die_def = DICE_DEF_SCRIPT.new()
	die_def.name = die_name
	die_def.color = die_color
	die_def.shape = DICE_SHAPE_SCRIPT.new("D6")
	return die_def

func _ensure_result_dice_control() -> void:
	if main == null or main.turn_result_dice_row == null:
		return
	if is_instance_valid(result_dice_control):
		if result_dice_control.get_parent() != main.turn_result_dice_row:
			result_dice_control.reparent(main.turn_result_dice_row)
		return
	result_dice_control = DICE_ROLLER_CONTROL_SCRIPT.new()
	if result_dice_control == null:
		return
	result_dice_control.name = "TurnResultDiceRoller"
	result_dice_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_dice_control.focus_mode = Control.FOCUS_NONE
	result_dice_control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	result_dice_control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	result_dice_control.custom_minimum_size = TURN_RESULT_DICE_VIEW_SIZE
	var preview_dice_set: Array[Resource] = []
	preview_dice_set.append(_make_result_die("left", UI_PALETTE.alpha(UI_PALETTE.PAPER, 1.0)))
	preview_dice_set.append(_make_result_die("right", UI_PALETTE.alpha(UI_PALETTE.PAPER, 1.0)))
	result_dice_control.configure_runtime(preview_dice_set, UI_PALETTE.alpha(UI_PALETTE.INK, 0.0), Vector3(8.0, 7.2, 4.6), false)
	main.turn_result_dice_row.add_child(result_dice_control)

func _apply_dice_summary(dice_data: Dictionary) -> void:
	if main.turn_result_dice_summary == null:
		return
	var die_a: int = int(dice_data.get("die_a", 1))
	var die_b: int = int(dice_data.get("die_b", 1))
	var modifier: float = float(dice_data.get("modifier", 0.0))
	var roll_total: int = int(dice_data.get("roll", die_a + die_b))
	var final_score: float = float(dice_data.get("final_score", float(roll_total) + modifier))
	var dc: float = float(dice_data.get("dc", 0.0))
	var lines: Array[String] = []
	if dc > 0.0:
		lines.append(TextDB.format_text("ui.turn_results.roll_summary", [
			_format_score_value(die_a),
			_format_score_value(die_b),
			_format_score_value(roll_total),
			_format_signed_score_value(modifier),
			_format_score_value(final_score),
			_format_score_value(dc)
		]))
	else:
		lines.append(TextDB.format_text("ui.turn_results.roll_summary_no_dc", [
			_format_score_value(die_a),
			_format_score_value(die_b),
			_format_score_value(roll_total),
			_format_signed_score_value(modifier),
			_format_score_value(final_score)
		]))
	_append_requirement_line(lines, dc, modifier, str(dice_data.get("pass_label", TextDB.get_text("ui.turn_results.pass_labels.success", "success"))))
	var secondary_dc: float = float(dice_data.get("secondary_dc", 0.0))
	if secondary_dc > 0.0:
		_append_requirement_line(lines, secondary_dc, modifier, str(dice_data.get("secondary_pass_label", TextDB.get_text("ui.turn_results.pass_labels.success", "success"))), true)
	main.turn_result_dice_summary.text = "\n".join(lines)

func _format_score_value(value_variant) -> String:
	var value: float = float(value_variant)
	var rounded_value: float = round(value)
	if absf(value - rounded_value) < 0.001:
		return str(int(rounded_value))
	return "%.1f" % value

func _format_signed_score_value(value_variant) -> String:
	var value: float = float(value_variant)
	var rounded_value: float = round(value)
	if absf(value - rounded_value) < 0.001:
		return "%+d" % int(rounded_value)
	return "%+.1f" % value

func _append_requirement_line(lines: Array[String], dc: float, modifier: float, pass_label: String, secondary: bool = false) -> void:
	if dc <= 0.0:
		return
	var label: String = pass_label.strip_edges()
	if label.is_empty():
		label = TextDB.get_text("ui.turn_results.pass_labels.success", "success")
	var required_roll: int = int(ceil(dc - modifier))
	if required_roll > 12:
		lines.append(TextDB.format_text("ui.turn_results.roll_impossible", [label]))
		return
	var clamped_required: int = maxi(2, required_roll)
	var key: String = "ui.turn_results.roll_requirement_secondary" if secondary else "ui.turn_results.roll_requirement"
	lines.append(TextDB.format_text(key, [_format_score_value(clamped_required), label]))
func make_reward_payload(reward: Dictionary) -> Dictionary:
	var card_type: String = str(reward.get("card_type", ""))
	var card_id: String = str(reward.get("id", ""))
	var amount: int = maxi(1, int(reward.get("amount", 1)))
	match card_type:
		"character":
			if not main.characters.has(card_id):
				return {}
			var character: CharacterData = main.characters[card_id] as CharacterData
			var role_name: String = main._role_type_text(character.role_type)
			var subtitle: String = role_name
			if main.run_state != null and main.run_state.relation_states.has(card_id):
				subtitle = "%s / %s" % [role_name, main.relation_manager.describe_relation(main.run_state, card_id)]
			return {
				"uid": "result:character:%s" % card_id,
				"id": card_id,
				"card_type": "character",
				"title": character.display_name,
				"subtitle": subtitle,
				"body": main._character_body(card_id, false),
				"tags": character.tags,
				"locked": true,
				"image_path": character.art_path,
				"image_label": character.display_name,
				"art_bg_color": Color(0.20, 0.20, 0.22),
				"color": Color(0.12, 0.12, 0.13),
				"compact_details": true,
				"show_subtitle_in_compact": false,
				"show_assigned_in_compact": false,
				"embedded": true,
				"card_width": TURN_RESULT_CARD_WIDTH,
				"art_height": TURN_RESULT_CARD_ART_HEIGHT,
				"collapsed_height": TURN_RESULT_CARD_HEIGHT,
				"expanded_height": TURN_RESULT_CARD_HEIGHT,
				"stack_count": amount
			}
		"resource":
			if not main.resources.has(card_id):
				return {}
			var resource: ResourceCardData = main.resources[card_id] as ResourceCardData
			return {
				"uid": "result:resource:%s" % card_id,
				"id": card_id,
				"card_type": "resource",
				"title": resource.display_name,
				"subtitle": main._resource_category_text(resource.category),
				"body": resource.description,
				"tags": resource.tags,
				"locked": true,
				"image_path": resource.art_path,
				"image_label": resource.display_name,
				"art_bg_color": Color(0.18, 0.18, 0.19),
				"color": Color(0.11, 0.11, 0.12),
				"compact_details": true,
				"show_subtitle_in_compact": false,
				"show_assigned_in_compact": false,
				"embedded": true,
				"card_width": TURN_RESULT_CARD_WIDTH,
				"art_height": TURN_RESULT_CARD_ART_HEIGHT,
				"collapsed_height": TURN_RESULT_CARD_HEIGHT,
				"expanded_height": TURN_RESULT_CARD_HEIGHT,
				"stack_count": amount
			}
	return {}

func make_card_front(reward: Dictionary) -> Control:
	var payload: Dictionary = make_reward_payload(reward)
	if payload.is_empty():
		return null
	var card_size := Vector2(TURN_RESULT_CARD_WIDTH, TURN_RESULT_CARD_HEIGHT)
	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = card_size
	panel.size = card_size
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = payload.get("color", Color(0.12, 0.12, 0.13)) as Color
	panel_style.border_color = Color(0.50, 0.50, 0.52, 0.96)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.20)
	panel_style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", panel_style)
	var margin: MarginContainer = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 3)
	margin.add_child(box)
	var art_frame: PanelContainer = PanelContainer.new()
	art_frame.custom_minimum_size = Vector2(0.0, TURN_RESULT_CARD_ART_HEIGHT)
	art_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art_style: StyleBoxFlat = StyleBoxFlat.new()
	art_style.bg_color = (payload.get("art_bg_color", payload.get("color", Color(0.23, 0.19, 0.14))) as Color).darkened(0.12)
	art_style.corner_radius_top_left = 8
	art_style.corner_radius_top_right = 8
	art_style.corner_radius_bottom_left = 8
	art_style.corner_radius_bottom_right = 8
	art_style.border_width_left = 2
	art_style.border_width_top = 2
	art_style.border_width_right = 2
	art_style.border_width_bottom = 2
	art_style.border_color = Color(0.54, 0.54, 0.56, 0.88)
	art_style.shadow_color = Color(0.0, 0.0, 0.0, 0.20)
	art_style.shadow_size = 4
	art_frame.add_theme_stylebox_override("panel", art_style)
	box.add_child(art_frame)
	var art_margin: MarginContainer = MarginContainer.new()
	art_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_margin.add_theme_constant_override("margin_left", 1)
	art_margin.add_theme_constant_override("margin_top", 1)
	art_margin.add_theme_constant_override("margin_right", 1)
	art_margin.add_theme_constant_override("margin_bottom", 1)
	art_frame.add_child(art_margin)
	var art_content: Control = Control.new()
	art_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_margin.add_child(art_content)
	var art_texture: TextureRect = TextureRect.new()
	art_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	art_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var image_path: String = str(payload.get("image_path", ""))
	if not image_path.is_empty() and ResourceLoader.exists(image_path):
		art_texture.texture = load(image_path) as Texture2D
	art_content.add_child(art_texture)
	if art_texture.texture == null:
		var art_label: Label = Label.new()
		art_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		art_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		art_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		art_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		art_label.text = str(payload.get("image_label", payload.get("title", TextDB.get_text("ui.fallback.card"))))
		art_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_content.add_child(art_label)
	var title: Label = Label.new()
	title.text = str(payload.get("title", TextDB.get_text("ui.fallback.card")))
	title.custom_minimum_size = Vector2(0.0, 24.0)
	title.clip_text = true
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 13)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)
	var amount: int = maxi(1, int(payload.get("stack_count", 1)))
	if amount > 1:
		var badge: PanelContainer = PanelContainer.new()
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.anchor_left = 1.0
		badge.anchor_top = 0.0
		badge.anchor_right = 1.0
		badge.anchor_bottom = 0.0
		badge.offset_left = -38.0
		badge.offset_top = 6.0
		badge.offset_right = -6.0
		badge.offset_bottom = 30.0
		var badge_style: StyleBoxFlat = StyleBoxFlat.new()
		badge_style.bg_color = Color(0.10, 0.10, 0.11, 0.94)
		badge_style.border_width_left = 1
		badge_style.border_width_top = 1
		badge_style.border_width_right = 1
		badge_style.border_width_bottom = 1
		badge_style.border_color = Color(0.70, 0.70, 0.72, 0.92)
		badge_style.corner_radius_top_left = 10
		badge_style.corner_radius_top_right = 10
		badge_style.corner_radius_bottom_left = 10
		badge_style.corner_radius_bottom_right = 10
		badge.add_theme_stylebox_override("panel", badge_style)
		var badge_label: Label = Label.new()
		badge_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		badge_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_label.text = str(amount) if amount < 100 else "99+"
		badge_label.add_theme_font_size_override("font_size", 11)
		badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(badge_label)
		art_content.add_child(badge)
	return panel
func make_card_back(reward: Dictionary) -> PanelContainer:
	var amount: int = maxi(1, int(reward.get("amount", 1)))
	var back: PanelContainer = PanelContainer.new()
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.10, 0.11, 0.96)
	style.border_color = Color(0.66, 0.66, 0.68, 0.92)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 8
	back.add_theme_stylebox_override("panel", style)
	var margin: MarginContainer = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	back.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var title: Label = Label.new()
	title.text = TextDB.get_text("ui.turn_results.card_back")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", 18)
	box.add_child(title)
	var hint: Label = Label.new()
	hint.text = TextDB.get_text("ui.turn_results.card_hint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(1.0, 1.0, 1.0, 0.72)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_size_override("font_size", 12)
	box.add_child(hint)
	if amount > 1:
		var badge: Label = Label.new()
		badge.text = "x%d" % amount
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		badge.anchor_left = 1.0
		badge.anchor_top = 0.0
		badge.anchor_right = 1.0
		badge.anchor_bottom = 0.0
		badge.offset_left = -46.0
		badge.offset_top = 8.0
		badge.offset_right = -12.0
		badge.offset_bottom = 26.0
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		back.add_child(badge)
	return back

func all_cards_collected() -> bool:
	for entry_variant in main.turn_result_card_entries:
		var entry: Dictionary = entry_variant as Dictionary
		if not bool(entry.get("collected", false)):
			return false
	return true

func clear_cards() -> void:
	main.turn_result_card_entries.clear()
	main.turn_result_collecting = false
	if main.turn_result_animation_layer != null:
		for child in main.turn_result_animation_layer.get_children():
			child.queue_free()
	if main.turn_result_card_row == null:
		return
	for child in main.turn_result_card_row.get_children():
		child.queue_free()

func render_cards(rewards: Array) -> void:
	clear_cards()
	for reward_variant in rewards:
		if reward_variant is not Dictionary:
			continue
		var reward: Dictionary = (reward_variant as Dictionary).duplicate(true)
		var card_size := Vector2(TURN_RESULT_CARD_WIDTH, TURN_RESULT_CARD_HEIGHT)
		var button: Control = Control.new()
		button.custom_minimum_size = card_size
		button.size = card_size
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.gui_input.connect(handle_input.bind(button))
		main.turn_result_card_row.add_child(button)
		var front_card: Control = make_card_front(reward)
		if front_card != null:
			front_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			front_card.visible = false
			front_card.position = Vector2.ZERO
			front_card.anchor_left = 0.0
			front_card.anchor_top = 0.0
			front_card.anchor_right = 0.0
			front_card.anchor_bottom = 0.0
			front_card.offset_left = 0.0
			front_card.offset_top = 0.0
			front_card.offset_right = card_size.x
			front_card.offset_bottom = card_size.y
			front_card.custom_minimum_size = card_size
			front_card.size = card_size
			front_card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			front_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			button.add_child(front_card)
		var back_card: PanelContainer = make_card_back(reward)
		back_card.position = Vector2.ZERO
		back_card.anchor_left = 0.0
		back_card.anchor_top = 0.0
		back_card.anchor_right = 0.0
		back_card.anchor_bottom = 0.0
		back_card.offset_left = 0.0
		back_card.offset_top = 0.0
		back_card.offset_right = card_size.x
		back_card.offset_bottom = card_size.y
		back_card.custom_minimum_size = card_size
		back_card.size = card_size
		back_card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		back_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		button.add_child(back_card)
		main.turn_result_card_entries.append({
			"button": button,
			"holder": button,
			"front": front_card,
			"back": back_card,
			"reward": reward,
			"revealed": false,
			"collected": false
		})
	refresh_collect_button()

func find_card_index(button: Control) -> int:
	for index in range(main.turn_result_card_entries.size()):
		var entry: Dictionary = main.turn_result_card_entries[index] as Dictionary
		if entry.get("button", null) == button:
			return index
	return -1

func set_card_revealed(index: int, animated: bool = true, play_sound: bool = true) -> void:
	if index < 0 or index >= main.turn_result_card_entries.size():
		return
	var entry: Dictionary = main.turn_result_card_entries[index] as Dictionary
	if bool(entry.get("revealed", false)):
		return
	entry["revealed"] = true
	main.turn_result_card_entries[index] = entry
	var button: Control = entry.get("button", null) as Control
	var holder: Control = entry.get("holder", button) as Control
	var front_card: Control = entry.get("front", null) as Control
	var back_card: PanelContainer = entry.get("back", null) as PanelContainer
	if holder == null or front_card == null or back_card == null:
		refresh_collect_button()
		return
	var holder_size: Vector2 = holder.size if holder.size != Vector2.ZERO else holder.custom_minimum_size
	holder.pivot_offset = holder_size * 0.5
	holder.scale = Vector2.ONE
	if not animated:
		back_card.visible = false
		front_card.visible = true
		if play_sound:
			main._play_ui_sound("card_flip")
		refresh_collect_button()
		return
	var tween: Tween = create_tween()
	tween.tween_property(holder, "scale:x", 0.08, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(_swap_card_faces.bind(index))
	if play_sound:
		tween.tween_callback(main._play_ui_sound.bind("card_flip"))
	tween.tween_property(holder, "scale:x", 1.05, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "scale:x", 1.0, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _swap_card_faces(index: int) -> void:
	if index < 0 or index >= main.turn_result_card_entries.size():
		return
	var entry: Dictionary = main.turn_result_card_entries[index] as Dictionary
	var front_card: Control = entry.get("front", null) as Control
	var back_card: PanelContainer = entry.get("back", null) as PanelContainer
	if front_card != null:
		front_card.visible = true
	if back_card != null:
		back_card.visible = false
	refresh_collect_button()

func collect_all_cards(animated: bool = false) -> bool:
	var had_hidden: bool = false
	for index in range(main.turn_result_card_entries.size()):
		var entry: Dictionary = main.turn_result_card_entries[index] as Dictionary
		if not bool(entry.get("revealed", false)):
			had_hidden = true
		set_card_revealed(index, animated, false)
	refresh_collect_button()
	return had_hidden
func target_rect_for_reward(reward: Dictionary) -> Rect2:
	var card_type: String = str(reward.get("card_type", ""))
	var card_id: String = str(reward.get("id", ""))
	var row: Control = main.resource_row if card_type == "resource" else main.roster_row
	if row != null:
		for child in row.get_children():
			var card: CardView = child as CardView
			if card == null or not card.visible:
				continue
			if str(card.card_payload.get("card_type", "")) == card_type and str(card.card_payload.get("id", "")) == card_id:
				return card.get_global_rect()
	var fallback: Control = main.resource_scroll if card_type == "resource" else main.roster_scroll
	if fallback != null and fallback.visible:
		return fallback.get_global_rect()
	if main.hands_panel != null and main.hands_panel.visible:
		return main.hands_panel.get_global_rect()
	return Rect2(main.get_viewport_rect().size * 0.5 - Vector2(TURN_RESULT_CARD_WIDTH, TURN_RESULT_CARD_HEIGHT) * 0.5, Vector2(TURN_RESULT_CARD_WIDTH, TURN_RESULT_CARD_HEIGHT))

func collect_cards_to_targets(play_sound: bool = true) -> void:
	if main.turn_result_collecting or all_cards_collected():
		refresh_collect_button()
		return
	main.turn_result_collecting = true
	collect_all_cards(false)
	refresh_collect_button()
	if play_sound:
		main._play_ui_sound("collect_all")
	var source_rects: Array[Rect2] = []
	for entry_variant in main.turn_result_card_entries:
		var entry: Dictionary = entry_variant as Dictionary
		var front_card: Control = entry.get("front", null) as Control
		var button: Control = entry.get("button", null) as Control
		var source_rect: Rect2 = front_card.get_global_rect() if front_card != null and front_card.visible else (button.get_global_rect() if button != null else Rect2())
		source_rects.append(source_rect)
	var longest: float = 0.0
	for index in range(main.turn_result_card_entries.size()):
		var entry: Dictionary = main.turn_result_card_entries[index] as Dictionary
		if bool(entry.get("collected", false)):
			continue
		var reward: Dictionary = entry.get("reward", {}) as Dictionary
		var button: Control = entry.get("button", null) as Control
		var source_rect: Rect2 = source_rects[index] if index < source_rects.size() else Rect2()
		var flyer: Control = make_card_front(reward)
		if flyer != null:
			flyer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			flyer.top_level = true
			flyer.z_as_relative = false
			flyer.z_index = 2600 + index
			flyer.custom_minimum_size = source_rect.size
			flyer.size = source_rect.size
			flyer.position = source_rect.position
			flyer.pivot_offset = source_rect.size * 0.5
			if main.turn_result_animation_layer != null:
				main.turn_result_animation_layer.add_child(flyer)
			else:
				main.turn_result_overlay.add_child(flyer)
			var target_rect: Rect2 = target_rect_for_reward(reward)
			var target_position: Vector2 = target_rect.position + (target_rect.size - source_rect.size) * 0.5
			var delay: float = float(index) * 0.05
			var duration: float = 0.34
			longest = maxf(longest, delay + duration)
			var tween: Tween = create_tween()
			if delay > 0.0:
				tween.tween_interval(delay)
			tween.tween_property(flyer, "position", target_position, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tween.parallel().tween_property(flyer, "scale", Vector2(0.76, 0.76), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(flyer, "modulate:a", 0.12, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		entry["collected"] = true
		main.turn_result_card_entries[index] = entry
		if button != null:
			button.modulate = Color(1.0, 1.0, 1.0, 0.0)
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	refresh_collect_button()
	if longest > 0.0:
		await get_tree().create_timer(longest + 0.04).timeout
	if main.turn_result_animation_layer != null:
		for child in main.turn_result_animation_layer.get_children():
			child.queue_free()
	main.turn_result_collecting = false
	refresh_collect_button()

func refresh_collect_button() -> void:
	if main.turn_result_collect_button == null:
		return
	main.turn_result_collect_button.text = TextDB.get_text("ui.turn_results.collect_all")
	var has_collectable: bool = false
	for entry_variant in main.turn_result_card_entries:
		var entry: Dictionary = entry_variant as Dictionary
		if not bool(entry.get("collected", false)):
			has_collectable = true
			break
	main.turn_result_collect_button.disabled = main.turn_result_collecting or not has_collectable
	if main.turn_result_continue_button != null:
		main.turn_result_continue_button.disabled = main.turn_result_collecting

func show_current_result() -> void:
	if not main.turn_result_active or main.turn_result_index < 0 or main.turn_result_index >= main.turn_result_queue.size():
		finish_sequence()
		return
	if main.turn_result_overlay == null:
		build_if_needed()
	main.turn_result_collecting = false
	var entry: Dictionary = main.turn_result_queue[main.turn_result_index] as Dictionary
	var rewards: Array = entry.get("rewards", []) as Array
	_apply_result_panel_size()
	main.turn_result_title.text = str(entry.get("title", TextDB.get_text("ui.fallback.card")))
	main.turn_result_subtitle.text = TextDB.format_text("ui.turn_results.page", [main.turn_result_index + 1, main.turn_result_queue.size()])
	_show_dice_result((entry.get("dice", {}) as Dictionary).duplicate(true))
	var body_text: String = str(entry.get("body", "")).strip_edges()
	if body_text.is_empty():
		body_text = TextDB.format_text("ui.turn_results.default_body", [main.turn_result_title.text])
	main.turn_result_body.text = body_text
	main.turn_result_body.scroll_to_line(0)
	main._set_rich_text_layout(main.turn_result_body, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP)
	main.turn_result_reward_title.text = TextDB.get_text("ui.turn_results.reward_header")
	main.turn_result_reward_title.visible = not rewards.is_empty()
	if main.turn_result_card_scroll != null:
		main.turn_result_card_scroll.visible = not rewards.is_empty()
	if main.turn_result_collect_button != null:
		main.turn_result_collect_button.visible = not rewards.is_empty()
	render_cards(rewards)
	main.turn_result_continue_button.text = TextDB.get_text("ui.buttons.next")
	main.turn_result_overlay.visible = true
	main.turn_result_continue_button.grab_focus()

func _show_dice_result(dice_data: Dictionary) -> void:
	main.turn_result_dice_token += 1
	var token: int = main.turn_result_dice_token
	if main.turn_result_dice_panel == null:
		return
	if dice_data.is_empty():
		main.turn_result_dice_panel.visible = false
		return
	main.turn_result_dice_panel.visible = true
	if main.turn_result_dice_title != null:
		main.turn_result_dice_title.text = TextDB.get_text("ui.turn_results.roll_header")
	if main.turn_result_dice_summary != null:
		main.turn_result_dice_summary.text = TextDB.get_text("ui.turn_results.roll_wait")
	_ensure_result_dice_control()
	await get_tree().process_frame
	if token != main.turn_result_dice_token:
		return
	await _animate_dice_result(token, dice_data)

func _animate_dice_result(token: int, dice_data: Dictionary) -> void:
	var die_a: int = int(dice_data.get("die_a", 1))
	var die_b: int = int(dice_data.get("die_b", 1))
	if not is_instance_valid(result_dice_control):
		_apply_dice_summary(dice_data)
		return
	if token != main.turn_result_dice_token:
		return
	var roller = result_dice_control.get("roller")
	if roller != null and bool(roller.get("rolling")):
		await result_dice_control.roll_finnished
		if token != main.turn_result_dice_token:
			return
		roller = result_dice_control.get("roller")
	if roller != null:
		roller.call("prepare")
	await get_tree().process_frame
	if token != main.turn_result_dice_token:
		return
	var faces: Array[int] = []
	faces.append(die_a)
	faces.append(die_b)
	result_dice_control.show_faces(faces)
	await result_dice_control.roll_finnished
	if token != main.turn_result_dice_token:
		return
	_apply_dice_summary(dice_data)

func start_sequence(results: Array, report_payload: Dictionary) -> bool:
	if results.is_empty():
		return false
	if main.turn_result_overlay == null:
		build_if_needed()
	main.pending_turn_result_report_payload = report_payload.duplicate(true)
	main.turn_result_queue = results.duplicate(true)
	main.turn_result_index = 0
	main.turn_result_active = true
	main.turn_result_collecting = false
	main.detail_overlay.visible = false
	main._configure_popup_for_detail()
	main._play_ui_sound("panel_open")
	show_current_result()
	return true

func finish_sequence() -> void:
	main.turn_result_active = false
	main.turn_result_collecting = false
	main.turn_result_dice_token += 1
	main.turn_result_index = -1
	main.turn_result_queue.clear()
	clear_cards()
	if main.turn_result_overlay != null:
		main.turn_result_overlay.visible = false
	var payload: Dictionary = main.pending_turn_result_report_payload.duplicate(true)
	main.pending_turn_result_report_payload.clear()
	if payload.is_empty():
		return
	if main._start_story_event_sequence(payload):
		return
	if bool(payload.get("show_report", false)):
		if main._try_show_tutorial_pre_report_dialog(
			int(payload.get("turn_index", main.run_state.turn_index)),
			payload.get("logs", []) as Array[String],
			str(payload.get("title", "")),
			str(payload.get("subtitle", "")),
			str(payload.get("body", ""))
		):
			return
		main._show_turn_report_dialog(
			int(payload.get("turn_index", main.run_state.turn_index)),
			payload.get("logs", []) as Array[String],
			str(payload.get("title", "")),
			str(payload.get("subtitle", "")),
			str(payload.get("body", ""))
		)
	elif main.defer_settlement_popup and main.run_state != null and main.run_state.game_over:
		main.defer_settlement_popup = false
		main.settlement_page_index = -1
		main._refresh_settlement_sequence()

func is_active() -> bool:
	return main.turn_result_active

func handle_input(event: InputEvent, button: Control) -> void:
	if not main.turn_result_active or main.turn_result_collecting:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			var index: int = find_card_index(button)
			if index >= 0:
				var entry: Dictionary = main.turn_result_card_entries[index] as Dictionary
				if bool(entry.get("collected", false)):
					return
				set_card_revealed(index, true, true)
				main.accept_event()

func on_collect_pressed() -> void:
	if not main.turn_result_active or main.turn_result_collecting:
		return
	await collect_cards_to_targets(true)

func on_continue_pressed() -> void:
	if not main.turn_result_active or main.turn_result_collecting:
		return
	continue_requested.emit()
	var auto_collected: bool = false
	if not all_cards_collected():
		auto_collected = true
		await collect_cards_to_targets(true)
	main.turn_result_index += 1
	if main.turn_result_index >= main.turn_result_queue.size():
		finish_sequence()
		return
	if not auto_collected:
		main._play_ui_sound("button")
	show_current_result()
