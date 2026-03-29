extends Control

const CARD_SCENE := preload("res://scenes/CardView.tscn")
const SLOT_SCENE := preload("res://scenes/SlotView.tscn")
const EVENT_UI_CONTROLLER_SCRIPT := preload("res://scripts/ui/event_ui_controller.gd")
const FLOATING_DETAIL_WINDOW_SCRIPT := preload("res://scripts/ui/floating_detail_window.gd")
const TUTORIAL_MANAGER_SCRIPT := preload("res://scripts/managers/tutorial_manager.gd")
const FIRE_MARKER_TEXTURE := preload("res://assets/ui/fire_marker.svg")
const POPUP_DETAIL_SIZE := Vector2(860.0, 560.0)
const POPUP_SETTLEMENT_SIZE := Vector2(960.0, 620.0)
const POPUP_CONFIRM_SIZE := Vector2(560.0, 320.0)
const POPUP_TURN_REPORT_SIZE := Vector2(780.0, 520.0)
const POPUP_MESSAGE_SIZE := Vector2(760.0, 420.0)
const STACK_CARD_SEPARATION := -82
const LIST_CARD_WIDTH := 120.0
const LIST_CARD_HEIGHT := 160.0
const LIST_CARD_ART_HEIGHT := 116.0
const DETAIL_PANEL_WINDOW_SIZE := Vector2(640.0, 480.0)
const CHARACTER_DETAIL_WINDOW_SIZE := Vector2(720.0, 540.0)
const CHARACTER_DETAIL_ART_SIZE := Vector2(180.0, 240.0)

@onready var top_bar_panel: PanelContainer = $Root/Layout/TopBar
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
@onready var detail_header: HBoxContainer = $Root/Layout/Desk/LeftSidebar/DetailPanel/DetailMargin/DetailVBox/DetailHeader
@onready var log_label: RichTextLabel = %LogText
@onready var end_turn_button: Button = %EndTurnButton
@onready var toggle_log_button: Button = %ToggleLogButton
@onready var log_panel: PanelContainer = %LogPanel
@onready var event_dialog: PanelContainer = %EventDialog
@onready var event_dialog_header: PanelContainer = %EventDialogHeader
@onready var event_dialog_title: Label = %EventDialogTitle
@onready var event_dialog_subtitle: Label = %EventDialogSubtitle
@onready var event_dialog_close: Button = %EventDialogClose
@onready var event_dialog_body_panel: PanelContainer = %EventDialogBodyPanel
@onready var event_dialog_body: RichTextLabel = %EventDialogBody
@onready var event_dialog_slot_panel: PanelContainer = %EventDialogSlotPanel
@onready var event_dialog_slot_title: Label = %EventDialogSlotTitle
@onready var event_dialog_slot_row: HBoxContainer = %EventDialogSlotRow
@onready var event_dialog_assigned_title: Label = %EventDialogAssignedTitle
@onready var event_dialog_assigned_row: HBoxContainer = %EventDialogAssignedRow
@onready var detail_overlay: ColorRect = %DetailOverlay
@onready var popup_panel: PanelContainer = %PopupPanel
@onready var popup_header: HBoxContainer = $DetailOverlay/DetailCenter/PopupPanel/PopupMargin/PopupVBox/PopupHeader
@onready var popup_art_frame: PanelContainer = $DetailOverlay/DetailCenter/PopupPanel/PopupMargin/PopupVBox/PopupContent/PopupArtFrame
@onready var popup_art: TextureRect = %PopupArt
@onready var popup_title: Label = %PopupTitle
@onready var popup_subtitle: Label = %PopupSubtitle
@onready var popup_body: RichTextLabel = %PopupBody
@onready var popup_close: Button = %PopupClose
var popup_cancel: Button

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
var selected_slot_id: String = ""
var detail_panel_open: bool = false
var event_ui_controller: EventUiController
var fire_panel: PanelContainer
var fire_track: Control
var fire_marker: TextureRect
var fire_fill: ColorRect
var settlement_dialog_active: bool = false
var settlement_page_index: int = -1
var end_turn_confirm_active: bool = false
var turn_report_dialog_active: bool = false
var defer_settlement_popup: bool = false
var tutorial_prompt_after_popup: bool = false
var detail_window_layer: Control
var active_detail_windows: Array = []
var detail_window_by_key: Dictionary = {}
var dragging_detail_window: Control = null
var detail_window_drag_offset: Vector2 = Vector2.ZERO
var detail_window_z_counter: int = 40
var detail_window_spawn_index: int = 0
var dragging_detail_panel: bool = false
var detail_panel_drag_offset: Vector2 = Vector2.ZERO
var detail_panel_has_position: bool = false
var detail_assignment_scroll: ScrollContainer
var tutorial_manager

@onready var board_manager: BoardManager = $BoardManager
@onready var event_manager: EventManager = $EventManager
@onready var relation_manager: RelationManager = $RelationManager
@onready var turn_manager: TurnManager = $TurnManager

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var popup_mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if popup_mouse_event.button_index == MOUSE_BUTTON_LEFT and popup_mouse_event.pressed and detail_overlay.visible:
			var popup_mouse_position: Vector2 = get_global_mouse_position()
			if popup_cancel != null and popup_cancel.visible and popup_cancel.get_global_rect().has_point(popup_mouse_position):
				_on_popup_cancel_pressed()
				get_viewport().set_input_as_handled()
				return
			if popup_close != null and popup_close.visible and popup_close.get_global_rect().has_point(popup_mouse_position):
				_on_popup_close_pressed()
				get_viewport().set_input_as_handled()
				return
	if dragging_detail_panel:
		if event is InputEventMouseMotion:
			detail_panel.position = _clamp_floating_panel_position(get_global_mouse_position() - detail_panel_drag_offset, detail_panel)
		elif event is InputEventMouseButton:
			var detail_mouse_event: InputEventMouseButton = event as InputEventMouseButton
			if detail_mouse_event.button_index == MOUSE_BUTTON_LEFT and not detail_mouse_event.pressed:
				dragging_detail_panel = false
	if dragging_detail_window != null:
		if event is InputEventMouseMotion:
			dragging_detail_window.position = _clamp_detail_window_position(get_global_mouse_position() - detail_window_drag_offset, dragging_detail_window)
		elif event is InputEventMouseButton:
			var mouse_event: InputEventMouseButton = event as InputEventMouseButton
			if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
				dragging_detail_window = null
	if event_ui_controller == null:
		return
	event_ui_controller.handle_global_input(event, get_global_mouse_position(), get_viewport_rect().size)

func _ready() -> void:
	randomize()
	TextDB.reload_texts()
	tutorial_manager = TUTORIAL_MANAGER_SCRIPT.new()
	characters = GameData.create_characters()
	resources = GameData.create_resources()
	risks = GameData.create_risks()
	events = GameData.create_events()
	run_state = GameData.create_run_state()
	event_manager.setup(events)
	board_manager.board_changed.connect(_refresh_board)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	toggle_log_button.pressed.connect(_on_toggle_log_pressed)
	popup_close.pressed.connect(_on_popup_close_pressed)
	popup_panel.gui_input.connect(_on_popup_panel_gui_input)
	_ensure_popup_cancel_button()
	detail_close.pressed.connect(_close_detail_panel)
	event_dialog_close.pressed.connect(_on_event_dialog_close_pressed)
	event_dialog_header.gui_input.connect(_on_event_dialog_header_gui_input)
	detail_overlay.gui_input.connect(_on_detail_overlay_gui_input)
	detail_overlay.visible = false
	detail_overlay.z_as_relative = false
	detail_overlay.z_index = 1000
	detail_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	var detail_center: Control = $DetailOverlay/DetailCenter
	detail_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_header.mouse_filter = Control.MOUSE_FILTER_PASS
	popup_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_close.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_close.focus_mode = Control.FOCUS_ALL
	log_panel.visible = false
	event_ui_controller = EVENT_UI_CONTROLLER_SCRIPT.new()
	event_ui_controller.setup(
		event_column,
		event_dialog,
		event_dialog_title,
		event_dialog_subtitle,
		event_dialog_body_panel,
		event_dialog_body,
		event_dialog_slot_panel,
		event_dialog_slot_title,
		event_dialog_slot_row,
		event_dialog_assigned_title,
		event_dialog_assigned_row,
		Callable(self, "_event_body")
	)
	event_ui_controller.refresh_requested.connect(_refresh_board)
	event_ui_controller.target_drop_requested.connect(_on_target_drop_requested)
	event_ui_controller.detail_requested.connect(_on_detail_card_clicked)
	event_ui_controller.remove_requested.connect(_on_card_remove_requested)
	event_ui_controller.dialog_focus_requested.connect(_focus_event_dialog)
	_build_top_bar_layout()
	roster_row.add_theme_constant_override("separation", STACK_CARD_SEPARATION)
	resource_row.add_theme_constant_override("separation", STACK_CARD_SEPARATION)
	_apply_static_texts()
	_apply_visual_styles()
	_prepare_detail_panel_window()
	detail_panel.gui_input.connect(_on_detail_panel_gui_input)
	detail_header.gui_input.connect(_on_detail_header_gui_input)
	_configure_popup_for_detail()
	board_manager.reset_turn_targets(run_state.active_event_ids)
	_build_slots()
	_refresh_board()
	call_deferred("_show_tutorial_prompt_if_needed")

func _build_top_bar_layout() -> void:
	if fire_panel != null:
		return
	if top_info.get_parent() != top_bar_panel:
		return
	top_bar_panel.remove_child(top_info)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 6)
	top_bar_panel.add_child(margin)
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	top_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(top_info)
	fire_panel = PanelContainer.new()
	fire_panel.custom_minimum_size = Vector2(420.0, 0.0)
	fire_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(fire_panel)
	var fire_margin: MarginContainer = MarginContainer.new()
	fire_margin.add_theme_constant_override("margin_left", 10)
	fire_margin.add_theme_constant_override("margin_top", 8)
	fire_margin.add_theme_constant_override("margin_right", 10)
	fire_margin.add_theme_constant_override("margin_bottom", 8)
	fire_panel.add_child(fire_margin)
	var fire_box: VBoxContainer = VBoxContainer.new()
	fire_margin.add_child(fire_box)
	fire_track = Control.new()
	fire_track.custom_minimum_size = Vector2(388.0, 30.0)
	fire_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fire_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fire_box.add_child(fire_track)
	var rail: PanelContainer = PanelContainer.new()
	rail.name = "Rail"
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.anchor_left = 0.0
	rail.anchor_top = 0.5
	rail.anchor_right = 1.0
	rail.anchor_bottom = 0.5
	rail.offset_left = 10.0
	rail.offset_top = -4.0
	rail.offset_right = -10.0
	rail.offset_bottom = 4.0
	fire_track.add_child(rail)
	fire_fill = ColorRect.new()
	fire_fill.anchor_left = 0.0
	fire_fill.anchor_top = 0.5
	fire_fill.anchor_bottom = 0.5
	fire_fill.offset_left = 10.0
	fire_fill.offset_top = -4.0
	fire_fill.offset_bottom = 4.0
	fire_fill.color = Color(0.86, 0.38, 0.18, 0.88)
	fire_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fire_track.add_child(fire_fill)
	fire_marker = TextureRect.new()
	fire_marker.texture = FIRE_MARKER_TEXTURE
	fire_marker.custom_minimum_size = Vector2(24.0, 24.0)
	fire_marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fire_marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fire_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fire_track.add_child(fire_marker)
	top_bar_panel.resized.connect(_refresh_fire_progress)
	fire_track.resized.connect(_refresh_fire_progress)
	call_deferred("_refresh_fire_progress")

func _prepare_detail_panel_window() -> void:
	if detail_panel == null:
		return
	var current_parent: Node = detail_panel.get_parent()
	if current_parent != self:
		if current_parent != null:
			current_parent.remove_child(detail_panel)
		add_child(detail_panel)
	detail_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	detail_panel.anchor_right = 0.0
	detail_panel.anchor_bottom = 0.0
	detail_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	detail_panel.z_as_relative = false
	detail_panel.z_index = 18
	detail_panel.custom_minimum_size = DETAIL_PANEL_WINDOW_SIZE
	detail_panel.size = DETAIL_PANEL_WINDOW_SIZE
	detail_panel.clip_contents = true
	detail_header.mouse_filter = Control.MOUSE_FILTER_STOP
	detail_panel.visible = false
	_prepare_detail_assignment_scroll()

func _prepare_detail_assignment_scroll() -> void:
	if detail_assignment_row == null:
		return
	if detail_assignment_row.get_parent() is ScrollContainer:
		detail_assignment_scroll = detail_assignment_row.get_parent() as ScrollContainer
		return
	var parent_box: VBoxContainer = detail_assignment_row.get_parent() as VBoxContainer
	if parent_box == null:
		return
	var row_index: int = detail_assignment_row.get_index()
	parent_box.remove_child(detail_assignment_row)
	detail_assignment_scroll = ScrollContainer.new()
	detail_assignment_scroll.name = "DetailAssignmentScroll"
	detail_assignment_scroll.custom_minimum_size = Vector2(0.0, LIST_CARD_HEIGHT + 18.0)
	detail_assignment_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_assignment_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	detail_assignment_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	detail_assignment_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_assignment_scroll.clip_contents = true
	parent_box.add_child(detail_assignment_scroll)
	parent_box.move_child(detail_assignment_scroll, row_index)
	detail_assignment_scroll.add_child(detail_assignment_row)
	detail_assignment_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	detail_assignment_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

func _apply_detail_panel_window_size() -> void:
	if detail_panel == null:
		return
	detail_panel.custom_minimum_size = DETAIL_PANEL_WINDOW_SIZE
	detail_panel.size = DETAIL_PANEL_WINDOW_SIZE
	detail_panel.update_minimum_size()
	if detail_assignment_scroll != null:
		detail_assignment_scroll.custom_minimum_size = Vector2(0.0, LIST_CARD_HEIGHT + 18.0)

func _raise_window_layer(panel: Control) -> void:
	if panel == null:
		return
	detail_window_z_counter += 2
	panel.z_as_relative = false
	panel.z_index = detail_window_z_counter
	var panel_parent: Node = panel.get_parent()
	if panel_parent != null:
		panel_parent.move_child(panel, panel_parent.get_child_count() - 1)

func _focus_detail_panel() -> void:
	if detail_panel == null:
		return
	_raise_window_layer(detail_panel)

func _ensure_detail_panel_position(force_reset: bool = false) -> void:
	if detail_panel == null:
		return
	if force_reset or not detail_panel_has_position:
		detail_panel.position = _clamp_floating_panel_position(_default_detail_panel_position(), detail_panel)
		detail_panel_has_position = true
	else:
		detail_panel.position = _clamp_floating_panel_position(detail_panel.position, detail_panel)

func _default_detail_panel_position() -> Vector2:
	var slot_rect: Rect2 = slot_column.get_global_rect()
	var default_position: Vector2 = Vector2(slot_rect.position.x + slot_rect.size.x + 18.0, top_bar_panel.global_position.y + top_bar_panel.size.y + 12.0)
	if slot_rect.size == Vector2.ZERO:
		default_position = Vector2(24.0, 72.0)
	return default_position

func _clamp_floating_panel_position(position: Vector2, panel: Control) -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var panel_size: Vector2 = panel.size if panel.size != Vector2.ZERO else panel.custom_minimum_size
	return Vector2(
		clampf(position.x, 0.0, maxf(0.0, viewport_size.x - panel_size.x)),
		clampf(position.y, 0.0, maxf(0.0, viewport_size.y - panel_size.y))
	)

func _refresh_fire_progress() -> void:
	if run_state == null or fire_panel == null or fire_track == null or fire_marker == null or fire_fill == null:
		return
	var passed_terms: int = clampi(run_state.turn_index - 1, 0, GameRules.playable_turns())
	var track_width: float = fire_track.size.x
	var track_height: float = fire_track.size.y
	if track_width <= 0.0 or track_height <= 0.0:
		call_deferred("_refresh_fire_progress")
		return
	var marker_size: Vector2 = fire_marker.custom_minimum_size
	var padding: float = 10.0
	var usable_width: float = maxf(0.0, track_width - marker_size.x - padding * 2.0)
	var ratio: float = float(passed_terms) / float(maxi(GameRules.playable_turns(), 1))
	fire_fill.size = Vector2(marker_size.x * 0.5 + usable_width * ratio, 8.0)
	fire_fill.position = Vector2(padding, (track_height - fire_fill.size.y) * 0.5)
	fire_marker.position = Vector2(padding + usable_width * ratio, (track_height - marker_size.y) * 0.5 - 1.0)
	fire_marker.rotation = -0.08 + 0.16 * ratio
	fire_marker.modulate = Color(1.0, 1.0, 1.0, 0.84 + 0.16 * ratio)

func _apply_static_texts() -> void:
	end_turn_button.text = TextDB.get_text("ui.buttons.end_turn")
	toggle_log_button.text = TextDB.get_text("ui.buttons.show_log")
	popup_close.text = TextDB.get_text("ui.buttons.close")
	_set_popup_cancel_state(false, TextDB.get_text("turn_report.buttons.cancel", "Cancel"))
	detail_close.text = TextDB.get_text("ui.buttons.close")
	event_dialog_close.text = TextDB.get_text("ui.buttons.close")
	event_dialog_slot_title.text = TextDB.get_text("ui.detail_panel.assignment_title")
	event_dialog_assigned_title.text = ""
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
	var event_body_panel_style: StyleBoxFlat = body_style.duplicate() as StyleBoxFlat
	event_body_panel_style.bg_color = Color(0.03, 0.06, 0.09, 0.94)
	event_dialog_body_panel.add_theme_stylebox_override("panel", event_body_panel_style)
	event_dialog_body.add_theme_stylebox_override("normal", body_style)
	var event_slot_panel_style: StyleBoxFlat = StyleBoxFlat.new()
	event_slot_panel_style.bg_color = Color(0.03, 0.03, 0.04, 0.96)
	event_slot_panel_style.border_width_left = 1
	event_slot_panel_style.border_width_top = 1
	event_slot_panel_style.border_width_right = 1
	event_slot_panel_style.border_width_bottom = 1
	event_slot_panel_style.border_color = Color(0.18, 0.20, 0.23, 0.96)
	event_slot_panel_style.corner_radius_top_left = 8
	event_slot_panel_style.corner_radius_top_right = 8
	event_slot_panel_style.corner_radius_bottom_left = 8
	event_slot_panel_style.corner_radius_bottom_right = 8
	event_slot_panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	event_slot_panel_style.shadow_size = 8
	event_dialog_slot_panel.add_theme_stylebox_override("panel", event_slot_panel_style)

	var top_bar_style: StyleBoxFlat = StyleBoxFlat.new()
	top_bar_style.bg_color = Color(0.06, 0.06, 0.07, 0.96)
	top_bar_style.border_width_left = 1
	top_bar_style.border_width_top = 1
	top_bar_style.border_width_right = 1
	top_bar_style.border_width_bottom = 1
	top_bar_style.border_color = Color(0.24, 0.26, 0.30, 0.96)
	top_bar_style.corner_radius_top_left = 8
	top_bar_style.corner_radius_top_right = 8
	top_bar_style.corner_radius_bottom_left = 8
	top_bar_style.corner_radius_bottom_right = 8
	top_bar_style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
	top_bar_style.shadow_size = 8
	top_bar_panel.add_theme_stylebox_override("panel", top_bar_style)

	if fire_panel != null:
		var fire_panel_style: StyleBoxFlat = StyleBoxFlat.new()
		fire_panel_style.bg_color = Color(0.13, 0.10, 0.09, 0.94)
		fire_panel_style.border_width_left = 1
		fire_panel_style.border_width_top = 1
		fire_panel_style.border_width_right = 1
		fire_panel_style.border_width_bottom = 1
		fire_panel_style.border_color = Color(0.45, 0.24, 0.16, 0.92)
		fire_panel_style.corner_radius_top_left = 8
		fire_panel_style.corner_radius_top_right = 8
		fire_panel_style.corner_radius_bottom_left = 8
		fire_panel_style.corner_radius_bottom_right = 8
		fire_panel.add_theme_stylebox_override("panel", fire_panel_style)
		var rail: PanelContainer = fire_track.get_node_or_null("Rail") as PanelContainer
		if rail != null:
			var rail_style: StyleBoxFlat = StyleBoxFlat.new()
			rail_style.bg_color = Color(0.12, 0.10, 0.10, 0.96)
			rail_style.border_width_left = 1
			rail_style.border_width_top = 1
			rail_style.border_width_right = 1
			rail_style.border_width_bottom = 1
			rail_style.border_color = Color(0.24, 0.18, 0.16, 0.95)
			rail_style.corner_radius_top_left = 4
			rail_style.corner_radius_top_right = 4
			rail_style.corner_radius_bottom_left = 4
			rail_style.corner_radius_bottom_right = 4
			rail.add_theme_stylebox_override("panel", rail_style)

func _get_unlocked_slot_ids() -> Array[String]:
	if tutorial_manager != null and tutorial_manager.is_active(run_state):
		return tutorial_manager.unlocked_slot_ids(run_state)
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

func _current_slot_ids() -> Array[String]:
	var ids: Array[String] = []
	for child in slot_column.get_children():
		var slot_view = child as SlotView
		if slot_view == null:
			continue
		ids.append(str(slot_view.card_payload.get("id", "")))
	return ids

func _apply_unlocks() -> void:
	var rebuild_needed: bool = false
	if tutorial_manager != null and tutorial_manager.is_active(run_state):
		var desired_ids: Array[String] = tutorial_manager.unlocked_slot_ids(run_state)
		rebuild_needed = tutorial_manager.sync_unlock_flags(run_state)
		if _current_slot_ids() != desired_ids:
			rebuild_needed = true
		if rebuild_needed:
			_build_slots()
		return
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
	if tutorial_manager != null and tutorial_manager.is_active(run_state):
		return tutorial_manager.is_minimal_mode(run_state)
	return not bool(run_state.flags.get("first_governance_done", false))

func _refresh_layout_visibility() -> void:
	var minimal: bool = _is_minimal_mode()
	detail_panel.visible = detail_panel_open
	if detail_panel_open:
		_ensure_detail_panel_position()
	event_panel.visible = not minimal
	right_sidebar.visible = not minimal and _has_visible_leads()
	resource_scroll.visible = not minimal
	hands_panel.visible = true
	event_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if minimal:
		log_panel.visible = false
		hands_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		roster_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		resource_scroll.size_flags_vertical = Control.SIZE_FILL
		event_panel.custom_minimum_size = Vector2(0.0, 0.0)
	else:
		hands_panel.size_flags_vertical = Control.SIZE_FILL
		roster_scroll.size_flags_vertical = Control.SIZE_FILL
		resource_scroll.size_flags_vertical = Control.SIZE_FILL
		event_panel.custom_minimum_size = Vector2(0.0, 236.0)
	toggle_log_button.visible = not minimal
	roster_scroll.custom_minimum_size = Vector2(0.0, 194.0 if minimal else 148.0)
	resource_scroll.custom_minimum_size = Vector2(0.0, 0.0 if minimal else 118.0)

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
	if run_state.game_over:
		end_turn_button.disabled = true
		detail_panel.visible = true
		detail_panel_open = true
		detail_body.text = _game_over_text()
		if not defer_settlement_popup:
			_refresh_settlement_sequence()

func _ensure_popup_cancel_button() -> void:
	if popup_cancel != null:
		return
	popup_cancel = Button.new()
	popup_cancel.custom_minimum_size = Vector2(92.0, 42.0)
	popup_cancel.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_cancel.focus_mode = Control.FOCUS_ALL
	popup_cancel.visible = false
	popup_cancel.pressed.connect(_on_popup_cancel_pressed)
	popup_header.add_child(popup_cancel)
	popup_header.move_child(popup_cancel, popup_header.get_child_count() - 2)

func _set_popup_cancel_state(visible: bool, text: String = "") -> void:
	if popup_cancel == null:
		return
	popup_cancel.visible = visible
	if not text.is_empty():
		popup_cancel.text = text

func _refresh_top_bar() -> void:
	for child in top_info.get_children():
		child.queue_free()
	var items: Array[String] = []
	var shown_turn: int = run_state.turn_index
	var total_turns: int = GameRules.settlement_turn() if GameRules.is_settlement_turn(shown_turn) else GameRules.playable_turns()
	var term_name: String = GameRules.current_term_name(shown_turn)
	var camp: Dictionary = GameRules.current_camp_attributes(run_state, characters)
	items.append(TextDB.format_text("ui.status.term", [term_name, shown_turn, total_turns]))
	items.append(_camp_status_text("supplies", int(camp.get("supplies", 0))))
	items.append(_camp_status_text("forces", int(camp.get("forces", 0))))
	items.append(_camp_status_text("cohesion", int(camp.get("cohesion", 0))))
	items.append(_camp_status_text("strategy", int(camp.get("strategy", 0))))
	for item in items:
		var label: Label = Label.new()
		label.text = item
		top_info.add_child(label)
	_refresh_fire_progress()

func _camp_status_text(attribute_id: String, value: int) -> String:
	var label_text: String = TextDB.get_text("system.camp_attributes.%s" % attribute_id, attribute_id)
	return "%s %d" % [label_text, value]

func _game_over_text() -> String:
	var ending_tier: String = str(run_state.flags.get("ending_tier", "bad"))
	var sections: Array[String] = [TextDB.format_text(_ending_message_key(ending_tier), [run_state.ending_id])]
	if not run_state.settlement_report.is_empty():
		sections.append("[b]%s[/b]\n%s" % [TextDB.get_text("ui.finale.report_title"), "\n".join(run_state.settlement_report)])
	if not run_state.personal_epilogues.is_empty():
		sections.append("[b]%s[/b]\n%s" % [TextDB.get_text("ui.finale.personal_title"), "\n".join(run_state.personal_epilogues)])
	return "\n\n".join(sections)

func _ending_message_key(ending_tier: String) -> String:
	match ending_tier:
		"good":
			return "ui.messages.good_ending"
		"favorable":
			return "ui.messages.favorable_ending"
		"normal":
			return "ui.messages.normal_ending"
		"defeat":
			return "ui.messages.defeat_ending"
		_:
			return "ui.messages.bad_ending"

func _refresh_settlement_sequence() -> void:
	if run_state == null or not run_state.game_over:
		return
	var pages: Array = _settlement_pages()
	if pages.is_empty():
		return
	if settlement_page_index >= pages.size():
		return
	if settlement_page_index < 0:
		settlement_page_index = 0
	settlement_dialog_active = true
	_configure_popup_for_settlement()
	_show_settlement_page(pages)

func _settlement_pages() -> Array:
	if run_state == null:
		return []
	if not run_state.settlement_pages.is_empty():
		return run_state.settlement_pages
	return [{
		"title": TextDB.get_text("ui.finale.report_title"),
		"body": TextDB.format_text(_ending_message_key(str(run_state.flags.get("ending_tier", "bad"))), [run_state.ending_id])
	}]

func _show_settlement_page(pages: Array = []) -> void:
	var active_pages: Array = pages if not pages.is_empty() else _settlement_pages()
	if active_pages.is_empty():
		return
	settlement_page_index = clampi(settlement_page_index, 0, active_pages.size() - 1)
	var page: Dictionary = active_pages[settlement_page_index] as Dictionary
	popup_title.text = str(page.get("title", TextDB.get_text("ui.finale.report_title")))
	popup_subtitle.text = str(page.get("subtitle", TextDB.format_text("ui.finale.step_counter", [settlement_page_index + 1, active_pages.size()])))
	popup_subtitle.visible = not popup_subtitle.text.strip_edges().is_empty()
	popup_body.text = str(page.get("body", ""))
	popup_art.texture = null
	popup_close.text = TextDB.get_text("ui.buttons.finish") if settlement_page_index >= active_pages.size() - 1 else TextDB.get_text("ui.buttons.next")
	detail_overlay.visible = true

func _configure_popup_for_settlement() -> void:
	popup_panel.custom_minimum_size = POPUP_SETTLEMENT_SIZE
	popup_art_frame.visible = false
	_set_popup_cancel_state(false)

func _configure_popup_for_confirm() -> void:
	popup_panel.custom_minimum_size = POPUP_CONFIRM_SIZE
	popup_art_frame.visible = false
	popup_close.text = TextDB.get_text("turn_report.buttons.confirm")
	_set_popup_cancel_state(true, TextDB.get_text("turn_report.buttons.cancel"))

func _configure_popup_for_turn_report() -> void:
	popup_panel.custom_minimum_size = POPUP_TURN_REPORT_SIZE
	popup_art_frame.visible = false
	popup_close.text = TextDB.get_text("turn_report.buttons.close")
	_set_popup_cancel_state(false)

func _configure_popup_for_message() -> void:
	popup_panel.custom_minimum_size = POPUP_MESSAGE_SIZE
	popup_art_frame.visible = false
	popup_close.text = TextDB.get_text("turn_report.buttons.close")
	_set_popup_cancel_state(false)

func _show_message_popup(title: String, subtitle: String, body: String) -> void:
	settlement_dialog_active = false
	end_turn_confirm_active = false
	turn_report_dialog_active = false
	_configure_popup_for_message()
	popup_title.text = title
	popup_subtitle.text = subtitle
	popup_subtitle.visible = not subtitle.strip_edges().is_empty()
	popup_body.text = body
	popup_body.scroll_to_line(0)
	popup_art.texture = null
	detail_overlay.visible = true

func _show_tutorial_prompt_if_needed(force: bool = false) -> bool:
	if tutorial_manager == null or run_state == null:
		return false
	if detail_overlay.visible:
		return false
	var prompt: Dictionary = tutorial_manager.force_prompt(run_state) if force else tutorial_manager.consume_prompt(run_state)
	if prompt.is_empty():
		return false
	_show_message_popup(str(prompt.get("title", "")), str(prompt.get("subtitle", "")), str(prompt.get("body", "")))
	return true

func _show_tutorial_followup_if_needed() -> bool:
	if tutorial_manager == null or run_state == null or detail_overlay.visible:
		return false
	var popup: Dictionary = tutorial_manager.consume_followup_popup(run_state)
	if popup.is_empty():
		return false
	_show_message_popup(str(popup.get("title", "")), str(popup.get("subtitle", "")), str(popup.get("body", "")))
	tutorial_prompt_after_popup = bool(popup.get("chain_to_prompt", false))
	return true

func _configure_popup_for_detail() -> void:
	popup_panel.custom_minimum_size = POPUP_DETAIL_SIZE
	popup_art_frame.visible = true
	popup_close.text = TextDB.get_text("ui.buttons.close")
	_set_popup_cancel_state(false)

func _on_popup_close_pressed() -> void:
	if settlement_dialog_active:
		_advance_settlement_dialog()
		return
	if end_turn_confirm_active:
		_confirm_end_turn()
		return
	if turn_report_dialog_active:
		_close_turn_report_dialog()
		return
	_close_detail_popup()

func _on_popup_cancel_pressed() -> void:
	if end_turn_confirm_active:
		_close_detail_popup()

func _on_popup_panel_gui_input(event: InputEvent) -> void:
	if not detail_overlay.visible:
		return
	if event is not InputEventMouseButton:
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	var mouse_pos: Vector2 = get_global_mouse_position()
	if popup_cancel != null and popup_cancel.visible and popup_cancel.get_global_rect().has_point(mouse_pos):
		_on_popup_cancel_pressed()
		accept_event()
		return
	if popup_close != null and popup_close.visible and popup_close.get_global_rect().has_point(mouse_pos):
		_on_popup_close_pressed()
		accept_event()

func _advance_settlement_dialog() -> void:
	var pages: Array = _settlement_pages()
	if pages.is_empty():
		settlement_dialog_active = false
		_close_detail_popup()
		return
	if settlement_page_index >= pages.size() - 1:
		settlement_dialog_active = false
		settlement_page_index = pages.size()
		detail_overlay.visible = false
		_configure_popup_for_detail()
		return
	settlement_page_index += 1
	_show_settlement_page(pages)

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
		"card_width": LIST_CARD_WIDTH,
		"art_height": LIST_CARD_ART_HEIGHT,
		"current_cards": board_manager.get_slot_cards(slot_id),
		"collapsed_height": LIST_CARD_HEIGHT,
		"expanded_height": LIST_CARD_HEIGHT
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
	if event_ui_controller == null:
		return
	event_ui_controller.refresh(run_state, events, board_manager, _is_minimal_mode(), get_viewport_rect().size)

func _build_committed_preview(card: Dictionary) -> CardView:
	return _build_committed_preview_with_size(card, LIST_CARD_WIDTH, LIST_CARD_HEIGHT, LIST_CARD_ART_HEIGHT)

func _build_committed_preview_with_size(card: Dictionary, card_width: float, card_height: float, art_height: float) -> CardView:
	var preview: CardView = CARD_SCENE.instantiate()
	var payload: Dictionary = card.duplicate(true)
	payload["subtitle"] = ""
	payload["body"] = ""
	payload["compact_details"] = true
	payload["card_width"] = card_width
	payload["art_height"] = art_height
	payload["collapsed_height"] = card_height
	payload["expanded_height"] = card_height
	payload["show_subtitle_in_compact"] = false
	payload["show_assigned_in_compact"] = false
	payload["assigned"] = true
	payload["removable"] = true
	payload["embedded"] = true
	preview.setup(payload)
	preview.custom_minimum_size = Vector2(card_width, card_height)
	preview.card_clicked.connect(_on_detail_card_clicked)
	preview.remove_requested.connect(_on_card_remove_requested)
	return preview

func _refresh_roster() -> void:
	for child in roster_row.get_children():
		child.queue_free()
	var character_ids: Array[String] = []
	for character_id_variant in run_state.roster_ids:
		var character_id: String = str(character_id_variant)
		if characters.has(character_id):
			character_ids.append(character_id)
	for character_id in character_ids:
		if not characters.has(character_id):
			continue
		var character_uid: String = "character:%s" % character_id
		if board_manager.is_committed(character_uid):
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
			"card_width": LIST_CARD_WIDTH,
			"art_height": LIST_CARD_ART_HEIGHT,
			"collapsed_height": LIST_CARD_HEIGHT,
			"expanded_height": 236.0
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
		var total_amount: int = int(run_state.resource_states[resource_id])
		if total_amount <= 0:
			continue
		var available_amount: int = _available_resource_count(resource_id, total_amount)
		if available_amount <= 0:
			continue
		var uid: String = _first_available_resource_uid(resource_id, total_amount)
		if uid.is_empty():
			continue
		var data: ResourceCardData = resources[resource_id] as ResourceCardData
		var card: CardView = CARD_SCENE.instantiate()
		card.setup({
			"uid": uid,
			"id": resource_id,
			"card_type": "resource",
			"title": data.display_name,
			"subtitle": _resource_category_text(data.category),
			"body": data.description,
			"tags": data.tags,
			"stack_count": available_amount,
			"assigned": false,
			"assigned_text": "",
			"image_path": data.art_path,
			"image_label": data.display_name,
			"art_bg_color": Color(0.18, 0.18, 0.19),
			"color": Color(0.11, 0.11, 0.12),
			"compact_details": true,
			"show_subtitle_in_compact": false,
			"show_assigned_in_compact": false,
			"card_width": LIST_CARD_WIDTH,
			"art_height": LIST_CARD_ART_HEIGHT,
			"collapsed_height": LIST_CARD_HEIGHT,
			"expanded_height": 214.0
		})
		card.card_clicked.connect(_on_detail_card_clicked)
		card.quick_assign_requested.connect(_on_card_quick_assign_requested)
		card.remove_requested.connect(_on_card_remove_requested)
		resource_row.add_child(card)

func _available_resource_count(resource_id: String, total_amount: int) -> int:
	var available_amount: int = 0
	for index in range(total_amount):
		var uid: String = "resource:%s:%d" % [resource_id, index]
		if not board_manager.is_committed(uid):
			available_amount += 1
	return available_amount

func _first_available_resource_uid(resource_id: String, total_amount: int) -> String:
	for index in range(total_amount):
		var uid: String = "resource:%s:%d" % [resource_id, index]
		if not board_manager.is_committed(uid):
			return uid
	return ""

func _refresh_leads() -> void:
	for child in lead_row.get_children():
		child.queue_free()
	if run_state == null:
		return
	for risk_id_variant in risks.keys():
		var risk_id: String = str(risk_id_variant)
		var total_amount: int = int(run_state.risk_states.get(risk_id, 0))
		if total_amount <= 0:
			continue
		var available_amount: int = _available_risk_count(risk_id, total_amount)
		if available_amount <= 0:
			continue
		var uid: String = _first_available_risk_uid(risk_id, total_amount)
		if uid.is_empty():
			continue
		var risk_data: RiskCardData = risks[risk_id] as RiskCardData
		var card: CardView = CARD_SCENE.instantiate()
		card.setup({
			"uid": uid,
			"id": risk_id,
			"card_type": "risk",
			"title": risk_data.display_name,
			"subtitle": TextDB.format_text("system.risk_detail.current", [total_amount]),
			"body": _risk_body(risk_data, total_amount),
			"tags": ["risk", risk_id],
			"stack_count": available_amount,
			"assigned": false,
			"assigned_text": "",
			"image_path": risk_data.art_path,
			"image_label": risk_data.display_name,
			"art_bg_color": Color(0.18, 0.18, 0.19),
			"color": Color(0.10, 0.10, 0.11),
			"compact_details": true,
			"show_subtitle_in_compact": false,
			"show_assigned_in_compact": false,
			"card_width": LIST_CARD_WIDTH,
			"art_height": LIST_CARD_ART_HEIGHT,
			"collapsed_height": LIST_CARD_HEIGHT,
			"expanded_height": 214.0
		})
		card.card_clicked.connect(_on_detail_card_clicked)
		card.remove_requested.connect(_on_card_remove_requested)
		lead_row.add_child(card)

func _has_visible_leads() -> bool:
	if run_state == null:
		return false
	for risk_id_variant in risks.keys():
		var risk_id: String = str(risk_id_variant)
		var total_amount: int = int(run_state.risk_states.get(risk_id, 0))
		if _available_risk_count(risk_id, total_amount) > 0:
			return true
	return false

func _available_risk_count(risk_id: String, total_amount: int) -> int:
	var available_amount: int = 0
	for index in range(total_amount):
		var uid: String = "risk:%s:%d" % [risk_id, index]
		if not board_manager.is_committed(uid):
			available_amount += 1
	return available_amount

func _first_available_risk_uid(risk_id: String, total_amount: int) -> String:
	for index in range(total_amount):
		var uid: String = "risk:%s:%d" % [risk_id, index]
		if not board_manager.is_committed(uid):
			return uid
	return ""

func _refresh_log() -> void:
	var start_index: int = maxi(0, run_state.log_entries.size() - 4)
	var recent: Array[String] = []
	for index in range(start_index, run_state.log_entries.size()):
		recent.append(str(run_state.log_entries[index]))
	log_label.text = "  |  ".join(recent)

func _refresh_detail() -> void:
	if selected_slot_id.is_empty():
		if tutorial_manager != null and run_state != null and tutorial_manager.is_active(run_state):
			detail_panel_open = false
			detail_panel.visible = false
			return
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
	var camp: Dictionary = GameRules.current_camp_attributes(run_state, characters)
	var camp_line: String = TextDB.format_text(
		"ui.finale.camp_line",
		[
			int(camp.get("supplies", 0)),
			int(camp.get("forces", 0)),
			int(camp.get("cohesion", 0)),
			int(camp.get("strategy", 0))
		]
	)
	var overview_body: String = TextDB.format_text(
		"ui.messages.overview",
		[
			run_state.jingzhou_stability,
			run_state.naval_readiness,
			run_state.alliance_strength,
			guo_stage,
			camp_line,
			"\n".join(risk_lines)
		]
	)
	if tutorial_manager != null:
		var tutorial_hint: String = tutorial_manager.overview_hint(run_state)
		if not tutorial_hint.strip_edges().is_empty():
			overview_body += "\n\n[b]教学提示[/b]\n" + tutorial_hint
	_detail_setup(
		TextDB.get_text("ui.detail_panel.overview_title"),
		TextDB.get_text("ui.detail_panel.overview_subtitle"),
		overview_body,
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
	elif risks.has(card_id):
		var data_risk: RiskCardData = risks[card_id] as RiskCardData
		var count: int = int(run_state.risk_states.get(card_id, 0))
		detail_body.text = "[b]%s[/b]\n%s" % [data_risk.display_name, _risk_body(data_risk, count)]


func _on_detail_card_clicked(card_id: String) -> void:
	_open_detail_popup(card_id)

func _detail_window_key(card_id: String) -> String:
	if characters.has(card_id):
		return "character:%s" % card_id
	if resources.has(card_id):
		return "resource:%s" % card_id
	if events.has(card_id):
		return "event:%s" % card_id
	if risks.has(card_id):
		return "risk:%s" % card_id
	return "detail:%s" % card_id

func _open_detail_popup(card_id: String) -> void:
	var payload: Dictionary = _build_popup_payload(card_id)
	if payload.is_empty():
		return
	if detail_window_layer == null:
		_build_detail_window_layer()
	var window_key: String = _detail_window_key(card_id)
	var existing_window = detail_window_by_key.get(window_key, null)
	if existing_window != null and is_instance_valid(existing_window):
		_focus_detail_window(existing_window)
		return
	if detail_window_by_key.has(window_key):
		detail_window_by_key.erase(window_key)
	var window = FLOATING_DETAIL_WINDOW_SCRIPT.new()
	window.set_meta("detail_key", window_key)
	window.setup(payload)
	detail_window_layer.add_child(window)
	active_detail_windows.append(window)
	detail_window_by_key[window_key] = window
	window.close_requested.connect(_on_floating_detail_window_close_requested)
	window.focus_requested.connect(_on_floating_detail_window_focus_requested)
	window.drag_requested.connect(_on_floating_detail_window_drag_requested)
	_focus_detail_window(window)
	_position_detail_window(window)

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
			"image_path": data.art_path,
			"window_size": CHARACTER_DETAIL_WINDOW_SIZE,
			"art_size": CHARACTER_DETAIL_ART_SIZE
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
	if risks.has(card_id):
		var data_risk: RiskCardData = risks[card_id] as RiskCardData
		return {
			"title": data_risk.display_name,
			"subtitle": TextDB.format_text("system.risk_detail.current", [int(run_state.risk_states.get(card_id, 0))]),
			"body": _risk_body(data_risk, int(run_state.risk_states.get(card_id, 0))),
			"image_path": data_risk.art_path
		}
	return {}

func _build_detail_window_layer() -> void:
	if detail_window_layer != null:
		return
	detail_window_layer = Control.new()
	detail_window_layer.name = "DetailWindowLayer"
	detail_window_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	detail_window_layer.anchor_right = 1.0
	detail_window_layer.anchor_bottom = 1.0
	detail_window_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_window_layer.z_as_relative = false
	detail_window_layer.z_index = 18
	add_child(detail_window_layer)

func _focus_detail_window(window) -> void:
	if window == null or not is_instance_valid(window):
		return
	if detail_window_layer != null:
		_raise_window_layer(detail_window_layer)
		if window.get_parent() == detail_window_layer:
			window.z_as_relative = true
			window.z_index = 0
			detail_window_layer.move_child(window, detail_window_layer.get_child_count() - 1)

func _focus_event_dialog() -> void:
	if event_dialog == null:
		return
	_raise_window_layer(event_dialog)

func _position_detail_window(window) -> void:
	if window == null or not is_instance_valid(window):
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var window_size: Vector2 = window.custom_minimum_size if window.custom_minimum_size != Vector2.ZERO else window.size
	var offset_index: int = detail_window_spawn_index % 6
	var base_position: Vector2 = Vector2((viewport_size.x - window_size.x) * 0.5, (viewport_size.y - window_size.y) * 0.5)
	base_position += Vector2(24.0 * offset_index, 18.0 * offset_index)
	window.position = _clamp_detail_window_position(base_position, window)
	window.size = window_size
	detail_window_spawn_index += 1

func _clamp_detail_window_position(position: Vector2, window: Control) -> Vector2:
	return _clamp_floating_panel_position(position, window)

func _on_floating_detail_window_close_requested(window) -> void:
	if window == dragging_detail_window:
		dragging_detail_window = null
	var detail_key: String = ""
	if window != null:
		detail_key = str(window.get_meta("detail_key", ""))
	if not detail_key.is_empty() and detail_window_by_key.get(detail_key, null) == window:
		detail_window_by_key.erase(detail_key)
	active_detail_windows.erase(window)
	if window != null and is_instance_valid(window):
		window.queue_free()

func _on_floating_detail_window_focus_requested(window) -> void:
	_focus_detail_window(window)

func _on_floating_detail_window_drag_requested(window, mouse_global_position: Vector2) -> void:
	if window == null or not is_instance_valid(window):
		return
	_focus_detail_window(window)
	dragging_detail_window = window
	detail_window_drag_offset = mouse_global_position - window.global_position

func _close_detail_popup() -> void:
	settlement_dialog_active = false
	end_turn_confirm_active = false
	turn_report_dialog_active = false
	_configure_popup_for_detail()
	detail_overlay.visible = false
	if tutorial_prompt_after_popup:
		tutorial_prompt_after_popup = false
		_show_tutorial_prompt_if_needed()

func _close_all_detail_views() -> void:
	dragging_detail_panel = false
	selected_slot_id = ""
	detail_panel_open = false
	if detail_panel != null:
		detail_panel.visible = false
	if event_ui_controller != null:
		event_ui_controller.close_dialog(false)
	dragging_detail_window = null
	for window in active_detail_windows.duplicate():
		if window != null and is_instance_valid(window):
			window.queue_free()
	active_detail_windows.clear()
	detail_window_by_key.clear()
	if detail_overlay.visible and not settlement_dialog_active:
		_close_detail_popup()

func _on_slot_card_clicked(slot_id: String) -> void:
	_show_slot_detail(slot_id, true)

func _show_slot_detail(slot_id: String, focus_window: bool = false) -> void:
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
		TextDB.get_text("ui.detail_panel.slot_hint"),
		focus_window
	)

func _detail_setup(title: String, subtitle: String, body: String, icon_path: String, assigned_cards: Array, footnote: String, focus_window: bool = false) -> void:
	var detail_panel_was_visible: bool = detail_panel.visible
	detail_panel_open = true
	detail_panel.visible = true
	_apply_detail_panel_window_size()
	_ensure_detail_panel_position()
	if focus_window or not detail_panel_was_visible:
		_focus_detail_panel()
	detail_title.text = title
	detail_subtitle.text = subtitle
	detail_subtitle.visible = not subtitle.strip_edges().is_empty()
	detail_body.text = body
	detail_assignment_title.text = TextDB.get_text("ui.detail_panel.assignment_title")
	detail_assignment_title.visible = true
	detail_assignment_row.visible = true
	detail_footnote.text = footnote
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		detail_icon.texture = load(icon_path) as Texture2D
	else:
		detail_icon.texture = null
	_refresh_detail_assignment_row(selected_slot_id, assigned_cards)
	call_deferred("_apply_detail_panel_window_size")

func _build_detail_assignment_well(content: Control) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(LIST_CARD_WIDTH, LIST_CARD_HEIGHT)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.03, 0.04, 0.98)
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
	var center: CenterContainer = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(center)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.visible = true
	content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(content)
	return panel

func _refresh_detail_assignment_row(slot_id: String, assigned_cards: Array) -> void:
	for child in detail_assignment_row.get_children():
		child.queue_free()
	detail_assignment_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	var remaining_slots: int = _detail_remaining_capacity(slot_id, assigned_cards)
	var display_cards: Array = _group_assigned_cards_for_display(assigned_cards)
	var total_slots: int = display_cards.size() + remaining_slots
	var layout: Dictionary = _detail_assignment_layout(total_slots)
	var card_width: float = float(layout.get("card_width", LIST_CARD_WIDTH))
	var card_height: float = float(layout.get("card_height", LIST_CARD_HEIGHT))
	var art_height: float = float(layout.get("art_height", LIST_CARD_ART_HEIGHT))
	for card_variant in display_cards:
		var card: Dictionary = card_variant as Dictionary
		var preview: CardView = _build_committed_preview_with_size(card, card_width, card_height, art_height)
		preview.custom_minimum_size = Vector2(card_width, card_height)
		preview.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		preview.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		detail_assignment_row.add_child(preview)
	for index in range(remaining_slots):
		var placeholder: SlotView = SLOT_SCENE.instantiate()
		placeholder.custom_minimum_size = Vector2(card_width, card_height)
		placeholder.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		placeholder.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
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
			"art_bg_color": Color(0.04, 0.05, 0.06, 1.0),
			"color": Color(0.08, 0.09, 0.10, 1.0),
			"compact_details": true,
			"hide_title": true,
			"hide_subtitle": true,
			"hide_assigned": true,
			"hide_body": true,
			"drop_slot": true,
			"embedded": true,
			"card_width": card_width,
			"art_height": art_height,
			"current_cards": assigned_cards,
			"collapsed_height": card_height,
			"expanded_height": card_height
		}, true)
		placeholder.target_drop_requested.connect(_on_target_drop_requested)
		detail_assignment_row.add_child(placeholder)

func _detail_remaining_capacity(slot_id: String, assigned_cards: Array) -> int:
	var total_capacity: int = -1
	if tutorial_manager != null:
		total_capacity = tutorial_manager.total_capacity_override(run_state, slot_id)
	if total_capacity < 0:
		var capacities: Dictionary = GameRules.SLOT_CAPACITY.get(slot_id, {})
		total_capacity = 0
		for value_variant in capacities.values():
			total_capacity += int(value_variant)
	return maxi(0, total_capacity - assigned_cards.size())

func _detail_assignment_layout(total_slots: int) -> Dictionary:
	var safe_total: int = maxi(total_slots, 1)
	var spacing: float = 8.0
	var available_width: float = DETAIL_PANEL_WINDOW_SIZE.x - 48.0
	var card_width: float = floor((available_width - spacing * float(maxi(safe_total - 1, 0))) / float(safe_total))
	card_width = clampf(card_width, 88.0, LIST_CARD_WIDTH)
	var card_height: float = round(card_width * 4.0 / 3.0)
	var art_height: float = round(card_height * 0.725)
	return {
		"card_width": card_width,
		"card_height": card_height,
		"art_height": art_height
	}

func _group_assigned_cards_for_display(cards: Array) -> Array:
	var display_cards: Array = []
	var resource_groups: Dictionary = {}
	for card_variant in cards:
		var card: Dictionary = card_variant as Dictionary
		if str(card.get("card_type", "")) != "resource":
			display_cards.append(card)
			continue
		var resource_id: String = str(card.get("id", ""))
		if not resource_groups.has(resource_id):
			var grouped_card: Dictionary = card.duplicate(true)
			grouped_card["stack_count"] = 1
			resource_groups[resource_id] = grouped_card
			display_cards.append(grouped_card)
			continue
		var existing_group: Dictionary = resource_groups[resource_id] as Dictionary
		existing_group["stack_count"] = int(existing_group.get("stack_count", 1)) + 1
		resource_groups[resource_id] = existing_group
	return display_cards

func _decorate_body_with_tags(base_text: String, tags: Array) -> String:
	if tags.is_empty():
		return base_text
	return "%s\n\n%s" % [base_text, TextDB.format_text("system.traits.line", [_join_tag_texts(tags)])]

func _resource_body(data_res: ResourceCardData) -> String:
	return _decorate_body_with_tags(data_res.description, data_res.tags)

func _event_body(data_event: EventData) -> String:
	var sections: Array[String] = [data_event.description, event_manager.describe_event_rules(data_event, run_state)]
	return _decorate_body_with_tags("\n\n".join(sections), data_event.tags)

func _risk_body(data_risk: RiskCardData, count: int) -> String:
	var lines: Array[String] = [data_risk.description, ""]
	lines.append(TextDB.format_text("system.risk_detail.current", [count]))
	lines.append(TextDB.get_text("system.risk_detail.penalty_title"))
	lines.append(TextDB.format_text("system.risk_detail.mild", [_penalty_dictionary_text(data_risk.mild_penalty)]))
	lines.append(TextDB.format_text("system.risk_detail.severe", [_penalty_dictionary_text(data_risk.severe_penalty)]))
	lines.append(TextDB.format_text("system.risk_detail.ending", [data_risk.bad_ending_id]))
	return "\n".join(lines)

func _penalty_dictionary_text(penalty: Dictionary) -> String:
	if penalty.is_empty():
		return TextDB.get_text("ui.fallback.none")
	var parts: Array[String] = []
	var ordered_keys: Array[String] = ["health", "mind", "morale", "stability", "naval", "alliance", "fire"]
	for key in ordered_keys:
		if penalty.has(key):
			parts.append("%s %s" % [_penalty_target_text(key), _signed_delta_text(int(penalty[key]))])
	for key_variant in penalty.keys():
		var extra_key: String = str(key_variant)
		if ordered_keys.has(extra_key):
			continue
		parts.append("%s %s" % [_penalty_target_text(extra_key), _signed_delta_text(int(penalty[key_variant]))])
	return TextDB.get_text("ui.list_separator").join(parts)

func _penalty_target_text(target_id: String) -> String:
	return TextDB.get_text("system.penalty_targets.%s" % target_id, target_id)

func _signed_delta_text(value: int) -> String:
	return "+%d" % value if value > 0 else str(value)

func _slot_assigned_line(names: Array[String]) -> String:
	return TextDB.format_text("ui.slot_detail.assigned", [_join_name_texts(names)])

func _join_name_texts(names: Array[String]) -> String:
	var separator: String = TextDB.get_text("ui.list_separator")
	return separator.join(names)

func _tutorial_allows_assignment(target_id: String, payload: Dictionary) -> bool:
	if tutorial_manager == null:
		return true
	return tutorial_manager.can_assign(run_state, board_manager, target_id, payload)

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
	var expanded_event_id: String = event_ui_controller.get_expanded_event_id() if event_ui_controller != null else ""
	if not expanded_event_id.is_empty():
		var expanded_target: Dictionary = _event_quick_target(expanded_event_id, payload, 260)
		if not expanded_target.is_empty():
			best_target = expanded_target
			best_score = int(expanded_target.get("score", -999))
	elif not selected_slot_id.is_empty():
		var selected_score: int = GameRules.quick_assign_score(selected_slot_id, payload, board_manager.get_slot_cards(selected_slot_id))
		if selected_score >= 0 and _tutorial_allows_assignment(selected_slot_id, payload):
			best_target = {
				"kind": "slot",
				"slot_id": selected_slot_id,
				"score": 240 + selected_score,
				"label": TextDB.get_text("system.slots.%s.title" % selected_slot_id)
			}
			best_score = int(best_target.get("score", -999))
	for slot_id in _get_unlocked_slot_ids():
		if slot_id == selected_slot_id and best_score >= 240:
			continue
		if not _tutorial_allows_assignment(slot_id, payload):
			continue
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
	if not _tutorial_allows_assignment("%s:%s" % [event_id, slot_type], payload):
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
	var current_attrs: Dictionary = GameRules.current_character_attributes(data, run_state.active_character_states.get(character_id, {}))
	var lines: Array[String] = []
	if not bio.strip_edges().is_empty():
		lines.append(bio)
		lines.append("")
	lines.append("专长：%s" % _join_specialty_texts(data.specialty_tags))
	lines.append(
		"当前属性：%s %d / %s %d / %s %d" % [
			_attribute_text("strength"),
			int(current_attrs.get("strength", 0)),
			_attribute_text("agility"),
			int(current_attrs.get("agility", 0)),
			_attribute_text("constitution"),
			int(current_attrs.get("constitution", 0))
		]
	)
	lines.append(
		"%s %d / %s %d / %s %d" % [
			_attribute_text("intelligence"),
			int(current_attrs.get("intelligence", 0)),
			_attribute_text("perception"),
			int(current_attrs.get("perception", 0)),
			_attribute_text("charisma"),
			int(current_attrs.get("charisma", 0))
		]
	)
	lines.append(TextDB.get_text("system.character_templates.current_note"))
	if character_id == "guo_jia":
		lines.append(TextDB.format_text("system.character_templates.guojia_stage", [int(run_state.active_character_states["guo_jia"]["sick_stage"])]))
	if locked:
		lines.append(TextDB.get_text("system.character_templates.locked_hint"))
	return "\n".join(lines)

func _on_target_drop_requested(target_id: String, payload: Dictionary) -> void:
	if payload == null:
		return
	if not _tutorial_allows_assignment(target_id, payload):
		run_state.log_entries.append(TextDB.get_text("logs.board.invalid_drop"))
		_refresh_board()
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
			_focus_detail_panel()
	_refresh_board()

func _on_event_dialog_close_pressed() -> void:
	if event_ui_controller != null:
		event_ui_controller.close_dialog()

func _on_event_dialog_header_gui_input(event: InputEvent) -> void:
	if event_ui_controller != null:
		event_ui_controller.handle_header_input(event, get_global_mouse_position())

func _close_detail_panel() -> void:
	selected_slot_id = ""
	detail_panel_open = false
	dragging_detail_panel = false
	detail_panel.visible = false
	_refresh_board()

func _on_detail_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_focus_detail_panel()

func _on_detail_header_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_focus_detail_panel()
			dragging_detail_panel = true
			detail_panel_drag_offset = get_global_mouse_position() - detail_panel.global_position
			accept_event()

func _on_detail_overlay_gui_input(event: InputEvent) -> void:
	if not detail_overlay.visible:
		return
	if settlement_dialog_active or end_turn_confirm_active or turn_report_dialog_active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not popup_panel.get_global_rect().has_point(get_global_mouse_position()):
			_close_detail_popup()

func _show_end_turn_confirm_dialog() -> void:
	end_turn_confirm_active = true
	turn_report_dialog_active = false
	settlement_dialog_active = false
	_configure_popup_for_confirm()
	popup_title.text = TextDB.get_text("turn_report.confirm.title")
	popup_subtitle.text = TextDB.get_text("turn_report.confirm.subtitle")
	popup_subtitle.visible = not popup_subtitle.text.strip_edges().is_empty()
	popup_body.text = TextDB.get_text("turn_report.confirm.body")
	popup_body.scroll_to_line(0)
	popup_art.texture = null
	detail_overlay.visible = true

func _build_turn_report_body(turn_index: int, logs: Array[String]) -> String:
	var start_line: String = TextDB.format_text("logs.turn.start", [turn_index])
	var summary_lines: Array[String] = []
	for log_variant in logs:
		var line: String = str(log_variant).strip_edges()
		if line.is_empty() or line == start_line:
			continue
		summary_lines.append("- %s" % line)
	if summary_lines.is_empty():
		summary_lines.append("- %s" % TextDB.get_text("turn_report.report.empty"))
	var narrative_key: String = "turn_report.narratives.turn_%02d" % turn_index
	var narrative_text: String = TextDB.get_text(narrative_key, TextDB.get_text("turn_report.report.placeholder_body"))
	return "\n".join([
		TextDB.get_text("turn_report.report.summary_header"),
		"\n".join(summary_lines),
		"",
		TextDB.get_text("turn_report.report.placeholder_header"),
		narrative_text
	])

func _show_turn_report_dialog(turn_index: int, logs: Array[String], title_override: String = "", subtitle_override: String = "") -> void:
	turn_report_dialog_active = true
	end_turn_confirm_active = false
	settlement_dialog_active = false
	_configure_popup_for_turn_report()
	popup_title.text = title_override if not title_override.is_empty() else TextDB.format_text("turn_report.report.title", [turn_index])
	popup_subtitle.text = subtitle_override if not subtitle_override.is_empty() else TextDB.format_text("turn_report.report.subtitle", [GameRules.current_term_name(turn_index)])
	popup_subtitle.visible = not popup_subtitle.text.strip_edges().is_empty()
	popup_body.text = _build_turn_report_body(turn_index, logs)
	popup_body.scroll_to_line(0)
	popup_art.texture = null
	detail_overlay.visible = true

func _close_turn_report_dialog() -> void:
	turn_report_dialog_active = false
	detail_overlay.visible = false
	_configure_popup_for_detail()
	if tutorial_manager != null and run_state != null:
		tutorial_manager.clear_report_context(run_state)
	if defer_settlement_popup and run_state != null and run_state.game_over:
		defer_settlement_popup = false
		settlement_page_index = -1
		_refresh_settlement_sequence()
		return
	if _show_tutorial_followup_if_needed():
		return
	if tutorial_manager != null and run_state != null and tutorial_manager.is_active(run_state):
		selected_slot_id = ""
		detail_panel_open = false
		detail_panel.visible = false

func _confirm_end_turn() -> void:
	end_turn_confirm_active = false
	_close_all_detail_views()
	var resolved_turn_index: int = run_state.turn_index
	var logs: Array[String] = turn_manager.resolve_turn(run_state, board_manager, event_manager, relation_manager, characters, resources, tutorial_manager)
	var report_logs: Array[String] = []
	for log_variant in logs:
		report_logs.append(str(log_variant))
	if report_logs.is_empty():
		var stable_line: String = TextDB.get_text("logs.turn.stable")
		run_state.log_entries.append(stable_line)
		report_logs.append(stable_line)
	defer_settlement_popup = run_state.game_over
	_refresh_board()
	var report_turn_index: int = resolved_turn_index
	var report_title_override: String = ""
	var report_subtitle_override: String = ""
	if tutorial_manager != null:
		report_turn_index = tutorial_manager.report_index(run_state, resolved_turn_index)
		report_title_override = tutorial_manager.report_title(run_state)
		report_subtitle_override = tutorial_manager.report_subtitle(run_state, resolved_turn_index)
	_show_turn_report_dialog(report_turn_index, report_logs, report_title_override, report_subtitle_override)

func _on_end_turn_pressed() -> void:
	if run_state.game_over or detail_overlay.visible:
		return
	if tutorial_manager != null:
		var tutorial_status: Dictionary = tutorial_manager.end_turn_status(run_state, board_manager)
		if not bool(tutorial_status.get("ok", true)):
			_show_message_popup(str(tutorial_status.get("title", "")), str(tutorial_status.get("subtitle", "")), str(tutorial_status.get("body", "")))
			return
	_show_end_turn_confirm_dialog()

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

func _attribute_text(attribute_id: String) -> String:
	return TextDB.get_text("system.attributes.%s" % attribute_id, attribute_id)

func _join_tag_texts(tags: Array) -> String:
	var texts: Array[String] = []
	for tag_variant in tags:
		texts.append(_tag_text(str(tag_variant)))
	var separator: String = TextDB.get_text("ui.list_separator")
	return separator.join(texts)

func _join_specialty_texts(specialties: Array) -> String:
	if specialties.is_empty():
		return TextDB.get_text("ui.fallback.none")
	var texts: Array[String] = []
	for specialty_variant in specialties:
		texts.append(_specialty_text(str(specialty_variant)))
	var separator: String = TextDB.get_text("ui.list_separator")
	return separator.join(texts)

func _specialty_text(specialty: String) -> String:
	return TextDB.get_text("system.specialties.%s" % specialty, specialty)

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
