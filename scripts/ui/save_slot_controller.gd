extends Node
class_name SaveSlotController

var main

func setup(main_node) -> void:
	main = main_node

func build_if_needed() -> void:
	if main.save_slot_overlay != null or main.system_menu_overlay == null:
		return
	main.save_slot_overlay = Control.new()
	main.save_slot_overlay.name = "SaveSlotOverlay"
	main.save_slot_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.save_slot_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	main.save_slot_overlay.visible = false
	main.system_menu_overlay.add_child(main.save_slot_overlay)
	var shade: ColorRect = ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.28)
	main.save_slot_overlay.add_child(shade)
	main.save_slot_panel = PanelContainer.new()
	main.save_slot_panel.anchor_left = 0.5
	main.save_slot_panel.anchor_top = 0.5
	main.save_slot_panel.anchor_right = 0.5
	main.save_slot_panel.anchor_bottom = 0.5
	main.save_slot_panel.offset_left = -360
	main.save_slot_panel.offset_top = -250
	main.save_slot_panel.offset_right = 360
	main.save_slot_panel.offset_bottom = 250
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
	main.save_slot_panel.add_theme_stylebox_override("panel", panel_style)
	main.save_slot_overlay.add_child(main.save_slot_panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	main.save_slot_panel.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	main.save_slot_title = Label.new()
	main.save_slot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.save_slot_title.add_theme_font_size_override("font_size", 28)
	box.add_child(main.save_slot_title)
	main.save_slot_subtitle = Label.new()
	main.save_slot_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.save_slot_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main.save_slot_subtitle.modulate = Color(1, 1, 1, 0.78)
	main.save_slot_subtitle.visible = false
	box.add_child(main.save_slot_subtitle)
	var slot_list: VBoxContainer = VBoxContainer.new()
	slot_list.add_theme_constant_override("separation", 8)
	slot_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(slot_list)
	main.save_slot_buttons.clear()
	for _index in range(6):
		var slot_button: Button = Button.new()
		slot_button.custom_minimum_size = Vector2(0.0, 52.0)
		slot_button.focus_mode = Control.FOCUS_ALL
		slot_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot_button.pressed.connect(_on_save_slot_button_pressed.bind(_index))
		slot_list.add_child(slot_button)
		main.save_slot_buttons.append(slot_button)
	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	box.add_child(footer)
	main.save_slot_prev_button = Button.new()
	main.save_slot_prev_button.text = TextDB.get_text("ui.save_slots.prev", "Prev")
	main.save_slot_prev_button.custom_minimum_size = Vector2(110.0, 42.0)
	main.save_slot_prev_button.pressed.connect(_on_save_slot_prev_pressed)
	footer.add_child(main.save_slot_prev_button)
	main.save_slot_page_label = Label.new()
	main.save_slot_page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.save_slot_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_child(main.save_slot_page_label)
	main.save_slot_next_button = Button.new()
	main.save_slot_next_button.text = TextDB.get_text("ui.save_slots.next", "Next")
	main.save_slot_next_button.custom_minimum_size = Vector2(110.0, 42.0)
	main.save_slot_next_button.pressed.connect(_on_save_slot_next_pressed)
	footer.add_child(main.save_slot_next_button)
	main.save_slot_close_button = Button.new()
	main.save_slot_close_button.text = TextDB.get_text("ui.buttons.close")
	main.save_slot_close_button.custom_minimum_size = Vector2(110.0, 42.0)
	main.save_slot_close_button.pressed.connect(close)
	footer.add_child(main.save_slot_close_button)

func open(mode: String) -> void:
	if main.save_manager == null:
		return
	build_if_needed()
	if main.save_slot_overlay == null:
		return
	var was_visible: bool = main.save_slot_overlay.visible
	if not was_visible:
		main._play_ui_sound("panel_open")
	main.save_slot_mode = mode
	main.save_slot_page = 0
	main.save_slot_overlay.visible = true
	refresh()

func close() -> void:
	if main.save_slot_overlay == null:
		return
	var was_visible: bool = main.save_slot_overlay.visible
	main.save_slot_overlay.visible = false
	main.save_slot_mode = ""
	if was_visible:
		main._play_ui_sound("panel_close")

func is_visible() -> bool:
	return main.save_slot_overlay != null and main.save_slot_overlay.visible

func refresh() -> void:
	if main.save_slot_overlay == null or not main.save_slot_overlay.visible or main.save_manager == null:
		return
	var page_total: int = maxi(1, main.save_manager.page_count())
	main.save_slot_page = clampi(main.save_slot_page, 0, page_total - 1)
	var is_load_mode: bool = main.save_slot_mode == "load"
	main.save_slot_title.text = TextDB.get_text("ui.save_slots.load_title", "Load Save") if is_load_mode else TextDB.get_text("ui.save_slots.save_title", "Choose Slot")
	main.save_slot_subtitle.text = TextDB.get_text("ui.save_slots.load_subtitle", "Choose a slot to load.") if is_load_mode else TextDB.get_text("ui.save_slots.save_subtitle", "System slot autosaves each turn; other slots are manual.")
	main.save_slot_subtitle.visible = false
	main.save_slot_page_label.text = TextDB.format_text("ui.save_slots.page", [main.save_slot_page + 1, page_total], {}, "Page %d / %d")
	main.save_slot_prev_button.disabled = main.save_slot_page <= 0
	main.save_slot_next_button.disabled = main.save_slot_page >= page_total - 1
	var slot_entries: Array[Dictionary] = main.save_manager.list_slots(main.save_slot_page)
	for button_index in range(main.save_slot_buttons.size()):
		var button: Button = main.save_slot_buttons[button_index]
		if button_index >= slot_entries.size():
			button.visible = false
			button.disabled = true
			continue
		button.visible = true
		var entry: Dictionary = slot_entries[button_index]
		var slot_index: int = int(entry.get("slot_index", -1))
		var has_save: bool = bool(entry.get("has_save", false))
		var metadata: Dictionary = entry.get("metadata", {}) as Dictionary
		button.text = save_slot_button_text(slot_index, has_save, metadata)
		button.disabled = is_load_mode and not has_save

func save_slot_button_text(slot_index: int, has_save: bool, metadata: Dictionary) -> String:
	var slot_name: String = main.save_manager.slot_display_name(slot_index)
	if not has_save:
		return TextDB.format_text("ui.save_slots.empty", [slot_name], {}, "%s\nEmpty")
	var label: String = str(metadata.get("label", slot_name))
	var term_name: String = str(metadata.get("term_name", ""))
	var turn_index: int = int(metadata.get("turn_index", 0))
	var saved_at: String = str(metadata.get("saved_at", ""))
	return TextDB.format_text("ui.save_slots.filled", [slot_name, label, term_name, turn_index, saved_at], {}, "%s | %s\n%s | Turn %d | %s")

func _on_save_slot_button_pressed(local_index: int) -> void:
	if main.save_manager == null or main.run_state == null:
		return
	var slot_index: int = main.save_slot_page * main.save_manager.PAGE_SIZE + local_index
	if slot_index < 0 or slot_index > main.save_manager.MANUAL_SLOT_COUNT:
		return
	if main.save_slot_mode == "load":
		var snapshot: Dictionary = main.save_manager.load_from_slot(slot_index)
		if snapshot.is_empty():
			main._show_message_popup(TextDB.get_text("ui.save_slots.load_title", "Load Save"), "", TextDB.get_text("ui.system_menu.no_save"))
			return
		main._apply_loaded_snapshot(snapshot)
		close()
		main._show_system_menu(false)
		main._show_message_popup(TextDB.get_text("ui.save_slots.load_title", "Load Save"), "", TextDB.get_text("ui.system_menu.load_done"))
		return
	var label: String = main.save_manager.slot_display_name(slot_index)
	if slot_index == main.save_manager.SYSTEM_SLOT_INDEX:
		label = TextDB.get_text("ui.save_slots.system_label", "绯荤粺瀛樻。")
	var ok: bool = main.save_manager.save_to_slot(slot_index, main.run_state, main.board_manager, label, slot_index == main.save_manager.SYSTEM_SLOT_INDEX)
	if ok:
		refresh()
		main._show_message_popup(TextDB.get_text("ui.system_menu.save", "瀛樻。"), "", TextDB.get_text("ui.system_menu.save_done"))

func _on_save_slot_prev_pressed() -> void:
	main.save_slot_page -= 1
	refresh()

func _on_save_slot_next_pressed() -> void:
	main.save_slot_page += 1
	refresh()
