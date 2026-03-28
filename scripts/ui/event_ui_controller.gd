extends RefCounted
class_name EventUiController

signal refresh_requested
signal target_drop_requested(target_id: String, payload: Dictionary)
signal detail_requested(card_id: String)
signal remove_requested(payload: Dictionary)
signal dialog_focus_requested

const CARD_SCENE := preload("res://scenes/CardView.tscn")
const SLOT_SCENE := preload("res://scenes/SlotView.tscn")
const EVENT_DIALOG_MIN_SIZE := Vector2(580.0, 386.0)
const EVENT_DIALOG_MAX_SIZE := Vector2(700.0, 468.0)
const LIST_CARD_WIDTH := 120.0
const LIST_CARD_HEIGHT := 160.0
const LIST_CARD_ART_HEIGHT := 116.0

var event_column: VBoxContainer
var event_dialog: PanelContainer
var event_dialog_title: Label
var event_dialog_subtitle: Label
var event_dialog_body_panel: PanelContainer
var event_dialog_body: RichTextLabel
var event_dialog_slot_panel: PanelContainer
var event_dialog_slot_title: Label
var event_dialog_slot_row: HBoxContainer
var event_dialog_assigned_title: Label
var event_dialog_assigned_row: HBoxContainer

var _event_body_callback: Callable = Callable()
var _expanded_event_id: String = ""
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _needs_center: bool = false

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
	p_event_body_callback: Callable
) -> void:
	event_column = p_event_column
	event_dialog = p_event_dialog
	event_dialog_title = p_event_dialog_title
	event_dialog_subtitle = p_event_dialog_subtitle
	event_dialog_body_panel = p_event_dialog_body_panel
	event_dialog_body = p_event_dialog_body
	event_dialog_slot_panel = p_event_dialog_slot_panel
	event_dialog_slot_title = p_event_dialog_slot_title
	event_dialog_slot_row = p_event_dialog_slot_row
	event_dialog_assigned_title = p_event_dialog_assigned_title
	event_dialog_assigned_row = p_event_dialog_assigned_row
	_event_body_callback = p_event_body_callback

func get_expanded_event_id() -> String:
	return _expanded_event_id

func is_dragging() -> bool:
	return _dragging

func toggle_event(event_id: String) -> void:
	if _expanded_event_id == event_id and event_dialog != null and event_dialog.visible:
		close_dialog(false)
	else:
		_expanded_event_id = event_id
		_needs_center = true
		if event_dialog != null:
			event_dialog.visible = false
			event_dialog.size = Vector2.ZERO
		emit_signal("dialog_focus_requested")
	emit_signal("refresh_requested")

func close_dialog(emit_refresh: bool = true) -> void:
	_expanded_event_id = ""
	_dragging = false
	_needs_center = false
	if event_dialog != null:
		event_dialog.visible = false
	if emit_refresh:
		emit_signal("refresh_requested")

func handle_global_input(event: InputEvent, mouse_global_position: Vector2, viewport_size: Vector2) -> void:
	if not _dragging or event_dialog == null:
		return
	if event is InputEventMouseMotion:
		event_dialog.position = _clamp_dialog_position(mouse_global_position - _drag_offset, viewport_size)
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
		event_card.setup(_make_event_icon_payload(event, turns_left, assigned_cards, _expanded_event_id == event_id))
		event_card.card_clicked.connect(_on_event_card_clicked)
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
	_configure_event_dialog_layout(viewport_size)
	var event: EventData = event_defs[_expanded_event_id] as EventData
	var state: Dictionary = run_state.active_event_states.get(_expanded_event_id, {})
	event_dialog.visible = true
	event_dialog_title.text = event.title
	event_dialog_subtitle.text = TextDB.format_text("ui.event_subtitle.expanded", [int(state.get("turns_left", 0))])
	event_dialog_body.text = _event_body(event)
	_populate_event_dialog_slots(board_manager, _expanded_event_id)
	event_dialog_assigned_title.visible = false
	event_dialog_assigned_row.visible = false
	_apply_dialog_rect(viewport_size)
	if _needs_center:
		_needs_center = false

func _configure_event_dialog_layout(viewport_size: Vector2) -> void:
	if event_dialog == null or event_dialog_body == null or event_dialog_slot_row == null:
		return
	var dialog_width: float = clampf(viewport_size.x * 0.42, EVENT_DIALOG_MIN_SIZE.x, EVENT_DIALOG_MAX_SIZE.x)
	var body_height: float = clampf(dialog_width * 0.18, 96.0, 126.0)
	var slot_height: float = LIST_CARD_HEIGHT
	var slot_panel_height: float = LIST_CARD_HEIGHT + 28.0
	var body_panel_height: float = body_height + 12.0
	var required_height: float = 44.0 + body_panel_height + slot_panel_height + 36.0
	var dialog_height: float = maxf(dialog_width * 0.60, required_height)
	var max_height: float = maxf(required_height, viewport_size.y - 220.0)
	if dialog_height > max_height:
		dialog_height = max_height
		dialog_width = clampf(dialog_height / 0.60, EVENT_DIALOG_MIN_SIZE.x, EVENT_DIALOG_MAX_SIZE.x)
	var dialog_size: Vector2 = Vector2(dialog_width, dialog_height)
	event_dialog.custom_minimum_size = dialog_size
	event_dialog.size = dialog_size
	event_dialog.update_minimum_size()
	if event_dialog_body_panel != null:
		event_dialog_body_panel.custom_minimum_size = Vector2(0.0, body_panel_height)
		event_dialog_body_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		event_dialog_body_panel.update_minimum_size()
	event_dialog_body.fit_content = false
	event_dialog_body.scroll_active = true
	event_dialog_body.clip_contents = true
	event_dialog_body.custom_minimum_size = Vector2(0.0, body_height)
	event_dialog_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	event_dialog_body.size = Vector2(event_dialog_body.size.x, body_height)
	event_dialog_body.update_minimum_size()
	if event_dialog_slot_panel != null:
		event_dialog_slot_panel.custom_minimum_size = Vector2(0.0, slot_panel_height)
		event_dialog_slot_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		event_dialog_slot_panel.update_minimum_size()
	event_dialog_slot_title.visible = true
	event_dialog_slot_row.visible = true
	event_dialog_slot_row.custom_minimum_size = Vector2(0.0, slot_height)
	event_dialog_slot_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	event_dialog_slot_row.size = Vector2(event_dialog_slot_row.size.x, slot_height)
	event_dialog_slot_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	event_dialog_slot_row.update_minimum_size()
	var dialog_margin: Control = event_dialog.get_child(0) as Control
	if dialog_margin != null:
		dialog_margin.update_minimum_size()
	event_dialog.queue_sort()
	event_dialog_slot_title.text = TextDB.get_text("ui.detail_panel.assignment_title")
	event_dialog_assigned_title.visible = false
	event_dialog_assigned_row.visible = false

func _populate_event_dialog_slots(board_manager: BoardManager, event_id: String) -> void:
	if event_dialog_slot_row == null:
		return
	for child in event_dialog_slot_row.get_children():
		child.queue_free()
	event_dialog_slot_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	for slot_type in ["character", "resource"]:
		var slot_cards: Array = board_manager.get_event_slot_cards(event_id, slot_type)
		if slot_cards.is_empty():
			var placeholder: SlotView = SLOT_SCENE.instantiate()
			placeholder.custom_minimum_size = Vector2(LIST_CARD_WIDTH, LIST_CARD_HEIGHT)
			placeholder.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			placeholder.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			placeholder.setup(_make_event_slot_payload(board_manager, event_id, slot_type), true)
			placeholder.target_drop_requested.connect(_on_target_drop_requested)
			event_dialog_slot_row.add_child(placeholder)
		else:
			var card: Dictionary = slot_cards[0] as Dictionary
			var preview: CardView = _build_event_dialog_preview(card)
			preview.custom_minimum_size = Vector2(LIST_CARD_WIDTH, LIST_CARD_HEIGHT)
			preview.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			preview.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			event_dialog_slot_row.add_child(preview)
	event_dialog_slot_row.queue_sort()

func _build_event_dialog_preview(card: Dictionary) -> CardView:
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
	preview.setup(payload)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	preview.z_index = 0
	preview.card_clicked.connect(_on_detail_card_clicked)
	preview.remove_requested.connect(_on_card_remove_requested)
	return preview

func _build_event_slot_well(slot_type: String, content: Control) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(LIST_CARD_WIDTH, LIST_CARD_HEIGHT + 22.0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.06, 0.98)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.24, 0.26, 0.30, 0.96)
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

	var slot_frame: PanelContainer = PanelContainer.new()
	slot_frame.custom_minimum_size = Vector2(LIST_CARD_WIDTH, LIST_CARD_HEIGHT)
	slot_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var slot_style: StyleBoxFlat = StyleBoxFlat.new()
	slot_style.bg_color = Color(0.01, 0.01, 0.02, 1.0)
	slot_style.border_width_left = 1
	slot_style.border_width_top = 1
	slot_style.border_width_right = 1
	slot_style.border_width_bottom = 1
	slot_style.border_color = Color(0.32, 0.34, 0.38, 0.92)
	slot_style.corner_radius_top_left = 6
	slot_style.corner_radius_top_right = 6
	slot_style.corner_radius_bottom_left = 6
	slot_style.corner_radius_bottom_right = 6
	slot_frame.add_theme_stylebox_override("panel", slot_style)
	box.add_child(slot_frame)

	var center: CenterContainer = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot_frame.add_child(center)
	content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content.visible = true
	center.add_child(content)
	return panel

func _make_event_slot_payload(board_manager: BoardManager, event_id: String, slot_type: String) -> Dictionary:
	var title_key: String = "ui.event_slots.%s_title" % slot_type
	var body_key: String = "ui.event_slots.%s_body" % slot_type
	var current_cards: Array = board_manager.get_event_slot_cards(event_id, slot_type)
	var palette: Dictionary = {
		"panel": Color(0.08, 0.08, 0.09) if slot_type == "character" else Color(0.07, 0.07, 0.08),
		"art": Color(0.03, 0.03, 0.04) if slot_type == "character" else Color(0.02, 0.02, 0.03)
	}
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
		"image_label": "",
		"art_bg_color": Color(0.00, 0.01, 0.02, 1.0),
		"color": Color(0.02, 0.03, 0.05, 0.98),
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
		"collapsed_height": LIST_CARD_HEIGHT,
		"expanded_height": LIST_CARD_HEIGHT
	}

func _make_event_icon_payload(event: EventData, turns_left: int, _assigned_cards: Array, expanded: bool) -> Dictionary:
	var art_color: Color = Color(0.22, 0.22, 0.23) if not expanded else Color(0.30, 0.30, 0.32)
	var panel_color: Color = Color(0.11, 0.11, 0.12) if not expanded else Color(0.15, 0.15, 0.16)
	return {
		"uid": "event:%s" % event.id,
		"id": event.id,
		"card_type": "event",
		"title": event.title,
		"subtitle": "",
		"body": event.description,
		"tags": event.tags,
		"assigned_text": "",
		"badge_text": str(turns_left),
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

func _center_event_dialog(viewport_size: Vector2) -> void:
	_apply_dialog_rect(viewport_size)

func _apply_dialog_rect(viewport_size: Vector2) -> void:
	if event_dialog == null:
		return
	var dialog_size: Vector2 = event_dialog.custom_minimum_size if event_dialog.custom_minimum_size != Vector2.ZERO else event_dialog.size
	var position: Vector2 = Vector2((viewport_size.x - dialog_size.x) * 0.5, (viewport_size.y - dialog_size.y) * 0.5)
	position = _clamp_dialog_position(position, viewport_size)
	event_dialog.position = position
	event_dialog.size = dialog_size
	event_dialog.offset_left = position.x
	event_dialog.offset_top = position.y
	event_dialog.offset_right = position.x + dialog_size.x
	event_dialog.offset_bottom = position.y + dialog_size.y
	event_dialog.set_deferred("position", position)
	event_dialog.set_deferred("size", dialog_size)
	event_dialog.set_deferred("offset_left", position.x)
	event_dialog.set_deferred("offset_top", position.y)
	event_dialog.set_deferred("offset_right", position.x + dialog_size.x)
	event_dialog.set_deferred("offset_bottom", position.y + dialog_size.y)

func _clamp_dialog_position(position: Vector2, viewport_size: Vector2) -> Vector2:
	if event_dialog == null:
		return position
	var dialog_size: Vector2 = event_dialog.size if event_dialog.size != Vector2.ZERO else event_dialog.custom_minimum_size
	return Vector2(
		clampf(position.x, 0.0, maxf(0.0, viewport_size.x - dialog_size.x)),
		clampf(position.y, 0.0, maxf(0.0, viewport_size.y - dialog_size.y))
	)

func _on_event_card_clicked(event_id: String) -> void:
	toggle_event(event_id)

func _on_target_drop_requested(target_id: String, payload: Dictionary) -> void:
	emit_signal("target_drop_requested", target_id, payload)

func _on_detail_card_clicked(card_id: String) -> void:
	emit_signal("detail_requested", card_id)

func _on_card_remove_requested(payload: Dictionary) -> void:
	emit_signal("remove_requested", payload)
