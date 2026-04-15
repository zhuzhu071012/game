extends Node
class_name StoryEventController

const UI_PALETTE := preload("res://scripts/ui/ui_palette.gd")

signal sequence_finished

var main
var hovered_plan_id: String = ""
var hovered_plan_button: Button = null

func setup(main_node) -> void:
	main = main_node

func build_if_needed() -> void:
	if main.story_event_overlay != null:
		return
	main.story_event_overlay = Control.new()
	main.story_event_overlay.name = "StoryEventOverlay"
	main.story_event_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.story_event_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	main.story_event_overlay.z_as_relative = false
	main.story_event_overlay.z_index = 1012
	main.story_event_overlay.visible = false
	main.add_child(main.story_event_overlay)
	var shade := ColorRect.new()
	shade.name = "StoryEventShade"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = UI_PALETTE.alpha(UI_PALETTE.INK, 0.74)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.story_event_overlay.add_child(shade)
	var center := MarginContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.add_theme_constant_override("margin_left", 42)
	center.add_theme_constant_override("margin_top", 36)
	center.add_theme_constant_override("margin_right", 42)
	center.add_theme_constant_override("margin_bottom", 36)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.story_event_overlay.add_child(center)
	main.story_event_panel = PanelContainer.new()
	main.story_event_panel.custom_minimum_size = main.POPUP_DETAIL_SIZE
	main.story_event_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main.story_event_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.INK, 0.98)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = UI_PALETTE.alpha(UI_PALETTE.SLATE.lightened(0.10), 0.95)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.shadow_size = 20
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	main.story_event_panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(main.story_event_panel)
	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 18)
	panel_margin.add_theme_constant_override("margin_top", 18)
	panel_margin.add_theme_constant_override("margin_right", 18)
	panel_margin.add_theme_constant_override("margin_bottom", 18)
	main.story_event_panel.add_child(panel_margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel_margin.add_child(box)
	main.story_event_title = Label.new()
	main.story_event_title.add_theme_font_size_override("font_size", 30)
	main.story_event_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(main.story_event_title)
	main.story_event_subtitle = Label.new()
	main.story_event_subtitle.modulate = UI_PALETTE.alpha(UI_PALETTE.PAPER, 0.82)
	main.story_event_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	main.story_event_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main.story_event_subtitle.visible = false
	box.add_child(main.story_event_subtitle)
	var body_panel := MarginContainer.new()
	body_panel.custom_minimum_size = Vector2(0.0, 248.0)
	body_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(body_panel)
	var body_margin := MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 18)
	body_margin.add_theme_constant_override("margin_top", 12)
	body_margin.add_theme_constant_override("margin_right", 18)
	body_margin.add_theme_constant_override("margin_bottom", 12)
	body_panel.add_child(body_margin)
	main.story_event_body = RichTextLabel.new()
	main.story_event_body.bbcode_enabled = true
	main.story_event_body.fit_content = false
	main.story_event_body.scroll_active = false
	main.story_event_body.custom_minimum_size = Vector2(0.0, 220.0)
	main.story_event_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_margin.add_child(main.story_event_body)
	var plan_center := CenterContainer.new()
	plan_center.custom_minimum_size = Vector2(0.0, 188.0)
	plan_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plan_center.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(plan_center)
	var plan_box := VBoxContainer.new()
	plan_box.add_theme_constant_override("separation", 10)
	plan_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	plan_center.add_child(plan_box)
	main.story_event_plan_list = VBoxContainer.new()
	main.story_event_plan_list.add_theme_constant_override("separation", 10)
	main.story_event_plan_list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	plan_box.add_child(main.story_event_plan_list)
	main.story_event_plan_summary = Label.new()
	main.story_event_plan_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main.story_event_plan_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.story_event_plan_summary.modulate = UI_PALETTE.alpha(UI_PALETTE.PAPER, 0.86)
	main.story_event_plan_summary.visible = false
	plan_box.add_child(main.story_event_plan_summary)
	main._set_rich_text_layout(main.story_event_body, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP)
	_refresh_overlay_chrome()

func start_sequence(report_payload: Dictionary) -> bool:
	if main.story_event_manager == null or main.run_state == null or not main.story_event_manager.has_pending_events(main.run_state):
		return false
	if not main.story_event_manager.current_event_requires_choice(main.run_state):
		return false
	if main.story_event_overlay == null:
		build_if_needed()
	main.pending_story_event_report_payload = report_payload.duplicate(true)
	main.story_event_active = true
	main.story_event_total_count = main.story_event_manager.pending_count(main.run_state)
	main.story_event_current_index = 1
	main.detail_overlay.visible = false
	main._configure_popup_for_detail()
	prepare_current_event()
	main._play_ui_sound("panel_open")
	return true

func resume_after_load() -> void:
	if main.story_event_manager == null or main.run_state == null or not main.story_event_manager.has_pending_events(main.run_state):
		return
	if not main.story_event_manager.current_event_requires_choice(main.run_state):
		return
	start_sequence({
		"turn_index": main.run_state.turn_index,
		"logs": [],
		"title": "",
		"subtitle": "",
		"body": "",
		"show_report": false
	})
func prepare_current_event() -> void:
	main.story_event_display_event = main.story_event_manager.build_current_event_view(main.run_state)
	main.story_event_selected_plan_id = ""
	hovered_plan_id = ""
	hovered_plan_button = null
	main.story_event_selected_character_id = ""
	main.story_event_resource_allocations.clear()
	main.story_event_result_visible = false
	main.story_event_result_text = ""
	main._clear_story_event_attribute_preview()
	refresh_ui()

func finish_sequence() -> void:
	main.story_event_active = false
	hovered_plan_id = ""
	hovered_plan_button = null
	main.story_event_selected_plan_id = ""
	main.story_event_selected_character_id = ""
	main.story_event_resource_allocations.clear()
	main.story_event_result_visible = false
	main.story_event_result_text = ""
	main.story_event_display_event.clear()
	if main.story_event_overlay != null:
		main.story_event_overlay.visible = false
	main._clear_story_event_attribute_preview()
	var payload: Dictionary = main.pending_story_event_report_payload.duplicate(true)
	main.pending_story_event_report_payload.clear()
	sequence_finished.emit()
	if payload.is_empty():
		return
	if bool(payload.get("show_report", false)):
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

func plan_info_text(event_id: String, plan_id: String) -> String:
	if main.story_event_manager == null or event_id.is_empty() or plan_id.is_empty():
		return TextDB.get_text("story_events.ui.plan_choice_hint")
	var lines: Array[String] = []
	var summary: String = main.story_event_manager.plan_summary(event_id, plan_id)
	if not summary.strip_edges().is_empty():
		lines.append(summary)
	lines.append(TextDB.format_text("story_events.ui.board_requirements", [main.story_event_manager.board_requirement_text(event_id, plan_id)]))
	lines.append(TextDB.get_text("story_events.ui.plan_choice_hint"))
	return "\n\n".join(lines)

func refresh_ui() -> void:
	if main.story_event_overlay == null:
		return
	if not main.story_event_active:
		main.story_event_overlay.visible = false
		return
	if main.story_event_display_event.is_empty():
		main.story_event_display_event = main.story_event_manager.build_current_event_view(main.run_state)
	if main.story_event_display_event.is_empty():
		finish_sequence()
		return
	main.story_event_overlay.visible = true
	_refresh_overlay_chrome()
	var event_view: Dictionary = main.story_event_display_event
	var plans: Array = event_view.get("plans", []) as Array
	if not hovered_plan_id.is_empty():
		var hover_still_valid: bool = false
		for plan_variant in plans:
			var hover_plan: Dictionary = plan_variant as Dictionary
			if str(hover_plan.get("id", "")) == hovered_plan_id:
				hover_still_valid = true
				break
		if not hover_still_valid:
			hovered_plan_id = ""
	if main.story_event_selected_plan_id.is_empty() and not plans.is_empty():
		main.story_event_selected_plan_id = str((plans[0] as Dictionary).get("id", ""))
	main.story_event_title.text = str(event_view.get("title", TextDB.get_text("story_events.ui.title")))
	var subtitle_parts: Array[String] = []
	for tag_variant in event_view.get("tags", []) as Array:
		subtitle_parts.append(str(tag_variant))
	var remaining_turns: int = int(event_view.get("remaining_turns", 1))
	if remaining_turns > 0:
		subtitle_parts.append(TextDB.format_text("story_events.ui.turn_limit", [remaining_turns]))
	subtitle_parts.append(TextDB.format_text("story_events.ui.queue_progress", [main.story_event_current_index, main.story_event_total_count]))
	main.story_event_subtitle.text = " / ".join(subtitle_parts)
	main.story_event_subtitle.visible = false
	main.story_event_body.text = main._format_event_description_body(str(event_view.get("description", "")))
	main.story_event_body.scroll_to_line(0)
	for child in main.story_event_plan_list.get_children():
		child.queue_free()
	hovered_plan_button = null
	for plan_variant in plans:
		var plan: Dictionary = plan_variant as Dictionary
		var plan_id: String = str(plan.get("id", ""))
		var button := Button.new()
		button.custom_minimum_size = Vector2(main.POPUP_DETAIL_SIZE.x - 250.0, 58.0)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.text = str(plan.get("title", plan_id))
		_apply_plan_button_style(button, false)
		button.pressed.connect(on_plan_pressed.bind(plan_id))
		button.mouse_entered.connect(_on_plan_hovered.bind(plan_id, button))
		button.mouse_exited.connect(_on_plan_unhovered.bind(plan_id, button))
		main.story_event_plan_list.add_child(button)
	main.story_event_plan_summary.visible = false
	_refresh_preview_panel(plans)
	main._apply_global_text_adjustments(main.story_event_overlay)

func is_active() -> bool:
	return main.story_event_active

func on_plan_pressed(plan_id: String) -> void:
	main.story_event_selected_plan_id = plan_id
	hovered_plan_id = ""
	if hovered_plan_button != null:
		_apply_plan_button_style(hovered_plan_button, false)
	hovered_plan_button = null
	main._clear_story_event_attribute_preview()
	on_confirm_pressed()

func on_confirm_pressed() -> void:
	if not main.story_event_active or main.story_event_manager == null or main.story_event_selected_plan_id.is_empty():
		return
	var result: Dictionary = main.story_event_manager.commit_current_event_plan(main.run_state, main.story_event_selected_plan_id)
	if not bool(result.get("ok", false)):
		refresh_ui()
		return
	if bool(result.get("instant_resolved", false)):
		var payload_logs: Array = main.pending_story_event_report_payload.get("logs", []) as Array
		for line_variant in result.get("report_lines", []) as Array:
			var line: String = str(line_variant)
			payload_logs.append(line)
			main.run_state.log_entries.append(line)
		main.pending_story_event_report_payload["logs"] = payload_logs.duplicate(true)
		main._refresh_board()
		main._save_system_game()
		main._play_ui_sound("confirm")
		finish_sequence()
		return
	main.story_event_manager.sync_active_board_events(main.run_state, main.events)
	var log_line: String = TextDB.format_text("story_events.logs.committed", [str(main.story_event_display_event.get("title", "")), str(result.get("plan_title", ""))])
	var payload_logs: Array = main.pending_story_event_report_payload.get("logs", []) as Array
	payload_logs.append(log_line)
	main.pending_story_event_report_payload["logs"] = payload_logs.duplicate(true)
	main.run_state.log_entries.append(log_line)
	main._refresh_board()
	main._save_system_game()
	main._play_ui_sound("confirm")
	finish_sequence()

func on_continue_pressed() -> void:
	finish_sequence()

func _refresh_preview_panel(plans: Array) -> void:
	if hovered_plan_id.is_empty():
		main._clear_story_event_attribute_preview()
		return
	for plan_variant in plans:
		var plan: Dictionary = plan_variant as Dictionary
		if str(plan.get("id", "")) != hovered_plan_id:
			continue
		main._set_story_event_attribute_preview(plan.get("camp_preview", {}) as Dictionary)
		return
	main._clear_story_event_attribute_preview()

func _apply_plan_button_style(button: Button, highlighted: bool) -> void:
	if button == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = UI_PALETTE.alpha(UI_PALETTE.INK.lightened(0.02), 0.92)
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	if highlighted:
		style.bg_color = UI_PALETTE.alpha(UI_PALETTE.SAGE.darkened(0.18), 0.98)
		style.border_color = UI_PALETTE.alpha(UI_PALETTE.SAGE.lightened(0.18), 0.98)
	else:
		style.border_color = UI_PALETTE.alpha(UI_PALETTE.SLATE, 0.90)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	button.add_theme_color_override("font_color", UI_PALETTE.alpha(UI_PALETTE.PAPER, 1.0) if highlighted else UI_PALETTE.alpha(UI_PALETTE.PAPER, 0.92))

func _on_plan_hovered(plan_id: String, button: Button) -> void:
	if hovered_plan_button != null and hovered_plan_button != button:
		_apply_plan_button_style(hovered_plan_button, false)
	hovered_plan_button = button
	_apply_plan_button_style(button, true)
	hovered_plan_id = plan_id
	_refresh_preview_panel(main.story_event_display_event.get("plans", []) as Array)

func _on_plan_unhovered(plan_id: String, button: Button) -> void:
	_apply_plan_button_style(button, false)
	if hovered_plan_button == button:
		hovered_plan_button = null
	if hovered_plan_id != plan_id:
		return
	hovered_plan_id = ""
	_refresh_preview_panel(main.story_event_display_event.get("plans", []) as Array)

func _refresh_overlay_chrome() -> void:
	if main == null or main.story_event_overlay == null:
		return
	var shade: ColorRect = main.story_event_overlay.get_node_or_null("StoryEventShade") as ColorRect
	if shade == null or main.top_bar_panel == null:
		return
	var overlay_rect: Rect2 = main.get_global_rect()
	var top_bar_rect: Rect2 = main.top_bar_panel.get_global_rect()
	var clear_until: float = maxf(0.0, top_bar_rect.position.y + top_bar_rect.size.y - overlay_rect.position.y + 8.0)
	shade.offset_top = clear_until
