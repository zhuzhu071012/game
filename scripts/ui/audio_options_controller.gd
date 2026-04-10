extends Node
class_name AudioOptionsController

signal font_scale_changed(value: float)
signal settings_changed

var main

func setup(main_node) -> void:
	main = main_node

func build_if_needed() -> void:
	if main.audio_options_overlay != null or main.system_menu_overlay == null:
		return
	main.audio_options_overlay = Control.new()
	main.audio_options_overlay.name = "AudioOptionsOverlay"
	main.audio_options_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.audio_options_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	main.audio_options_overlay.visible = false
	main.system_menu_overlay.add_child(main.audio_options_overlay)
	var shade: ColorRect = ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.30)
	main.audio_options_overlay.add_child(shade)
	main.audio_options_panel = PanelContainer.new()
	main.audio_options_panel.anchor_left = 0.5
	main.audio_options_panel.anchor_top = 0.5
	main.audio_options_panel.anchor_right = 0.5
	main.audio_options_panel.anchor_bottom = 0.5
	main.audio_options_panel.offset_left = -280
	main.audio_options_panel.offset_top = -230
	main.audio_options_panel.offset_right = 280
	main.audio_options_panel.offset_bottom = 230
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.09, 0.98)
	panel_style.border_color = Color(0.42, 0.42, 0.44, 0.96)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	main.audio_options_panel.add_theme_stylebox_override("panel", panel_style)
	main.audio_options_overlay.add_child(main.audio_options_panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	main.audio_options_panel.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	main.audio_options_title = Label.new()
	main.audio_options_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.audio_options_title.add_theme_font_size_override("font_size", 28)
	box.add_child(main.audio_options_title)
	main.audio_options_subtitle = Label.new()
	main.audio_options_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.audio_options_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main.audio_options_subtitle.modulate = Color(1, 1, 1, 0.78)
	main.audio_options_subtitle.visible = false
	box.add_child(main.audio_options_subtitle)
	var slider_box: VBoxContainer = VBoxContainer.new()
	slider_box.add_theme_constant_override("separation", 12)
	slider_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(slider_box)
	_build_audio_slider_row(slider_box, "master", TextDB.get_text("ui.audio_options.master"))
	_build_audio_slider_row(slider_box, "music", TextDB.get_text("ui.audio_options.music"))
	_build_audio_slider_row(slider_box, "sfx", TextDB.get_text("ui.audio_options.sfx"))
	_build_font_size_slider_row(slider_box, TextDB.get_text("ui.audio_options.font_size"))
	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	box.add_child(footer)
	main.audio_options_reset_button = Button.new()
	main.audio_options_reset_button.custom_minimum_size = Vector2(130.0, 42.0)
	main.audio_options_reset_button.pressed.connect(_on_audio_options_reset_pressed)
	footer.add_child(main.audio_options_reset_button)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	main.audio_options_close_button = Button.new()
	main.audio_options_close_button.custom_minimum_size = Vector2(110.0, 42.0)
	main.audio_options_close_button.pressed.connect(close)
	footer.add_child(main.audio_options_close_button)

func _build_audio_slider_row(parent: VBoxContainer, channel_id: String, label_text: String) -> void:
	var row: VBoxContainer = VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var header: HBoxContainer = HBoxContainer.new()
	row.add_child(header)
	var name_label: Label = Label.new()
	name_label.text = label_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	var value_label: Label = Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(60.0, 0.0)
	header.add_child(value_label)
	var slider: HSlider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_audio_slider_value_changed.bind(channel_id))
	slider.drag_ended.connect(_on_audio_slider_drag_ended.bind(channel_id))
	row.add_child(slider)
	main.audio_option_sliders[channel_id] = slider
	main.audio_option_value_labels[channel_id] = value_label

func _build_font_size_slider_row(parent: VBoxContainer, label_text: String) -> void:
	var row: VBoxContainer = VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var header: HBoxContainer = HBoxContainer.new()
	row.add_child(header)
	var name_label: Label = Label.new()
	name_label.text = label_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	main.ui_font_size_value_label = Label.new()
	main.ui_font_size_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	main.ui_font_size_value_label.custom_minimum_size = Vector2(60.0, 0.0)
	header.add_child(main.ui_font_size_value_label)
	main.ui_font_size_slider = HSlider.new()
	main.ui_font_size_slider.min_value = main.UI_FONT_SCALE_MIN * 100.0
	main.ui_font_size_slider.max_value = main.UI_FONT_SCALE_MAX * 100.0
	main.ui_font_size_slider.step = main.UI_FONT_SCALE_STEP * 100.0
	main.ui_font_size_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.ui_font_size_slider.value_changed.connect(_on_font_size_slider_value_changed)
	main.ui_font_size_slider.drag_ended.connect(_on_font_size_slider_drag_ended)
	row.add_child(main.ui_font_size_slider)

func open() -> void:
	build_if_needed()
	if main.audio_options_overlay == null:
		return
	var was_visible: bool = main.audio_options_overlay.visible
	if not was_visible:
		main._play_ui_sound("panel_open")
	refresh()
	main.audio_options_overlay.visible = true

func close(play_sound: bool = true) -> void:
	if main.audio_options_overlay == null:
		return
	var was_visible: bool = main.audio_options_overlay.visible
	main.audio_options_overlay.visible = false
	if was_visible and play_sound:
		main._play_ui_sound("panel_close")

func is_visible() -> bool:
	return main.audio_options_overlay != null and main.audio_options_overlay.visible

func refresh() -> void:
	if main.audio_options_overlay == null:
		return
	main.audio_options_title.text = TextDB.get_text("ui.audio_options.title")
	main.audio_options_subtitle.text = TextDB.get_text("ui.audio_options.subtitle")
	main.audio_options_subtitle.visible = false
	main.audio_options_reset_button.text = TextDB.get_text("ui.audio_options.reset")
	main.audio_options_close_button.text = TextDB.get_text("ui.audio_options.close", TextDB.get_text("ui.buttons.close"))
	if main.audio_manager != null:
		for channel_id in ["master", "music", "sfx"]:
			var slider: HSlider = main.audio_option_sliders.get(channel_id, null) as HSlider
			if slider == null:
				continue
			slider.set_block_signals(true)
			slider.value = round(main.audio_manager.get_volume_level(channel_id) * 100.0)
			slider.set_block_signals(false)
			_update_audio_option_value_label(channel_id)
	if main.ui_font_size_slider != null:
		main.ui_font_size_slider.set_block_signals(true)
		main.ui_font_size_slider.value = round(main.ui_font_scale * 100.0)
		main.ui_font_size_slider.set_block_signals(false)
		_update_font_size_value_label()

func _update_audio_option_value_label(channel_id: String) -> void:
	var value_label: Label = main.audio_option_value_labels.get(channel_id, null) as Label
	if value_label == null or main.audio_manager == null:
		return
	value_label.text = TextDB.format_text("ui.audio_options.value", [int(round(main.audio_manager.get_volume_level(channel_id) * 100.0))], {}, "%d%%")

func _update_font_size_value_label() -> void:
	if main.ui_font_size_value_label == null:
		return
	main.ui_font_size_value_label.text = TextDB.format_text("ui.audio_options.value", [int(round(main.ui_font_scale * 100.0))], {}, "%d%%")

func _on_audio_slider_value_changed(value: float, channel_id: String) -> void:
	if main.audio_manager == null:
		return
	main.audio_manager.set_volume_level(channel_id, value / 100.0)
	_update_audio_option_value_label(channel_id)
	settings_changed.emit()

func _on_audio_slider_drag_ended(changed: bool, channel_id: String) -> void:
	if changed and channel_id in ["master", "sfx"]:
		main._play_ui_sound("button")

func _on_font_size_slider_value_changed(value: float) -> void:
	var next_scale: float = clampf(value / 100.0, main.UI_FONT_SCALE_MIN, main.UI_FONT_SCALE_MAX)
	if absf(next_scale - main.ui_font_scale) <= 0.001:
		_update_font_size_value_label()
		return
	main.ui_font_scale = next_scale
	main._save_ui_settings()
	main._apply_font_preferences()
	_update_font_size_value_label()
	font_scale_changed.emit(main.ui_font_scale)
	settings_changed.emit()

func _on_font_size_slider_drag_ended(changed: bool) -> void:
	if changed:
		main._play_ui_sound("button")

func _on_audio_options_reset_pressed() -> void:
	if main.audio_manager != null:
		main.audio_manager.reset_volume_levels()
	if absf(main.ui_font_scale - main.UI_FONT_SCALE_DEFAULT) > 0.001:
		main.ui_font_scale = main.UI_FONT_SCALE_DEFAULT
		main._save_ui_settings()
		main._apply_font_preferences()
	else:
		refresh()
	main._play_ui_sound("button")
	settings_changed.emit()
