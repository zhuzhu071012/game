extends Control

const CARD_SCENE := preload("res://scenes/CardView.tscn")
const SLOT_SCENE := preload("res://scenes/SlotView.tscn")
const EVENT_UI_CONTROLLER_SCRIPT := preload("res://scripts/ui/event_ui_controller.gd")
const FLOATING_DETAIL_WINDOW_SCRIPT := preload("res://scripts/ui/floating_detail_window.gd")
const TUTORIAL_MANAGER_SCRIPT := preload("res://scripts/managers/tutorial_manager.gd")
const SAVE_MANAGER_SCRIPT := preload("res://scripts/managers/save_manager.gd")
const FIRE_MARKER_TEXTURE := preload("res://assets/ui/fire_marker.svg")
const GLOBAL_FONT_PATH := "res://assets/fonts/ZhuqueFangsong-Regular.ttf"
const TITLE_FONT_PATH := "res://assets/fonts/Huiwen-mincho.ttf"
const GLOBAL_FONT_RESOURCE := preload("res://assets/fonts/ZhuqueFangsong-Regular.ttf")
const TITLE_FONT_RESOURCE := preload("res://assets/fonts/Huiwen-mincho.ttf")
const GLOBAL_FONT_SIZE := 20
const GLOBAL_FONT_SIZE_DELTA := 2
const GLOBAL_LINE_SPACING := 4
const BODY_FONT_SIZE := 24
const DESK_BACKGROUND_PATH := "res://assets/ui/backgrounds/main_menu_map.png"
const DESK_BACKGROUND_SHADER := preload("res://assets/ui/shaders/desk_background_blur.gdshader")
const DESK_BACKGROUND_PARALLAX := Vector2(0.032, 0.024)
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
const LETTER_POPUP_EFFECT_DURATION := 0.32
const TURN_RESULT_CARD_WIDTH := LIST_CARD_WIDTH
const TURN_RESULT_CARD_HEIGHT := LIST_CARD_HEIGHT
const TURN_RESULT_CARD_ART_HEIGHT := LIST_CARD_ART_HEIGHT

@onready var root_layer: ColorRect = $Root
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
var popup_effect_overlay: Control
var popup_effect_top_cover: ColorRect
var popup_effect_bottom_cover: ColorRect
var popup_effect_seam: ColorRect
var popup_effect_tween: Tween
var popup_presentation_effect: String = ""
var popup_presentation_token: int = 0

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
var tutorial_dialog_overlay: Control
var tutorial_dialog_panel: PanelContainer
var tutorial_dialog_left_portrait: TextureRect
var tutorial_dialog_right_portrait: TextureRect
var tutorial_dialog_name: Label
var tutorial_dialog_text: RichTextLabel
var tutorial_dialog_hint: Label
var tutorial_dialog_active: bool = false
var tutorial_dialog_lines: Array = []
var tutorial_dialog_index: int = -1
var tutorial_dialog_flip_sides: bool = false
var pending_report_payload: Dictionary = {}
var save_manager
var system_menu_overlay: Control
var system_menu_panel: PanelContainer
var system_menu_title: Label
var system_menu_subtitle: Label
var system_menu_primary_button: Button
var system_menu_return_button: Button
var system_menu_load_button: Button
var system_menu_save_button: Button
var system_menu_options_button: Button
var system_menu_help_button: Button
var save_slot_overlay: Control
var save_slot_panel: PanelContainer
var save_slot_title: Label
var save_slot_subtitle: Label
var save_slot_page_label: Label
var save_slot_prev_button: Button
var save_slot_next_button: Button
var save_slot_close_button: Button
var save_slot_mode: String = ""
var save_slot_page: int = 0
var save_slot_buttons: Array[Button] = []
var audio_options_overlay: Control
var desk_background: TextureRect
var desk_background_material: ShaderMaterial
var desk_background_texture: Texture2D
var system_menu_cover: ColorRect
var audio_options_panel: PanelContainer
var audio_options_title: Label
var audio_options_subtitle: Label
var audio_options_reset_button: Button
var audio_options_close_button: Button
var audio_option_sliders: Dictionary = {}
var audio_option_value_labels: Dictionary = {}
var tutorial_toast_panel: PanelContainer
var tutorial_toast_label: Label
var tutorial_toast_token: int = 0
var turn_result_overlay: Control
var turn_result_panel: PanelContainer
var turn_result_title: Label
var turn_result_subtitle: Label
var turn_result_body: RichTextLabel
var turn_result_reward_title: Label
var turn_result_card_scroll: ScrollContainer
var turn_result_card_row: HBoxContainer
var turn_result_animation_layer: Control
var turn_result_collect_button: Button
var turn_result_continue_button: Button
var turn_result_queue: Array = []
var turn_result_index: int = -1
var turn_result_card_entries: Array = []
var turn_result_active: bool = false
var turn_result_collecting: bool = false
var pending_turn_result_report_payload: Dictionary = {}
var startup_cover_active: bool = true
var loaded_font_resources: Dictionary = {}

@onready var board_manager: BoardManager = $BoardManager
@onready var event_manager: EventManager = $EventManager
@onready var relation_manager: RelationManager = $RelationManager
@onready var turn_manager: TurnManager = $TurnManager
@onready var audio_manager = $AudioManager

func _play_ui_sound(sound_id: String) -> void:
	if audio_manager == null or sound_id.is_empty():
		return
	audio_manager.play_ui(sound_id)

func _play_event_spawn_sound(event_id: String) -> void:
	if audio_manager == null or event_id.is_empty():
		return
	audio_manager.play_event_spawn(event_id, events)

func _play_event_open_sound(event_id: String) -> void:
	if audio_manager == null or event_id.is_empty():
		return
	audio_manager.play_event_open(event_id, events)

func _play_event_result_sound(event_id: String, outcome: String) -> void:
	if audio_manager == null or event_id.is_empty():
		return
	audio_manager.play_event_result(event_id, events, outcome)

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
	if event is InputEventMouseMotion:
		_update_desk_background_parallax((event as InputEventMouseMotion).position)
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if turn_result_active:
			_on_turn_result_continue_pressed()
			get_viewport().set_input_as_handled()
			return
		if tutorial_dialog_active:
			return
		if startup_cover_active:
			return
		if _audio_options_visible():
			_close_audio_options_overlay()
			get_viewport().set_input_as_handled()
			return
		if save_slot_overlay != null and save_slot_overlay.visible:
			_close_save_slot_overlay()
			get_viewport().set_input_as_handled()
			return
		_show_system_menu(not _system_menu_visible())
		get_viewport().set_input_as_handled()

func _system_menu_visible() -> bool:
	return system_menu_overlay != null and system_menu_overlay.visible

func _audio_options_visible() -> bool:
	return audio_options_overlay != null and audio_options_overlay.visible

func _build_turn_result_ui() -> void:
	if turn_result_overlay != null:
		return
	turn_result_overlay = Control.new()
	turn_result_overlay.name = "TurnResultOverlay"
	turn_result_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	turn_result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	turn_result_overlay.z_as_relative = false
	turn_result_overlay.z_index = 1010
	turn_result_overlay.visible = false
	add_child(turn_result_overlay)
	var shade: ColorRect = ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.76)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	turn_result_overlay.add_child(shade)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	turn_result_overlay.add_child(center)
	turn_result_animation_layer = Control.new()
	turn_result_animation_layer.name = "TurnResultAnimationLayer"
	turn_result_animation_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	turn_result_animation_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	turn_result_overlay.add_child(turn_result_animation_layer)
	turn_result_panel = PanelContainer.new()
	turn_result_panel.custom_minimum_size = Vector2(920.0, 640.0)
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.06, 0.07, 0.985)
	panel_style.border_color = Color(0.44, 0.44, 0.46, 0.96)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	panel_style.shadow_size = 12
	turn_result_panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(turn_result_panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	turn_result_panel.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	box.add_child(header)
	var title_box: VBoxContainer = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 4)
	header.add_child(title_box)
	turn_result_title = Label.new()
	turn_result_title.add_theme_font_size_override("font_size", 30)
	title_box.add_child(turn_result_title)
	turn_result_subtitle = Label.new()
	turn_result_subtitle.modulate = Color(0.84, 0.82, 0.78, 0.92)
	turn_result_subtitle.add_theme_font_size_override("font_size", 15)
	title_box.add_child(turn_result_subtitle)
	var body_panel: PanelContainer = PanelContainer.new()
	body_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var body_style: StyleBoxFlat = StyleBoxFlat.new()
	body_style.bg_color = Color(0.03, 0.04, 0.05, 0.94)
	body_style.border_color = Color(0.16, 0.18, 0.21, 0.95)
	body_style.border_width_left = 1
	body_style.border_width_top = 1
	body_style.border_width_right = 1
	body_style.border_width_bottom = 1
	body_style.corner_radius_top_left = 10
	body_style.corner_radius_top_right = 10
	body_style.corner_radius_bottom_left = 10
	body_style.corner_radius_bottom_right = 10
	body_panel.add_theme_stylebox_override("panel", body_style)
	box.add_child(body_panel)
	var body_margin: MarginContainer = MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 14)
	body_margin.add_theme_constant_override("margin_top", 12)
	body_margin.add_theme_constant_override("margin_right", 14)
	body_margin.add_theme_constant_override("margin_bottom", 12)
	body_panel.add_child(body_margin)
	turn_result_body = RichTextLabel.new()
	turn_result_body.bbcode_enabled = true
	turn_result_body.fit_content = false
	turn_result_body.scroll_active = true
	turn_result_body.custom_minimum_size = Vector2(0.0, 220.0)
	turn_result_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	turn_result_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	turn_result_body.mouse_filter = Control.MOUSE_FILTER_STOP
	body_margin.add_child(turn_result_body)
	turn_result_reward_title = Label.new()
	turn_result_reward_title.add_theme_font_size_override("font_size", 18)
	box.add_child(turn_result_reward_title)
	turn_result_card_scroll = ScrollContainer.new()
	turn_result_card_scroll.custom_minimum_size = Vector2(0.0, TURN_RESULT_CARD_HEIGHT + 20.0)
	turn_result_card_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	turn_result_card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	turn_result_card_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(turn_result_card_scroll)
	turn_result_card_row = HBoxContainer.new()
	turn_result_card_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	turn_result_card_row.add_theme_constant_override("separation", 12)
	turn_result_card_scroll.add_child(turn_result_card_row)
	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	box.add_child(actions)
	turn_result_collect_button = Button.new()
	turn_result_collect_button.custom_minimum_size = Vector2(130.0, 42.0)
	turn_result_collect_button.pressed.connect(_on_turn_result_collect_pressed)
	actions.add_child(turn_result_collect_button)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	turn_result_continue_button = Button.new()
	turn_result_continue_button.custom_minimum_size = Vector2(110.0, 42.0)
	turn_result_continue_button.pressed.connect(_on_turn_result_continue_pressed)
	actions.add_child(turn_result_continue_button)

func _make_turn_result_reward_payload(reward: Dictionary) -> Dictionary:
	var card_type: String = str(reward.get("card_type", ""))
	var card_id: String = str(reward.get("id", ""))
	var amount: int = maxi(1, int(reward.get("amount", 1)))
	match card_type:
		"character":
			if not characters.has(card_id):
				return {}
			var character: CharacterData = characters[card_id] as CharacterData
			var role_name: String = _role_type_text(character.role_type)
			var subtitle: String = role_name
			if run_state != null and run_state.relation_states.has(card_id):
				subtitle = "%s / %s" % [role_name, relation_manager.describe_relation(run_state, card_id)]
			return {
				"uid": "result:character:%s" % card_id,
				"id": card_id,
				"card_type": "character",
				"title": character.display_name,
				"subtitle": subtitle,
				"body": _character_body(card_id, false),
				"tags": character.tags,
				"locked": true,
				"image_path": character.art_path,
				"image_label": character.display_name,
				"art_bg_color": Color(0.20, 0.20, 0.22),
				"color": Color(0.12, 0.12, 0.13),
				"compact_details": true,
				"show_subtitle_in_compact": false,
				"show_assigned_in_compact": false,
				"embedded": true,
				"card_width": TURN_RESULT_CARD_WIDTH,
				"art_height": TURN_RESULT_CARD_ART_HEIGHT,
				"collapsed_height": TURN_RESULT_CARD_HEIGHT,
				"expanded_height": TURN_RESULT_CARD_HEIGHT,
				"stack_count": amount
			}
		"resource":
			if not resources.has(card_id):
				return {}
			var resource: ResourceCardData = resources[card_id] as ResourceCardData
			return {
				"uid": "result:resource:%s" % card_id,
				"id": card_id,
				"card_type": "resource",
				"title": resource.display_name,
				"subtitle": _resource_category_text(resource.category),
				"body": resource.description,
				"tags": resource.tags,
				"locked": true,
				"image_path": resource.art_path,
				"image_label": resource.display_name,
				"art_bg_color": Color(0.18, 0.18, 0.19),
				"color": Color(0.11, 0.11, 0.12),
				"compact_details": true,
				"show_subtitle_in_compact": false,
				"show_assigned_in_compact": false,
				"embedded": true,
				"card_width": TURN_RESULT_CARD_WIDTH,
				"art_height": TURN_RESULT_CARD_ART_HEIGHT,
				"collapsed_height": TURN_RESULT_CARD_HEIGHT,
				"expanded_height": TURN_RESULT_CARD_HEIGHT,
				"stack_count": amount
			}
	return {}

func _make_turn_result_card_front(reward: Dictionary) -> Control:
	var payload: Dictionary = _make_turn_result_reward_payload(reward)
	if payload.is_empty():
		return null
	var card_size := Vector2(TURN_RESULT_CARD_WIDTH, TURN_RESULT_CARD_HEIGHT)
	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = card_size
	panel.size = card_size
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = payload.get("color", Color(0.12, 0.12, 0.13)) as Color
	panel_style.border_color = Color(0.50, 0.50, 0.52, 0.96)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.20)
	panel_style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", panel_style)
	var margin: MarginContainer = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 3)
	margin.add_child(box)
	var art_frame: PanelContainer = PanelContainer.new()
	art_frame.custom_minimum_size = Vector2(0.0, TURN_RESULT_CARD_ART_HEIGHT)
	art_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art_style: StyleBoxFlat = StyleBoxFlat.new()
	art_style.bg_color = (payload.get("art_bg_color", payload.get("color", Color(0.23, 0.19, 0.14))) as Color).darkened(0.12)
	art_style.corner_radius_top_left = 8
	art_style.corner_radius_top_right = 8
	art_style.corner_radius_bottom_left = 8
	art_style.corner_radius_bottom_right = 8
	art_style.border_width_left = 2
	art_style.border_width_top = 2
	art_style.border_width_right = 2
	art_style.border_width_bottom = 2
	art_style.border_color = Color(0.54, 0.54, 0.56, 0.88)
	art_style.shadow_color = Color(0.0, 0.0, 0.0, 0.20)
	art_style.shadow_size = 4
	art_frame.add_theme_stylebox_override("panel", art_style)
	box.add_child(art_frame)
	var art_margin: MarginContainer = MarginContainer.new()
	art_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_margin.add_theme_constant_override("margin_left", 1)
	art_margin.add_theme_constant_override("margin_top", 1)
	art_margin.add_theme_constant_override("margin_right", 1)
	art_margin.add_theme_constant_override("margin_bottom", 1)
	art_frame.add_child(art_margin)
	var art_content: Control = Control.new()
	art_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_margin.add_child(art_content)
	var art_texture: TextureRect = TextureRect.new()
	art_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	art_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var image_path: String = str(payload.get("image_path", ""))
	if not image_path.is_empty() and ResourceLoader.exists(image_path):
		art_texture.texture = load(image_path) as Texture2D
	art_content.add_child(art_texture)
	if art_texture.texture == null:
		var art_label: Label = Label.new()
		art_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		art_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		art_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		art_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		art_label.text = str(payload.get("image_label", payload.get("title", TextDB.get_text("ui.fallback.card"))))
		art_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_content.add_child(art_label)
	var title: Label = Label.new()
	title.text = str(payload.get("title", TextDB.get_text("ui.fallback.card")))
	title.custom_minimum_size = Vector2(0.0, 24.0)
	title.clip_text = true
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 13)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)
	var amount: int = maxi(1, int(payload.get("stack_count", 1)))
	if amount > 1:
		var badge: PanelContainer = PanelContainer.new()
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.anchor_left = 1.0
		badge.anchor_top = 0.0
		badge.anchor_right = 1.0
		badge.anchor_bottom = 0.0
		badge.offset_left = -38.0
		badge.offset_top = 6.0
		badge.offset_right = -6.0
		badge.offset_bottom = 30.0
		var badge_style: StyleBoxFlat = StyleBoxFlat.new()
		badge_style.bg_color = Color(0.10, 0.10, 0.11, 0.94)
		badge_style.border_width_left = 1
		badge_style.border_width_top = 1
		badge_style.border_width_right = 1
		badge_style.border_width_bottom = 1
		badge_style.border_color = Color(0.70, 0.70, 0.72, 0.92)
		badge_style.corner_radius_top_left = 10
		badge_style.corner_radius_top_right = 10
		badge_style.corner_radius_bottom_left = 10
		badge_style.corner_radius_bottom_right = 10
		badge.add_theme_stylebox_override("panel", badge_style)
		var badge_label: Label = Label.new()
		badge_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		badge_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_label.text = str(amount) if amount < 100 else "99+"
		badge_label.add_theme_font_size_override("font_size", 11)
		badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(badge_label)
		art_content.add_child(badge)
	return panel

func _make_turn_result_card_back(reward: Dictionary) -> PanelContainer:
	var amount: int = maxi(1, int(reward.get("amount", 1)))
	var back: PanelContainer = PanelContainer.new()
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.10, 0.11, 0.96)
	style.border_color = Color(0.66, 0.66, 0.68, 0.92)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 8
	back.add_theme_stylebox_override("panel", style)
	var margin: MarginContainer = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	back.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var title: Label = Label.new()
	title.text = TextDB.get_text("ui.turn_results.card_back")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", 18)
	box.add_child(title)
	var hint: Label = Label.new()
	hint.text = TextDB.get_text("ui.turn_results.card_hint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(1.0, 1.0, 1.0, 0.72)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_size_override("font_size", 12)
	box.add_child(hint)
	if amount > 1:
		var badge: Label = Label.new()
		badge.text = "x%d" % amount
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		badge.anchor_left = 1.0
		badge.anchor_top = 0.0
		badge.anchor_right = 1.0
		badge.anchor_bottom = 0.0
		badge.offset_left = -46.0
		badge.offset_top = 8.0
		badge.offset_right = -12.0
		badge.offset_bottom = 26.0
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		back.add_child(badge)
	return back

func _all_turn_result_cards_collected() -> bool:
	for entry_variant in turn_result_card_entries:
		var entry: Dictionary = entry_variant as Dictionary
		if not bool(entry.get("collected", false)):
			return false
	return true

func _clear_turn_result_cards() -> void:
	turn_result_card_entries.clear()
	turn_result_collecting = false
	if turn_result_animation_layer != null:
		for child in turn_result_animation_layer.get_children():
			child.queue_free()
	if turn_result_card_row == null:
		return
	for child in turn_result_card_row.get_children():
		child.queue_free()

func _render_turn_result_cards(rewards: Array) -> void:
	_clear_turn_result_cards()
	for reward_variant in rewards:
		if reward_variant is not Dictionary:
			continue
		var reward: Dictionary = (reward_variant as Dictionary).duplicate(true)
		var card_size := Vector2(TURN_RESULT_CARD_WIDTH, TURN_RESULT_CARD_HEIGHT)
		var button: Control = Control.new()
		button.custom_minimum_size = card_size
		button.size = card_size
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.gui_input.connect(_on_turn_result_card_gui_input.bind(button))
		turn_result_card_row.add_child(button)
		var front_card: Control = _make_turn_result_card_front(reward)
		if front_card != null:
			front_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			front_card.visible = false
			front_card.position = Vector2.ZERO
			front_card.anchor_left = 0.0
			front_card.anchor_top = 0.0
			front_card.anchor_right = 0.0
			front_card.anchor_bottom = 0.0
			front_card.offset_left = 0.0
			front_card.offset_top = 0.0
			front_card.offset_right = card_size.x
			front_card.offset_bottom = card_size.y
			front_card.custom_minimum_size = card_size
			front_card.size = card_size
			front_card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			front_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			button.add_child(front_card)
		var back_card: PanelContainer = _make_turn_result_card_back(reward)
		back_card.position = Vector2.ZERO
		back_card.anchor_left = 0.0
		back_card.anchor_top = 0.0
		back_card.anchor_right = 0.0
		back_card.anchor_bottom = 0.0
		back_card.offset_left = 0.0
		back_card.offset_top = 0.0
		back_card.offset_right = card_size.x
		back_card.offset_bottom = card_size.y
		back_card.custom_minimum_size = card_size
		back_card.size = card_size
		back_card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		back_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		button.add_child(back_card)
		turn_result_card_entries.append({
			"button": button,
			"holder": button,
			"front": front_card,
			"back": back_card,
			"reward": reward,
			"revealed": false,
			"collected": false
		})
	_refresh_turn_result_collect_button()

func _find_turn_result_card_index(button: Control) -> int:
	for index in range(turn_result_card_entries.size()):
		var entry: Dictionary = turn_result_card_entries[index] as Dictionary
		if entry.get("button", null) == button:
			return index
	return -1

func _set_turn_result_card_revealed(index: int, animated: bool = true, play_sound: bool = true) -> void:
	if index < 0 or index >= turn_result_card_entries.size():
		return
	var entry: Dictionary = turn_result_card_entries[index] as Dictionary
	if bool(entry.get("revealed", false)):
		return
	entry["revealed"] = true
	turn_result_card_entries[index] = entry
	var button: Control = entry.get("button", null) as Control
	var holder: Control = entry.get("holder", button) as Control
	var front_card: Control = entry.get("front", null) as Control
	var back_card: PanelContainer = entry.get("back", null) as PanelContainer
	if holder == null or front_card == null or back_card == null:
		_refresh_turn_result_collect_button()
		return
	var holder_size: Vector2 = holder.size if holder.size != Vector2.ZERO else holder.custom_minimum_size
	holder.pivot_offset = holder_size * 0.5
	holder.scale = Vector2.ONE
	if not animated:
		back_card.visible = false
		front_card.visible = true
		if play_sound:
			_play_ui_sound("card_flip")
		_refresh_turn_result_collect_button()
		return
	var tween: Tween = create_tween()
	tween.tween_property(holder, "scale:x", 0.08, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(_swap_turn_result_card_faces.bind(index))
	if play_sound:
		tween.tween_callback(_play_ui_sound.bind("card_flip"))
	tween.tween_property(holder, "scale:x", 1.05, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "scale:x", 1.0, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _swap_turn_result_card_faces(index: int) -> void:
	if index < 0 or index >= turn_result_card_entries.size():
		return
	var entry: Dictionary = turn_result_card_entries[index] as Dictionary
	var front_card: Control = entry.get("front", null) as Control
	var back_card: PanelContainer = entry.get("back", null) as PanelContainer
	if front_card != null:
		front_card.visible = true
	if back_card != null:
		back_card.visible = false
	_refresh_turn_result_collect_button()

func _collect_all_turn_result_cards(animated: bool = false) -> bool:
	var had_hidden: bool = false
	for index in range(turn_result_card_entries.size()):
		var entry: Dictionary = turn_result_card_entries[index] as Dictionary
		if not bool(entry.get("revealed", false)):
			had_hidden = true
		_set_turn_result_card_revealed(index, animated, false)
	_refresh_turn_result_collect_button()
	return had_hidden

func _turn_result_target_rect_for_reward(reward: Dictionary) -> Rect2:
	var card_type: String = str(reward.get("card_type", ""))
	var card_id: String = str(reward.get("id", ""))
	var row: Control = resource_row if card_type == "resource" else roster_row
	if row != null:
		for child in row.get_children():
			var card: CardView = child as CardView
			if card == null or not card.visible:
				continue
			if str(card.card_payload.get("card_type", "")) == card_type and str(card.card_payload.get("id", "")) == card_id:
				return card.get_global_rect()
	var fallback: Control = resource_scroll if card_type == "resource" else roster_scroll
	if fallback != null and fallback.visible:
		return fallback.get_global_rect()
	if hands_panel != null and hands_panel.visible:
		return hands_panel.get_global_rect()
	return Rect2(get_viewport_rect().size * 0.5 - Vector2(TURN_RESULT_CARD_WIDTH, TURN_RESULT_CARD_HEIGHT) * 0.5, Vector2(TURN_RESULT_CARD_WIDTH, TURN_RESULT_CARD_HEIGHT))

func _collect_turn_result_cards_to_targets(play_sound: bool = true) -> void:
	if turn_result_collecting or _all_turn_result_cards_collected():
		_refresh_turn_result_collect_button()
		return
	turn_result_collecting = true
	_collect_all_turn_result_cards(false)
	_refresh_turn_result_collect_button()
	if play_sound:
		_play_ui_sound("collect_all")
	var source_rects: Array[Rect2] = []
	for entry_variant in turn_result_card_entries:
		var entry: Dictionary = entry_variant as Dictionary
		var front_card: Control = entry.get("front", null) as Control
		var button: Control = entry.get("button", null) as Control
		var source_rect: Rect2 = front_card.get_global_rect() if front_card != null and front_card.visible else (button.get_global_rect() if button != null else Rect2())
		source_rects.append(source_rect)
	var longest: float = 0.0
	for index in range(turn_result_card_entries.size()):
		var entry: Dictionary = turn_result_card_entries[index] as Dictionary
		if bool(entry.get("collected", false)):
			continue
		var reward: Dictionary = entry.get("reward", {}) as Dictionary
		var button: Control = entry.get("button", null) as Control
		var source_rect: Rect2 = source_rects[index] if index < source_rects.size() else Rect2()
		var flyer: Control = _make_turn_result_card_front(reward)
		if flyer != null:
			flyer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			flyer.top_level = true
			flyer.z_as_relative = false
			flyer.z_index = 2600 + index
			flyer.custom_minimum_size = source_rect.size
			flyer.size = source_rect.size
			flyer.position = source_rect.position
			flyer.pivot_offset = source_rect.size * 0.5
			if turn_result_animation_layer != null:
				turn_result_animation_layer.add_child(flyer)
			else:
				turn_result_overlay.add_child(flyer)
			var target_rect: Rect2 = _turn_result_target_rect_for_reward(reward)
			var target_position: Vector2 = target_rect.position + (target_rect.size - source_rect.size) * 0.5
			var delay: float = float(index) * 0.05
			var duration: float = 0.34
			longest = maxf(longest, delay + duration)
			var tween: Tween = create_tween()
			if delay > 0.0:
				tween.tween_interval(delay)
			tween.tween_property(flyer, "position", target_position, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tween.parallel().tween_property(flyer, "scale", Vector2(0.76, 0.76), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(flyer, "modulate:a", 0.12, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		entry["collected"] = true
		turn_result_card_entries[index] = entry
		if button != null:
			button.modulate = Color(1.0, 1.0, 1.0, 0.0)
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_turn_result_collect_button()
	if longest > 0.0:
		await get_tree().create_timer(longest + 0.04).timeout
	if turn_result_animation_layer != null:
		for child in turn_result_animation_layer.get_children():
			child.queue_free()
	turn_result_collecting = false
	_refresh_turn_result_collect_button()

func _refresh_turn_result_collect_button() -> void:
	if turn_result_collect_button == null:
		return
	turn_result_collect_button.text = TextDB.get_text("ui.turn_results.collect_all")
	var has_collectable: bool = false
	for entry_variant in turn_result_card_entries:
		var entry: Dictionary = entry_variant as Dictionary
		if not bool(entry.get("collected", false)):
			has_collectable = true
			break
	turn_result_collect_button.disabled = turn_result_collecting or not has_collectable
	if turn_result_continue_button != null:
		turn_result_continue_button.disabled = turn_result_collecting

func _show_current_turn_result() -> void:
	if not turn_result_active or turn_result_index < 0 or turn_result_index >= turn_result_queue.size():
		_finish_turn_result_sequence()
		return
	if turn_result_overlay == null:
		_build_turn_result_ui()
	turn_result_collecting = false
	var entry: Dictionary = turn_result_queue[turn_result_index] as Dictionary
	var rewards: Array = entry.get("rewards", []) as Array
	turn_result_title.text = str(entry.get("title", TextDB.get_text("ui.fallback.card")))
	turn_result_subtitle.text = TextDB.format_text("ui.turn_results.page", [turn_result_index + 1, turn_result_queue.size()])
	var body_text: String = str(entry.get("body", "")).strip_edges()
	if body_text.is_empty():
		body_text = TextDB.format_text("ui.turn_results.default_body", [turn_result_title.text])
	turn_result_body.text = body_text
	turn_result_body.scroll_to_line(0)
	_set_rich_text_layout(turn_result_body, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP)
	turn_result_reward_title.text = TextDB.get_text("ui.turn_results.reward_header")
	turn_result_reward_title.visible = not rewards.is_empty()
	if turn_result_card_scroll != null:
		turn_result_card_scroll.visible = not rewards.is_empty()
	if turn_result_collect_button != null:
		turn_result_collect_button.visible = not rewards.is_empty()
	_render_turn_result_cards(rewards)
	turn_result_continue_button.text = TextDB.get_text("ui.buttons.next")
	turn_result_overlay.visible = true
	turn_result_continue_button.grab_focus()

func _start_turn_result_sequence(results: Array, report_payload: Dictionary) -> bool:
	if results.is_empty():
		return false
	if turn_result_overlay == null:
		_build_turn_result_ui()
	pending_turn_result_report_payload = report_payload.duplicate(true)
	turn_result_queue = results.duplicate(true)
	turn_result_index = 0
	turn_result_active = true
	turn_result_collecting = false
	detail_overlay.visible = false
	_configure_popup_for_detail()
	_play_ui_sound("panel_open")
	_show_current_turn_result()
	return true

func _finish_turn_result_sequence() -> void:
	turn_result_active = false
	turn_result_collecting = false
	turn_result_index = -1
	turn_result_queue.clear()
	_clear_turn_result_cards()
	if turn_result_overlay != null:
		turn_result_overlay.visible = false
	var payload: Dictionary = pending_turn_result_report_payload.duplicate(true)
	pending_turn_result_report_payload.clear()
	if payload.is_empty():
		return
	if bool(payload.get("show_report", false)):
		_show_turn_report_dialog(
			int(payload.get("turn_index", run_state.turn_index)),
			payload.get("logs", []) as Array[String],
			str(payload.get("title", "")),
			str(payload.get("subtitle", "")),
			str(payload.get("body", ""))
		)
	elif defer_settlement_popup and run_state != null and run_state.game_over:
		defer_settlement_popup = false
		settlement_page_index = -1
		_refresh_settlement_sequence()

func _on_turn_result_card_gui_input(event: InputEvent, button: Control) -> void:
	if not turn_result_active or turn_result_collecting:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			var index: int = _find_turn_result_card_index(button)
			if index >= 0:
				var entry: Dictionary = turn_result_card_entries[index] as Dictionary
				if bool(entry.get("collected", false)):
					return
				_set_turn_result_card_revealed(index, true, true)
				accept_event()

func _on_turn_result_collect_pressed() -> void:
	if not turn_result_active or turn_result_collecting:
		return
	await _collect_turn_result_cards_to_targets(true)

func _on_turn_result_continue_pressed() -> void:
	if not turn_result_active or turn_result_collecting:
		return
	var auto_collected: bool = false
	if not _all_turn_result_cards_collected():
		auto_collected = true
		await _collect_turn_result_cards_to_targets(true)
	turn_result_index += 1
	if turn_result_index >= turn_result_queue.size():
		_finish_turn_result_sequence()
		return
	if not auto_collected:
		_play_ui_sound("button")
	_show_current_turn_result()

func _load_font_resource(font_path: String) -> FontFile:
	if font_path.is_empty():
		return null
	var cached_font = loaded_font_resources.get(font_path, null)
	if cached_font != null:
		return cached_font as FontFile
	var loaded_font: FontFile = load(font_path) as FontFile
	if loaded_font != null:
		loaded_font_resources[font_path] = loaded_font
		return loaded_font
	var font_bytes: PackedByteArray = FileAccess.get_file_as_bytes(font_path)
	if font_bytes.is_empty():
		push_warning("Failed to load font: %s" % font_path)
		return null
	var font_resource := FontFile.new()
	font_resource.data = font_bytes
	loaded_font_resources[font_path] = font_resource
	return font_resource

func _apply_global_font() -> void:
	var font_resource: FontFile = GLOBAL_FONT_RESOURCE
	if font_resource == null:
		font_resource = _load_font_resource(GLOBAL_FONT_PATH)
	if font_resource == null:
		return
	ThemeDB.fallback_font = font_resource
	ThemeDB.fallback_font_size = GLOBAL_FONT_SIZE
	var global_theme := Theme.new()
	global_theme.default_font = font_resource
	global_theme.default_font_size = GLOBAL_FONT_SIZE
	theme = global_theme

func _apply_title_font_override(control: Control, font_resource: FontFile) -> void:
	if control == null or font_resource == null:
		return
	control.add_theme_font_override("font", font_resource)

func _apply_title_fonts() -> void:
	var title_font: FontFile = TITLE_FONT_RESOURCE
	if title_font == null:
		title_font = _load_font_resource(TITLE_FONT_PATH)
	if title_font == null:
		return
	for node in [system_menu_title, detail_title, popup_title, event_dialog_title]:
		var control: Control = node as Control
		_apply_title_font_override(control, title_font)

func _apply_body_font_override(label: RichTextLabel) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("normal_font_size", BODY_FONT_SIZE)
	label.set_meta("normal_font_size_tuned", true)
	label.add_theme_constant_override("line_separation", GLOBAL_LINE_SPACING)
	label.add_theme_constant_override("line_spacing", GLOBAL_LINE_SPACING)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_meta("line_spacing_tuned", true)

func _apply_body_fonts() -> void:
	for label in [detail_body, event_dialog_body, popup_body, turn_result_body]:
		_apply_body_font_override(label as RichTextLabel)

func _set_rich_text_layout(label: RichTextLabel, horizontal: HorizontalAlignment, vertical: VerticalAlignment) -> void:
	if label == null:
		return
	label.horizontal_alignment = horizontal
	label.vertical_alignment = vertical

func _set_popup_body_document_layout() -> void:
	_set_rich_text_layout(popup_body, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP)

func _set_popup_body_center_layout() -> void:
	_set_rich_text_layout(popup_body, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)

func _set_popup_body_prompt_layout() -> void:
	_set_rich_text_layout(popup_body, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)

func _normalize_document_body(body: String, blank_lines_before: int = 2) -> String:
	var normalized: String = body.replace("\r\n", "\n").replace("\r", "\n").strip_edges()
	while normalized.find("\n\n\n") >= 0:
		normalized = normalized.replace("\n\n\n", "\n\n")
	if normalized.is_empty():
		return "\n".repeat(blank_lines_before)
	var paragraphs: Array[String] = []
	for paragraph_variant in normalized.split("\n\n"):
		var paragraph: String = str(paragraph_variant).strip_edges()
		if paragraph.is_empty():
			continue
		if not paragraph.begins_with("　　"):
			paragraph = "　　" + paragraph
		paragraphs.append(paragraph)
	return "\n".repeat(blank_lines_before) + "\n\n".join(paragraphs)

func _set_popup_art_image(image_path: String) -> void:
	popup_art.texture = null
	popup_art_frame.visible = false
	var normalized_path: String = image_path.strip_edges()
	if normalized_path.is_empty():
		return
	var texture: Texture2D = null
	texture = load(normalized_path) as Texture2D
	if texture == null:
		return
	popup_art.texture = texture
	popup_art_frame.visible = true

func _apply_global_text_adjustments(node: Node) -> void:
	if node is Control:
		_adjust_control_text(node as Control)
	for child in node.get_children():
		_apply_global_text_adjustments(child)

func _adjust_control_text(control: Control) -> void:
	if control.has_theme_font_size_override("font_size") and not bool(control.get_meta("font_size_tuned", false)):
		control.add_theme_font_size_override("font_size", control.get_theme_font_size("font_size") + GLOBAL_FONT_SIZE_DELTA)
		control.set_meta("font_size_tuned", true)
	if control.has_theme_font_size_override("normal_font_size") and not bool(control.get_meta("normal_font_size_tuned", false)):
		control.add_theme_font_size_override("normal_font_size", control.get_theme_font_size("normal_font_size") + GLOBAL_FONT_SIZE_DELTA)
		control.set_meta("normal_font_size_tuned", true)
	if bool(control.get_meta("line_spacing_tuned", false)):
		return
	if control is RichTextLabel:
		control.add_theme_constant_override("line_separation", GLOBAL_LINE_SPACING)
		control.add_theme_constant_override("line_spacing", GLOBAL_LINE_SPACING)
	elif control is Label or control is Button:
		control.add_theme_constant_override("line_spacing", GLOBAL_LINE_SPACING)
	control.set_meta("line_spacing_tuned", true)

func _ready() -> void:
	randomize()
	_apply_global_font()
	TextDB.reload_texts()
	tutorial_manager = TUTORIAL_MANAGER_SCRIPT.new()
	save_manager = SAVE_MANAGER_SCRIPT.new()
	characters = GameData.create_characters()
	resources = GameData.create_resources()
	risks = GameData.create_risks()
	events = GameData.create_events()
	run_state = GameData.create_run_state()
	event_manager.setup(events)
	event_manager.event_spawned.connect(_on_event_spawned)
	event_manager.event_resolved.connect(_on_event_resolved)
	board_manager.board_changed.connect(_refresh_board)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	toggle_log_button.pressed.connect(_on_toggle_log_pressed)
	popup_close.pressed.connect(_on_popup_close_pressed)
	popup_panel.gui_input.connect(_on_popup_panel_gui_input)
	popup_body.gui_input.connect(_on_popup_body_gui_input)
	_build_popup_presentation_ui()
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
	popup_body.mouse_filter = Control.MOUSE_FILTER_STOP
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
	event_ui_controller.quick_assign_requested.connect(_on_card_quick_assign_requested)
	event_ui_controller.remove_requested.connect(_on_card_remove_requested)
	event_ui_controller.dialog_focus_requested.connect(_focus_event_dialog)
	event_ui_controller.event_dialog_toggled.connect(_on_event_dialog_toggled)
	_build_top_bar_layout()
	roster_row.add_theme_constant_override("separation", STACK_CARD_SEPARATION)
	resource_row.add_theme_constant_override("separation", STACK_CARD_SEPARATION)
	_apply_static_texts()
	_apply_visual_styles()
	_build_desk_background_ui()
	_prepare_detail_panel_window()
	_build_tutorial_dialog_ui()
	_build_system_menu_ui()
	_build_tutorial_toast_ui()
	_build_turn_result_ui()
	_apply_title_fonts()
	_apply_body_fonts()
	detail_panel.gui_input.connect(_on_detail_panel_gui_input)
	detail_header.gui_input.connect(_on_detail_header_gui_input)
	_configure_popup_for_detail()
	board_manager.reset_turn_targets(run_state.active_event_ids)
	_build_slots()
	_refresh_board()
	_update_desk_background_parallax(get_viewport_rect().size * 0.5)
	_show_system_menu(true)

func _build_desk_background_ui() -> void:
	if root_layer == null or desk_background != null:
		return
	desk_background = TextureRect.new()
	desk_background.name = "DeskBackground"
	desk_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	desk_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	desk_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	desk_background.texture = _load_desk_background_texture()
	desk_background.material = _make_desk_background_material()
	desk_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_layer.add_child(desk_background)
	root_layer.move_child(desk_background, 0)
	var shade: ColorRect = ColorRect.new()
	shade.name = "DeskBackgroundShade"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03, 0.025, 0.02, 0.42)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_layer.add_child(shade)
	root_layer.move_child(shade, 1)

func _make_desk_background_material() -> ShaderMaterial:
	desk_background_material = ShaderMaterial.new()
	desk_background_material.shader = DESK_BACKGROUND_SHADER
	desk_background_material.set_shader_parameter("blur_strength", 0.0)
	desk_background_material.set_shader_parameter("uv_offset", Vector2.ZERO)
	return desk_background_material

func _load_desk_background_texture() -> Texture2D:
	if desk_background_texture != null:
		return desk_background_texture
	desk_background_texture = load(DESK_BACKGROUND_PATH) as Texture2D
	return desk_background_texture

func _update_desk_background_parallax(mouse_position: Vector2) -> void:
	if desk_background_material == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var normalized: Vector2 = Vector2(
		clampf(mouse_position.x / viewport_size.x, 0.0, 1.0),
		clampf(mouse_position.y / viewport_size.y, 0.0, 1.0)
	) - Vector2(0.5, 0.5)
	desk_background_material.set_shader_parameter("uv_offset", normalized * DESK_BACKGROUND_PARALLAX)

func _build_system_menu_ui() -> void:
	if system_menu_overlay != null:
		return
	system_menu_overlay = Control.new()
	system_menu_overlay.name = "SystemMenuOverlay"
	system_menu_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	system_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	system_menu_overlay.z_as_relative = false
	system_menu_overlay.z_index = 900
	system_menu_overlay.visible = false
	add_child(system_menu_overlay)
	system_menu_cover = ColorRect.new()
	system_menu_cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	system_menu_cover.color = Color(0.0, 0.0, 0.0, 1.0)
	system_menu_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	system_menu_overlay.add_child(system_menu_cover)
	system_menu_panel = PanelContainer.new()
	system_menu_panel.anchor_left = 0.5
	system_menu_panel.anchor_top = 0.5
	system_menu_panel.anchor_right = 0.5
	system_menu_panel.anchor_bottom = 0.5
	system_menu_panel.offset_left = -240
	system_menu_panel.offset_top = -230
	system_menu_panel.offset_right = 240
	system_menu_panel.offset_bottom = 230
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
	system_menu_panel.add_theme_stylebox_override("panel", style)
	system_menu_overlay.add_child(system_menu_panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	system_menu_panel.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	system_menu_title = Label.new()
	system_menu_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	system_menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	system_menu_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	system_menu_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	system_menu_title.add_theme_font_size_override("font_size", 36)
	box.add_child(system_menu_title)
	system_menu_subtitle = Label.new()
	system_menu_subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	system_menu_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	system_menu_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	system_menu_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	system_menu_subtitle.modulate = Color(1,1,1,0.78)
	system_menu_subtitle.visible = false
	box.add_child(system_menu_subtitle)
	system_menu_primary_button = _make_system_menu_button()
	system_menu_primary_button.pressed.connect(_on_system_menu_primary_pressed)
	box.add_child(system_menu_primary_button)
	system_menu_return_button = _make_system_menu_button()
	system_menu_return_button.pressed.connect(_on_system_menu_return_pressed)
	box.add_child(system_menu_return_button)
	system_menu_load_button = _make_system_menu_button()
	system_menu_load_button.pressed.connect(_on_system_menu_load_pressed)
	box.add_child(system_menu_load_button)
	system_menu_save_button = _make_system_menu_button()
	system_menu_save_button.pressed.connect(_on_system_menu_save_pressed)
	box.add_child(system_menu_save_button)
	system_menu_options_button = _make_system_menu_button()
	system_menu_options_button.pressed.connect(_on_system_menu_options_pressed)
	box.add_child(system_menu_options_button)
	system_menu_help_button = _make_system_menu_button()
	system_menu_help_button.pressed.connect(_on_system_menu_help_pressed)
	box.add_child(system_menu_help_button)
	_build_save_slot_overlay()
	_build_audio_options_overlay()

func _build_tutorial_toast_ui() -> void:
	if tutorial_toast_panel != null:
		return
	tutorial_toast_panel = PanelContainer.new()
	tutorial_toast_panel.anchor_left = 0.5
	tutorial_toast_panel.anchor_top = 1.0
	tutorial_toast_panel.anchor_right = 0.5
	tutorial_toast_panel.anchor_bottom = 1.0
	tutorial_toast_panel.offset_left = -250
	tutorial_toast_panel.offset_top = -120
	tutorial_toast_panel.offset_right = 250
	tutorial_toast_panel.offset_bottom = -56
	tutorial_toast_panel.z_as_relative = false
	tutorial_toast_panel.z_index = 1200
	tutorial_toast_panel.visible = false
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.06, 0.94)
	style.border_color = Color(0.62, 0.62, 0.64, 0.92)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	tutorial_toast_panel.add_theme_stylebox_override("panel", style)
	add_child(tutorial_toast_panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	tutorial_toast_panel.add_child(margin)
	tutorial_toast_label = Label.new()
	tutorial_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_toast_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_toast_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(tutorial_toast_label)

func _show_transient_tutorial_hint(message: String, duration: float = 2.4) -> void:
	if tutorial_toast_panel == null or tutorial_toast_label == null:
		return
	var safe_message: String = message.strip_edges()
	if safe_message.is_empty():
		return
	tutorial_toast_token += 1
	var token: int = tutorial_toast_token
	tutorial_toast_label.text = safe_message
	tutorial_toast_panel.visible = true
	_call_hide_tutorial_toast(token, duration)

func _call_hide_tutorial_toast(token: int, duration: float) -> void:
	_hide_tutorial_toast_later(token, duration)

func _hide_tutorial_toast_later(token: int, duration: float) -> void:
	await get_tree().create_timer(duration).timeout
	if token != tutorial_toast_token:
		return
	if tutorial_toast_panel != null:
		tutorial_toast_panel.visible = false


func _make_system_menu_button() -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(0, 44)
	button.focus_mode = Control.FOCUS_ALL
	return button

func _show_system_menu(visible: bool) -> void:
	if system_menu_overlay == null:
		return
	var was_visible: bool = system_menu_overlay.visible
	var child_overlay_was_visible: bool = (save_slot_overlay != null and save_slot_overlay.visible) or _audio_options_visible()
	if visible and not was_visible and not startup_cover_active:
		_play_ui_sound("panel_open")
	if visible and system_menu_cover != null:
		system_menu_cover.color = Color(0.0, 0.0, 0.0, 1.0) if startup_cover_active else Color(0.02, 0.02, 0.03, 0.84)
	system_menu_overlay.visible = visible
	if not visible:
		_close_save_slot_overlay()
		_close_audio_options_overlay(false)
		if was_visible and not child_overlay_was_visible:
			_play_ui_sound("panel_close")
		return
	var title_font_size: int = 76 if startup_cover_active else 36
	system_menu_panel.offset_left = -320 if startup_cover_active else -240
	system_menu_panel.offset_right = 320 if startup_cover_active else 240
	system_menu_title.add_theme_font_size_override("font_size", title_font_size)
	system_menu_title.custom_minimum_size = Vector2(0.0, 116.0) if startup_cover_active else Vector2.ZERO
	system_menu_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	system_menu_title.text = TextDB.get_text("ui.system_menu.cover_title") if startup_cover_active else TextDB.get_text("ui.system_menu.title")
	system_menu_subtitle.text = TextDB.get_text("ui.system_menu.startup_subtitle") if startup_cover_active else TextDB.get_text("ui.system_menu.ingame_subtitle")
	system_menu_subtitle.visible = false
	system_menu_primary_button.text = TextDB.get_text("ui.system_menu.new_game") if startup_cover_active else TextDB.get_text("ui.system_menu.resume")
	system_menu_return_button.text = TextDB.get_text("ui.system_menu.return_to_cover")
	system_menu_load_button.text = TextDB.get_text("ui.system_menu.load")
	system_menu_save_button.text = TextDB.get_text("ui.system_menu.save")
	system_menu_options_button.text = TextDB.get_text("ui.system_menu.options")
	system_menu_help_button.text = TextDB.get_text("ui.system_menu.help")
	var tutorial_locked: bool = not startup_cover_active and tutorial_manager != null and run_state != null and tutorial_manager.is_active(run_state)
	var has_save: bool = save_manager != null and save_manager.has_any_save()
	system_menu_return_button.visible = not startup_cover_active
	system_menu_load_button.disabled = tutorial_locked or not has_save
	system_menu_save_button.visible = not startup_cover_active
	system_menu_save_button.disabled = startup_cover_active or tutorial_locked
	system_menu_primary_button.grab_focus()

func _on_system_menu_primary_pressed() -> void:
	if startup_cover_active:
		_start_new_game()
	else:
		_show_system_menu(false)

func _on_system_menu_return_pressed() -> void:
	_save_system_game()
	_close_all_detail_views()
	startup_cover_active = true
	_show_system_menu(true)

func _start_new_game() -> void:
	_close_all_detail_views()
	defer_settlement_popup = false
	turn_result_active = false
	turn_result_index = -1
	turn_result_queue.clear()
	pending_turn_result_report_payload.clear()
	if turn_result_overlay != null:
		turn_result_overlay.visible = false
	_clear_turn_result_cards()
	run_state = GameData.create_run_state()
	board_manager.reset_turn_targets(run_state.active_event_ids)
	startup_cover_active = false
	_show_system_menu(false)
	_refresh_board()
	_show_tutorial_prompt_if_needed()

func _on_system_menu_load_pressed() -> void:
	if not startup_cover_active and tutorial_manager != null and run_state != null and tutorial_manager.is_active(run_state):
		_show_message_popup(TextDB.get_text("ui.system_menu.load"), "", TextDB.get_text("ui.system_menu.tutorial_locked_load"))
		return
	if save_manager == null or not save_manager.has_any_save():
		_show_message_popup(TextDB.get_text("ui.system_menu.load"), "", TextDB.get_text("ui.system_menu.no_save"))
		return
	_open_save_slot_overlay("load")

func _on_system_menu_save_pressed() -> void:
	if startup_cover_active:
		return
	if tutorial_manager != null and run_state != null and tutorial_manager.is_active(run_state):
		_show_message_popup(TextDB.get_text("ui.system_menu.save"), "", TextDB.get_text("ui.system_menu.tutorial_locked_save"))
		return
	_open_save_slot_overlay("save")

func _on_system_menu_options_pressed() -> void:
	_open_audio_options_overlay()

func _on_system_menu_help_pressed() -> void:
	_show_message_popup(TextDB.get_text("ui.detail_slots.menu_help.title"), "", TextDB.get_text("ui.detail_slots.menu_help.body"))

func _build_audio_options_overlay() -> void:
	if audio_options_overlay != null or system_menu_overlay == null:
		return
	audio_options_overlay = Control.new()
	audio_options_overlay.name = "AudioOptionsOverlay"
	audio_options_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	audio_options_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	audio_options_overlay.visible = false
	system_menu_overlay.add_child(audio_options_overlay)
	var shade: ColorRect = ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.30)
	audio_options_overlay.add_child(shade)
	audio_options_panel = PanelContainer.new()
	audio_options_panel.anchor_left = 0.5
	audio_options_panel.anchor_top = 0.5
	audio_options_panel.anchor_right = 0.5
	audio_options_panel.anchor_bottom = 0.5
	audio_options_panel.offset_left = -280
	audio_options_panel.offset_top = -190
	audio_options_panel.offset_right = 280
	audio_options_panel.offset_bottom = 190
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
	audio_options_panel.add_theme_stylebox_override("panel", panel_style)
	audio_options_overlay.add_child(audio_options_panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	audio_options_panel.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	audio_options_title = Label.new()
	audio_options_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	audio_options_title.add_theme_font_size_override("font_size", 28)
	box.add_child(audio_options_title)
	audio_options_subtitle = Label.new()
	audio_options_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	audio_options_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	audio_options_subtitle.modulate = Color(1, 1, 1, 0.78)
	audio_options_subtitle.visible = false
	box.add_child(audio_options_subtitle)
	var slider_box: VBoxContainer = VBoxContainer.new()
	slider_box.add_theme_constant_override("separation", 12)
	slider_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(slider_box)
	_build_audio_slider_row(slider_box, "master", TextDB.get_text("ui.audio_options.master"))
	_build_audio_slider_row(slider_box, "music", TextDB.get_text("ui.audio_options.music"))
	_build_audio_slider_row(slider_box, "sfx", TextDB.get_text("ui.audio_options.sfx"))
	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	box.add_child(footer)
	audio_options_reset_button = Button.new()
	audio_options_reset_button.custom_minimum_size = Vector2(130.0, 42.0)
	audio_options_reset_button.pressed.connect(_on_audio_options_reset_pressed)
	footer.add_child(audio_options_reset_button)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	audio_options_close_button = Button.new()
	audio_options_close_button.custom_minimum_size = Vector2(110.0, 42.0)
	audio_options_close_button.pressed.connect(_close_audio_options_overlay)
	footer.add_child(audio_options_close_button)

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
	audio_option_sliders[channel_id] = slider
	audio_option_value_labels[channel_id] = value_label

func _open_audio_options_overlay() -> void:
	_build_audio_options_overlay()
	if audio_options_overlay == null:
		return
	var was_visible: bool = audio_options_overlay.visible
	if not was_visible:
		_play_ui_sound("panel_open")
	_refresh_audio_options_overlay()
	audio_options_overlay.visible = true

func _close_audio_options_overlay(play_sound: bool = true) -> void:
	if audio_options_overlay == null:
		return
	var was_visible: bool = audio_options_overlay.visible
	audio_options_overlay.visible = false
	if was_visible and play_sound:
		_play_ui_sound("panel_close")

func _refresh_audio_options_overlay() -> void:
	if audio_options_overlay == null or audio_manager == null:
		return
	audio_options_title.text = TextDB.get_text("ui.audio_options.title")
	audio_options_subtitle.text = TextDB.get_text("ui.audio_options.subtitle")
	audio_options_subtitle.visible = false
	audio_options_reset_button.text = TextDB.get_text("ui.audio_options.reset")
	audio_options_close_button.text = TextDB.get_text("ui.audio_options.close", TextDB.get_text("ui.buttons.close"))
	for channel_id in ["master", "music", "sfx"]:
		var slider: HSlider = audio_option_sliders.get(channel_id, null) as HSlider
		if slider == null:
			continue
		slider.set_block_signals(true)
		slider.value = round(audio_manager.get_volume_level(channel_id) * 100.0)
		slider.set_block_signals(false)
		_update_audio_option_value_label(channel_id)

func _update_audio_option_value_label(channel_id: String) -> void:
	var value_label: Label = audio_option_value_labels.get(channel_id, null) as Label
	if value_label == null or audio_manager == null:
		return
	value_label.text = TextDB.format_text("ui.audio_options.value", [int(round(audio_manager.get_volume_level(channel_id) * 100.0))], {}, "%d%%")

func _on_audio_slider_value_changed(value: float, channel_id: String) -> void:
	if audio_manager == null:
		return
	audio_manager.set_volume_level(channel_id, value / 100.0)
	_update_audio_option_value_label(channel_id)

func _on_audio_slider_drag_ended(changed: bool, channel_id: String) -> void:
	if changed and channel_id in ["master", "sfx"]:
		_play_ui_sound("button")

func _on_audio_options_reset_pressed() -> void:
	if audio_manager == null:
		return
	audio_manager.reset_volume_levels()
	_refresh_audio_options_overlay()
	_play_ui_sound("button")

func _on_event_dialog_toggled(event_id: String, expanded: bool) -> void:
	if expanded:
		_play_event_open_sound(event_id)
	else:
		_play_ui_sound("panel_close")

func _on_event_spawned(event_id: String) -> void:
	if not startup_cover_active:
		_play_event_spawn_sound(event_id)

func _on_event_resolved(event_id: String, outcome: String) -> void:
	_play_event_result_sound(event_id, outcome)

func _save_system_game() -> bool:
	if save_manager == null or run_state == null:
		return false
	if tutorial_manager != null and tutorial_manager.is_active(run_state):
		return false
	return save_manager.save_system(run_state, board_manager)

func _build_save_slot_overlay() -> void:
	if save_slot_overlay != null or system_menu_overlay == null:
		return
	save_slot_overlay = Control.new()
	save_slot_overlay.name = "SaveSlotOverlay"
	save_slot_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	save_slot_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	save_slot_overlay.visible = false
	system_menu_overlay.add_child(save_slot_overlay)
	var shade: ColorRect = ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.28)
	save_slot_overlay.add_child(shade)
	save_slot_panel = PanelContainer.new()
	save_slot_panel.anchor_left = 0.5
	save_slot_panel.anchor_top = 0.5
	save_slot_panel.anchor_right = 0.5
	save_slot_panel.anchor_bottom = 0.5
	save_slot_panel.offset_left = -360
	save_slot_panel.offset_top = -250
	save_slot_panel.offset_right = 360
	save_slot_panel.offset_bottom = 250
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
	save_slot_panel.add_theme_stylebox_override("panel", panel_style)
	save_slot_overlay.add_child(save_slot_panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	save_slot_panel.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	save_slot_title = Label.new()
	save_slot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_slot_title.add_theme_font_size_override("font_size", 28)
	box.add_child(save_slot_title)
	save_slot_subtitle = Label.new()
	save_slot_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_slot_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_slot_subtitle.modulate = Color(1, 1, 1, 0.78)
	save_slot_subtitle.visible = false
	box.add_child(save_slot_subtitle)
	var slot_list: VBoxContainer = VBoxContainer.new()
	slot_list.add_theme_constant_override("separation", 8)
	slot_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(slot_list)
	save_slot_buttons.clear()
	for _index in range(6):
		var slot_button: Button = Button.new()
		slot_button.custom_minimum_size = Vector2(0.0, 52.0)
		slot_button.focus_mode = Control.FOCUS_ALL
		slot_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot_button.pressed.connect(_on_save_slot_button_pressed.bind(_index))
		slot_list.add_child(slot_button)
		save_slot_buttons.append(slot_button)
	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	box.add_child(footer)
	save_slot_prev_button = Button.new()
	save_slot_prev_button.text = TextDB.get_text("ui.save_slots.prev", "Prev")
	save_slot_prev_button.custom_minimum_size = Vector2(110.0, 42.0)
	save_slot_prev_button.pressed.connect(_on_save_slot_prev_pressed)
	footer.add_child(save_slot_prev_button)
	save_slot_page_label = Label.new()
	save_slot_page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_slot_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_child(save_slot_page_label)
	save_slot_next_button = Button.new()
	save_slot_next_button.text = TextDB.get_text("ui.save_slots.next", "Next")
	save_slot_next_button.custom_minimum_size = Vector2(110.0, 42.0)
	save_slot_next_button.pressed.connect(_on_save_slot_next_pressed)
	footer.add_child(save_slot_next_button)
	save_slot_close_button = Button.new()
	save_slot_close_button.text = TextDB.get_text("ui.buttons.close")
	save_slot_close_button.custom_minimum_size = Vector2(110.0, 42.0)
	save_slot_close_button.pressed.connect(_close_save_slot_overlay)
	footer.add_child(save_slot_close_button)

func _open_save_slot_overlay(mode: String) -> void:
	if save_manager == null:
		return
	_build_save_slot_overlay()
	if save_slot_overlay == null:
		return
	var was_visible: bool = save_slot_overlay.visible
	if not was_visible:
		_play_ui_sound("panel_open")
	save_slot_mode = mode
	save_slot_page = 0
	save_slot_overlay.visible = true
	_refresh_save_slot_overlay()

func _close_save_slot_overlay() -> void:
	if save_slot_overlay == null:
		return
	var was_visible: bool = save_slot_overlay.visible
	save_slot_overlay.visible = false
	save_slot_mode = ""
	if was_visible:
		_play_ui_sound("panel_close")

func _refresh_save_slot_overlay() -> void:
	if save_slot_overlay == null or not save_slot_overlay.visible or save_manager == null:
		return
	var page_total: int = maxi(1, save_manager.page_count())
	save_slot_page = clampi(save_slot_page, 0, page_total - 1)
	var is_load_mode: bool = save_slot_mode == "load"
	save_slot_title.text = TextDB.get_text("ui.save_slots.load_title", "Load Save") if is_load_mode else TextDB.get_text("ui.save_slots.save_title", "Choose Slot")
	save_slot_subtitle.text = TextDB.get_text("ui.save_slots.load_subtitle", "Choose a slot to load.") if is_load_mode else TextDB.get_text("ui.save_slots.save_subtitle", "System slot autosaves each turn; other slots are manual.")
	save_slot_subtitle.visible = false
	save_slot_page_label.text = TextDB.format_text("ui.save_slots.page", [save_slot_page + 1, page_total], {}, "Page %d / %d")
	save_slot_prev_button.disabled = save_slot_page <= 0
	save_slot_next_button.disabled = save_slot_page >= page_total - 1
	var slot_entries: Array[Dictionary] = save_manager.list_slots(save_slot_page)
	for button_index in range(save_slot_buttons.size()):
		var button: Button = save_slot_buttons[button_index]
		if button_index >= slot_entries.size():
			button.visible = false
			button.disabled = true
			continue
		button.visible = true
		var entry: Dictionary = slot_entries[button_index]
		var slot_index: int = int(entry.get("slot_index", -1))
		var has_save: bool = bool(entry.get("has_save", false))
		var metadata: Dictionary = entry.get("metadata", {}) as Dictionary
		button.text = _save_slot_button_text(slot_index, has_save, metadata)
		button.disabled = is_load_mode and not has_save

func _save_slot_button_text(slot_index: int, has_save: bool, metadata: Dictionary) -> String:
	var slot_name: String = save_manager.slot_display_name(slot_index)
	if not has_save:
		return TextDB.format_text("ui.save_slots.empty", [slot_name], {}, "%s\nEmpty")
	var label: String = str(metadata.get("label", slot_name))
	var term_name: String = str(metadata.get("term_name", ""))
	var turn_index: int = int(metadata.get("turn_index", 0))
	var saved_at: String = str(metadata.get("saved_at", ""))
	return TextDB.format_text("ui.save_slots.filled", [slot_name, label, term_name, turn_index, saved_at], {}, "%s | %s\n%s | Turn %d | %s")

func _on_save_slot_button_pressed(local_index: int) -> void:
	if save_manager == null or run_state == null:
		return
	var slot_index: int = save_slot_page * save_manager.PAGE_SIZE + local_index
	if slot_index < 0 or slot_index > save_manager.MANUAL_SLOT_COUNT:
		return
	if save_slot_mode == "load":
		var snapshot: Dictionary = save_manager.load_from_slot(slot_index)
		if snapshot.is_empty():
			_show_message_popup(TextDB.get_text("ui.save_slots.load_title", "Load Save"), "", TextDB.get_text("ui.system_menu.no_save"))
			return
		_apply_loaded_snapshot(snapshot)
		_close_save_slot_overlay()
		_show_system_menu(false)
		_show_message_popup(TextDB.get_text("ui.save_slots.load_title", "Load Save"), "", TextDB.get_text("ui.system_menu.load_done"))
		return
	var label: String = save_manager.slot_display_name(slot_index)
	if slot_index == save_manager.SYSTEM_SLOT_INDEX:
		label = TextDB.get_text("ui.save_slots.system_label", "系统存档")
	var ok: bool = save_manager.save_to_slot(slot_index, run_state, board_manager, label, slot_index == save_manager.SYSTEM_SLOT_INDEX)
	if ok:
		_refresh_save_slot_overlay()
		_show_message_popup(TextDB.get_text("ui.system_menu.save", "存档"), "", TextDB.get_text("ui.system_menu.save_done"))

func _on_save_slot_prev_pressed() -> void:
	save_slot_page -= 1
	_refresh_save_slot_overlay()

func _on_save_slot_next_pressed() -> void:
	save_slot_page += 1
	_refresh_save_slot_overlay()

func _apply_loaded_snapshot(snapshot: Dictionary) -> void:
	_close_all_detail_views()
	run_state = snapshot.get("run_state", GameData.create_run_state()) as RunState
	if tutorial_manager != null and run_state != null:
		tutorial_manager.repair_loaded_state(run_state)
	board_manager.restore_state(run_state.active_event_ids, snapshot.get("board", {}) as Dictionary)
	startup_cover_active = false
	_refresh_board()

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
	if bool(run_state.flags.get("unlocked_recruit", false)):
		ids.append("recruit")
	if bool(run_state.flags.get("unlocked_audience", false)):
		ids.append("audience")
	if bool(run_state.flags.get("unlocked_research", false)):
		ids.append("research")
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
		slot.drag_slot_hovered.connect(_on_slot_drag_hovered)
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
	var desired_ids: Array[String] = _get_unlocked_slot_ids()
	if _current_slot_ids() != desired_ids:
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
	_apply_global_text_adjustments(self)
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
	popup_subtitle.visible = false
	popup_body.text = str(page.get("body", ""))
	_set_popup_body_document_layout()
	_set_popup_art_image("")
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

func _show_message_popup(title: String, subtitle: String, body: String, presentation: String = "", image_path: String = "") -> void:
	settlement_dialog_active = false
	end_turn_confirm_active = false
	turn_report_dialog_active = false
	popup_presentation_token += 1
	popup_presentation_effect = presentation
	_reset_popup_presentation_visuals()
	_play_ui_sound("panel_open")
	_configure_popup_for_message()
	popup_title.text = title
	popup_subtitle.text = subtitle
	popup_subtitle.visible = false
	var display_body: String = body
	if popup_presentation_effect == "letter_unfold":
		display_body = _normalize_document_body(body)
	popup_body.text = display_body
	popup_body.scroll_to_line(0)
	if popup_presentation_effect == "letter_unfold":
		_set_popup_body_document_layout()
	else:
		_set_popup_body_center_layout()
	_set_popup_art_image(image_path)
	detail_overlay.visible = true
	if popup_presentation_effect == "letter_unfold":
		call_deferred("_play_popup_presentation", popup_presentation_token, popup_presentation_effect)

func _show_tutorial_prompt_if_needed(force: bool = false) -> bool:
	if tutorial_manager == null or run_state == null:
		return false
	if detail_overlay.visible:
		return false
	var prompt: Dictionary = tutorial_manager.force_prompt(run_state) if force else tutorial_manager.consume_prompt(run_state)
	if prompt.is_empty():
		return false
	_show_message_popup(str(prompt.get("title", "")), str(prompt.get("subtitle", "")), str(prompt.get("body", "")))
	_set_popup_body_prompt_layout()
	return true

func _build_tutorial_dialog_ui() -> void:
	if tutorial_dialog_overlay != null:
		return
	tutorial_dialog_overlay = Control.new()
	tutorial_dialog_overlay.name = "TutorialDialogueOverlay"
	tutorial_dialog_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	tutorial_dialog_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	tutorial_dialog_overlay.z_as_relative = false
	tutorial_dialog_overlay.z_index = 1200
	tutorial_dialog_overlay.visible = false
	add_child(tutorial_dialog_overlay)
	tutorial_dialog_overlay.gui_input.connect(_on_tutorial_dialog_gui_input)
	var dimmer: ColorRect = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.14)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_dialog_overlay.add_child(dimmer)
	tutorial_dialog_panel = PanelContainer.new()
	tutorial_dialog_panel.anchor_left = 0.03
	tutorial_dialog_panel.anchor_top = 1.0
	tutorial_dialog_panel.anchor_right = 0.97
	tutorial_dialog_panel.anchor_bottom = 1.0
	tutorial_dialog_panel.offset_top = -252.0
	tutorial_dialog_panel.offset_bottom = -14.0
	tutorial_dialog_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	tutorial_dialog_panel.gui_input.connect(_on_tutorial_dialog_gui_input)
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.06, 0.96)
	panel_style.border_color = Color(0.45, 0.45, 0.48, 0.95)
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
	tutorial_dialog_panel.add_theme_stylebox_override("panel", panel_style)
	tutorial_dialog_overlay.add_child(tutorial_dialog_panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	tutorial_dialog_panel.add_child(margin)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(row)
	tutorial_dialog_left_portrait = TextureRect.new()
	tutorial_dialog_left_portrait.custom_minimum_size = Vector2(150.0, 210.0)
	tutorial_dialog_left_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tutorial_dialog_left_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tutorial_dialog_left_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(tutorial_dialog_left_portrait)
	var center_box: VBoxContainer = VBoxContainer.new()
	center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_box.add_theme_constant_override("separation", 8)
	row.add_child(center_box)
	tutorial_dialog_name = Label.new()
	tutorial_dialog_name.add_theme_font_size_override("font_size", 28)
	tutorial_dialog_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_box.add_child(tutorial_dialog_name)
	tutorial_dialog_text = RichTextLabel.new()
	tutorial_dialog_text.bbcode_enabled = false
	tutorial_dialog_text.fit_content = false
	tutorial_dialog_text.scroll_active = false
	tutorial_dialog_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_dialog_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tutorial_dialog_text.add_theme_font_size_override("normal_font_size", 24)
	tutorial_dialog_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_box.add_child(tutorial_dialog_text)
	tutorial_dialog_hint = Label.new()
	tutorial_dialog_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tutorial_dialog_hint.modulate = Color(1.0, 1.0, 1.0, 0.72)
	tutorial_dialog_hint.text = TextDB.get_text("ui.messages.dialog_click_continue", "Continue")
	tutorial_dialog_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_box.add_child(tutorial_dialog_hint)
	tutorial_dialog_right_portrait = TextureRect.new()
	tutorial_dialog_right_portrait.custom_minimum_size = Vector2(150.0, 210.0)
	tutorial_dialog_right_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tutorial_dialog_right_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tutorial_dialog_right_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(tutorial_dialog_right_portrait)

func _show_tutorial_followup_if_needed() -> bool:
	if tutorial_manager == null or run_state == null or detail_overlay.visible:
		return false
	var popup: Dictionary = tutorial_manager.consume_followup_popup(run_state)
	if popup.is_empty():
		return false
	_show_message_popup(
		str(popup.get("title", "")),
		str(popup.get("subtitle", "")),
		str(popup.get("body", "")),
		str(popup.get("presentation", "")),
		str(popup.get("image_path", ""))
	)
	tutorial_prompt_after_popup = bool(popup.get("chain_to_prompt", false))
	return true

func _try_show_tutorial_pre_report_dialog(report_turn_index: int, report_logs: Array[String], title_override: String, subtitle_override: String, body_override: String) -> bool:
	if tutorial_manager == null or run_state == null:
		return false
	var dialogue: Dictionary = tutorial_manager.pre_report_dialogue(run_state)
	if dialogue.is_empty():
		return false
	pending_report_payload = {
		"turn_index": report_turn_index,
		"logs": report_logs.duplicate(true),
		"title": title_override,
		"subtitle": subtitle_override,
		"body": body_override
	}
	_start_tutorial_dialog(dialogue)
	return true

func _start_tutorial_dialog(dialogue: Dictionary) -> void:
	if tutorial_dialog_overlay == null:
		_build_tutorial_dialog_ui()
	tutorial_dialog_lines = []
	for line_variant in dialogue.get("lines", []):
		if line_variant is Dictionary:
			tutorial_dialog_lines.append((line_variant as Dictionary).duplicate(true))
	tutorial_dialog_index = 0
	tutorial_dialog_active = not tutorial_dialog_lines.is_empty()
	if not tutorial_dialog_active:
		_finish_tutorial_dialog()
		return
	var left_character_id: String = str(dialogue.get("left_character_id", ""))
	var right_character_id: String = str(dialogue.get("right_character_id", ""))
	tutorial_dialog_flip_sides = false
	if left_character_id == "cao_cao" and not right_character_id.is_empty():
		tutorial_dialog_flip_sides = true
		var swapped_character_id: String = left_character_id
		left_character_id = right_character_id
		right_character_id = swapped_character_id
	_set_tutorial_dialog_portrait(tutorial_dialog_left_portrait, left_character_id)
	_set_tutorial_dialog_portrait(tutorial_dialog_right_portrait, right_character_id)
	detail_overlay.visible = false
	tutorial_dialog_overlay.visible = true
	_render_tutorial_dialog_line()

func _set_tutorial_dialog_portrait(target: TextureRect, character_id: String) -> void:
	if target == null:
		return
	var texture: Texture2D = null
	if characters.has(character_id):
		var data: CharacterData = characters[character_id] as CharacterData
		if data != null and not data.art_path.is_empty() and ResourceLoader.exists(data.art_path):
			texture = load(data.art_path) as Texture2D
	target.texture = texture

func _render_tutorial_dialog_line() -> void:
	if not tutorial_dialog_active or tutorial_dialog_index < 0 or tutorial_dialog_index >= tutorial_dialog_lines.size():
		_finish_tutorial_dialog()
		return
	var line: Dictionary = tutorial_dialog_lines[tutorial_dialog_index] as Dictionary
	var side: String = str(line.get("side", "left"))
	if tutorial_dialog_flip_sides:
		side = "right" if side == "left" else "left"
	tutorial_dialog_name.text = str(line.get("speaker", ""))
	tutorial_dialog_text.text = str(line.get("text", ""))
	tutorial_dialog_text.scroll_to_line(0)
	tutorial_dialog_left_portrait.modulate = Color(1.0, 1.0, 1.0, 1.0 if side == "left" else 0.45)
	tutorial_dialog_right_portrait.modulate = Color(1.0, 1.0, 1.0, 1.0 if side == "right" else 0.45)
	tutorial_dialog_hint.text = TextDB.get_text("ui.messages.dialog_click_continue", "Continue")

func _advance_tutorial_dialog() -> void:
	if not tutorial_dialog_active:
		return
	tutorial_dialog_index += 1
	if tutorial_dialog_index >= tutorial_dialog_lines.size():
		_finish_tutorial_dialog()
		return
	_render_tutorial_dialog_line()

func _finish_tutorial_dialog() -> void:
	tutorial_dialog_active = false
	tutorial_dialog_index = -1
	tutorial_dialog_flip_sides = false
	tutorial_dialog_lines.clear()
	if tutorial_dialog_overlay != null:
		tutorial_dialog_overlay.visible = false
	var payload: Dictionary = pending_report_payload.duplicate(true)
	pending_report_payload.clear()
	if payload.is_empty():
		return
	var report_logs: Array[String] = []
	for log_variant in payload.get("logs", []):
		report_logs.append(str(log_variant))
	_show_turn_report_dialog(
		int(payload.get("turn_index", run_state.turn_index)),
		report_logs,
		str(payload.get("title", "")),
		str(payload.get("subtitle", "")),
		str(payload.get("body", ""))
	)

func _on_tutorial_dialog_gui_input(event: InputEvent) -> void:
	if not tutorial_dialog_active:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_advance_tutorial_dialog()
			accept_event()

func _build_popup_presentation_ui() -> void:
	if popup_panel == null or popup_effect_overlay != null:
		return
	popup_effect_overlay = Control.new()
	popup_effect_overlay.name = "PopupEffectOverlay"
	popup_effect_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_effect_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_effect_overlay.clip_contents = true
	popup_effect_overlay.visible = false
	popup_panel.add_child(popup_effect_overlay)
	popup_panel.move_child(popup_effect_overlay, popup_panel.get_child_count() - 1)
	popup_effect_top_cover = ColorRect.new()
	popup_effect_top_cover.color = Color(0.17, 0.14, 0.12, 0.98)
	popup_effect_top_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_effect_overlay.add_child(popup_effect_top_cover)
	popup_effect_bottom_cover = ColorRect.new()
	popup_effect_bottom_cover.color = Color(0.17, 0.14, 0.12, 0.98)
	popup_effect_bottom_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_effect_overlay.add_child(popup_effect_bottom_cover)
	popup_effect_seam = ColorRect.new()
	popup_effect_seam.color = Color(0.82, 0.72, 0.52, 0.92)
	popup_effect_seam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_effect_overlay.add_child(popup_effect_seam)
	popup_panel.resized.connect(_layout_popup_letter_overlay)
	_layout_popup_letter_overlay()

func _layout_popup_letter_overlay() -> void:
	if popup_effect_overlay == null or popup_effect_top_cover == null or popup_effect_bottom_cover == null or popup_effect_seam == null:
		return
	var panel_size: Vector2 = popup_panel.size if popup_panel.size != Vector2.ZERO else popup_panel.custom_minimum_size
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		return
	var seam_height: float = 8.0
	var half_height: float = panel_size.y * 0.5 + seam_height
	popup_effect_top_cover.position = Vector2.ZERO
	popup_effect_top_cover.size = Vector2(panel_size.x, half_height)
	popup_effect_bottom_cover.position = Vector2(0.0, panel_size.y - half_height)
	popup_effect_bottom_cover.size = Vector2(panel_size.x, half_height)
	popup_effect_seam.position = Vector2(0.0, panel_size.y * 0.5 - seam_height * 0.5)
	popup_effect_seam.size = Vector2(panel_size.x, seam_height)

func _reset_popup_presentation_visuals() -> void:
	if popup_effect_tween != null:
		popup_effect_tween.kill()
		popup_effect_tween = null
	if popup_panel != null:
		popup_panel.scale = Vector2.ONE
		popup_panel.modulate = Color.WHITE
		popup_panel.pivot_offset = popup_panel.size * 0.5
	if popup_effect_overlay != null:
		_layout_popup_letter_overlay()
		popup_effect_overlay.visible = false
	if popup_effect_seam != null:
		popup_effect_seam.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _play_popup_presentation(token: int, presentation: String) -> void:
	await get_tree().process_frame
	if token != popup_presentation_token or presentation != popup_presentation_effect or not detail_overlay.visible:
		return
	if presentation != "letter_unfold":
		return
	_build_popup_presentation_ui()
	_layout_popup_letter_overlay()
	if popup_effect_overlay == null or popup_effect_top_cover == null or popup_effect_bottom_cover == null or popup_effect_seam == null:
		return
	popup_panel.pivot_offset = popup_panel.size * 0.5
	popup_panel.scale = Vector2(0.985, 0.94)
	popup_panel.modulate = Color(1.0, 1.0, 1.0, 0.82)
	popup_effect_overlay.visible = true
	popup_effect_top_cover.position.y = 0.0
	popup_effect_bottom_cover.position.y = popup_panel.size.y - popup_effect_bottom_cover.size.y
	popup_effect_seam.modulate = Color(1.0, 1.0, 1.0, 1.0)
	popup_effect_tween = create_tween().set_parallel(true)
	popup_effect_tween.tween_property(popup_panel, "scale", Vector2.ONE, LETTER_POPUP_EFFECT_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	popup_effect_tween.tween_property(popup_panel, "modulate", Color.WHITE, LETTER_POPUP_EFFECT_DURATION * 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	popup_effect_tween.tween_property(popup_effect_top_cover, "position:y", -popup_effect_top_cover.size.y - 10.0, LETTER_POPUP_EFFECT_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	popup_effect_tween.tween_property(popup_effect_bottom_cover, "position:y", popup_panel.size.y + 10.0, LETTER_POPUP_EFFECT_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	popup_effect_tween.tween_property(popup_effect_seam, "modulate:a", 0.0, LETTER_POPUP_EFFECT_DURATION * 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	popup_effect_tween.finished.connect(_on_popup_presentation_finished.bind(token))

func _on_popup_presentation_finished(token: int) -> void:
	if token != popup_presentation_token:
		return
	if popup_effect_overlay != null:
		popup_effect_overlay.visible = false
	popup_effect_tween = null

func _configure_popup_for_detail() -> void:
	_reset_popup_presentation_visuals()
	popup_panel.custom_minimum_size = POPUP_DETAIL_SIZE
	popup_art_frame.visible = true
	popup_close.text = TextDB.get_text("ui.buttons.close")
	_set_popup_cancel_state(false)
	_set_popup_body_center_layout()

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

func _on_popup_body_gui_input(event: InputEvent) -> void:
	if popup_body == null or not detail_overlay.visible:
		return
	if event is not InputEventMouseButton:
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	var direction: float = 0.0
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		direction = -1.0
	elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		direction = 1.0
	else:
		return
	var scroll_bar: VScrollBar = popup_body.get_v_scroll_bar()
	if scroll_bar == null or is_zero_approx(scroll_bar.max_value - scroll_bar.min_value):
		return
	var step: float = 72.0 * maxf(mouse_event.factor, 1.0)
	scroll_bar.value = clampf(scroll_bar.value + direction * step, scroll_bar.min_value, scroll_bar.max_value)
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

func _replace_target_base_id(target_id: String) -> String:
	var base_target_id: String = target_id.strip_edges()
	if base_target_id.contains("@replace="):
		base_target_id = base_target_id.get_slice("@replace=", 0)
	if base_target_id.contains("#"):
		base_target_id = base_target_id.get_slice("#", 0)
	return base_target_id

func _make_replace_assign_target(target_id: String, replace_uid: String) -> String:
	if target_id.is_empty() or replace_uid.is_empty():
		return target_id
	return "%s@replace=%s" % [target_id, replace_uid]

func _build_committed_preview_with_size(card: Dictionary, card_width: float, card_height: float, art_height: float, replace_target_id: String = "", current_cards: Array = [], spec: Dictionary = {}) -> CardView:
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
	if not replace_target_id.is_empty():
		payload["assign_target_id"] = replace_target_id
		payload["target_id"] = _replace_target_base_id(replace_target_id)
		payload["replace_drop_enabled"] = true
		payload["replace_uid"] = str(card.get("uid", ""))
		payload["current_cards"] = current_cards.duplicate(true)
		payload["slot_key"] = str(spec.get("key", ""))
		payload["allowed_card_types"] = spec.get("allowed_card_types", [])
		payload["allowed_card_ids"] = spec.get("allowed_card_ids", [])
		payload["blocked_card_ids"] = spec.get("blocked_card_ids", [])
		payload["required_tags"] = spec.get("required_tags", [])
	preview.setup(payload)
	preview.custom_minimum_size = Vector2(card_width, card_height)
	preview.card_clicked.connect(_on_detail_card_clicked)
	preview.remove_requested.connect(_on_card_remove_requested)
	if not replace_target_id.is_empty():
		preview.target_drop_requested.connect(_on_target_drop_requested)
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
			"title_font_size": 16,
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
			"title_font_size": 16,
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
		card.quick_assign_requested.connect(_on_card_quick_assign_requested)
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
	_play_ui_sound("card_focus")
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
	window.apply_title_font(_load_font_resource(TITLE_FONT_PATH))
	window.apply_body_font_size(BODY_FONT_SIZE)
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
	var was_visible: bool = detail_overlay.visible
	popup_presentation_token += 1
	popup_presentation_effect = ""
	settlement_dialog_active = false
	end_turn_confirm_active = false
	turn_report_dialog_active = false
	_configure_popup_for_detail()
	detail_overlay.visible = false
	if was_visible:
		_play_ui_sound("panel_close")
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

func _on_slot_drag_hovered(slot_id: String, payload: Dictionary) -> void:
	if slot_id.is_empty() or payload == null:
		return
	if slot_id.contains(":") or events.has(slot_id):
		return
	if not _tutorial_allows_assignment(slot_id, payload):
		return
	if detail_panel_open and selected_slot_id == slot_id:
		return
	_show_slot_detail(slot_id, false, true)

func _on_slot_card_clicked(slot_id: String) -> void:
	_play_ui_sound("card_focus")
	_show_slot_detail(slot_id, true)

func _show_slot_detail(slot_id: String, focus_window: bool = false, suppress_focus: bool = false) -> void:
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
		focus_window,
		suppress_focus
	)

func _detail_setup(title: String, subtitle: String, body: String, icon_path: String, assigned_cards: Array, footnote: String, focus_window: bool = false, suppress_focus: bool = false) -> void:
	var detail_panel_was_visible: bool = detail_panel.visible
	detail_panel_open = true
	detail_panel.visible = true
	_apply_detail_panel_window_size()
	_ensure_detail_panel_position()
	if not suppress_focus and (focus_window or not detail_panel_was_visible):
		_focus_detail_panel()
	detail_title.text = title
	detail_subtitle.text = subtitle
	detail_subtitle.visible = false
	detail_body.text = body
	_set_rich_text_layout(detail_body, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP)
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
	var display_cards: Array = _group_assigned_cards_for_display(assigned_cards)
	var specs: Array = _detail_slot_specs(slot_id)
	var effective_capacity: int = _detail_total_capacity(slot_id)
	if not specs.is_empty() and effective_capacity > 0 and specs.size() > effective_capacity:
		specs = specs.slice(0, effective_capacity)
	var total_slots: int = specs.size() if not specs.is_empty() else (display_cards.size() + _detail_remaining_capacity(slot_id, assigned_cards))
	var layout: Dictionary = _detail_assignment_layout(total_slots)
	var card_width: float = float(layout.get("card_width", LIST_CARD_WIDTH))
	var card_height: float = float(layout.get("card_height", LIST_CARD_HEIGHT))
	var art_height: float = float(layout.get("art_height", LIST_CARD_ART_HEIGHT))
	if specs.is_empty():
		for card_variant in display_cards:
			var loose_card: Dictionary = card_variant as Dictionary
			var replace_target_id: String = _make_replace_assign_target(slot_id, str(loose_card.get("uid", "")))
			var loose_preview: CardView = _build_committed_preview_with_size(loose_card, card_width, card_height, art_height, replace_target_id, assigned_cards)
			loose_preview.custom_minimum_size = Vector2(card_width, card_height)
			loose_preview.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			loose_preview.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			detail_assignment_row.add_child(loose_preview)
		for index in range(_detail_remaining_capacity(slot_id, assigned_cards)):
			var fallback_placeholder: SlotView = _build_detail_placeholder(slot_id, index, {}, assigned_cards, card_width, card_height, art_height)
			detail_assignment_row.add_child(fallback_placeholder)
		return
	var placements: Array = _place_cards_into_detail_specs(specs, display_cards)
	for index in range(specs.size()):
		var placed_card: Dictionary = placements[index] as Dictionary
		var spec: Dictionary = specs[index] as Dictionary
		if not placed_card.is_empty():
			var replace_base_target_id: String = slot_id if str(spec.get("key", "")).is_empty() else "%s#%s" % [slot_id, str(spec.get("key", ""))]
			var replace_target_id: String = _make_replace_assign_target(replace_base_target_id, str(placed_card.get("uid", "")))
			var preview: CardView = _build_committed_preview_with_size(placed_card, card_width, card_height, art_height, replace_target_id, assigned_cards, spec)
			preview.custom_minimum_size = Vector2(card_width, card_height)
			preview.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			preview.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			detail_assignment_row.add_child(preview)
		else:
			var placeholder: SlotView = _build_detail_placeholder(slot_id, index, specs[index] as Dictionary, assigned_cards, card_width, card_height, art_height)
			detail_assignment_row.add_child(placeholder)

func _detail_total_capacity(slot_id: String) -> int:
	var total_capacity: int = -1
	if tutorial_manager != null:
		total_capacity = tutorial_manager.total_capacity_override(run_state, slot_id)
	if total_capacity < 0:
		var capacities: Dictionary = GameRules.SLOT_CAPACITY.get(slot_id, {})
		total_capacity = 0
		for value_variant in capacities.values():
			total_capacity += int(value_variant)
	return total_capacity

func _detail_slot_specs(slot_id: String) -> Array:
	match slot_id:
		"governance":
			return [
				{"key": "governance_primary", "allowed_card_types": ["character"]},
				{"key": "governance_support", "allowed_card_types": ["character"]}
			]
		"audience":
			return [
				{"key": "audience_lord", "allowed_card_types": ["character"], "allowed_card_ids": ["cao_cao"]},
				{"key": "audience_guest", "allowed_card_types": ["character", "risk"], "blocked_card_ids": ["cao_cao"], "allowed_card_ids": ["rumor", "alienation"]},
				{"key": "audience_resource_1", "allowed_card_types": ["resource"]}
			]
		"research":
			return [
				{"key": "research_primary", "allowed_card_types": ["character"]},
				{"key": "research_support", "allowed_card_types": ["character"]},
				{"key": "research_subject", "allowed_card_types": ["event"]},
				{"key": "research_resource_1", "allowed_card_types": ["resource"]}
			]
		"recruit":
			return [
				{"key": "recruit_primary", "allowed_card_types": ["character"]},
				{"key": "recruit_support", "allowed_card_types": ["character"]},
				{"key": "recruit_money", "allowed_card_types": ["resource"], "allowed_card_ids": ["silver_pack"]},
				{"key": "recruit_task", "allowed_card_types": ["resource"], "required_tags": ["task", "recruit", "document"]}
			]
		"rest":
			return [
				{"key": "rest_target", "allowed_card_types": ["character"]},
				{"key": "rest_resource_1", "allowed_card_types": ["resource"], "allowed_card_ids": ["silver_pack", "herbal_tonic", "calming_incense"]},
				{"key": "rest_caregiver", "allowed_card_types": ["character", "risk"], "allowed_card_ids": ["headwind"]}
			]
	return []

func _place_cards_into_detail_specs(specs: Array, display_cards: Array) -> Array:
	var placements: Array = []
	for _index in range(specs.size()):
		placements.append({})
	for card_variant in display_cards:
		var card: Dictionary = card_variant as Dictionary
		var placed: bool = false
		for index in range(specs.size()):
			if not (placements[index] as Dictionary).is_empty():
				continue
			if _card_matches_detail_spec(card, specs[index] as Dictionary):
				placements[index] = card
				placed = true
				break
		if placed:
			continue
		for index in range(specs.size()):
			if (placements[index] as Dictionary).is_empty():
				placements[index] = card
				break
	return placements

func _card_matches_detail_spec(card: Dictionary, spec: Dictionary) -> bool:
	var card_type: String = str(card.get("card_type", ""))
	var card_id: String = str(card.get("id", ""))
	var spec_key: String = str(spec.get("key", ""))
	var allowed_types: Array = spec.get("allowed_card_types", [])
	if not allowed_types.is_empty() and not allowed_types.has(card_type):
		return false
	if spec_key == "recruit_support":
		return card_type == "character"
	if spec_key == "recruit_money":
		return card_type == "resource" and card_id == "silver_pack"
	if spec_key == "recruit_task":
		return card_type == "resource" and card_id == "recruit_writ"
	var allowed_ids: Array = spec.get("allowed_card_ids", [])
	if not allowed_ids.is_empty():
		if card_type == "risk":
			if not allowed_ids.has(card_id):
				return false
		elif not allowed_ids.has(card_id) and spec_key not in ["audience_guest", "rest_caregiver"]:
			return false
	var blocked_ids: Array = spec.get("blocked_card_ids", [])
	if blocked_ids.has(card_id):
		return false
	var required_tags: Array = spec.get("required_tags", [])
	if required_tags.is_empty():
		return true
	var tags: Array = card.get("tags", [])
	for tag_variant in required_tags:
		if tags.has(tag_variant):
			return true
	return false

func _build_detail_placeholder(slot_id: String, index: int, spec: Dictionary, assigned_cards: Array, card_width: float, card_height: float, art_height: float) -> SlotView:
	var placeholder: SlotView = SLOT_SCENE.instantiate()
	placeholder.custom_minimum_size = Vector2(card_width, card_height)
	placeholder.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	placeholder.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var spec_key: String = str(spec.get("key", "")).strip_edges()
	var title: String = TextDB.get_text("ui.detail_slots.%s.title" % spec_key) if not spec_key.is_empty() else ""
	var body: String = TextDB.get_text("ui.detail_slots.%s.body" % spec_key) if not spec_key.is_empty() else ""
	var tooltip_text: String = title if body.is_empty() else "%s\n%s" % [title, body]
	placeholder.setup({
		"id": "%s:detail:%d" % [slot_id, index],
		"target_id": slot_id,
		"assign_target_id": "%s#%s" % [slot_id, spec_key],
		"card_type": "slot",
		"title": title,
		"subtitle": "",
		"body": body,
		"assigned_text": "",
		"image_path": "",
		"image_label": title,
		"tooltip_text": tooltip_text,
		"slot_key": spec_key,
		"allowed_card_types": spec.get("allowed_card_types", []),
		"allowed_card_ids": spec.get("allowed_card_ids", []),
		"blocked_card_ids": spec.get("blocked_card_ids", []),
		"required_tags": spec.get("required_tags", []),
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
	return placeholder

func _detail_remaining_capacity(slot_id: String, assigned_cards: Array) -> int:
	return maxi(0, _detail_total_capacity(slot_id) - assigned_cards.size())

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
		_play_ui_sound("assign_fail")
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
		_play_ui_sound("assign_ok")
	else:
		run_state.log_entries.append(TextDB.get_text("logs.board.invalid_drop"))
		_play_ui_sound("assign_fail")
	_refresh_board()

func _on_card_remove_requested(payload: Dictionary) -> void:
	var uid: String = str(payload.get("uid", ""))
	if uid.is_empty():
		return
	if board_manager.unassign_card(uid):
		_play_ui_sound("remove")
		_refresh_board()

func _find_quick_assign_target(payload: Dictionary) -> Dictionary:
	var tutorial_override: Dictionary = _tutorial_quick_assign_override(payload)
	if not tutorial_override.is_empty():
		return tutorial_override
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

func _tutorial_quick_assign_override(payload: Dictionary) -> Dictionary:
	if tutorial_manager == null or run_state == null or payload.is_empty():
		return {}
	if not tutorial_manager.is_active(run_state):
		return {}
	if tutorial_manager.current_step(run_state) != 4:
		return {}
	if str(payload.get("card_type", "")) != "character" or str(payload.get("id", "")) != "cao_cao":
		return {}
	if not _tutorial_allows_assignment("rest", payload):
		return {}
	if not GameRules.can_drop_on_slot("rest", payload, board_manager.get_slot_cards("rest")):
		return {}
	return {
		"kind": "slot",
		"slot_id": "rest",
		"score": 1000,
		"label": TextDB.get_text("system.slots.rest.title")
	}

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
	if locked:
		lines.append(TextDB.get_text("system.character_templates.locked_hint"))
	return "\n".join(lines)

func _parse_drop_request_target(target_id: String) -> Dictionary:
	var tutorial_target_id: String = target_id.strip_edges()
	var replace_uid: String = ""
	if tutorial_target_id.contains("@replace="):
		replace_uid = tutorial_target_id.get_slice("@replace=", 1)
		tutorial_target_id = tutorial_target_id.get_slice("@replace=", 0)
	var resolved_target_id: String = tutorial_target_id.get_slice("#", 0) if tutorial_target_id.contains("#") else tutorial_target_id
	return {
		"tutorial_target_id": tutorial_target_id,
		"resolved_target_id": resolved_target_id,
		"replace_uid": replace_uid
	}

func _on_target_drop_requested(target_id: String, payload: Dictionary) -> void:
	if payload == null:
		return
	var target_info: Dictionary = _parse_drop_request_target(target_id)
	var tutorial_target_id: String = str(target_info.get("tutorial_target_id", ""))
	var resolved_target_id: String = str(target_info.get("resolved_target_id", ""))
	var replace_uid: String = str(target_info.get("replace_uid", ""))
	if not _tutorial_allows_assignment(tutorial_target_id, payload):
		run_state.log_entries.append(TextDB.get_text("logs.board.invalid_drop"))
		_play_ui_sound("assign_fail")
		_refresh_board()
		return
	var ok: bool = false
	if resolved_target_id.contains(":character"):
		ok = board_manager.assign_to_event(resolved_target_id.get_slice(":", 0), payload, "character", replace_uid)
	elif resolved_target_id.contains(":resource"):
		ok = board_manager.assign_to_event(resolved_target_id.get_slice(":", 0), payload, "resource", replace_uid)
	elif events.has(resolved_target_id):
		ok = board_manager.assign_to_event(resolved_target_id, payload, "", replace_uid)
	else:
		ok = board_manager.assign_to_slot(resolved_target_id, payload, replace_uid)
	if not ok:
		run_state.log_entries.append(TextDB.get_text("logs.board.invalid_drop"))
		_play_ui_sound("assign_fail")
	else:
		_play_ui_sound("assign_ok")
		if not resolved_target_id.contains(":") and not events.has(resolved_target_id):
			selected_slot_id = resolved_target_id
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
	_play_ui_sound("panel_open")
	_configure_popup_for_confirm()
	popup_title.text = TextDB.get_text("turn_report.confirm.title")
	popup_subtitle.text = TextDB.get_text("turn_report.confirm.subtitle")
	popup_subtitle.visible = false
	popup_body.text = TextDB.get_text("turn_report.confirm.body")
	popup_body.scroll_to_line(0)
	_set_popup_body_center_layout()
	_set_popup_art_image("")
	detail_overlay.visible = true

func _build_turn_report_body(turn_index: int, logs: Array[String], body_override: String = "") -> String:
	if _has_meaningful_story_text(body_override):
		return _normalize_document_body(body_override)
	return _normalize_document_body(_build_turn_story_body(turn_index, logs))

func _build_turn_story_body(turn_index: int, logs: Array[String]) -> String:
	var term_name: String = GameRules.current_term_name(turn_index)
	var start_line: String = TextDB.format_text("logs.turn.start", [turn_index])
	var story_lines: Array[String] = []
	var raw_lines: Array[String] = []
	for log_variant in logs:
		var line: String = str(log_variant).strip_edges()
		if line.is_empty() or line == start_line:
			continue
		raw_lines.append(line)
	if raw_lines.is_empty():
		return TextDB.format_text(
			"turn_report.report.story_quiet",
			[term_name],
			{},
			"The desk stayed quiet this turn, and little changed beneath the lamp."
		)
	story_lines.append(
		TextDB.format_text(
			"turn_report.report.story_intro",
			[term_name],
			{},
			"This turn, matters beneath the lamp slowly found their course in %s."
		)
	)
	var connectors: Array = TextDB.get_array("turn_report.report.story_connectors")
	if connectors.is_empty():
		connectors = ["First, ", "Then, ", "Soon after, ", "Later, ", "By turn's end, "]
	for index in range(raw_lines.size()):
		var connector: String = str(connectors[index % connectors.size()]).strip_edges()
		story_lines.append(_build_story_sentence(raw_lines[index], connector))
	var narrative_key: String = "turn_report.narratives.turn_%02d" % turn_index
	var narrative_tail: String = TextDB.get_text(narrative_key, "").strip_edges()
	if _has_meaningful_story_text(narrative_tail):
		story_lines.append(narrative_tail)
	else:
		story_lines.append(TextDB.get_text("turn_report.report.story_closing", "Night deepened, and the turn quietly came to a close."))
	return "\n\n".join(story_lines)

func _build_story_sentence(raw_line: String, connector: String = "") -> String:
	var content: String = raw_line.strip_edges()
	if content.is_empty():
		return ""
	if not connector.is_empty() and not content.begins_with(connector):
		content = "%s%s" % [connector, content]
	return _ensure_story_period(content)

func _ensure_story_period(text: String) -> String:
	var content: String = text.strip_edges()
	if content.is_empty():
		return ""
	var last_code: int = content.unicode_at(content.length() - 1)
	if [46, 33, 63, 0x3002, 0xFF01, 0xFF1F, 0x2026].has(last_code):
		return content
	return "%s%s" % [content, char(0x3002)]

func _has_meaningful_story_text(text: String) -> bool:
	var content: String = text.strip_edges()
	if content.is_empty():
		return false
	for index in range(content.length()):
		var code: int = content.unicode_at(index)
		if [9, 10, 13, 32, 33, 45, 63, 0x3002, 0xFF01, 0xFF1F, 0xFF0C, 0x3001, 0x2026].has(code):
			continue
		return true
	return false

func _show_turn_report_dialog(turn_index: int, logs: Array[String], title_override: String = "", subtitle_override: String = "", body_override: String = "") -> void:
	turn_report_dialog_active = true
	end_turn_confirm_active = false
	settlement_dialog_active = false
	_play_ui_sound("panel_open")
	_configure_popup_for_turn_report()
	popup_title.text = title_override if not title_override.is_empty() else GameRules.current_term_name(turn_index)
	popup_subtitle.text = subtitle_override if not subtitle_override.is_empty() else ""
	popup_subtitle.visible = false
	popup_body.text = _build_turn_report_body(turn_index, logs, body_override)
	popup_body.scroll_to_line(0)
	_set_popup_body_document_layout()
	_set_popup_art_image("")
	detail_overlay.visible = true

func _close_turn_report_dialog() -> void:
	turn_report_dialog_active = false
	detail_overlay.visible = false
	_play_ui_sound("panel_close")
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
		_show_tutorial_prompt_if_needed(true)

func _confirm_end_turn() -> void:
	end_turn_confirm_active = false
	_play_ui_sound("confirm")
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
	_save_system_game()
	var report_turn_index: int = resolved_turn_index
	var report_title_override: String = ""
	var report_subtitle_override: String = ""
	var report_body_override: String = ""
	var should_show_report: bool = true
	var tutorial_active: bool = tutorial_manager != null and run_state != null and tutorial_manager.is_active(run_state)
	if tutorial_manager != null:
		report_turn_index = tutorial_manager.report_index(run_state, resolved_turn_index)
		report_title_override = tutorial_manager.report_title(run_state)
		report_subtitle_override = tutorial_manager.report_subtitle(run_state, resolved_turn_index)
		report_body_override = tutorial_manager.report_body_override(run_state)
		should_show_report = tutorial_manager.should_show_report(run_state)
	if not tutorial_active:
		var result_presentations: Array = turn_manager.consume_result_presentations()
		if _start_turn_result_sequence(result_presentations, {
			"turn_index": report_turn_index,
			"logs": report_logs.duplicate(true),
			"title": report_title_override,
			"subtitle": report_subtitle_override,
			"body": report_body_override,
			"show_report": should_show_report
		}):
			return
	if should_show_report:
		if _try_show_tutorial_pre_report_dialog(report_turn_index, report_logs, report_title_override, report_subtitle_override, report_body_override):
			return
		_show_turn_report_dialog(report_turn_index, report_logs, report_title_override, report_subtitle_override, report_body_override)
	elif tutorial_manager != null and run_state != null and tutorial_manager.is_active(run_state):
		selected_slot_id = ""
		detail_panel_open = false
		detail_panel.visible = false
		if not _show_tutorial_followup_if_needed():
			_show_tutorial_prompt_if_needed(true)

func _on_end_turn_pressed() -> void:
	if startup_cover_active or _system_menu_visible() or run_state.game_over or detail_overlay.visible or tutorial_dialog_active or turn_result_active:
		return
	if tutorial_manager != null:
		var tutorial_status: Dictionary = tutorial_manager.end_turn_status(run_state, board_manager)
		if not bool(tutorial_status.get("ok", true)):
			_show_transient_tutorial_hint(str(tutorial_status.get("toast_body", tutorial_status.get("body", ""))))
			return
	_show_end_turn_confirm_dialog()

func _on_toggle_log_pressed() -> void:
	log_panel.visible = not log_panel.visible
	toggle_log_button.text = TextDB.get_text("ui.buttons.hide_log") if log_panel.visible else TextDB.get_text("ui.buttons.show_log")
	_play_ui_sound("button")

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
