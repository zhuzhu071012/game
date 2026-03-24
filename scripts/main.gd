extends Control

const CARD_SCENE := preload("res://scenes/CardView.tscn")
const SLOT_SCENE := preload("res://scenes/SlotView.tscn")

@onready var top_info: HBoxContainer = %Info
@onready var slot_column: GridContainer = %Slots
@onready var event_column: VBoxContainer = %Events
@onready var roster_row: HBoxContainer = %RosterRow
@onready var resource_row: HBoxContainer = %ResourceRow
@onready var lead_row: VBoxContainer = %LeadRow
@onready var detail_body: RichTextLabel = %DetailBody
@onready var detail_title: Label = %DetailTitle
@onready var detail_subtitle: Label = %DetailSubtitle
@onready var detail_icon: TextureRect = %DetailIcon
@onready var detail_assignment_title: Label = %DetailAssignmentTitle
@onready var detail_assignment_row: HBoxContainer = %DetailAssignmentRow
@onready var detail_footnote: Label = %DetailFootnote
@onready var detail_close: Button = %DetailClose
@onready var log_label: RichTextLabel = %LogText
@onready var end_turn_button: Button = %EndTurnButton
@onready var toggle_log_button: Button = %ToggleLogButton
@onready var log_panel: PanelContainer = %LogPanel
@onready var event_dialog: PanelContainer = %EventDialog
@onready var event_dialog_header: PanelContainer = %EventDialogHeader
@onready var event_dialog_title: Label = %EventDialogTitle
@onready var event_dialog_subtitle: Label = %EventDialogSubtitle
@onready var event_dialog_close: Button = %EventDialogClose
@onready var event_dialog_body: RichTextLabel = %EventDialogBody
@onready var event_dialog_slot_title: Label = %EventDialogSlotTitle
@onready var event_dialog_slot_row: HBoxContainer = %EventDialogSlotRow
@onready var event_dialog_assigned_title: Label = %EventDialogAssignedTitle
@onready var event_dialog_assigned_row: HBoxContainer = %EventDialogAssignedRow
@onready var detail_overlay: ColorRect = %DetailOverlay
@onready var popup_panel: PanelContainer = %PopupPanel
@onready var popup_art: TextureRect = %PopupArt
@onready var popup_title: Label = %PopupTitle
@onready var popup_subtitle: Label = %PopupSubtitle
@onready var popup_body: RichTextLabel = %PopupBody
@onready var popup_close: Button = %PopupClose

@onready var detail_panel: PanelContainer = $Root/Layout/Desk/LeftSidebar/DetailPanel
@onready var event_panel: PanelContainer = $Root/Layout/Desk/CenterColumn/EventPanel
@onready var hands_panel: PanelContainer = $Root/Layout/Desk/CenterColumn/HandsPanel
@onready var right_sidebar: VBoxContainer = $Root/Layout/Desk/RightSidebar
@onready var resource_scroll: ScrollContainer = $Root/Layout/Desk/CenterColumn/HandsPanel/HandsVBox/ResourceScroll
@onready var roster_scroll: ScrollContainer = $Root/Layout/Desk/CenterColumn/HandsPanel/HandsVBox/RosterScroll
@onready var events_header: Label = $Root/Layout/Desk/CenterColumn/EventPanel/EventVBox/EventsHeader
@onready var roster_header: Label = $Root/Layout/Desk/CenterColumn/HandsPanel/HandsVBox/RosterLabel
@onready var resource_header: Label = $Root/Layout/Desk/CenterColumn/HandsPanel/HandsVBox/ResourceLabel
@onready var lead_header: Label = $Root/Layout/Desk/RightSidebar/LeadPanel/LeadVBox/LeadHeader

var run_state: RunState
var characters: Dictionary = {}
var resources: Dictionary = {}
var risks: Dictionary = {}
var events: Dictionary = {}
var expanded_event_id: String = ""
var selected_slot_id: String = ""
var detail_panel_open: bool = false
var event_dialog_dragging: bool = false
var event_dialog_drag_offset: Vector2 = Vector2.ZERO
var event_dialog_needs_center: bool = false

@onready var board_manager: BoardManager = $BoardManager
@onready var event_manager: EventManager = $EventManager
@onready var relation_manager: RelationManager = $RelationManager
@onready var turn_manager: TurnManager = $TurnManager

func _input(event: InputEvent) -> void:
	if not event_dialog_dragging:
		return
	if event is InputEventMouseMotion:
		event_dialog.position = _clamp_event_dialog_position(get_global_mouse_position() - event_dialog_drag_offset)
	elif event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			event_dialog_dragging = false

func _ready() -> void:
	randomize()
	TextDB.reload_texts()
	characters = GameData.create_characters()
	resources = GameData.create_resources()
	risks = GameData.create_risks()
	events = GameData.create_events()
	run_state = GameData.create_run_state()
	event_manager.setup(events)
	board_manager.board_changed.connect(_refresh_board)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	toggle_log_button.pressed.connect(_on_toggle_log_pressed)
	popup_close.pressed.connect(_close_detail_popup)
	detail_close.pressed.connect(_close_detail_panel)
	event_dialog_close.pressed.connect(_close_event_dialog)
	event_dialog_header.gui_input.connect(_on_event_dialog_header_gui_input)
	detail_overlay.gui_input.connect(_on_detail_overlay_gui_input)
	detail_overlay.visible = false
	log_panel.visible = false
	roster_row.add_theme_constant_override("separation", -112)
	resource_row.add_theme_constant_override("separation", -104)
	_apply_static_texts()
	_apply_visual_styles()
	board_manager.reset_turn_targets(run_state.active_event_ids)
	_build_slots()
	_refresh_board()

func _apply_static_texts() -> void:
	end_turn_button.text = TextDB.get_text("ui.buttons.end_turn")
	toggle_log_button.text = TextDB.get_text("ui.buttons.show_log")
	popup_close.text = TextDB.get_text("ui.buttons.close")
	detail_close.text = TextDB.get_text("ui.buttons.close")
	event_dialog_close.text = TextDB.get_text("ui.buttons.close")
	event_dialog_slot_title.text = TextDB.get_text("ui.detail_panel.assignment_title")
	event_dialog_assigned_title.text = TextDB.get_text("ui.assigned.prefix").replace("%s", "")
	events_header.text = TextDB.get_text("ui.headers.events")
	roster_header.text = TextDB.get_text("ui.headers.roster")
	resource_header.text = TextDB.get_text("ui.headers.resources")
	lead_header.text = TextDB.get_text("ui.headers.leads")

func _apply_visual_styles() -> void:
	var drawer_style: StyleBoxFlat = StyleBoxFlat.new()
	drawer_style.bg_color = Color(0.05, 0.11, 0.17, 0.97)
	drawer_style.border_width_left = 2
	drawer_style.border_width_top = 2
	drawer_style.border_width_right = 2
	drawer_style.border_width_bottom = 2
	drawer_style.border_color = Color(0.09, 0.29, 0.40, 0.95)
	drawer_style.corner_radius_top_left = 8
	drawer_style.corner_radius_top_right = 8
	drawer_style.corner_radius_bottom_left = 8
	drawer_style.corner_radius_bottom_right = 8
	drawer_style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	drawer_style.shadow_size = 18
	detail_panel.add_theme_stylebox_override("panel", drawer_style)

	var icon_frame_style: StyleBoxFlat = StyleBoxFlat.new()
	icon_frame_style.bg_color = Color(0.03, 0.16, 0.21, 1.0)
	icon_frame_style.border_width_left = 2
	icon_frame_style.border_width_top = 2
	icon_frame_style.border_width_right = 2
	icon_frame_style.border_width_bottom = 2
	icon_frame_style.border_color = Color(0.23, 0.78, 0.90, 0.9)
	icon_frame_style.corner_radius_top_left = 6
	icon_frame_style.corner_radius_top_right = 6
	icon_frame_style.corner_radius_bottom_left = 6
	icon_frame_style.corner_radius_bottom_right = 6
	icon_frame_style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	icon_frame_style.shadow_size = 8
	($Root/Layout/Desk/LeftSidebar/DetailPanel/DetailMargin/DetailVBox/DetailHeader/DetailIconFrame as PanelContainer).add_theme_stylebox_override("panel", icon_frame_style)

	var body_style: StyleBoxFlat = StyleBoxFlat.new()
	body_style.bg_color = Color(0.02, 0.07, 0.11, 0.92)
	body_style.border_width_left = 1
	body_style.border_width_top = 1
	body_style.border_width_right = 1
	body_style.border_width_bottom = 1
	body_style.border_color = Color(0.10, 0.24, 0.34, 0.95)
	body_style.corner_radius_top_left = 8
	body_style.corner_radius_top_right = 8
	body_style.corner_radius_bottom_left = 8
	body_style.corner_radius_bottom_right = 8
	detail_body.add_theme_stylebox_override("normal", body_style)

	var event_dialog_style: StyleBoxFlat = StyleBoxFlat.new()
	event_dialog_style.bg_color = Color(0.04, 0.07, 0.10, 0.97)
	event_dialog_style.border_width_left = 2
	event_dialog_style.border_width_top = 2
	event_dialog_style.border_width_right = 2
	event_dialog_style.border_width_bottom = 2
	event_dialog_style.border_color = Color(0.28, 0.38, 0.47, 0.95)
	event_dialog_style.corner_radius_top_left = 10
	event_dialog_style.corner_radius_top_right = 10
	event_dialog_style.corner_radius_bottom_left = 10
	event_dialog_style.corner_radius_bottom_right = 10
	event_dialog_style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	event_dialog_style.shadow_size = 16
	event_dialog.add_theme_stylebox_override("panel", event_dialog_style)

	var event_header_style: StyleBoxFlat = StyleBoxFlat.new()
	event_header_style.bg_color = Color(0.10, 0.16, 0.22, 0.98)
	event_header_style.border_width_left = 1
	event_header_style.border_width_top = 1
	event_header_style.border_width_right = 1
	event_header_style.border_width_bottom = 1
	event_header_style.border_color = Color(0.33, 0.46, 0.58, 0.95)
	event_header_style.corner_radius_top_left = 8
	event_header_style.corner_radius_top_right = 8
	event_header_style.corner_radius_bottom_left = 8
	event_header_style.corner_radius_bottom_right = 8
	event_dialog_header.add_theme_stylebox_override("panel", event_header_style)
	event_dialog_body.add_theme_stylebox_override("normal", body_style)

func _get_unlocked_slot_ids() -> Array[String]:
	var ids: Array[String] = ["governance"]
	if bool(run_state.flags.get("unlocked_research", false)):
		ids.append("research")
	if bool(run_state.flags.get("unlocked_recruit", false)):
		ids.append("recruit")
	if bool(run_state.flags.get("unlocked_audience", false)):
		ids.append("audience")
	if bool(run_state.flags.get("unlocked_rest", false)):
		ids.append("rest")
	return ids

func _build_slots() -> void:
	for child in slot_column.get_children():
		child.queue_free()
	for slot_id in _get_unlocked_slot_ids():
		var slot: SlotView = SLOT_SCENE.instantiate()
		slot.setup(_make_action_slot_payload(slot_id), true)
		slot.target_drop_requested.connect(_on_target_drop_requested)
		slot.card_clicked.connect(_on_slot_card_clicked)
		slot_column.add_child(slot)

func _apply_unlocks() -> void:
	var rebuild_needed: bool = false
	if bool(run_state.flags.get("first_governance_done", false)):
		if not bool(run_state.flags.get("unlocked_research", false)):
			run_state.flags["unlocked_research"] = true
			rebuild_needed = true
		if not bool(run_state.flags.get("unlocked_recruit", false)):
			run_state.flags["unlocked_recruit"] = true
			rebuild_needed = true
	if bool(run_state.flags.get("first_recruit_done", false)) and not bool(run_state.flags.get("unlocked_audience", false)):
		run_state.flags["unlocked_audience"] = true
		rebuild_needed = true
	if bool(run_state.flags.get("first_headwind_seen", false)) and not bool(run_state.flags.get("unlocked_rest", false)):
		run_state.flags["unlocked_rest"] = true
		rebuild_needed = true
	if rebuild_needed:
		_build_slots()

func _is_minimal_mode() -> bool:
	return not bool(run_state.flags.get("first_governance_done", false))

func _refresh_layout_visibility() -> void:
	var minimal: bool = _is_minimal_mode()
	detail_panel.visible = detail_panel_open
	event_panel.visible = not minimal
	right_sidebar.visible = false
	resource_scroll.visible = not minimal
	hands_panel.visible = true
	if minimal:
		log_panel.visible = false
	toggle_log_button.visible = not minimal
	roster_scroll.custom_minimum_size = Vector2(0.0, 210.0 if minimal else 196.0)
	resource_scroll.custom_minimum_size = Vector2(0.0, 0.0 if minimal else 184.0)

func _refresh_board() -> void:
	_apply_unlocks()
	_refresh_layout_visibility()
	_refresh_top_bar()
	_refresh_slots()
	_refresh_events()
	_refresh_roster()
	_refresh_resources()
	_refresh_leads()
	_refresh_log()
	_refresh_detail()
	_refresh_event_dialog()
	if run_state.game_over:
		end_turn_button.disabled = true
		detail_body.text = TextDB.format_text("ui.messages.bad_ending", [run_state.ending_id])

func _refresh_top_bar() -> void:
	for child in top_info.get_children():
		child.queue_free()
	var items: Array[String] = []
	items.append(TextDB.format_text("ui.status.stage", [run_state.stage_index]))
	items.append(TextDB.format_text("ui.status.turn", [run_state.turn_index]))
	items.append(TextDB.format_text("ui.status.health", [run_state.cao_health]))
	items.append(TextDB.format_text("ui.status.mind", [run_state.cao_mind]))
	items.append(TextDB.format_text("ui.status.money", [run_state.money]))
	items.append(TextDB.format_text("ui.status.morale", [run_state.morale]))
	items.append(TextDB.format_text("ui.status.fire", [run_state.fire_progress]))
	for item in items:
		var label: Label = Label.new()
		label.text = item
		top_info.add_child(label)

func _make_action_slot_payload(slot_id: String) -> Dictionary:
	var title: String = TextDB.get_text("system.slots.%s.title" % slot_id)
	var body: String = TextDB.get_text("system.slots.%s.body" % slot_id)
	var palette: Dictionary = _slot_palette(slot_id)
	return {
		"id": slot_id,
		"target_id": slot_id,
		"card_type": "slot",
		"title": title,
		"subtitle": "",
		"body": body,
		"assigned_text": "",
		"image_path": _slot_art_path(slot_id),
		"image_label": "",
		"art_bg_color": palette.get("art", Color(0.18, 0.18, 0.20)),
		"color": palette.get("panel", Color(0.20, 0.20, 0.23)),
		"compact_details": true,
		"hide_title": true,
		"hide_subtitle": true,
		"hide_assigned": true,
		"hide_body": true,
		"icon_button": true,
		"art_height": 84.0,
		"current_cards": board_manager.get_slot_cards(slot_id),
		"collapsed_height": 96.0,
		"expanded_height": 96.0
	}

func _make_event_slot_payload(event_id: String, slot_type: String) -> Dictionary:
	var title_key: String = "ui.event_slots.%s_title" % slot_type
	var body_key: String = "ui.event_slots.%s_body" % slot_type
	var icon_path: String = "res://assets/cards/slot_generic.svg" if slot_type == "character" else "res://assets/cards/slot_support.svg"
	var current_cards: Array = board_manager.get_event_slot_cards(event_id, slot_type)
	var palette: Dictionary = {
		"panel": Color(0.14, 0.14, 0.15) if slot_type == "character" else Color(0.11, 0.11, 0.12),
		"art": Color(0.22, 0.22, 0.24) if slot_type == "character" else Color(0.18, 0.18, 0.20)
	}
	return {
		"id": "%s:%s" % [event_id, slot_type],
		"target_id": "%s:%s" % [event_id, slot_type],
		"drop_kind": "event_%s" % slot_type,
		"card_type": "slot",
		"title": TextDB.get_text(title_key),
		"subtitle": "",
		"body": TextDB.get_text(body_key),
		"assigned_text": _slot_badge_text(current_cards.size(), 1),
		"image_path": icon_path,
		"image_label": TextDB.get_text(title_key),
		"art_bg_color": palette["art"],
		"color": palette["panel"],
		"compact_details": true,
		"show_assigned_in_compact": true,
		"collapsed_height": 102.0,
		"expanded_height": 102.0
	}

func _slot_palette(slot_id: String) -> Dictionary:
	match slot_id:
		"governance":
			return {"panel": Color(0.10, 0.10, 0.11), "art": Color(0.18, 0.18, 0.19)}
		"research":
			return {"panel": Color(0.11, 0.11, 0.12), "art": Color(0.20, 0.20, 0.21)}
		"recruit":
			return {"panel": Color(0.09, 0.09, 0.10), "art": Color(0.17, 0.17, 0.18)}
		"audience":
			return {"panel": Color(0.12, 0.12, 0.13), "art": Color(0.22, 0.22, 0.23)}
		"rest":
			return {"panel": Color(0.13, 0.13, 0.14), "art": Color(0.24, 0.24, 0.25)}
		_:
			return {"panel": Color(0.10, 0.10, 0.11), "art": Color(0.18, 0.18, 0.19)}

func _slot_badge_text(count: int, max_count: int = 0) -> String:
	if max_count > 0:
		return TextDB.format_text("ui.slot_badge.count_max", [count, max_count])
	if count <= 0:
		return TextDB.get_text("ui.slot_badge.empty")
	return TextDB.format_text("ui.slot_badge.count", [count])

func _refresh_slots() -> void:
	for slot_view in slot_column.get_children():
		var slot: SlotView = slot_view as SlotView
		if slot == null:
			continue
		var slot_id: String = str(slot.card_payload.get("id", ""))
		slot.card_payload["current_cards"] = board_manager.get_slot_cards(slot_id)
		slot.assigned_label.text = ""

func _refresh_events() -> void:
	for child in event_column.get_children():
		child.queue_free()
	if _is_minimal_mode():
		_close_event_dialog(false)
		return
	if not run_state.active_event_ids.has(expanded_event_id):
		_close_event_dialog(false)
	for event_id in run_state.active_event_ids:
		var event: EventData = events[event_id] as EventData
		var state: Dictionary = run_state.active_event_states.get(event_id, {})
		var assigned_cards: Array = board_manager.get_event_cards(event_id)
		var event_card: CardView = CARD_SCENE.instantiate()
		var turns_left: int = int(state.get("turns_left", 0))
		event_card.setup(_make_event_icon_payload(event, turns_left, assigned_cards, expanded_event_id == event_id))
		event_card.card_clicked.connect(_on_event_card_clicked)
		event_column.add_child(event_card)
	if run_state.active_event_ids.is_empty():
		var label: Label = Label.new()
		label.text = TextDB.get_text("ui.messages.no_events")
		event_column.add_child(label)

func _make_event_icon_payload(event: EventData, turns_left: int, assigned_cards: Array, expanded: bool) -> Dictionary:
	var art_color: Color = Color(0.24, 0.24, 0.25) if not expanded else Color(0.32, 0.32, 0.34)
	var panel_color: Color = Color(0.10, 0.10, 0.11) if not expanded else Color(0.14, 0.14, 0.15)
	return {
		"id": event.id,
		"card_type": "event",
		"title": event.title,
		"subtitle": TextDB.format_text("ui.event_subtitle.collapsed", [turns_left]),
		"body": event.description,
		"assigned_text": _slot_badge_text(assigned_cards.size(), 2),
		"image_path": event.art_path,
		"image_label": event.title,
		"art_bg_color": art_color,
		"color": panel_color,
		"compact_details": true,
		"hide_title": true,
		"hide_subtitle": true,
		"hide_assigned": true,
		"hide_body": true,
		"icon_button": true,
		"locked": true,
		"art_height": 84.0,
		"collapsed_height": 96.0,
		"expanded_height": 96.0
	}

func _build_event_detail_panel(event_id: String) -> Control:
	var event: EventData = events[event_id] as EventData
	var state: Dictionary = run_state.active_event_states.get(event_id, {})
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.08, 0.11, 0.96)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.29, 0.42, 0.52, 0.92)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", panel_style)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var title: Label = Label.new()
	title.text = event.title
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	var subtitle: Label = Label.new()
	subtitle.text = TextDB.format_text("ui.event_subtitle.expanded", [int(state.get("turns_left", 0))])
	subtitle.modulate = Color(0.78, 0.78, 0.80, 1.0)
	box.add_child(subtitle)
	var body: RichTextLabel = RichTextLabel.new()
	body.bbcode_enabled = true
	body.scroll_active = false
	body.fit_content = true
	body.custom_minimum_size = Vector2(0, 72)
	body.text = event.description
	box.add_child(body)
	box.add_child(_build_event_slot_row(event_id))
	var assigned_row: HBoxContainer = _build_event_assigned_row(event_id)
	if assigned_row.get_child_count() > 0:
		box.add_child(assigned_row)
	return panel

func _build_event_slot_row(event_id: String) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	var char_slot: SlotView = SLOT_SCENE.instantiate()
	char_slot.setup(_make_event_slot_payload(event_id, "character"), true)
	char_slot.target_drop_requested.connect(_on_target_drop_requested)
	row.add_child(char_slot)
	var resource_slot: SlotView = SLOT_SCENE.instantiate()
	resource_slot.setup(_make_event_slot_payload(event_id, "resource"), true)
	resource_slot.target_drop_requested.connect(_on_target_drop_requested)
	row.add_child(resource_slot)
	return row

func _build_event_assigned_row(event_id: String) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for card_variant in board_manager.get_event_cards(event_id):
		var card: Dictionary = card_variant as Dictionary
		var preview: CardView = _build_committed_preview(card)
		row.add_child(preview)
	return row

func _build_committed_preview(card: Dictionary) -> CardView:
	var preview: CardView = CARD_SCENE.instantiate()
	var payload: Dictionary = card.duplicate(true)
	payload["subtitle"] = ""
	payload["body"] = ""
	payload["compact_details"] = true
	payload["art_height"] = 116.0
	payload["collapsed_height"] = 136.0
	payload["expanded_height"] = 136.0
	payload["show_subtitle_in_compact"] = false
	payload["show_assigned_in_compact"] = false
	payload["assigned"] = true
	payload["removable"] = true
	preview.setup(payload)
	preview.custom_minimum_size = Vector2(86, 136)
	preview.card_clicked.connect(_on_detail_card_clicked)
	preview.remove_requested.connect(_on_card_remove_requested)
	return preview

func _refresh_roster() -> void:
	for child in roster_row.get_children():
		child.queue_free()
	var character_ids: Array[String] = []
	for character_id in GameData.CHARACTER_SCENE_ORDER:
		if run_state.roster_ids.has(character_id):
			character_ids.append(character_id)
	for character_id in character_ids:
		if not characters.has(character_id):
			continue
		var data: CharacterData = characters[character_id] as CharacterData
		var card: CardView = CARD_SCENE.instantiate()
		var role_name: String = _role_type_text(data.role_type)
		var subtitle: String = role_name
		if run_state.relation_states.has(character_id):
			subtitle = "%s / %s" % [role_name, relation_manager.describe_relation(run_state, character_id)]
		card.setup({
			"uid": "character:%s" % character_id,
			"id": character_id,
			"card_type": "character",
			"title": data.display_name,
			"subtitle": subtitle,
			"body": _character_body(character_id, false),
			"tags": data.tags,
			"locked": false,
			"assigned": board_manager.is_committed("character:%s" % character_id),
			"assigned_text": _character_assigned_text(character_id, false),
			"image_path": data.art_path,
			"image_label": data.display_name,
			"art_bg_color": Color(0.20, 0.20, 0.22),
			"color": Color(0.12, 0.12, 0.13),
			"compact_details": true,
			"art_height": 166.0,
			"collapsed_height": 210.0,
			"expanded_height": 252.0
		})
		card.card_clicked.connect(_on_detail_card_clicked)
		card.quick_assign_requested.connect(_on_card_quick_assign_requested)
		card.remove_requested.connect(_on_card_remove_requested)
		roster_row.add_child(card)

func _refresh_resources() -> void:
	for child in resource_row.get_children():
		child.queue_free()
	if _is_minimal_mode():
		return
	for resource_id_variant in run_state.resource_states.keys():
		var resource_id: String = str(resource_id_variant)
		var amount: int = int(run_state.resource_states[resource_id])
		if amount <= 0:
			continue
		var data: ResourceCardData = resources[resource_id] as ResourceCardData
		for index in range(amount):
			var uid: String = "resource:%s:%d" % [resource_id, index]
			var card: CardView = CARD_SCENE.instantiate()
			card.setup({
				"uid": uid,
				"id": resource_id,
				"card_type": "resource",
				"title": data.display_name,
				"subtitle": TextDB.format_text("system.resource_templates.subtitle", [_resource_category_text(data.category), amount]),
				"body": data.description,
				"tags": data.tags,
				"assigned": board_manager.is_committed(uid),
				"assigned_text": TextDB.get_text("ui.assigned.committed") if board_manager.is_committed(uid) else "",
				"image_path": data.art_path,
				"image_label": data.display_name,
				"art_bg_color": Color(0.18, 0.18, 0.19),
				"color": Color(0.11, 0.11, 0.12),
			"art_height": 160.0,
			"collapsed_height": 206.0,
			"expanded_height": 246.0
			})
			card.card_clicked.connect(_on_detail_card_clicked)
			card.quick_assign_requested.connect(_on_card_quick_assign_requested)
			card.remove_requested.connect(_on_card_remove_requested)
			resource_row.add_child(card)

func _refresh_leads() -> void:
	for child in lead_row.get_children():
		child.queue_free()

func _refresh_log() -> void:
	var start_index: int = maxi(0, run_state.log_entries.size() - 4)
	var recent: Array[String] = []
	for index in range(start_index, run_state.log_entries.size()):
		recent.append(str(run_state.log_entries[index]))
	log_label.text = "  |  ".join(recent)

func _refresh_detail() -> void:
	if selected_slot_id.is_empty():
		_show_overview_detail()
		return
	_show_slot_detail(selected_slot_id)

func _show_overview_detail() -> void:
	if not detail_panel_open:
		return
	var risk_lines: Array[String] = []
	for risk_id_variant in risks.keys():
		var risk_id: String = str(risk_id_variant)
		var count: int = int(run_state.risk_states[risk_id])
		var risk_data: RiskCardData = risks[risk_id] as RiskCardData
		risk_lines.append(TextDB.format_text("system.risk_detail.line", [risk_data.display_name, count]))
	var guo_state: Dictionary = run_state.active_character_states.get("guo_jia", {})
	var guo_stage: int = int(guo_state.get("sick_stage", 0))
	_detail_setup(
		TextDB.get_text("ui.detail_panel.overview_title"),
		TextDB.get_text("ui.detail_panel.overview_subtitle"),
		TextDB.format_text(
			"ui.messages.overview",
			[
				run_state.jingzhou_stability,
				run_state.naval_readiness,
				run_state.alliance_strength,
				guo_stage,
				"\n".join(risk_lines)
			]
		),
		"",
		[],
		TextDB.get_text("ui.detail_panel.turn_hint")
	)

func _show_card_detail(card_id: String) -> void:
	if characters.has(card_id):
		var data: CharacterData = characters[card_id] as CharacterData
		detail_body.text = "[b]%s[/b]\n%s" % [data.display_name, _character_body(card_id, not run_state.roster_ids.has(card_id))]
	elif resources.has(card_id):
		var data_res: ResourceCardData = resources[card_id] as ResourceCardData
		detail_body.text = "[b]%s[/b]\n%s" % [data_res.display_name, _resource_body(data_res)]
	elif events.has(card_id):
		var data_event: EventData = events[card_id] as EventData
		detail_body.text = "[b]%s[/b]\n%s" % [data_event.title, _event_body(data_event)]

func _on_slot_card_clicked(slot_id: String) -> void:
	_show_slot_detail(slot_id)

func _show_slot_detail(slot_id: String) -> void:
	selected_slot_id = slot_id
	detail_panel_open = true
	var body: String = TextDB.get_text("system.slot_details.%s" % slot_id)
	var assigned_cards: Array = board_manager.get_slot_cards(slot_id)
	_detail_setup(
		TextDB.get_text("system.slots.%s.title" % slot_id),
		TextDB.get_text("ui.detail_panel.slot_subtitle"),
		body,
		_slot_art_path(slot_id),
		assigned_cards,
		TextDB.get_text("ui.detail_panel.slot_hint")
	)

func _detail_setup(title: String, subtitle: String, body: String, icon_path: String, assigned_cards: Array, footnote: String) -> void:
	detail_panel_open = true
	detail_panel.visible = true
	detail_title.text = title
	detail_subtitle.text = subtitle
	detail_subtitle.visible = not subtitle.strip_edges().is_empty()
	detail_body.text = body
	detail_assignment_title.text = TextDB.get_text("ui.detail_panel.assignment_title")
	detail_footnote.text = footnote
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		detail_icon.texture = load(icon_path) as Texture2D
	else:
		detail_icon.texture = null
	_refresh_detail_assignment_row(selected_slot_id, assigned_cards)

func _refresh_detail_assignment_row(slot_id: String, assigned_cards: Array) -> void:
	for child in detail_assignment_row.get_children():
		child.queue_free()
	for card_variant in assigned_cards:
		var card: Dictionary = card_variant as Dictionary
		var preview: CardView = _build_committed_preview(card)
		detail_assignment_row.add_child(preview)
	var remaining_slots: int = _detail_remaining_capacity(slot_id, assigned_cards)
	for index in range(remaining_slots):
		var placeholder: SlotView = SLOT_SCENE.instantiate()
		placeholder.custom_minimum_size = Vector2(86, 136)
		placeholder.setup({
			"id": "%s:detail:%d" % [slot_id, index],
			"target_id": slot_id,
			"card_type": "slot",
			"title": "",
			"subtitle": "",
			"body": "",
			"assigned_text": "",
			"image_path": "",
			"image_label": "",
			"art_bg_color": Color(0.02, 0.03, 0.05, 0.98),
			"color": Color(0.03, 0.06, 0.09, 0.96),
			"compact_details": true,
			"hide_title": true,
			"hide_subtitle": true,
			"hide_assigned": true,
			"hide_body": true,
			"drop_slot": true,
			"art_height": 124.0,
			"current_cards": assigned_cards,
			"collapsed_height": 136.0,
			"expanded_height": 136.0
		}, true)
		placeholder.target_drop_requested.connect(_on_target_drop_requested)
		detail_assignment_row.add_child(placeholder)

func _detail_remaining_capacity(slot_id: String, assigned_cards: Array) -> int:
	var capacities: Dictionary = GameRules.SLOT_CAPACITY.get(slot_id, {})
	var total_capacity: int = 0
	for value_variant in capacities.values():
		total_capacity += int(value_variant)
	return maxi(0, total_capacity - assigned_cards.size())

func _decorate_body_with_tags(base_text: String, tags: Array) -> String:
	if tags.is_empty():
		return base_text
	return "%s\n\n%s" % [base_text, TextDB.format_text("system.traits.line", [_join_tag_texts(tags)])]

func _resource_body(data_res: ResourceCardData) -> String:
	return _decorate_body_with_tags(data_res.description, data_res.tags)

func _event_body(data_event: EventData) -> String:
	return _decorate_body_with_tags(data_event.description, data_event.tags)

func _slot_assigned_line(names: Array[String]) -> String:
	return TextDB.format_text("ui.slot_detail.assigned", [_join_name_texts(names)])

func _join_name_texts(names: Array[String]) -> String:
	var separator: String = TextDB.get_text("ui.list_separator")
	return separator.join(names)

func _on_card_quick_assign_requested(payload: Dictionary) -> void:
	if payload.is_empty():
		return
	var target: Dictionary = _find_quick_assign_target(payload)
	if target.is_empty():
		run_state.log_entries.append(TextDB.get_text("logs.board.quick_assign_failed"))
		_refresh_board()
		return
	var ok: bool = false
	if str(target.get("kind", "")) == "event":
		ok = board_manager.assign_to_event(str(target.get("event_id", "")), payload, str(target.get("slot_type", "")))
	else:
		ok = board_manager.assign_to_slot(str(target.get("slot_id", "")), payload)
		if ok:
			selected_slot_id = str(target.get("slot_id", ""))
	if ok:
		run_state.log_entries.append(TextDB.format_text("logs.board.quick_assign_success", [str(payload.get("title", "")), str(target.get("label", ""))]))
	else:
		run_state.log_entries.append(TextDB.get_text("logs.board.invalid_drop"))
	_refresh_board()

func _on_card_remove_requested(payload: Dictionary) -> void:
	var uid: String = str(payload.get("uid", ""))
	if uid.is_empty():
		return
	if board_manager.unassign_card(uid):
		_refresh_board()

func _find_quick_assign_target(payload: Dictionary) -> Dictionary:
	var best_score: int = -999
	var best_target: Dictionary = {}
	if not expanded_event_id.is_empty():
		var expanded_target: Dictionary = _event_quick_target(expanded_event_id, payload, 220)
		if not expanded_target.is_empty():
			best_target = expanded_target
			best_score = int(expanded_target.get("score", -999))
	for slot_id in _get_unlocked_slot_ids():
		var score: int = GameRules.quick_assign_score(slot_id, payload, board_manager.get_slot_cards(slot_id))
		if score > best_score:
			best_score = score
			best_target = {
				"kind": "slot",
				"slot_id": slot_id,
				"score": score,
				"label": TextDB.get_text("system.slots.%s.title" % slot_id)
			}
	for event_id_variant in run_state.active_event_ids:
		var event_id: String = str(event_id_variant)
		if event_id == expanded_event_id:
			continue
		var event_target: Dictionary = _event_quick_target(event_id, payload, 120)
		if event_target.is_empty():
			continue
		var event_score: int = int(event_target.get("score", -999))
		if event_score > best_score:
			best_score = event_score
			best_target = event_target
	return best_target

func _event_quick_target(event_id: String, payload: Dictionary, base_score: int) -> Dictionary:
	var slot_type: String = str(payload.get("card_type", ""))
	if slot_type not in ["character", "resource"]:
		return {}
	if not GameRules.can_drop_on_event_slot(slot_type, payload, board_manager.get_event_slot_cards(event_id, slot_type)):
		return {}
	var event_data: EventData = events[event_id] as EventData
	var slot_label: String = TextDB.get_text("ui.event_slots.%s_title" % slot_type)
	return {
		"kind": "event",
		"event_id": event_id,
		"slot_type": slot_type,
		"score": base_score,
		"label": "%s / %s" % [event_data.title, slot_label]
	}

func _character_body(character_id: String, locked: bool) -> String:
	var data: CharacterData = characters[character_id] as CharacterData
	var bio: String = TextDB.get_text("characters.%s.bio" % character_id)
	var body: String = TextDB.format_text(
		"system.character_templates.profile",
		[
			bio,
			_join_tag_texts(data.tags),
			data.execution,
			data.insight,
			data.martial,
			data.charm,
			data.medicine
		]
	)
	if character_id == "guo_jia":
		body += TextDB.format_text("system.character_templates.guojia_stage", [int(run_state.active_character_states["guo_jia"]["sick_stage"])])
	if locked:
		body += TextDB.get_text("system.character_templates.locked_hint")
	return body

func _on_target_drop_requested(target_id: String, payload: Dictionary) -> void:
	if payload == null:
		return
	var ok: bool = false
	if target_id.contains(":character"):
		ok = board_manager.assign_to_event(target_id.get_slice(":", 0), payload, "character")
	elif target_id.contains(":resource"):
		ok = board_manager.assign_to_event(target_id.get_slice(":", 0), payload, "resource")
	elif events.has(target_id):
		ok = board_manager.assign_to_event(target_id, payload)
	else:
		ok = board_manager.assign_to_slot(target_id, payload)
	if not ok:
		run_state.log_entries.append(TextDB.get_text("logs.board.invalid_drop"))
	else:
		if not target_id.contains(":") and not events.has(target_id):
			selected_slot_id = target_id
			detail_panel_open = true
	_refresh_board()

func _on_event_card_clicked(event_id: String) -> void:
	if expanded_event_id == event_id and event_dialog.visible:
		_close_event_dialog()
		return
	expanded_event_id = event_id
	event_dialog_needs_center = true
	_refresh_board()

func _on_detail_card_clicked(card_id: String) -> void:
	_show_card_detail(card_id)
	_open_detail_popup(card_id)

func _open_detail_popup(card_id: String) -> void:
	var payload: Dictionary = _build_popup_payload(card_id)
	if payload.is_empty():
		return
	popup_title.text = str(payload.get("title", ""))
	popup_subtitle.text = str(payload.get("subtitle", ""))
	popup_subtitle.visible = not popup_subtitle.text.strip_edges().is_empty()
	popup_body.text = str(payload.get("body", ""))
	var image_path: String = str(payload.get("image_path", ""))
	if not image_path.is_empty() and ResourceLoader.exists(image_path):
		popup_art.texture = load(image_path) as Texture2D
	else:
		popup_art.texture = null
	detail_overlay.visible = true

func _build_popup_payload(card_id: String) -> Dictionary:
	if characters.has(card_id):
		var data: CharacterData = characters[card_id] as CharacterData
		var subtitle: String = _role_type_text(data.role_type)
		if run_state.relation_states.has(card_id):
			subtitle = "%s / %s" % [subtitle, relation_manager.describe_relation(run_state, card_id)]
		return {
			"title": data.display_name,
			"subtitle": subtitle,
			"body": _character_body(card_id, not run_state.roster_ids.has(card_id)),
			"image_path": data.art_path
		}
	if resources.has(card_id):
		var data_res: ResourceCardData = resources[card_id] as ResourceCardData
		return {
			"title": data_res.display_name,
			"subtitle": _resource_category_text(data_res.category),
			"body": _resource_body(data_res),
			"image_path": data_res.art_path
		}
	if events.has(card_id):
		var data_event: EventData = events[card_id] as EventData
		return {
			"title": data_event.title,
			"subtitle": _event_category_text(data_event.category),
			"body": _event_body(data_event),
			"image_path": data_event.art_path
		}
	return {}

func _close_detail_popup() -> void:
	detail_overlay.visible = false

func _refresh_event_dialog() -> void:
	if expanded_event_id.is_empty() or not run_state.active_event_ids.has(expanded_event_id):
		event_dialog.visible = false
		return
	var event: EventData = events[expanded_event_id] as EventData
	var state: Dictionary = run_state.active_event_states.get(expanded_event_id, {})
	event_dialog.visible = true
	event_dialog_title.text = event.title
	event_dialog_subtitle.text = TextDB.format_text("ui.event_subtitle.expanded", [int(state.get("turns_left", 0))])
	event_dialog_body.text = event.description
	_populate_event_dialog_slots(expanded_event_id)
	_populate_event_dialog_assigned(expanded_event_id)
	if event_dialog_needs_center:
		_center_event_dialog()
		event_dialog_needs_center = false

func _populate_event_dialog_slots(event_id: String) -> void:
	for child in event_dialog_slot_row.get_children():
		child.queue_free()
	var char_slot: SlotView = SLOT_SCENE.instantiate()
	char_slot.setup(_make_event_slot_payload(event_id, "character"), true)
	char_slot.target_drop_requested.connect(_on_target_drop_requested)
	event_dialog_slot_row.add_child(char_slot)
	var resource_slot: SlotView = SLOT_SCENE.instantiate()
	resource_slot.setup(_make_event_slot_payload(event_id, "resource"), true)
	resource_slot.target_drop_requested.connect(_on_target_drop_requested)
	event_dialog_slot_row.add_child(resource_slot)

func _populate_event_dialog_assigned(event_id: String) -> void:
	for child in event_dialog_assigned_row.get_children():
		child.queue_free()
	var cards: Array = board_manager.get_event_cards(event_id)
	event_dialog_assigned_title.visible = not cards.is_empty()
	for card_variant in cards:
		var card: Dictionary = card_variant as Dictionary
		var preview: CardView = _build_committed_preview(card)
		event_dialog_assigned_row.add_child(preview)

func _center_event_dialog() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var dialog_size: Vector2 = event_dialog.custom_minimum_size
	event_dialog.position = Vector2((viewport_size.x - dialog_size.x) * 0.5, (viewport_size.y - dialog_size.y) * 0.5)
	event_dialog.position = _clamp_event_dialog_position(event_dialog.position)

func _clamp_event_dialog_position(position: Vector2) -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var dialog_size: Vector2 = event_dialog.size if event_dialog.size != Vector2.ZERO else event_dialog.custom_minimum_size
	return Vector2(
		clampf(position.x, 0.0, maxf(0.0, viewport_size.x - dialog_size.x)),
		clampf(position.y, 0.0, maxf(0.0, viewport_size.y - dialog_size.y))
	)

func _close_event_dialog(refresh: bool = true) -> void:
	expanded_event_id = ""
	event_dialog.visible = false
	event_dialog_dragging = false
	if refresh:
		_refresh_board()

func _on_event_dialog_header_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			event_dialog_dragging = true
			event_dialog_drag_offset = get_global_mouse_position() - event_dialog.global_position

func _close_detail_panel() -> void:
	selected_slot_id = ""
	detail_panel_open = false
	detail_panel.visible = false
	_refresh_board()

func _on_detail_overlay_gui_input(event: InputEvent) -> void:
	if not detail_overlay.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not popup_panel.get_global_rect().has_point(get_global_mouse_position()):
			_close_detail_popup()

func _on_end_turn_pressed() -> void:
	if run_state.game_over:
		return
	var logs: Array[String] = turn_manager.resolve_turn(run_state, board_manager, event_manager, relation_manager, characters, resources)
	if logs.is_empty():
		run_state.log_entries.append(TextDB.get_text("logs.turn.stable"))
	_refresh_board()

func _on_toggle_log_pressed() -> void:
	log_panel.visible = not log_panel.visible
	toggle_log_button.text = TextDB.get_text("ui.buttons.hide_log") if log_panel.visible else TextDB.get_text("ui.buttons.show_log")

func _slot_art_path(slot_id: String) -> String:
	match slot_id:
		"governance":
			return "res://assets/ui/actions/governance.png"
		"audience":
			return "res://assets/ui/actions/audience.png"
		"research":
			return "res://assets/ui/actions/research.png"
		"recruit":
			return "res://assets/ui/actions/recruit.png"
		"rest":
			return "res://assets/ui/actions/rest.png"
		_:
			return "res://assets/cards/slot_generic.svg"

func _role_type_text(role_type: String) -> String:
	return TextDB.get_text("system.roles.%s" % role_type, role_type)

func _resource_category_text(category: String) -> String:
	return TextDB.get_text("system.resource_categories.%s" % category, category)

func _event_category_text(category: String) -> String:
	return TextDB.get_text("system.event_categories.%s" % category, category)

func _join_tag_texts(tags: Array) -> String:
	var texts: Array[String] = []
	for tag_variant in tags:
		texts.append(_tag_text(str(tag_variant)))
	var separator: String = TextDB.get_text("ui.list_separator")
	return separator.join(texts)

func _tag_text(tag: String) -> String:
	return TextDB.get_text("system.tags.%s" % tag, tag)

func _assigned_text(names: Array[String], empty_value: String) -> String:
	var separator: String = TextDB.get_text("ui.list_separator")
	var display: String = empty_value if names.is_empty() else separator.join(names)
	return TextDB.format_text("ui.assigned.prefix", [display])

func _character_assigned_text(character_id: String, locked: bool) -> String:
	if board_manager.is_committed("character:%s" % character_id):
		return TextDB.get_text("ui.assigned.committed")
	if locked:
		return TextDB.get_text("ui.assigned.locked_hint")
	return ""
