extends Node
class_name SystemMenuController

const UI_PALETTE := preload("res://scripts/ui/ui_palette.gd")
const MENU_PANEL_HALF_WIDTH := 240.0
const COVER_PANEL_HALF_WIDTH := 360.0
const MENU_PANEL_HALF_HEIGHT := 230.0
const COVER_PANEL_HALF_HEIGHT := 270.0
const MENU_BUTTON_HEIGHT := 44.0
const COVER_MENU_BUTTON_HEIGHT := 64.0
const MENU_BOX_SEPARATION := 12
const COVER_MENU_BOX_SEPARATION := 24
const MENU_BUTTON_FONT_SIZE := 24
const COVER_MENU_BUTTON_FONT_SIZE := 34
const MENU_TITLE_FONT_SIZE := 36
const COVER_TITLE_FONT_SIZE := 92

signal new_game_requested
signal load_requested
signal save_requested
signal options_requested
signal help_requested

var main
var menu_box: VBoxContainer
var panel_style: StyleBoxFlat

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
	main.system_menu_overlay.z_index = 4095
	main.system_menu_overlay.visible = false
	main.add_child(main.system_menu_overlay)
	main.system_menu_background = TextureRect.new()
	main.system_menu_background.name = "SystemMenuBackground"
	main.system_menu_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.system_menu_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	main.system_menu_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	main.system_menu_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(main.COVER_BACKGROUND_PATH):
		main.system_menu_background.texture = load(main.COVER_BACKGROUND_PATH) as Texture2D
	main.system_menu_background.visible = false
	main.system_menu_overlay.add_child(main.system_menu_background)
	main.system_menu_cover = ColorRect.new()
	main.system_menu_cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.system_menu_cover.color = UI_PALETTE.alpha(UI_PALETTE.INK, 1.0)
	main.system_menu_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.system_menu_overlay.add_child(main.system_menu_cover)
	main.system_menu_panel = PanelContainer.new()
	main.system_menu_panel.anchor_left = 0.5
	main.system_menu_panel.anchor_top = 0.5
	main.system_menu_panel.anchor_right = 0.5
	main.system_menu_panel.anchor_bottom = 0.5
	main.system_menu_panel.offset_left = -MENU_PANEL_HALF_WIDTH
	main.system_menu_panel.offset_top = -MENU_PANEL_HALF_HEIGHT
	main.system_menu_panel.offset_right = MENU_PANEL_HALF_WIDTH
	main.system_menu_panel.offset_bottom = MENU_PANEL_HALF_HEIGHT
	panel_style = StyleBoxFlat.new()
	panel_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.INK, 0.98)
	panel_style.border_color = UI_PALETTE.alpha(UI_PALETTE.SLATE.lightened(0.12), 0.95)
	panel_style.border_width_left = 0
	panel_style.border_width_top = 0
	panel_style.border_width_right = 0
	panel_style.border_width_bottom = 0
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.0)
	panel_style.shadow_size = 0
	main.system_menu_panel.add_theme_stylebox_override("panel", panel_style)
	main.system_menu_overlay.add_child(main.system_menu_panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	main.system_menu_panel.add_child(margin)
	menu_box = VBoxContainer.new()
	menu_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_box.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_box.add_theme_constant_override("separation", MENU_BOX_SEPARATION)
	margin.add_child(menu_box)
	main.system_menu_title = Label.new()
	main.system_menu_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.system_menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.system_menu_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main.system_menu_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main.system_menu_title.add_theme_font_size_override("font_size", MENU_TITLE_FONT_SIZE)
	if main.TITLE_FONT_RESOURCE != null:
		main.system_menu_title.add_theme_font_override("font", main.TITLE_FONT_RESOURCE)
	menu_box.add_child(main.system_menu_title)
	main.system_menu_subtitle = Label.new()
	main.system_menu_subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.system_menu_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.system_menu_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main.system_menu_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main.system_menu_subtitle.modulate = UI_PALETTE.alpha(UI_PALETTE.PAPER, 0.78)
	main.system_menu_subtitle.visible = false
	menu_box.add_child(main.system_menu_subtitle)
	main.system_menu_primary_button = _make_system_menu_button()
	main.system_menu_primary_button.pressed.connect(_on_system_menu_primary_pressed)
	menu_box.add_child(main.system_menu_primary_button)
	main.system_menu_return_button = _make_system_menu_button()
	main.system_menu_return_button.pressed.connect(_on_system_menu_return_pressed)
	menu_box.add_child(main.system_menu_return_button)
	main.system_menu_load_button = _make_system_menu_button()
	main.system_menu_load_button.pressed.connect(_on_system_menu_load_pressed)
	menu_box.add_child(main.system_menu_load_button)
	main.system_menu_save_button = _make_system_menu_button()
	main.system_menu_save_button.pressed.connect(_on_system_menu_save_pressed)
	menu_box.add_child(main.system_menu_save_button)
	main.system_menu_options_button = _make_system_menu_button()
	main.system_menu_options_button.pressed.connect(_on_system_menu_options_pressed)
	menu_box.add_child(main.system_menu_options_button)
	main.system_menu_help_button = _make_system_menu_button()
	main.system_menu_help_button.pressed.connect(_on_system_menu_help_pressed)
	menu_box.add_child(main.system_menu_help_button)

func _make_system_menu_button() -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(0.0, MENU_BUTTON_HEIGHT)
	button.focus_mode = Control.FOCUS_ALL
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_menu_button_theme(button)
	return button

func _menu_buttons() -> Array[Button]:
	return [
		main.system_menu_primary_button,
		main.system_menu_return_button,
		main.system_menu_load_button,
		main.system_menu_save_button,
		main.system_menu_options_button,
		main.system_menu_help_button
	]

func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_top = 6
	style.content_margin_right = 12
	style.content_margin_bottom = 6
	return style

func _apply_menu_button_theme(button: Button) -> void:
	if button == null:
		return
	var normal_bg: Color = UI_PALETTE.alpha(UI_PALETTE.SLATE, 0.58)
	var hover_bg: Color = UI_PALETTE.alpha(UI_PALETTE.RUST, 0.78)
	var pressed_bg: Color = UI_PALETTE.alpha(UI_PALETTE.RUST.darkened(0.10), 0.82)
	var disabled_bg: Color = UI_PALETTE.alpha(UI_PALETTE.SLATE.darkened(0.04), 0.36)
	var normal_border: Color = UI_PALETTE.alpha(UI_PALETTE.SLATE.darkened(0.18), 0.92)
	var active_border: Color = UI_PALETTE.alpha(UI_PALETTE.VERMILION, 0.96)
	var disabled_border: Color = UI_PALETTE.alpha(UI_PALETTE.SLATE.darkened(0.20), 0.42)
	button.add_theme_stylebox_override("normal", _button_style(normal_bg, normal_border))
	button.add_theme_stylebox_override("hover", _button_style(hover_bg, active_border))
	button.add_theme_stylebox_override("pressed", _button_style(pressed_bg, active_border))
	button.add_theme_stylebox_override("focus", _button_style(normal_bg, normal_border))
	button.add_theme_stylebox_override("disabled", _button_style(disabled_bg, disabled_border))
	button.add_theme_color_override("font_color", UI_PALETTE.alpha(UI_PALETTE.PAPER, 0.96))
	button.add_theme_color_override("font_hover_color", UI_PALETTE.alpha(UI_PALETTE.PAPER, 1.0))
	button.add_theme_color_override("font_pressed_color", UI_PALETTE.alpha(UI_PALETTE.PAPER, 1.0))
	button.add_theme_color_override("font_focus_color", UI_PALETTE.alpha(UI_PALETTE.PAPER, 0.96))
	button.add_theme_color_override("font_disabled_color", UI_PALETTE.alpha(UI_PALETTE.PAPER, 0.42))
	button.add_theme_font_size_override("font_size", MENU_BUTTON_FONT_SIZE)
	if main.TITLE_FONT_RESOURCE != null:
		button.add_theme_font_override("font", main.TITLE_FONT_RESOURCE)

func _apply_menu_layout_for_state() -> void:
	if main.system_menu_panel == null:
		return
	var is_cover: bool = main.startup_cover_active
	main.system_menu_panel.offset_left = -COVER_PANEL_HALF_WIDTH if is_cover else -MENU_PANEL_HALF_WIDTH
	main.system_menu_panel.offset_right = COVER_PANEL_HALF_WIDTH if is_cover else MENU_PANEL_HALF_WIDTH
	main.system_menu_panel.offset_top = -COVER_PANEL_HALF_HEIGHT if is_cover else -MENU_PANEL_HALF_HEIGHT
	main.system_menu_panel.offset_bottom = COVER_PANEL_HALF_HEIGHT if is_cover else MENU_PANEL_HALF_HEIGHT
	if panel_style != null:
		panel_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.INK, 0.62) if is_cover else UI_PALETTE.alpha(UI_PALETTE.INK, 0.98)
		panel_style.border_color = UI_PALETTE.alpha(UI_PALETTE.SLATE.lightened(0.08), 0.48) if is_cover else UI_PALETTE.alpha(UI_PALETTE.SLATE.lightened(0.12), 0.95)
		panel_style.border_width_left = 0
		panel_style.border_width_top = 0
		panel_style.border_width_right = 0
		panel_style.border_width_bottom = 0
		panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.0)
		panel_style.shadow_size = 0
	if menu_box != null:
		menu_box.add_theme_constant_override("separation", COVER_MENU_BOX_SEPARATION if is_cover else MENU_BOX_SEPARATION)
	main.system_menu_title.custom_minimum_size = Vector2(0.0, 144.0) if is_cover else Vector2.ZERO
	for button in _menu_buttons():
		if button == null:
			continue
		var button_width: float = 0.0
		if is_cover:
			button_width = COVER_PANEL_HALF_WIDTH * 2.0 - 92.0
		else:
			button_width = MENU_PANEL_HALF_WIDTH * 2.0 - 76.0
		button.custom_minimum_size = Vector2(button_width, COVER_MENU_BUTTON_HEIGHT if is_cover else MENU_BUTTON_HEIGHT)
		button.add_theme_font_size_override("font_size", COVER_MENU_BUTTON_FONT_SIZE if is_cover else MENU_BUTTON_FONT_SIZE)

func show_menu(visible: bool) -> void:
	if main.system_menu_overlay == null:
		return
	var was_visible: bool = main.system_menu_overlay.visible
	var child_overlay_was_visible: bool = (main.save_slot_overlay != null and main.save_slot_overlay.visible) or main._audio_options_visible()
	if visible and not was_visible and not main.startup_cover_active:
		main._play_ui_sound("panel_open")
	if main.system_menu_background != null:
		main.system_menu_background.visible = visible and main.startup_cover_active and main.system_menu_background.texture != null
	if visible and main.system_menu_cover != null:
		main.system_menu_cover.color = UI_PALETTE.alpha(UI_PALETTE.INK, 0.38) if main.startup_cover_active and main.system_menu_background != null and main.system_menu_background.texture != null else (UI_PALETTE.alpha(UI_PALETTE.INK, 1.0) if main.startup_cover_active else UI_PALETTE.alpha(UI_PALETTE.INK, 0.84))
	main.system_menu_overlay.visible = visible
	if not visible:
		main._close_save_slot_overlay()
		main._close_audio_options_overlay(false)
		if was_visible and not child_overlay_was_visible:
			main._play_ui_sound("panel_close")
		return
	main.system_menu_overlay.z_index = 4095
	main.system_menu_overlay.get_parent().move_child(main.system_menu_overlay, main.system_menu_overlay.get_parent().get_child_count() - 1)
	var title_font_size: int = COVER_TITLE_FONT_SIZE if main.startup_cover_active else MENU_TITLE_FONT_SIZE
	_apply_menu_layout_for_state()
	main.system_menu_title.add_theme_font_size_override("font_size", title_font_size)
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
	if main.startup_cover_active:
		for button in _menu_buttons():
			if button != null and button.has_focus():
				button.release_focus()
	else:
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
