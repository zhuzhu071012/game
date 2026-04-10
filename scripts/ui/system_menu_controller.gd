extends Node
class_name SystemMenuController

signal new_game_requested
signal load_requested
signal save_requested
signal options_requested
signal help_requested

var main

func setup(main_node) -> void:
	main = main_node

func build_if_needed() -> void:
	if main.system_menu_overlay != null:
		return
	main.system_menu_overlay = Control.new()
	main.system_menu_overlay.name = "SystemMenuOverlay"
	main.system_menu_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.system_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	main.system_menu_overlay.z_as_relative = false
	main.system_menu_overlay.z_index = 2048
	main.system_menu_overlay.visible = false
	main.add_child(main.system_menu_overlay)
	main.system_menu_cover = ColorRect.new()
	main.system_menu_cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.system_menu_cover.color = Color(0.0, 0.0, 0.0, 1.0)
	main.system_menu_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.system_menu_overlay.add_child(main.system_menu_cover)
	main.system_menu_panel = PanelContainer.new()
	main.system_menu_panel.anchor_left = 0.5
	main.system_menu_panel.anchor_top = 0.5
	main.system_menu_panel.anchor_right = 0.5
	main.system_menu_panel.anchor_bottom = 0.5
	main.system_menu_panel.offset_left = -240
	main.system_menu_panel.offset_top = -230
	main.system_menu_panel.offset_right = 240
	main.system_menu_panel.offset_bottom = 230
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.07, 0.08, 0.98)
	style.border_color = Color(0.45, 0.45, 0.47, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.40)
	style.shadow_size = 10
	main.system_menu_panel.add_theme_stylebox_override("panel", style)
	main.system_menu_overlay.add_child(main.system_menu_panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	main.system_menu_panel.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	main.system_menu_title = Label.new()
	main.system_menu_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.system_menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.system_menu_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main.system_menu_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main.system_menu_title.add_theme_font_size_override("font_size", 36)
	box.add_child(main.system_menu_title)
	main.system_menu_subtitle = Label.new()
	main.system_menu_subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.system_menu_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.system_menu_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main.system_menu_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main.system_menu_subtitle.modulate = Color(1,1,1,0.78)
	main.system_menu_subtitle.visible = false
	box.add_child(main.system_menu_subtitle)
	main.system_menu_primary_button = _make_system_menu_button()
	main.system_menu_primary_button.pressed.connect(_on_system_menu_primary_pressed)
	box.add_child(main.system_menu_primary_button)
	main.system_menu_return_button = _make_system_menu_button()
	main.system_menu_return_button.pressed.connect(_on_system_menu_return_pressed)
	box.add_child(main.system_menu_return_button)
	main.system_menu_load_button = _make_system_menu_button()
	main.system_menu_load_button.pressed.connect(_on_system_menu_load_pressed)
	box.add_child(main.system_menu_load_button)
	main.system_menu_save_button = _make_system_menu_button()
	main.system_menu_save_button.pressed.connect(_on_system_menu_save_pressed)
	box.add_child(main.system_menu_save_button)
	main.system_menu_options_button = _make_system_menu_button()
	main.system_menu_options_button.pressed.connect(_on_system_menu_options_pressed)
	box.add_child(main.system_menu_options_button)
	main.system_menu_help_button = _make_system_menu_button()
	main.system_menu_help_button.pressed.connect(_on_system_menu_help_pressed)
	box.add_child(main.system_menu_help_button)

func _make_system_menu_button() -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(0, 44)
	button.focus_mode = Control.FOCUS_ALL
	return button

func show_menu(visible: bool) -> void:
	if main.system_menu_overlay == null:
		return
	var was_visible: bool = main.system_menu_overlay.visible
	var child_overlay_was_visible: bool = (main.save_slot_overlay != null and main.save_slot_overlay.visible) or main._audio_options_visible()
	if visible and not was_visible and not main.startup_cover_active:
		main._play_ui_sound("panel_open")
	if visible and main.system_menu_cover != null:
		main.system_menu_cover.color = Color(0.0, 0.0, 0.0, 1.0) if main.startup_cover_active else Color(0.02, 0.02, 0.03, 0.84)
	main.system_menu_overlay.visible = visible
	if not visible:
		main._close_save_slot_overlay()
		main._close_audio_options_overlay(false)
		if was_visible and not child_overlay_was_visible:
			main._play_ui_sound("panel_close")
		return
	var title_font_size: int = 76 if main.startup_cover_active else 36
	main.system_menu_panel.offset_left = -320 if main.startup_cover_active else -240
	main.system_menu_panel.offset_right = 320 if main.startup_cover_active else 240
	main.system_menu_title.add_theme_font_size_override("font_size", title_font_size)
	main.system_menu_title.custom_minimum_size = Vector2(0.0, 116.0) if main.startup_cover_active else Vector2.ZERO
	main.system_menu_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main.system_menu_title.text = TextDB.get_text("ui.system_menu.cover_title") if main.startup_cover_active else TextDB.get_text("ui.system_menu.title")
	main.system_menu_subtitle.text = TextDB.get_text("ui.system_menu.startup_subtitle") if main.startup_cover_active else TextDB.get_text("ui.system_menu.ingame_subtitle")
	main.system_menu_subtitle.visible = false
	main.system_menu_primary_button.text = TextDB.get_text("ui.system_menu.new_game") if main.startup_cover_active else TextDB.get_text("ui.system_menu.resume")
	main.system_menu_return_button.text = TextDB.get_text("ui.system_menu.return_to_cover")
	main.system_menu_load_button.text = TextDB.get_text("ui.system_menu.load")
	main.system_menu_save_button.text = TextDB.get_text("ui.system_menu.save")
	main.system_menu_options_button.text = TextDB.get_text("ui.system_menu.options")
	main.system_menu_help_button.text = TextDB.get_text("ui.system_menu.help")
	var tutorial_locked: bool = not main.startup_cover_active and main.tutorial_manager != null and main.run_state != null and main.tutorial_manager.is_active(main.run_state)
	var has_save: bool = main.save_manager != null and main.save_manager.has_any_save()
	main.system_menu_return_button.visible = not main.startup_cover_active
	main.system_menu_load_button.disabled = tutorial_locked or not has_save
	main.system_menu_save_button.visible = not main.startup_cover_active
	main.system_menu_save_button.disabled = main.startup_cover_active or tutorial_locked
	main.system_menu_primary_button.grab_focus()

func is_visible() -> bool:
	return main.system_menu_overlay != null and main.system_menu_overlay.visible

func _on_system_menu_primary_pressed() -> void:
	if main.startup_cover_active:
		new_game_requested.emit()
		main._start_new_game()
	else:
		show_menu(false)

func _on_system_menu_return_pressed() -> void:
	main._save_system_game()
	main._close_all_detail_views()
	main.startup_cover_active = true
	show_menu(true)

func _on_system_menu_load_pressed() -> void:
	load_requested.emit()
	if not main.startup_cover_active and main.tutorial_manager != null and main.run_state != null and main.tutorial_manager.is_active(main.run_state):
		main._show_message_popup(TextDB.get_text("ui.system_menu.load"), "", TextDB.get_text("ui.system_menu.tutorial_locked_load"))
		return
	if main.save_manager == null or not main.save_manager.has_any_save():
		main._show_message_popup(TextDB.get_text("ui.system_menu.load"), "", TextDB.get_text("ui.system_menu.no_save"))
		return
	main.save_slot_controller.open("load")

func _on_system_menu_save_pressed() -> void:
	save_requested.emit()
	if main.startup_cover_active:
		return
	if main.tutorial_manager != null and main.run_state != null and main.tutorial_manager.is_active(main.run_state):
		main._show_message_popup(TextDB.get_text("ui.system_menu.save"), "", TextDB.get_text("ui.system_menu.tutorial_locked_save"))
		return
	main.save_slot_controller.open("save")

func _on_system_menu_options_pressed() -> void:
	options_requested.emit()
	main.audio_options_controller.open()

func _on_system_menu_help_pressed() -> void:
	help_requested.emit()
	main._show_message_popup(TextDB.get_text("ui.detail_slots.menu_help.title"), "", TextDB.get_text("ui.detail_slots.menu_help.body"))
