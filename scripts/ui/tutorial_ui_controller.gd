extends Node
class_name TutorialUiController

const UI_PALETTE := preload("res://scripts/ui/ui_palette.gd")

signal dialog_finished

var main

func setup(main_node) -> void:
	main = main_node

func build_toast_if_needed() -> void:
	if main.tutorial_toast_panel != null:
		return
	main.tutorial_toast_panel = PanelContainer.new()
	main.tutorial_toast_panel.anchor_left = 0.5
	main.tutorial_toast_panel.anchor_top = 1.0
	main.tutorial_toast_panel.anchor_right = 0.5
	main.tutorial_toast_panel.anchor_bottom = 1.0
	main.tutorial_toast_panel.offset_left = -250
	main.tutorial_toast_panel.offset_top = -120
	main.tutorial_toast_panel.offset_right = 250
	main.tutorial_toast_panel.offset_bottom = -56
	main.tutorial_toast_panel.z_as_relative = false
	main.tutorial_toast_panel.z_index = 1200
	main.tutorial_toast_panel.visible = false
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UI_PALETTE.alpha(UI_PALETTE.INK, 0.94)
	style.border_color = UI_PALETTE.alpha(UI_PALETTE.SLATE.lightened(0.16), 0.92)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	main.tutorial_toast_panel.add_theme_stylebox_override("panel", style)
	main.add_child(main.tutorial_toast_panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	main.tutorial_toast_panel.add_child(margin)
	main.tutorial_toast_label = Label.new()
	main.tutorial_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main.tutorial_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.tutorial_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main.tutorial_toast_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.tutorial_toast_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(main.tutorial_toast_label)

func build_dialog_if_needed() -> void:
	if main.tutorial_dialog_overlay != null:
		return
	main.tutorial_dialog_overlay = Control.new()
	main.tutorial_dialog_overlay.name = "TutorialDialogueOverlay"
	main.tutorial_dialog_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.tutorial_dialog_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	main.tutorial_dialog_overlay.z_as_relative = false
	main.tutorial_dialog_overlay.z_index = 1200
	main.tutorial_dialog_overlay.visible = false
	main.add_child(main.tutorial_dialog_overlay)
	main.tutorial_dialog_overlay.gui_input.connect(_on_tutorial_dialog_gui_input)
	var dimmer: ColorRect = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = UI_PALETTE.alpha(UI_PALETTE.INK, 0.14)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.tutorial_dialog_overlay.add_child(dimmer)
	main.tutorial_dialog_panel = PanelContainer.new()
	main.tutorial_dialog_panel.anchor_left = 0.20
	main.tutorial_dialog_panel.anchor_top = 1.0
	main.tutorial_dialog_panel.anchor_right = 0.80
	main.tutorial_dialog_panel.anchor_bottom = 1.0
	main.tutorial_dialog_panel.offset_top = -252.0
	main.tutorial_dialog_panel.offset_bottom = -14.0
	main.tutorial_dialog_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	main.tutorial_dialog_panel.gui_input.connect(_on_tutorial_dialog_gui_input)
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.INK, 0.96)
	panel_style.border_color = UI_PALETTE.alpha(UI_PALETTE.SLATE.lightened(0.14), 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	panel_style.shadow_size = 8
	main.tutorial_dialog_panel.add_theme_stylebox_override("panel", panel_style)
	main.tutorial_dialog_overlay.add_child(main.tutorial_dialog_panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	main.tutorial_dialog_panel.add_child(margin)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(row)
	main.tutorial_dialog_left_portrait = TextureRect.new()
	main.tutorial_dialog_left_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	main.tutorial_dialog_left_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	main.tutorial_dialog_left_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.tutorial_dialog_left_portrait.z_as_relative = false
	main.tutorial_dialog_left_portrait.z_index = 1201
	main.tutorial_dialog_overlay.add_child(main.tutorial_dialog_left_portrait)
	var center_box: VBoxContainer = VBoxContainer.new()
	center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_box.add_theme_constant_override("separation", 8)
	row.add_child(center_box)
	main.tutorial_dialog_name = Label.new()
	main.tutorial_dialog_name.add_theme_font_size_override("font_size", 28)
	main.tutorial_dialog_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_box.add_child(main.tutorial_dialog_name)
	main.tutorial_dialog_text = RichTextLabel.new()
	main.tutorial_dialog_text.bbcode_enabled = false
	main.tutorial_dialog_text.fit_content = false
	main.tutorial_dialog_text.scroll_active = false
	main.tutorial_dialog_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.tutorial_dialog_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.tutorial_dialog_text.add_theme_font_size_override("normal_font_size", 24)
	main.tutorial_dialog_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_box.add_child(main.tutorial_dialog_text)
	main.tutorial_dialog_hint = Label.new()
	main.tutorial_dialog_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	main.tutorial_dialog_hint.modulate = Color(1.0, 1.0, 1.0, 0.72)
	main.tutorial_dialog_hint.text = TextDB.get_text("ui.messages.dialog_click_continue", "Continue")
	main.tutorial_dialog_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_box.add_child(main.tutorial_dialog_hint)
	main.tutorial_dialog_right_portrait = TextureRect.new()
	main.tutorial_dialog_right_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	main.tutorial_dialog_right_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	main.tutorial_dialog_right_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.tutorial_dialog_right_portrait.z_as_relative = false
	main.tutorial_dialog_right_portrait.z_index = 1201
	main.tutorial_dialog_overlay.add_child(main.tutorial_dialog_right_portrait)
	if not main.tutorial_dialog_overlay.resized.is_connected(_refresh_dialog_layout):
		main.tutorial_dialog_overlay.resized.connect(_refresh_dialog_layout)
	_refresh_dialog_layout()

func show_toast(message: String, duration: float = 2.4) -> void:
	build_toast_if_needed()
	if main.tutorial_toast_panel == null or main.tutorial_toast_label == null:
		return
	var safe_message: String = message.strip_edges()
	if safe_message.is_empty():
		return
	main.tutorial_toast_token += 1
	var token: int = main.tutorial_toast_token
	main.tutorial_toast_label.text = safe_message
	main.tutorial_toast_panel.visible = true
	_hide_tutorial_toast_later(token, duration)

func _hide_tutorial_toast_later(token: int, duration: float) -> void:
	await get_tree().create_timer(duration).timeout
	if token != main.tutorial_toast_token:
		return
	if main.tutorial_toast_panel != null:
		main.tutorial_toast_panel.visible = false

func show_tutorial_followup_if_needed() -> bool:
	if main.tutorial_manager == null or main.run_state == null or main.detail_overlay.visible:
		return false
	var popup: Dictionary = main.tutorial_manager.consume_followup_popup(main.run_state)
	if popup.is_empty():
		return false
	main._show_message_popup(str(popup.get("title", "")), str(popup.get("subtitle", "")), str(popup.get("body", "")), str(popup.get("presentation", "")), str(popup.get("image_path", "")))
	main.tutorial_prompt_after_popup = bool(popup.get("chain_to_prompt", false))
	return true

func try_show_pre_report_dialog(report_turn_index: int, report_logs: Array[String], title_override: String, subtitle_override: String, body_override: String) -> bool:
	if main.tutorial_manager == null or main.run_state == null:
		return false
	var dialogue: Dictionary = main.tutorial_manager.pre_report_dialogue(main.run_state)
	if dialogue.is_empty():
		return false
	main.pending_report_payload = {"turn_index": report_turn_index, "logs": report_logs.duplicate(true), "title": title_override, "subtitle": subtitle_override, "body": body_override}
	start_dialog(dialogue)
	return true

func start_dialog(dialogue: Dictionary) -> void:
	build_dialog_if_needed()
	main.tutorial_dialog_lines = []
	for line_variant in dialogue.get("lines", []):
		if line_variant is Dictionary:
			main.tutorial_dialog_lines.append((line_variant as Dictionary).duplicate(true))
	main.tutorial_dialog_index = 0
	main.tutorial_dialog_active = not main.tutorial_dialog_lines.is_empty()
	if not main.tutorial_dialog_active:
		finish_dialog()
		return
	var left_character_id: String = str(dialogue.get("left_character_id", ""))
	var right_character_id: String = str(dialogue.get("right_character_id", ""))
	main.tutorial_dialog_flip_sides = false
	if left_character_id == "cao_cao" and not right_character_id.is_empty():
		main.tutorial_dialog_flip_sides = true
		var swapped_character_id: String = left_character_id
		left_character_id = right_character_id
		right_character_id = swapped_character_id
	_set_tutorial_dialog_portrait(main.tutorial_dialog_left_portrait, left_character_id)
	_set_tutorial_dialog_portrait(main.tutorial_dialog_right_portrait, right_character_id)
	main.detail_overlay.visible = false
	main.tutorial_dialog_overlay.visible = true
	_refresh_dialog_layout()
	_render_tutorial_dialog_line()

func advance_dialog() -> void:
	if not main.tutorial_dialog_active:
		return
	main.tutorial_dialog_index += 1
	if main.tutorial_dialog_index >= main.tutorial_dialog_lines.size():
		finish_dialog()
		return
	_render_tutorial_dialog_line()

func finish_dialog() -> void:
	main.tutorial_dialog_active = false
	main.tutorial_dialog_index = -1
	main.tutorial_dialog_flip_sides = false
	main.tutorial_dialog_lines.clear()
	if main.tutorial_dialog_overlay != null:
		main.tutorial_dialog_overlay.visible = false
	var payload: Dictionary = main.pending_report_payload.duplicate(true)
	main.pending_report_payload.clear()
	dialog_finished.emit()
	if payload.is_empty():
		return
	var report_logs: Array[String] = []
	for log_variant in payload.get("logs", []):
		report_logs.append(str(log_variant))
	main._show_turn_report_dialog(int(payload.get("turn_index", main.run_state.turn_index)), report_logs, str(payload.get("title", "")), str(payload.get("subtitle", "")), str(payload.get("body", "")))

func is_dialog_active() -> bool:
	return main.tutorial_dialog_active

func _set_tutorial_dialog_portrait(target: TextureRect, character_id: String) -> void:
	if target == null:
		return
	var texture: Texture2D = null
	if main.characters.has(character_id):
		var data: CharacterData = main.characters[character_id] as CharacterData
		if data != null and not data.art_path.is_empty() and ResourceLoader.exists(data.art_path):
			texture = load(data.art_path) as Texture2D
	target.texture = texture

func _render_tutorial_dialog_line() -> void:
	if not main.tutorial_dialog_active or main.tutorial_dialog_index < 0 or main.tutorial_dialog_index >= main.tutorial_dialog_lines.size():
		finish_dialog()
		return
	var line: Dictionary = main.tutorial_dialog_lines[main.tutorial_dialog_index] as Dictionary
	var side: String = str(line.get("side", "left"))
	if main.tutorial_dialog_flip_sides:
		side = "right" if side == "left" else "left"
	main.tutorial_dialog_name.text = str(line.get("speaker", ""))
	main.tutorial_dialog_text.text = str(line.get("text", ""))
	main.tutorial_dialog_text.scroll_to_line(0)
	main.tutorial_dialog_left_portrait.modulate = Color(1.0, 1.0, 1.0, 1.0 if side == "left" else 0.45)
	main.tutorial_dialog_right_portrait.modulate = Color(1.0, 1.0, 1.0, 1.0 if side == "right" else 0.45)
	main.tutorial_dialog_hint.text = TextDB.get_text("ui.messages.dialog_click_continue", "Continue")

func _refresh_dialog_layout() -> void:
	if main == null or main.tutorial_dialog_overlay == null:
		return
	var viewport_size: Vector2 = main.get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var portrait_width: float = clampf(viewport_size.x * 0.26, 280.0, 560.0)
	var portrait_height: float = clampf(viewport_size.y * 0.76, 420.0, 860.0)
	var bottom_offset: float = -10.0
	var side_margin: float = clampf(viewport_size.x * 0.018, 18.0, 42.0)
	main.tutorial_dialog_left_portrait.anchor_left = 0.0
	main.tutorial_dialog_left_portrait.anchor_right = 0.0
	main.tutorial_dialog_left_portrait.anchor_top = 1.0
	main.tutorial_dialog_left_portrait.anchor_bottom = 1.0
	main.tutorial_dialog_left_portrait.offset_left = side_margin
	main.tutorial_dialog_left_portrait.offset_top = bottom_offset - portrait_height
	main.tutorial_dialog_left_portrait.offset_right = side_margin + portrait_width
	main.tutorial_dialog_left_portrait.offset_bottom = bottom_offset
	main.tutorial_dialog_right_portrait.anchor_left = 1.0
	main.tutorial_dialog_right_portrait.anchor_right = 1.0
	main.tutorial_dialog_right_portrait.anchor_top = 1.0
	main.tutorial_dialog_right_portrait.anchor_bottom = 1.0
	main.tutorial_dialog_right_portrait.offset_left = -side_margin - portrait_width
	main.tutorial_dialog_right_portrait.offset_top = bottom_offset - portrait_height
	main.tutorial_dialog_right_portrait.offset_right = -side_margin
	main.tutorial_dialog_right_portrait.offset_bottom = bottom_offset

func _on_tutorial_dialog_gui_input(event: InputEvent) -> void:
	if not main.tutorial_dialog_active:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			advance_dialog()
			main.accept_event()
