extends RefCounted
class_name EventUiController

signal refresh_requested
signal target_drop_requested(target_id: String, payload: Dictionary)
signal detail_requested(card_id: String)
signal quick_assign_requested(payload: Dictionary)
signal remove_requested(payload: Dictionary)
signal dialog_focus_requested
signal event_dialog_toggled(event_id: String, expanded: bool)

const CARD_SCENE := preload("res://scenes/CardView.tscn")
const SLOT_SCENE := preload("res://scenes/SlotView.tscn")
const UI_PALETTE := preload("res://scripts/ui/ui_palette.gd")
const CARD_METRICS := preload("res://scripts/ui/card_metrics.gd")
const EVENT_DIALOG_MIN_SIZE := CARD_METRICS.EVENT_DIALOG_MIN_SIZE
const EVENT_DIALOG_MAX_SIZE := CARD_METRICS.EVENT_DIALOG_MAX_SIZE
const LIST_CARD_WIDTH := CARD_METRICS.COMPACT_CARD_WIDTH
const LIST_CARD_HEIGHT := CARD_METRICS.COMPACT_CARD_HEIGHT
const LIST_CARD_ART_HEIGHT := CARD_METRICS.COMPACT_CARD_ART_HEIGHT
const EVENT_DIALOG_BODY_PANEL_HEIGHT := 256.0
const EVENT_DIALOG_BODY_HEIGHT := 224.0
const EVENT_DIALOG_SLOT_PANEL_HEIGHT := 348.0
const EVENT_DIALOG_SLOT_SCROLL_HEIGHT := 272.0
const EVENT_DIALOG_FOOTNOTE_HEIGHT := 56.0

var event_column: VBoxContainer
var event_dialog: PanelContainer
var event_dialog_title: Label
var event_dialog_subtitle: Label
var event_dialog_close_button: Button
var event_dialog_body_panel: PanelContainer
var event_dialog_body: RichTextLabel
var event_dialog_slot_panel: PanelContainer
var event_dialog_slot_title: Label
var event_dialog_slot_scroll: ScrollContainer
var event_dialog_slot_row: HBoxContainer
var event_dialog_footnote: Label

var _event_body_callback: Callable = Callable()
var _event_title_callback: Callable = Callable()
var _event_hint_callback: Callable = Callable()
var _expanded_event_id: String = ""
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _needs_center: bool = false
var _dialog_position: Vector2 = Vector2.ZERO
var _has_dialog_position: bool = false
var _locked_dialog_size: Vector2 = Vector2.ZERO
var _dialog_size_locking: bool = false
var _restore_after_refresh_requested: bool = false
var _dialog_parent: Control
var _dialog_open_token: int = 0

func setup(
	p_event_column: VBoxContainer,
	p_event_dialog: PanelContainer,
	p_event_dialog_title: Label,
	p_event_dialog_subtitle: Label,
	p_event_dialog_body_panel: PanelContainer,
	p_event_dialog_body: RichTextLabel,
	p_event_dialog_slot_panel: PanelContainer,
	p_event_dialog_slot_title: Label,
	p_event_dialog_slot_row: HBoxContainer,
	p_event_dialog_assigned_title: Label,
	p_event_dialog_assigned_row: HBoxContainer,
	p_event_body_callback: Callable,
	p_event_title_callback: Callable = Callable(),
	p_event_hint_callback: Callable = Callable(),
	p_dialog_parent: Control = null
) -> void:
	event_column = p_event_column
	_event_body_callback = p_event_body_callback
	_event_title_callback = p_event_title_callback
	_event_hint_callback = p_event_hint_callback
	_dialog_parent = p_dialog_parent
	if p_event_dialog != null:
		p_event_dialog.visible = false
		p_event_dialog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_runtime_dialog()
	if event_dialog != null and not event_dialog.resized.is_connected(_on_event_dialog_resized):
		event_dialog.resized.connect(_on_event_dialog_resized)

func get_expanded_event_id() -> String:
	return _expanded_event_id

func is_dragging() -> bool:
	return _dragging

func is_dialog_visible() -> bool:
	return event_dialog != null and event_dialog.visible

func get_dialog_control() -> Control:
	return event_dialog

func apply_title_font(font_resource: Font) -> void:
	if font_resource == null or event_dialog_title == null:
		return
	event_dialog_title.add_theme_font_override("font", font_resource)

func apply_body_font_size(font_size: int, line_spacing: int = 4) -> void:
	if font_size <= 0 or event_dialog_body == null:
		return
	event_dialog_body.add_theme_font_size_override("normal_font_size", font_size)
	event_dialog_body.set_meta("body_font_managed", true)
	event_dialog_body.set_meta("normal_font_size_base", font_size)
	event_dialog_body.set_meta("normal_font_size_last_applied", font_size)
	event_dialog_body.add_theme_constant_override("line_separation", line_spacing)
	event_dialog_body.add_theme_constant_override("line_spacing", line_spacing)

func refresh_static_texts() -> void:
	if event_dialog_close_button != null:
		event_dialog_close_button.text = TextDB.get_text("ui.buttons.close")
	if event_dialog_slot_title != null:
		event_dialog_slot_title.text = TextDB.get_text("ui.detail_panel.assignment_title")

func _build_runtime_dialog() -> void:
	if _dialog_parent == null:
		return
	if event_dialog != null and is_instance_valid(event_dialog):
		return
	event_dialog = PanelContainer.new()
	event_dialog.name = "RuntimeEventDialog"
	event_dialog.visible = false
	event_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	event_dialog.set_anchors_preset(Control.PRESET_TOP_LEFT)
	event_dialog.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	event_dialog.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	event_dialog.z_as_relative = true
	event_dialog.z_index = 0
	event_dialog.custom_minimum_size = EVENT_DIALOG_MIN_SIZE
	event_dialog.size = EVENT_DIALOG_MIN_SIZE
	_locked_dialog_size = EVENT_DIALOG_MIN_SIZE
	_dialog_parent.add_child(event_dialog)

	var dialog_style := StyleBoxFlat.new()
	dialog_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.INK, 0.97)
	dialog_style.border_width_left = 2
	dialog_style.border_width_top = 2
	dialog_style.border_width_right = 2
	dialog_style.border_width_bottom = 2
	dialog_style.border_color = UI_PALETTE.alpha(UI_PALETTE.SLATE.lightened(0.10), 0.95)
	dialog_style.corner_radius_top_left = 10
	dialog_style.corner_radius_top_right = 10
	dialog_style.corner_radius_bottom_left = 10
	dialog_style.corner_radius_bottom_right = 10
	dialog_style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	dialog_style.shadow_size = 16
	event_dialog.add_theme_stylebox_override("panel", dialog_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	event_dialog.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0.0, 44.0)
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	header.gui_input.connect(_on_runtime_header_gui_input)
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.RUST, 0.98)
	header_style.border_width_left = 1
	header_style.border_width_top = 1
	header_style.border_width_right = 1
	header_style.border_width_bottom = 1
	header_style.border_color = UI_PALETTE.alpha(UI_PALETTE.VERMILION, 0.95)
	header_style.corner_radius_top_left = 8
	header_style.corner_radius_top_right = 8
	header_style.corner_radius_bottom_left = 8
	header_style.corner_radius_bottom_right = 8
	header.add_theme_stylebox_override("panel", header_style)
	vbox.add_child(header)

	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 8)
	header_margin.add_theme_constant_override("margin_top", 6)
	header_margin.add_theme_constant_override("margin_right", 8)
	header_margin.add_theme_constant_override("margin_bottom", 6)
	header_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(header_margin)

	var header_bar := HBoxContainer.new()
	header_bar.add_theme_constant_override("separation", 8)
	header_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_margin.add_child(header_bar)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_bar.add_child(title_box)

	event_dialog_title = Label.new()
	event_dialog_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_dialog_title.add_theme_font_size_override("font_size", 22)
	event_dialog_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_box.add_child(event_dialog_title)

	event_dialog_subtitle = Label.new()
	event_dialog_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_dialog_subtitle.modulate = UI_PALETTE.alpha(UI_PALETTE.PAPER, 0.84)
	event_dialog_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	event_dialog_subtitle.visible = false
	title_box.add_child(event_dialog_subtitle)

	event_dialog_close_button = Button.new()
	event_dialog_close_button.custom_minimum_size = Vector2(76.0, 32.0)
	event_dialog_close_button.text = TextDB.get_text("ui.buttons.close")
	event_dialog_close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	event_dialog_close_button.pressed.connect(_on_runtime_close_pressed)
	header_bar.add_child(event_dialog_close_button)

	event_dialog_body_panel = PanelContainer.new()
	event_dialog_body_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var body_panel_style := StyleBoxFlat.new()
	body_panel_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.SLATE.darkened(0.20), 0.96)
	body_panel_style.border_width_left = 1
	body_panel_style.border_width_top = 1
	body_panel_style.border_width_right = 1
	body_panel_style.border_width_bottom = 1
	body_panel_style.border_color = UI_PALETTE.alpha(UI_PALETTE.SLATE.lightened(0.08), 0.96)
	body_panel_style.corner_radius_top_left = 8
	body_panel_style.corner_radius_top_right = 8
	body_panel_style.corner_radius_bottom_left = 8
	body_panel_style.corner_radius_bottom_right = 8
	event_dialog_body_panel.add_theme_stylebox_override("panel", body_panel_style)
	event_dialog_body_panel.custom_minimum_size = Vector2(0.0, EVENT_DIALOG_BODY_PANEL_HEIGHT)
	vbox.add_child(event_dialog_body_panel)

	var body_margin := MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 8)
	body_margin.add_theme_constant_override("margin_top", 6)
	body_margin.add_theme_constant_override("margin_right", 8)
	body_margin.add_theme_constant_override("margin_bottom", 6)
	body_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	event_dialog_body_panel.add_child(body_margin)

	event_dialog_body = RichTextLabel.new()
	event_dialog_body.bbcode_enabled = true
	event_dialog_body.fit_content = false
	event_dialog_body.scroll_active = true
	event_dialog_body.custom_minimum_size = Vector2(0.0, EVENT_DIALOG_BODY_HEIGHT)
	event_dialog_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	event_dialog_body.mouse_filter = Control.MOUSE_FILTER_STOP
	event_dialog_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	event_dialog_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	event_dialog_body.set_meta("body_font_managed", true)
	body_margin.add_child(event_dialog_body)

	event_dialog_slot_panel = PanelContainer.new()
	event_dialog_slot_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var slot_panel_style := StyleBoxFlat.new()
	slot_panel_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.INK.darkened(0.08), 0.98)
	slot_panel_style.border_width_left = 1
	slot_panel_style.border_width_top = 1
	slot_panel_style.border_width_right = 1
	slot_panel_style.border_width_bottom = 1
	slot_panel_style.border_color = UI_PALETTE.alpha(UI_PALETTE.SLATE, 0.96)
	slot_panel_style.corner_radius_top_left = 8
	slot_panel_style.corner_radius_top_right = 8
	slot_panel_style.corner_radius_bottom_left = 8
	slot_panel_style.corner_radius_bottom_right = 8
	event_dialog_slot_panel.add_theme_stylebox_override("panel", slot_panel_style)
	event_dialog_slot_panel.custom_minimum_size = Vector2(0.0, EVENT_DIALOG_SLOT_PANEL_HEIGHT)
	vbox.add_child(event_dialog_slot_panel)

	var slot_margin := MarginContainer.new()
	slot_margin.add_theme_constant_override("margin_left", 8)
	slot_margin.add_theme_constant_override("margin_top", 8)
	slot_margin.add_theme_constant_override("margin_right", 8)
	slot_margin.add_theme_constant_override("margin_bottom", 8)
	slot_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	event_dialog_slot_panel.add_child(slot_margin)

	var slot_vbox := VBoxContainer.new()
	slot_vbox.add_theme_constant_override("separation", 6)
	slot_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_margin.add_child(slot_vbox)

	event_dialog_slot_title = Label.new()
	event_dialog_slot_title.add_theme_font_size_override("font_size", 16)
	event_dialog_slot_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_vbox.add_child(event_dialog_slot_title)

	event_dialog_slot_scroll = ScrollContainer.new()
	event_dialog_slot_scroll.custom_minimum_size = Vector2(0.0, EVENT_DIALOG_SLOT_SCROLL_HEIGHT)
	event_dialog_slot_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	event_dialog_slot_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	event_dialog_slot_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	event_dialog_slot_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	event_dialog_slot_scroll.clip_contents = true
	event_dialog_slot_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	slot_vbox.add_child(event_dialog_slot_scroll)

	event_dialog_slot_row = HBoxContainer.new()
	event_dialog_slot_row.add_theme_constant_override("separation", 8)
	event_dialog_slot_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	event_dialog_slot_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	event_dialog_slot_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	event_dialog_slot_scroll.add_child(event_dialog_slot_row)

	event_dialog_footnote = Label.new()
	event_dialog_footnote.custom_minimum_size = Vector2(0.0, EVENT_DIALOG_FOOTNOTE_HEIGHT)
	event_dialog_footnote.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	event_dialog_footnote.modulate = UI_PALETTE.alpha(UI_PALETTE.PAPER, 0.76)
	event_dialog_footnote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_dialog_footnote.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	event_dialog_footnote.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	event_dialog_footnote.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_vbox.add_child(event_dialog_footnote)

func _on_runtime_close_pressed() -> void:
	close_dialog()

func _on_runtime_header_gui_input(event: InputEvent) -> void:
	handle_header_input(event, event_dialog.get_global_mouse_position() if event_dialog != null else Vector2.ZERO)

func remember_dialog_position() -> void:
	if event_dialog == null:
		return
	_dialog_position = event_dialog.position
	_has_dialog_position = true
	_restore_after_refresh_requested = true

func restore_dialog_position_after_refresh(viewport_size: Vector2) -> void:
	if event_dialog == null or not _restore_after_refresh_requested:
		return
	_restore_after_refresh_requested = false
	_needs_center = false
	var dialog_size: Vector2 = _locked_dialog_size if _locked_dialog_size != Vector2.ZERO else (event_dialog.custom_minimum_size if event_dialog.custom_minimum_size != Vector2.ZERO else event_dialog.size)
	_set_dialog_position(_clamp_dialog_position(_dialog_position, viewport_size), dialog_size)
	call_deferred("_deferred_restore_dialog_position", viewport_size)

func toggle_event(event_id: String) -> void:
	if _expanded_event_id == event_id and event_dialog != null and event_dialog.visible:
		close_dialog(false)
	else:
		_expanded_event_id = event_id
		_needs_center = true
		if event_dialog != null:
			event_dialog.visible = false
		emit_signal("dialog_focus_requested")
		emit_signal("event_dialog_toggled", event_id, true)
	emit_signal("refresh_requested")

func close_dialog(emit_refresh: bool = true) -> void:
	var closed_event_id: String = _expanded_event_id
	var was_open: bool = not closed_event_id.is_empty() and event_dialog != null and event_dialog.visible
	_expanded_event_id = ""
	_dragging = false
	_needs_center = false
	_has_dialog_position = false
	_dialog_open_token += 1
	if event_dialog != null:
		event_dialog.visible = false
		event_dialog.modulate = Color.WHITE
		_locked_dialog_size = Vector2.ZERO
		_restore_after_refresh_requested = false
	if was_open:
		emit_signal("event_dialog_toggled", closed_event_id, false)
	if emit_refresh:
		emit_signal("refresh_requested")

func handle_global_input(event: InputEvent, mouse_global_position: Vector2, viewport_size: Vector2) -> void:
	if not _dragging or event_dialog == null:
		return
	if event is InputEventMouseMotion:
		_set_dialog_position(_clamp_dialog_position(mouse_global_position - _drag_offset, viewport_size))
	elif event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			_dragging = false

func handle_header_input(event: InputEvent, mouse_global_position: Vector2) -> void:
	if event_dialog == null:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			emit_signal("dialog_focus_requested")
			_dragging = true
			_drag_offset = mouse_global_position - event_dialog.global_position

func refresh(run_state: RunState, event_defs: Dictionary, board_manager: BoardManager, minimal_mode: bool, viewport_size: Vector2) -> void:
	_refresh_event_list(run_state, event_defs, board_manager, minimal_mode)
	_refresh_event_dialog(run_state, event_defs, board_manager, minimal_mode, viewport_size)

func _refresh_event_list(run_state: RunState, event_defs: Dictionary, board_manager: BoardManager, minimal_mode: bool) -> void:
	if event_column == null:
		return
	for child in event_column.get_children():
		child.queue_free()
	if minimal_mode:
		close_dialog(false)
		return
	if not run_state.active_event_ids.has(_expanded_event_id):
		close_dialog(false)
	for event_id_variant in run_state.active_event_ids:
		var event_id: String = str(event_id_variant)
		if not event_defs.has(event_id):
			continue
		var event_uid: String = "event:%s" % event_id
		if board_manager.is_committed(event_uid):
			if _expanded_event_id == event_id:
				close_dialog(false)
			continue
		var event: EventData = event_defs[event_id] as EventData
		var state: Dictionary = run_state.active_event_states.get(event_id, {})
		var assigned_cards: Array = board_manager.get_event_cards(event_id)
		var event_card: CardView = CARD_SCENE.instantiate()
		var turns_left: int = int(state.get("turns_left", 0))
		event_card.setup(_make_event_icon_payload(event, turns_left, assigned_cards, _expanded_event_id == event_id), true)
		event_card.card_clicked.connect(_on_event_card_clicked)
		event_card.drag_slot_hovered.connect(_on_event_card_drag_hovered)
		event_card.quick_assign_requested.connect(_on_event_quick_assign_requested)
		event_column.add_child(event_card)
	if run_state.active_event_ids.is_empty():
		var label: Label = Label.new()
		label.text = TextDB.get_text("ui.messages.no_events")
		event_column.add_child(label)

func _refresh_event_dialog(run_state: RunState, event_defs: Dictionary, board_manager: BoardManager, minimal_mode: bool, viewport_size: Vector2) -> void:
	if event_dialog == null:
		return
	if minimal_mode or _expanded_event_id.is_empty() or not run_state.active_event_ids.has(_expanded_event_id):
		event_dialog.visible = false
		return
	if board_manager.is_committed("event:%s" % _expanded_event_id):
		event_dialog.visible = false
		return
	var dialog_was_visible: bool = event_dialog.visible
	_configure_event_dialog_layout(viewport_size)
	var event: EventData = event_defs[_expanded_event_id] as EventData
	var state: Dictionary = run_state.active_event_states.get(_expanded_event_id, {})
	event_dialog.visible = true
	event_dialog_title.text = _event_title(event)
	var hint_text: String = _event_hint(event)
	event_dialog_subtitle.text = TextDB.format_text("ui.event_subtitle.expanded", [int(state.get("turns_left", 0))])
	event_dialog_subtitle.visible = false
	event_dialog_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	event_dialog_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	event_dialog_body.text = _format_dialog_body_text(_event_body(event))
	event_dialog_body.scroll_to_line(0)
	_populate_event_dialog_slots(run_state, board_manager, _expanded_event_id, hint_text)
	if event_dialog_footnote != null:
		event_dialog_footnote.text = hint_text if not hint_text.strip_edges().is_empty() else " "
		event_dialog_footnote.visible = true
	_apply_dialog_rect(viewport_size)
	if dialog_was_visible:
		_apply_locked_dialog_size()
	else:
		event_dialog.modulate = Color(1.0, 1.0, 1.0, 0.0)
		_dialog_open_token += 1
		call_deferred("_finalize_event_dialog_open", _dialog_open_token, viewport_size)
	if _needs_center:
		_needs_center = false

func _configure_event_dialog_layout(viewport_size: Vector2) -> void:
	if event_dialog == null or event_dialog_body == null or event_dialog_slot_row == null:
		return
	var dialog_size: Vector2 = EVENT_DIALOG_MIN_SIZE
	_locked_dialog_size = dialog_size
	event_dialog.custom_minimum_size = dialog_size
	event_dialog.size = dialog_size
	event_dialog.update_minimum_size()
	if event_dialog_body_panel != null:
		event_dialog_body_panel.custom_minimum_size = Vector2(0.0, EVENT_DIALOG_BODY_PANEL_HEIGHT)
		event_dialog_body_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		event_dialog_body_panel.update_minimum_size()
	event_dialog_body.fit_content = false
	event_dialog_body.scroll_active = true
	event_dialog_body.clip_contents = true
	event_dialog_body.custom_minimum_size = Vector2(0.0, EVENT_DIALOG_BODY_HEIGHT)
	event_dialog_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	event_dialog_body.update_minimum_size()
	if event_dialog_slot_panel != null:
		event_dialog_slot_panel.custom_minimum_size = Vector2(0.0, EVENT_DIALOG_SLOT_PANEL_HEIGHT)
		event_dialog_slot_panel.size_flags_vertical = Control.SIZE_SHRINK_END
		event_dialog_slot_panel.update_minimum_size()
	event_dialog_slot_title.visible = true
	event_dialog_slot_row.visible = true
	event_dialog_slot_row.custom_minimum_size = Vector2(0.0, LIST_CARD_HEIGHT)
	event_dialog_slot_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	event_dialog_slot_row.size = Vector2(event_dialog_slot_row.size.x, LIST_CARD_HEIGHT)
	event_dialog_slot_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	event_dialog_slot_row.update_minimum_size()
	if event_dialog_slot_scroll != null:
		event_dialog_slot_scroll.custom_minimum_size = Vector2(0.0, EVENT_DIALOG_SLOT_SCROLL_HEIGHT)
	var dialog_margin: Control = event_dialog.get_child(0) as Control
	if dialog_margin != null:
		dialog_margin.update_minimum_size()
	event_dialog.queue_sort()
	event_dialog_slot_title.text = TextDB.get_text("ui.detail_panel.assignment_title")
	_apply_locked_dialog_size()

func _format_dialog_body_text(text: String) -> String:
	var normalized: String = text.replace("\r\n", "\n").replace("\r", "\n").strip_edges()
	if normalized.is_empty():
		return ""
	return "\n" + normalized

func _populate_event_dialog_slots(run_state: RunState, board_manager: BoardManager, event_id: String, hint_text: String = "") -> void:
	if event_dialog_slot_row == null:
		return
	for child in event_dialog_slot_row.get_children():
		child.queue_free()
	event_dialog_slot_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	var state: Dictionary = run_state.active_event_states.get(event_id, {}) as Dictionary
	var slot_types: Array[String] = ["character", "resource"]
	var configured_types: Array = state.get("story_event_slot_types", [])
	if not configured_types.is_empty():
		slot_types.clear()
		for slot_type_variant in configured_types:
			var configured_type: String = str(slot_type_variant)
			if configured_type in ["character", "resource"] and not slot_types.has(configured_type):
				slot_types.append(configured_type)
	var slot_filters: Dictionary = state.get("story_event_slot_filters", {}) as Dictionary
	for slot_type in slot_types:
		var slot_cards: Array = board_manager.get_event_slot_cards(event_id, slot_type)
		var slot_filter: Dictionary = (slot_filters.get(slot_type, {}) as Dictionary).duplicate(true)
		if slot_cards.is_empty():
			var placeholder: SlotView = SLOT_SCENE.instantiate()
			placeholder.custom_minimum_size = Vector2(LIST_CARD_WIDTH, LIST_CARD_HEIGHT)
			placeholder.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			placeholder.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			placeholder.setup(_make_event_slot_payload(run_state, board_manager, event_id, slot_type, slot_filter), true)
			placeholder.target_drop_requested.connect(_on_target_drop_requested)
			event_dialog_slot_row.add_child(placeholder)
		else:
			var card: Dictionary = slot_cards[0] as Dictionary
			var preview: CardView = _build_event_dialog_preview(card, event_id, slot_type, slot_cards, slot_filter)
			preview.custom_minimum_size = Vector2(LIST_CARD_WIDTH, LIST_CARD_HEIGHT)
			preview.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			preview.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			event_dialog_slot_row.add_child(preview)
	event_dialog_slot_row.queue_sort()

func _build_event_dialog_preview(card: Dictionary, event_id: String, slot_type: String, current_cards: Array, slot_filter: Dictionary = {}) -> CardView:
	var preview: CardView = CARD_SCENE.instantiate()
	preview.custom_minimum_size = Vector2(LIST_CARD_WIDTH, LIST_CARD_HEIGHT)
	var payload: Dictionary = card.duplicate(true)
	payload["subtitle"] = ""
	payload["body"] = ""
	payload["compact_details"] = true
	payload["card_width"] = LIST_CARD_WIDTH
	payload["art_height"] = LIST_CARD_ART_HEIGHT
	payload["collapsed_height"] = LIST_CARD_HEIGHT
	payload["expanded_height"] = LIST_CARD_HEIGHT
	payload["show_subtitle_in_compact"] = false
	payload["show_assigned_in_compact"] = false
	payload["assigned"] = true
	payload["removable"] = true
	payload["embedded"] = true
	payload["target_id"] = "%s:%s" % [event_id, slot_type]
	payload["assign_target_id"] = "%s:%s@replace=%s" % [event_id, slot_type, str(card.get("uid", ""))]
	payload["drop_kind"] = "event_%s" % slot_type
	payload["replace_drop_enabled"] = true
	payload["replace_uid"] = str(card.get("uid", ""))
	payload["current_cards"] = current_cards.duplicate(true)
	payload["allowed_card_types"] = slot_filter.get("allowed_card_types", [])
	payload["allowed_card_ids"] = slot_filter.get("allowed_card_ids", [])
	payload["blocked_card_ids"] = slot_filter.get("blocked_card_ids", [])
	payload["required_tags"] = slot_filter.get("required_tags", [])
	preview.setup(payload)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	preview.z_index = 0
	preview.card_clicked.connect(_on_detail_card_clicked)
	preview.remove_requested.connect(_on_card_remove_requested)
	preview.target_drop_requested.connect(_on_target_drop_requested)
	return preview

func _build_event_slot_well(slot_type: String, content: Control) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(LIST_CARD_WIDTH, LIST_CARD_HEIGHT + 22.0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.INK, 0.98)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = UI_PALETTE.alpha(UI_PALETTE.SLATE, 0.96)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", panel_style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	var label: Label = Label.new()
	label.text = TextDB.get_text("ui.event_slots.%s_title" % slot_type)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	box.add_child(label)

	var center: CenterContainer = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.custom_minimum_size = Vector2(LIST_CARD_WIDTH, LIST_CARD_HEIGHT)
	center.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	box.add_child(center)
	content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content.visible = true
	center.add_child(content)
	return panel

func _make_event_slot_payload(run_state: RunState, board_manager: BoardManager, event_id: String, slot_type: String, slot_filter: Dictionary = {}) -> Dictionary:
	var title_key: String = "ui.event_slots.%s_title" % slot_type
	var current_cards: Array = board_manager.get_event_slot_cards(event_id, slot_type)
	var prompt_text: String = _event_slot_prompt(run_state, event_id, slot_type, slot_filter)
	var tooltip_lines: Array[String] = [TextDB.get_text(title_key)]
	if not prompt_text.strip_edges().is_empty() and prompt_text != TextDB.get_text(title_key):
		tooltip_lines.append(prompt_text.replace("\n", " / "))
	return {
		"id": "%s:%s" % [event_id, slot_type],
		"target_id": "%s:%s" % [event_id, slot_type],
		"drop_kind": "event_%s" % slot_type,
		"card_type": "slot",
		"title": TextDB.get_text(title_key),
		"subtitle": "",
		"body": "",
		"assigned_text": "",
		"image_path": "",
		"image_label": prompt_text,
		"tooltip_text": "\n".join(tooltip_lines),
		"art_label_font_size": 16 if prompt_text.contains("\n") else 18,
		"art_label_color": UI_PALETTE.alpha(UI_PALETTE.PAPER, 0.94),
		"art_bg_color": UI_PALETTE.alpha(UI_PALETTE.SLATE.darkened(0.28), 1.0),
		"color": UI_PALETTE.alpha(UI_PALETTE.INK.darkened(0.08), 0.98),
		"compact_details": true,
		"hide_title": true,
		"hide_subtitle": true,
		"hide_assigned": true,
		"hide_body": true,
		"drop_slot": true,
		"embedded": true,
		"card_width": LIST_CARD_WIDTH,
		"art_height": LIST_CARD_ART_HEIGHT,
		"current_cards": current_cards,
		"allowed_card_types": slot_filter.get("allowed_card_types", []),
		"allowed_card_ids": slot_filter.get("allowed_card_ids", []),
		"blocked_card_ids": slot_filter.get("blocked_card_ids", []),
		"required_tags": slot_filter.get("required_tags", []),
		"collapsed_height": LIST_CARD_HEIGHT,
		"expanded_height": LIST_CARD_HEIGHT
	}

func _event_slot_prompt(run_state: RunState, event_id: String, slot_type: String, slot_filter: Dictionary) -> String:
	if run_state == null:
		return TextDB.get_text("ui.event_slots.%s_title" % slot_type)
	match slot_type:
		"character":
			var character_ids: Array[String] = []
			for character_id_variant in slot_filter.get("allowed_card_ids", []):
				character_ids.append(str(character_id_variant))
			if not character_ids.is_empty():
				return "\n".join(_character_names(character_ids))
			return TextDB.get_text("ui.event_slots.character_title")
		"resource":
			var state: Dictionary = run_state.active_event_states.get(event_id, {}) as Dictionary
			var required_resources: Dictionary = state.get("story_event_required_resources", {}) as Dictionary
			if not required_resources.is_empty():
				var lines: Array[String] = []
				for resource_id_variant in required_resources.keys():
					var resource_id: String = str(resource_id_variant)
					lines.append("%s ×%d" % [TextDB.get_text("resources.%s.name" % resource_id, resource_id), int(required_resources.get(resource_id, 0))])
				return "\n".join(lines)
			var resource_ids: Array[String] = []
			for resource_id_variant in slot_filter.get("allowed_card_ids", []):
				resource_ids.append(str(resource_id_variant))
			if resource_ids.is_empty():
				for resource_id_variant in state.get("story_event_allowed_resource_ids", []):
					resource_ids.append(str(resource_id_variant))
			if not resource_ids.is_empty():
				return "\n".join(_resource_names(resource_ids))
			return TextDB.get_text("ui.event_slots.resource_title")
		_:
			return TextDB.get_text("ui.event_slots.%s_title" % slot_type, slot_type)

func _character_names(character_ids: Array[String]) -> Array[String]:
	var names: Array[String] = []
	for character_id in character_ids:
		names.append(TextDB.get_text("characters.%s.name" % character_id, character_id))
	return names

func _resource_names(resource_ids: Array[String]) -> Array[String]:
	var names: Array[String] = []
	for resource_id in resource_ids:
		names.append(TextDB.get_text("resources.%s.name" % resource_id, resource_id))
	return names

func _make_event_icon_payload(event: EventData, turns_left: int, _assigned_cards: Array, expanded: bool) -> Dictionary:
	var art_color: Color = UI_PALETTE.SLATE.darkened(0.10) if not expanded else UI_PALETTE.SLATE
	var panel_color: Color = UI_PALETTE.INK if not expanded else UI_PALETTE.INK.lightened(0.08)
	return {
		"uid": "event:%s" % event.id,
		"id": event.id,
		"card_type": "event",
		"title": event.title,
		"subtitle": "",
		"body": event.description,
		"tags": event.tags,
		"assigned_text": "",
		"badge_text": "" if turns_left <= 0 else str(turns_left),
		"image_path": event.art_path,
		"image_label": event.title,
		"art_bg_color": art_color,
		"color": panel_color,
		"compact_details": true,
		"show_subtitle_in_compact": false,
		"show_assigned_in_compact": false,
		"hide_body": true,
		"locked": false,
		"card_width": LIST_CARD_WIDTH,
		"art_height": LIST_CARD_ART_HEIGHT,
		"collapsed_height": LIST_CARD_HEIGHT,
		"expanded_height": LIST_CARD_HEIGHT
	}

func _slot_badge_text(count: int, max_count: int = 0) -> String:
	if max_count > 0:
		return TextDB.format_text("ui.slot_badge.count_max", [count, max_count])
	if count <= 0:
		return TextDB.get_text("ui.slot_badge.empty")
	return TextDB.format_text("ui.slot_badge.count", [count])

func _event_body(event: EventData) -> String:
	if _event_body_callback.is_valid():
		return str(_event_body_callback.call(event))
	return event.description

func _event_title(event: EventData) -> String:
	if _event_title_callback.is_valid():
		return str(_event_title_callback.call(event))
	return event.title

func _event_hint(event: EventData) -> String:
	if _event_hint_callback.is_valid():
		return str(_event_hint_callback.call(event))
	return ""

func _center_event_dialog(viewport_size: Vector2) -> void:
	_apply_dialog_rect(viewport_size)

func _apply_dialog_rect(viewport_size: Vector2) -> void:
	if event_dialog == null:
		return
	var dialog_size: Vector2 = event_dialog.custom_minimum_size if event_dialog.custom_minimum_size != Vector2.ZERO else event_dialog.size
	var position: Vector2 = _dialog_position if _has_dialog_position else event_dialog.position
	var should_center: bool = _needs_center or not event_dialog.visible or not _has_dialog_position
	if should_center:
		position = Vector2((viewport_size.x - dialog_size.x) * 0.5, (viewport_size.y - dialog_size.y) * 0.5)
	position = _clamp_dialog_position(position, viewport_size)
	_set_dialog_position(position, dialog_size)

func _set_dialog_position(position: Vector2, dialog_size: Vector2 = Vector2.ZERO) -> void:
	if event_dialog == null:
		return
	var applied_size: Vector2 = dialog_size if dialog_size != Vector2.ZERO else (event_dialog.custom_minimum_size if event_dialog.custom_minimum_size != Vector2.ZERO else event_dialog.size)
	_dialog_position = position
	_has_dialog_position = true
	event_dialog.position = position
	event_dialog.size = applied_size

func _apply_locked_dialog_size() -> void:
	if event_dialog == null or _locked_dialog_size == Vector2.ZERO:
		return
	_dialog_size_locking = true
	event_dialog.custom_minimum_size = _locked_dialog_size
	event_dialog.size = _locked_dialog_size
	_dialog_size_locking = false

func _on_event_dialog_resized() -> void:
	if _dialog_size_locking or event_dialog == null or not event_dialog.visible or _locked_dialog_size == Vector2.ZERO:
		return
	if absf(event_dialog.size.x - _locked_dialog_size.x) <= 0.5 and absf(event_dialog.size.y - _locked_dialog_size.y) <= 0.5:
		return
	_apply_locked_dialog_size()

func _deferred_restore_dialog_position(viewport_size: Vector2) -> void:
	if event_dialog == null or not event_dialog.visible:
		return
	_needs_center = false
	var dialog_size: Vector2 = _locked_dialog_size if _locked_dialog_size != Vector2.ZERO else (event_dialog.custom_minimum_size if event_dialog.custom_minimum_size != Vector2.ZERO else event_dialog.size)
	_set_dialog_position(_clamp_dialog_position(_dialog_position, viewport_size), dialog_size)

func _finalize_event_dialog_open(token: int, viewport_size: Vector2) -> void:
	if event_dialog == null or not event_dialog.visible or token != _dialog_open_token:
		return
	_apply_locked_dialog_size()
	_apply_dialog_rect(viewport_size)
	await event_dialog.get_tree().process_frame
	if event_dialog == null or not event_dialog.visible or token != _dialog_open_token:
		return
	_apply_locked_dialog_size()
	_apply_dialog_rect(viewport_size)
	await event_dialog.get_tree().process_frame
	if event_dialog == null or not event_dialog.visible or token != _dialog_open_token:
		return
	_apply_locked_dialog_size()
	_apply_dialog_rect(viewport_size)
	event_dialog.modulate = Color.WHITE

func _clamp_dialog_position(position: Vector2, viewport_size: Vector2) -> Vector2:
	if event_dialog == null:
		return position
	var dialog_size: Vector2 = event_dialog.size if event_dialog.size != Vector2.ZERO else event_dialog.custom_minimum_size
	return Vector2(
		clampf(position.x, 0.0, maxf(0.0, viewport_size.x - dialog_size.x)),
		clampf(position.y, 0.0, maxf(0.0, viewport_size.y - dialog_size.y))
	)

func _on_event_quick_assign_requested(payload: Dictionary) -> void:
	emit_signal("quick_assign_requested", payload)

func _on_event_card_clicked(event_id: String) -> void:
	toggle_event(event_id)

func _on_event_card_drag_hovered(event_id: String, _payload: Dictionary) -> void:
	if event_id.is_empty() or _expanded_event_id == event_id:
		return
	_expanded_event_id = event_id
	_needs_center = true
	if event_dialog != null:
		event_dialog.visible = false
	emit_signal("dialog_focus_requested")
	emit_signal("event_dialog_toggled", event_id, true)
	emit_signal("refresh_requested")

func _on_target_drop_requested(target_id: String, payload: Dictionary) -> void:
	emit_signal("target_drop_requested", target_id, payload)

func _on_detail_card_clicked(card_id: String) -> void:
	emit_signal("detail_requested", card_id)

func _on_card_remove_requested(payload: Dictionary) -> void:
	emit_signal("remove_requested", payload)
