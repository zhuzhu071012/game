extends Control

const CARD_SCENE := preload("res://scenes/CardView.tscn")
const SLOT_SCENE := preload("res://scenes/SlotView.tscn")
const EVENT_UI_CONTROLLER_SCRIPT := preload("res://scripts/ui/event_ui_controller.gd")
const FLOATING_DETAIL_WINDOW_SCRIPT := preload("res://scripts/ui/floating_detail_window.gd")
const UI_PALETTE := preload("res://scripts/ui/ui_palette.gd")
const SYSTEM_MENU_CONTROLLER_SCRIPT := preload("res://scripts/ui/system_menu_controller.gd")
const AUDIO_OPTIONS_CONTROLLER_SCRIPT := preload("res://scripts/ui/audio_options_controller.gd")
const SAVE_SLOT_CONTROLLER_SCRIPT := preload("res://scripts/ui/save_slot_controller.gd")
const TUTORIAL_UI_CONTROLLER_SCRIPT := preload("res://scripts/ui/tutorial_ui_controller.gd")
const TURN_RESULT_CONTROLLER_SCRIPT := preload("res://scripts/ui/turn_result_controller.gd")
const STORY_EVENT_CONTROLLER_SCRIPT := preload("res://scripts/ui/story_event_controller.gd")
const CARD_METRICS := preload("res://scripts/ui/card_metrics.gd")
const TUTORIAL_MANAGER_SCRIPT := preload("res://scripts/managers/tutorial_manager.gd")
const SAVE_MANAGER_SCRIPT := preload("res://scripts/managers/save_manager.gd")
const STORY_EVENT_MANAGER_SCRIPT := preload("res://scripts/managers/story_event_manager.gd")
const FIRE_MARKER_TEXTURE := preload("res://assets/ui/fire_marker.svg")
const GLOBAL_FONT_PATH := "res://assets/fonts/ZhuqueFangsong-Regular.ttf"
const TITLE_FONT_PATH := "res://assets/fonts/ZhuqueFangsong-Regular.ttf"
const GLOBAL_FONT_RESOURCE := preload("res://assets/fonts/ZhuqueFangsong-Regular.ttf")
const TITLE_FONT_RESOURCE := preload("res://assets/fonts/ZhuqueFangsong-Regular.ttf")
const GLOBAL_FONT_SIZE := 22
const GLOBAL_FONT_SIZE_DELTA := 3
const GLOBAL_LINE_SPACING := 5
const BODY_FONT_SIZE := 26
const UI_SETTINGS_PATH := "user://ui_settings.cfg"
const UI_FONT_SCALE_MIN := 0.85
const UI_FONT_SCALE_MAX := 1.50
const UI_FONT_SCALE_STEP := 0.05
const UI_FONT_SCALE_DEFAULT := 1.30
const DESK_BACKGROUND_PATH := "res://assets/ui/backgrounds/main_menu_map.png"
const COVER_BACKGROUND_PATH := "res://assets/ui/backgrounds/cover_pexels_res_10292825.jpg"
const DESK_BACKGROUND_SHADER := preload("res://assets/ui/shaders/desk_background_blur.gdshader")
const DESK_BACKGROUND_PARALLAX := Vector2(0.032, 0.024)
const POPUP_DETAIL_SIZE := Vector2(860.0, 560.0)
const POPUP_SETTLEMENT_SIZE := Vector2(960.0, 620.0)
const POPUP_CONFIRM_SIZE := Vector2(560.0, 320.0)
const POPUP_TURN_REPORT_SIZE := Vector2(780.0, 520.0)
const POPUP_MESSAGE_SIZE := Vector2(760.0, 420.0)
const STACK_CARD_SEPARATION := -110
const LIST_CARD_WIDTH := CARD_METRICS.COMPACT_CARD_WIDTH
const LIST_CARD_HEIGHT := CARD_METRICS.COMPACT_CARD_HEIGHT
const LIST_CARD_ART_HEIGHT := CARD_METRICS.COMPACT_CARD_ART_HEIGHT
const ACTION_SLOT_WIDTH := CARD_METRICS.ACTION_SLOT_WIDTH
const ACTION_SLOT_HEIGHT := CARD_METRICS.ACTION_SLOT_HEIGHT
const ACTION_SLOT_ART_HEIGHT := CARD_METRICS.ACTION_SLOT_ART_HEIGHT
const DETAIL_PANEL_WINDOW_SIZE := CARD_METRICS.DETAIL_PANEL_WINDOW_SIZE
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
@onready var events_scroll: ScrollContainer = $Root/Layout/Desk/CenterColumn/EventPanel/EventVBox/EventsScroll
@onready var resource_scroll: ScrollContainer = $Root/Layout/Desk/CenterColumn/HandsPanel/HandsVBox/ResourceScroll
@onready var roster_scroll: ScrollContainer = $Root/Layout/Desk/CenterColumn/HandsPanel/HandsVBox/RosterScroll
@onready var events_header: Label = $Root/Layout/Desk/CenterColumn/EventPanel/EventVBox/EventsHeader
@onready var roster_header: Label = $Root/Layout/Desk/CenterColumn/HandsPanel/HandsVBox/RosterLabel
@onready var resource_header: Label = $Root/Layout/Desk/CenterColumn/HandsPanel/HandsVBox/ResourceLabel
@onready var lead_header: Label = $Root/Layout/Desk/RightSidebar/LeadPanel/LeadVBox/LeadHeader
@onready var lead_scroll: ScrollContainer = $Root/Layout/Desk/RightSidebar/LeadPanel/LeadVBox/LeadScroll

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
var event_dialog_layer: Control
var active_detail_windows: Array = []
var detail_window_by_key: Dictionary = {}
var dragging_detail_window: Control = null
var detail_window_drag_offset: Vector2 = Vector2.ZERO
var detail_window_z_counter: int = 40
var detail_window_spawn_index: int = 0
var dragging_detail_panel: bool = false
var detail_panel_drag_offset: Vector2 = Vector2.ZERO
var detail_panel_has_position: bool = false
var detail_panel_size_lock_active: bool = false
var detail_panel_open_token: int = 0
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
var system_menu_background: TextureRect
var audio_options_panel: PanelContainer
var audio_options_title: Label
var audio_options_subtitle: Label
var audio_options_reset_button: Button
var audio_options_close_button: Button
var audio_option_sliders: Dictionary = {}
var audio_option_value_labels: Dictionary = {}
var ui_font_scale: float = UI_FONT_SCALE_DEFAULT
var ui_font_size_slider: HSlider
var ui_font_size_value_label: Label
var tutorial_toast_panel: PanelContainer
var tutorial_toast_label: Label
var tutorial_toast_token: int = 0
var turn_result_overlay: Control
var turn_result_panel: PanelContainer
var turn_result_title: Label
var turn_result_subtitle: Label
var turn_result_dice_panel: PanelContainer
var turn_result_dice_title: Label
var turn_result_dice_row: HBoxContainer
var turn_result_dice_summary: Label
var turn_result_die_labels: Array = []
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
var turn_result_dice_token: int = 0
var pending_turn_result_report_payload: Dictionary = {}
var story_event_manager
var story_event_overlay: Control
var story_event_panel: PanelContainer
var story_event_title: Label
var story_event_subtitle: Label
var story_event_body: RichTextLabel
var story_event_plan_list: VBoxContainer
var story_event_plan_summary: Label
var story_event_character_status: Label
var story_event_character_list: VBoxContainer
var story_event_resource_list: VBoxContainer
var story_event_breakdown: RichTextLabel
var story_event_confirm_button: Button
var story_event_result_panel: PanelContainer
var story_event_result_body: RichTextLabel
var story_event_continue_button: Button
var story_event_active: bool = false
var story_event_selected_plan_id: String = ""
var story_event_selected_character_id: String = ""
var story_event_resource_allocations: Dictionary = {}
var story_event_total_count: int = 0
var story_event_current_index: int = 0
var story_event_result_visible: bool = false
var story_event_result_text: String = ""
var story_event_display_event: Dictionary = {}
var pending_story_event_report_payload: Dictionary = {}
var startup_cover_active: bool = true
var loaded_font_resources: Dictionary = {}
var top_info_attribute_labels: Dictionary = {}
var top_info_attribute_arrow_labels: Dictionary = {}
var story_event_attribute_preview: Dictionary = {}
var system_menu_controller
var audio_options_controller
var save_slot_controller
var tutorial_ui_controller
var turn_result_controller
var story_event_controller

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

func _notify_audio_user_gesture(event: InputEvent) -> void:
	if audio_manager == null:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed:
			audio_manager.notify_user_gesture()
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		if touch_event.pressed:
			audio_manager.notify_user_gesture()
	elif event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			audio_manager.notify_user_gesture()

func _input(event: InputEvent) -> void:
	_notify_audio_user_gesture(event)
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
		if story_event_active:
			get_viewport().set_input_as_handled()
			return
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
	turn_result_controller.build_if_needed()

func _make_turn_result_reward_payload(reward: Dictionary) -> Dictionary:
	return turn_result_controller.make_reward_payload(reward)

func _make_turn_result_card_front(reward: Dictionary) -> Control:
	return turn_result_controller.make_card_front(reward)

func _make_turn_result_card_back(reward: Dictionary) -> PanelContainer:
	return turn_result_controller.make_card_back(reward)

func _all_turn_result_cards_collected() -> bool:
	return turn_result_controller.all_cards_collected()

func _clear_turn_result_cards() -> void:
	turn_result_controller.clear_cards()

func _render_turn_result_cards(rewards: Array) -> void:
	turn_result_controller.render_cards(rewards)

func _find_turn_result_card_index(button: Control) -> int:
	return turn_result_controller.find_card_index(button)

func _set_turn_result_card_revealed(index: int, animated: bool = true, play_sound: bool = true) -> void:
	turn_result_controller.set_card_revealed(index, animated, play_sound)

func _swap_turn_result_card_faces(index: int) -> void:
	turn_result_controller._swap_card_faces(index)

func _collect_all_turn_result_cards(animated: bool = false) -> bool:
	return turn_result_controller.collect_all_cards(animated)

func _turn_result_target_rect_for_reward(reward: Dictionary) -> Rect2:
	return turn_result_controller.target_rect_for_reward(reward)

func _collect_turn_result_cards_to_targets(play_sound: bool = true) -> void:
	await turn_result_controller.collect_cards_to_targets(play_sound)

func _refresh_turn_result_collect_button() -> void:
	turn_result_controller.refresh_collect_button()

func _show_current_turn_result() -> void:
	turn_result_controller.show_current_result()

func _start_turn_result_sequence(results: Array, report_payload: Dictionary) -> bool:
	return turn_result_controller.start_sequence(results, report_payload)

func _finish_turn_result_sequence() -> void:
	turn_result_controller.finish_sequence()

func _build_story_event_ui() -> void:
	story_event_controller.build_if_needed()

func _start_story_event_sequence(report_payload: Dictionary) -> bool:
	return story_event_controller.start_sequence(report_payload)

func _resume_story_event_sequence_after_load() -> void:
	story_event_controller.resume_after_load()

func _prepare_story_event_current_event() -> void:
	story_event_controller.prepare_current_event()

func _finish_story_event_sequence() -> void:
	story_event_controller.finish_sequence()

func _story_event_plan_info_text(event_id: String, plan_id: String) -> String:
	return story_event_controller.plan_info_text(event_id, plan_id)

func _refresh_story_event_ui() -> void:
	story_event_controller.refresh_ui()

func _on_story_event_plan_pressed(plan_id: String) -> void:
	story_event_controller.on_plan_pressed(plan_id)

func _on_story_event_confirm_pressed() -> void:
	story_event_controller.on_confirm_pressed()

func _on_story_event_continue_pressed() -> void:
	story_event_controller.on_continue_pressed()

func _on_turn_result_card_gui_input(event: InputEvent, button: Control) -> void:
	turn_result_controller.handle_input(event, button)

func _on_turn_result_collect_pressed() -> void:
	await turn_result_controller.on_collect_pressed()

func _on_turn_result_continue_pressed() -> void:
	await turn_result_controller.on_continue_pressed()

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
	ThemeDB.fallback_font_size = _scaled_base_size(GLOBAL_FONT_SIZE)
	var global_theme := Theme.new()
	global_theme.default_font = font_resource
	global_theme.default_font_size = _scaled_base_size(GLOBAL_FONT_SIZE)
	theme = global_theme

func _load_ui_settings() -> void:
	ui_font_scale = UI_FONT_SCALE_DEFAULT
	var config := ConfigFile.new()
	if config.load(UI_SETTINGS_PATH) != OK:
		return
	ui_font_scale = clampf(float(config.get_value("ui", "font_scale", UI_FONT_SCALE_DEFAULT)), UI_FONT_SCALE_MIN, UI_FONT_SCALE_MAX)

func _save_ui_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("ui", "font_scale", ui_font_scale)
	config.save(UI_SETTINGS_PATH)

func _scaled_base_size(base: int) -> int:
	return maxi(1, int(round(float(base) * ui_font_scale)))

func _scaled_adjusted_size(base: int) -> int:
	return maxi(1, int(round(float(base + GLOBAL_FONT_SIZE_DELTA) * ui_font_scale)))

func _scaled_line_spacing() -> int:
	return maxi(1, int(round(float(GLOBAL_LINE_SPACING) * ui_font_scale)))

func _current_body_font_size() -> int:
	return maxi(1, int(round(float(BODY_FONT_SIZE) * ui_font_scale)))

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
	for node in [system_menu_title, detail_title, popup_title, event_dialog_title, story_event_title]:
		var control: Control = node as Control
		_apply_title_font_override(control, title_font)
	if event_ui_controller != null:
		event_ui_controller.apply_title_font(title_font)

func _apply_body_font_override(label: RichTextLabel) -> void:
	if label == null:
		return
	var body_font_size: int = _current_body_font_size()
	var line_spacing: int = _scaled_line_spacing()
	label.add_theme_font_size_override("normal_font_size", body_font_size)
	label.set_meta("body_font_managed", true)
	label.set_meta("normal_font_size_base", BODY_FONT_SIZE)
	label.set_meta("normal_font_size_last_applied", body_font_size)
	label.add_theme_constant_override("line_separation", line_spacing)
	label.add_theme_constant_override("line_spacing", line_spacing)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _apply_body_fonts() -> void:
	for label in [detail_body, event_dialog_body, popup_body, turn_result_body, story_event_body, story_event_breakdown, story_event_result_body]:
		_apply_body_font_override(label as RichTextLabel)
	if event_ui_controller != null:
		event_ui_controller.apply_body_font_size(_current_body_font_size(), _scaled_line_spacing())

func _apply_font_preferences() -> void:
	_apply_global_font()
	_apply_title_fonts()
	_apply_body_fonts()
	for window_variant in active_detail_windows.duplicate():
		if not is_instance_valid(window_variant):
			continue
		window_variant.apply_title_font(_load_font_resource(TITLE_FONT_PATH))
		window_variant.apply_body_font_size(_current_body_font_size(), _scaled_line_spacing())
	_apply_global_text_adjustments(self)
	if audio_options_overlay != null and audio_options_overlay.visible:
		_refresh_audio_options_overlay()

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

func _format_event_description_body(body: String) -> String:
	var normalized: String = body.replace("\r\n", "\n").replace("\r", "\n").strip_edges()
	while normalized.find("\n\n\n") >= 0:
		normalized = normalized.replace("\n\n\n", "\n\n")
	if normalized.is_empty():
		return ""
	var paragraphs: Array[String] = []
	for paragraph_variant in normalized.split("\n\n"):
		var paragraph: String = str(paragraph_variant).strip_edges()
		if paragraph.is_empty():
			continue
		if not paragraph.begins_with("　　"):
			paragraph = "　　" + paragraph
		paragraphs.append(paragraph)
	return "\n\n".join(paragraphs)

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
	if control.has_theme_font_size_override("font_size"):
		var current_font_size: int = control.get_theme_font_size("font_size")
		var last_font_size: int = int(control.get_meta("font_size_last_applied", -1))
		var base_font_size: int = int(control.get_meta("font_size_base", current_font_size))
		if base_font_size <= 0 or (last_font_size != -1 and current_font_size != last_font_size):
			base_font_size = current_font_size
			control.set_meta("font_size_base", base_font_size)
		elif not control.has_meta("font_size_base"):
			control.set_meta("font_size_base", base_font_size)
		var scaled_font_size: int = _scaled_adjusted_size(base_font_size)
		if current_font_size != scaled_font_size:
			control.add_theme_font_size_override("font_size", scaled_font_size)
		control.set_meta("font_size_last_applied", scaled_font_size)
	if control.has_theme_font_size_override("normal_font_size") and not bool(control.get_meta("body_font_managed", false)):
		var current_normal_font_size: int = control.get_theme_font_size("normal_font_size")
		var last_normal_font_size: int = int(control.get_meta("normal_font_size_last_applied", -1))
		var base_normal_font_size: int = int(control.get_meta("normal_font_size_base", current_normal_font_size))
		if base_normal_font_size <= 0 or (last_normal_font_size != -1 and current_normal_font_size != last_normal_font_size):
			base_normal_font_size = current_normal_font_size
			control.set_meta("normal_font_size_base", base_normal_font_size)
		elif not control.has_meta("normal_font_size_base"):
			control.set_meta("normal_font_size_base", base_normal_font_size)
		var scaled_normal_font_size: int = _scaled_adjusted_size(base_normal_font_size)
		if current_normal_font_size != scaled_normal_font_size:
			control.add_theme_font_size_override("normal_font_size", scaled_normal_font_size)
		control.set_meta("normal_font_size_last_applied", scaled_normal_font_size)
	var line_spacing: int = _scaled_line_spacing()
	if control is RichTextLabel:
		control.add_theme_constant_override("line_separation", line_spacing)
		control.add_theme_constant_override("line_spacing", line_spacing)
	elif control is Label or control is Button:
		control.add_theme_constant_override("line_spacing", line_spacing)

func _ready() -> void:
	randomize()
	_load_ui_settings()
	_apply_global_font()
	TextDB.reload_texts()
	tutorial_manager = TUTORIAL_MANAGER_SCRIPT.new()
	save_manager = SAVE_MANAGER_SCRIPT.new()
	story_event_manager = STORY_EVENT_MANAGER_SCRIPT.new()
	system_menu_controller = SYSTEM_MENU_CONTROLLER_SCRIPT.new()
	audio_options_controller = AUDIO_OPTIONS_CONTROLLER_SCRIPT.new()
	save_slot_controller = SAVE_SLOT_CONTROLLER_SCRIPT.new()
	tutorial_ui_controller = TUTORIAL_UI_CONTROLLER_SCRIPT.new()
	turn_result_controller = TURN_RESULT_CONTROLLER_SCRIPT.new()
	story_event_controller = STORY_EVENT_CONTROLLER_SCRIPT.new()
	add_child(system_menu_controller)
	add_child(audio_options_controller)
	add_child(save_slot_controller)
	add_child(tutorial_ui_controller)
	add_child(turn_result_controller)
	add_child(story_event_controller)
	system_menu_controller.setup(self)
	audio_options_controller.setup(self)
	save_slot_controller.setup(self)
	tutorial_ui_controller.setup(self)
	turn_result_controller.setup(self)
	story_event_controller.setup(self)
	characters = GameData.create_characters()
	resources = GameData.create_resources()
	risks = GameData.create_risks()
	events = GameData.create_events()
	run_state = GameData.create_run_state()
	event_manager.setup(events)
	story_event_manager.setup()
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
	detail_overlay.gui_input.connect(_on_detail_overlay_gui_input)
	detail_overlay.visible = false
	detail_overlay.z_as_relative = false
	detail_overlay.z_index = 4096
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
	_build_event_dialog_layer()
	if event_dialog != null:
		event_dialog.visible = false
		event_dialog.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		Callable(self, "_event_body"),
		Callable(self, "_event_title"),
		Callable(self, "_event_dialog_hint"),
		event_dialog_layer
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
	slot_column.custom_minimum_size = Vector2(ACTION_SLOT_WIDTH, 0.0)
	slot_column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_apply_static_texts()
	_apply_visual_styles()
	_build_desk_background_ui()
	_prepare_detail_panel_window()
	_build_tutorial_dialog_ui()
	_build_system_menu_ui()
	_build_tutorial_toast_ui()
	_build_turn_result_ui()
	_build_story_event_ui()
	_apply_font_preferences()
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
	shade.color = UI_PALETTE.alpha(UI_PALETTE.INK, 0.42)
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
	system_menu_controller.build_if_needed()
	save_slot_controller.build_if_needed()
	audio_options_controller.build_if_needed()

func _build_tutorial_toast_ui() -> void:
	tutorial_ui_controller.build_toast_if_needed()

func _show_transient_tutorial_hint(message: String, duration: float = 2.4) -> void:
	tutorial_ui_controller.show_toast(message, duration)

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

func _build_accent_button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
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

func _apply_accent_button_theme(button: Button) -> void:
	if button == null:
		return
	var normal_bg: Color = UI_PALETTE.alpha(UI_PALETTE.SLATE.darkened(0.10), 0.88)
	var hover_bg: Color = UI_PALETTE.alpha(UI_PALETTE.RUST, 0.84)
	var pressed_bg: Color = UI_PALETTE.alpha(UI_PALETTE.RUST.darkened(0.10), 0.90)
	var disabled_bg: Color = UI_PALETTE.alpha(UI_PALETTE.SLATE.darkened(0.16), 0.38)
	var normal_border: Color = UI_PALETTE.alpha(UI_PALETTE.SLATE.lightened(0.04), 0.82)
	var active_border: Color = UI_PALETTE.alpha(UI_PALETTE.VERMILION, 0.98)
	var disabled_border: Color = UI_PALETTE.alpha(UI_PALETTE.SLATE.darkened(0.24), 0.42)
	button.add_theme_stylebox_override("normal", _build_accent_button_style(normal_bg, normal_border))
	button.add_theme_stylebox_override("hover", _build_accent_button_style(hover_bg, active_border))
	button.add_theme_stylebox_override("pressed", _build_accent_button_style(pressed_bg, active_border))
	button.add_theme_stylebox_override("focus", _build_accent_button_style(hover_bg, active_border))
	button.add_theme_stylebox_override("disabled", _build_accent_button_style(disabled_bg, disabled_border))
	button.add_theme_color_override("font_color", UI_PALETTE.alpha(UI_PALETTE.PAPER, 0.96))
	button.add_theme_color_override("font_hover_color", UI_PALETTE.alpha(UI_PALETTE.PAPER, 1.0))
	button.add_theme_color_override("font_pressed_color", UI_PALETTE.alpha(UI_PALETTE.PAPER, 1.0))
	button.add_theme_color_override("font_focus_color", UI_PALETTE.alpha(UI_PALETTE.PAPER, 1.0))
	button.add_theme_color_override("font_disabled_color", UI_PALETTE.alpha(UI_PALETTE.PAPER, 0.42))
	if TITLE_FONT_RESOURCE != null:
		button.add_theme_font_override("font", TITLE_FONT_RESOURCE)

func _show_system_menu(visible: bool) -> void:
	system_menu_controller.show_menu(visible)

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
	audio_options_controller.build_if_needed()

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
	ui_font_size_value_label = Label.new()
	ui_font_size_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui_font_size_value_label.custom_minimum_size = Vector2(60.0, 0.0)
	header.add_child(ui_font_size_value_label)
	ui_font_size_slider = HSlider.new()
	ui_font_size_slider.min_value = UI_FONT_SCALE_MIN * 100.0
	ui_font_size_slider.max_value = UI_FONT_SCALE_MAX * 100.0
	ui_font_size_slider.step = UI_FONT_SCALE_STEP * 100.0
	ui_font_size_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui_font_size_slider.value_changed.connect(_on_font_size_slider_value_changed)
	ui_font_size_slider.drag_ended.connect(_on_font_size_slider_drag_ended)
	row.add_child(ui_font_size_slider)

func _open_audio_options_overlay() -> void:
	audio_options_controller.open()

func _close_audio_options_overlay(play_sound: bool = true) -> void:
	audio_options_controller.close(play_sound)

func _refresh_audio_options_overlay() -> void:
	audio_options_controller.refresh()

func _update_audio_option_value_label(channel_id: String) -> void:
	audio_options_controller._update_audio_option_value_label(channel_id)

func _update_font_size_value_label() -> void:
	audio_options_controller._update_font_size_value_label()

func _on_audio_slider_value_changed(value: float, channel_id: String) -> void:
	audio_options_controller._on_audio_slider_value_changed(value, channel_id)

func _on_audio_slider_drag_ended(changed: bool, channel_id: String) -> void:
	if changed and channel_id in ["master", "sfx"]:
		_play_ui_sound("button")

func _on_font_size_slider_value_changed(value: float) -> void:
	var next_scale: float = clampf(value / 100.0, UI_FONT_SCALE_MIN, UI_FONT_SCALE_MAX)
	if absf(next_scale - ui_font_scale) <= 0.001:
		_update_font_size_value_label()
		return
	ui_font_scale = next_scale
	_save_ui_settings()
	_apply_font_preferences()

func _on_font_size_slider_drag_ended(changed: bool) -> void:
	if changed:
		_play_ui_sound("button")

func _on_audio_options_reset_pressed() -> void:
	audio_options_controller._on_audio_options_reset_pressed()

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
	save_slot_controller.build_if_needed()

func _open_save_slot_overlay(mode: String) -> void:
	save_slot_controller.open(mode)

func _close_save_slot_overlay() -> void:
	save_slot_controller.close()

func _refresh_save_slot_overlay() -> void:
	save_slot_controller.refresh()

func _save_slot_button_text(slot_index: int, has_save: bool, metadata: Dictionary) -> String:
	return save_slot_controller.save_slot_button_text(slot_index, has_save, metadata)

func _on_save_slot_button_pressed(local_index: int) -> void:
	save_slot_controller._on_save_slot_button_pressed(local_index)
	return
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
	save_slot_controller._on_save_slot_prev_pressed()
	return
	save_slot_page -= 1
	_refresh_save_slot_overlay()

func _on_save_slot_next_pressed() -> void:
	save_slot_controller._on_save_slot_next_pressed()
	return
	save_slot_page += 1
	_refresh_save_slot_overlay()

func _apply_loaded_snapshot(snapshot: Dictionary) -> void:
	_close_all_detail_views()
	run_state = snapshot.get("run_state", GameData.create_run_state()) as RunState
	if tutorial_manager != null and run_state != null:
		tutorial_manager.repair_loaded_state(run_state)
	if event_manager != null and run_state != null:
		event_manager.prune_disabled_events(run_state)
	if story_event_manager != null and run_state != null:
		story_event_manager.sync_active_board_events(run_state, events)
	board_manager.restore_state(run_state.active_event_ids, snapshot.get("board", {}) as Dictionary)
	startup_cover_active = false
	_refresh_board()
	if story_event_manager != null and story_event_manager.has_pending_events(run_state):
		call_deferred("_resume_story_event_sequence_after_load")

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
	fire_fill.color = UI_PALETTE.alpha(UI_PALETTE.VERMILION, 0.88)
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
	detail_panel.set("layout_mode", 1)
	detail_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	detail_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	detail_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	detail_panel.anchor_right = 0.0
	detail_panel.anchor_bottom = 0.0
	detail_panel.offset_left = 0.0
	detail_panel.offset_top = 0.0
	detail_panel.offset_right = DETAIL_PANEL_WINDOW_SIZE.x
	detail_panel.offset_bottom = DETAIL_PANEL_WINDOW_SIZE.y
	detail_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if not detail_panel.resized.is_connected(_on_detail_panel_resized):
		detail_panel.resized.connect(_on_detail_panel_resized)
	detail_panel.z_as_relative = false
	detail_panel.z_index = 18
	detail_panel.custom_minimum_size = DETAIL_PANEL_WINDOW_SIZE
	detail_panel.size = DETAIL_PANEL_WINDOW_SIZE
	detail_panel.clip_contents = true
	detail_header.mouse_filter = Control.MOUSE_FILTER_STOP
	detail_panel.visible = false
	_prepare_detail_assignment_scroll()

func _prepare_event_dialog_window() -> void:
	if event_dialog == null:
		return
	if event_dialog_layer == null:
		_build_event_dialog_layer()
	var initial_position: Vector2 = event_dialog.position
	var initial_size: Vector2 = event_dialog.size if event_dialog.size != Vector2.ZERO else event_dialog.custom_minimum_size
	var current_parent: Node = event_dialog.get_parent()
	if current_parent != event_dialog_layer:
		if current_parent != null:
			current_parent.remove_child(event_dialog)
		event_dialog_layer.add_child(event_dialog)
	event_dialog.set("layout_mode", 1)
	event_dialog.top_level = false
	event_dialog.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	event_dialog.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	event_dialog.set_anchors_preset(Control.PRESET_TOP_LEFT)
	event_dialog.anchor_right = 0.0
	event_dialog.anchor_bottom = 0.0
	event_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	event_dialog.z_as_relative = true
	event_dialog.z_index = 0
	event_dialog.position = initial_position
	event_dialog.size = initial_size
	event_dialog_header.mouse_filter = Control.MOUSE_FILTER_STOP

func _build_event_dialog_layer() -> void:
	if event_dialog_layer != null:
		return
	event_dialog_layer = Control.new()
	event_dialog_layer.name = "EventDialogLayer"
	event_dialog_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	event_dialog_layer.anchor_right = 1.0
	event_dialog_layer.anchor_bottom = 1.0
	event_dialog_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	event_dialog_layer.z_as_relative = false
	event_dialog_layer.z_index = 20
	add_child(event_dialog_layer)

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
	detail_panel_size_lock_active = true
	detail_panel.custom_minimum_size = DETAIL_PANEL_WINDOW_SIZE
	detail_panel.offset_right = detail_panel.offset_left + DETAIL_PANEL_WINDOW_SIZE.x
	detail_panel.offset_bottom = detail_panel.offset_top + DETAIL_PANEL_WINDOW_SIZE.y
	detail_panel.size = DETAIL_PANEL_WINDOW_SIZE
	detail_panel.update_minimum_size()
	detail_panel_size_lock_active = false
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

func _on_detail_panel_resized() -> void:
	if detail_panel == null or detail_panel_size_lock_active:
		return
	if absf(detail_panel.size.x - DETAIL_PANEL_WINDOW_SIZE.x) <= 0.5 and absf(detail_panel.size.y - DETAIL_PANEL_WINDOW_SIZE.y) <= 0.5:
		return
	call_deferred("_restore_detail_panel_window_size")

func _restore_detail_panel_window_size() -> void:
	_apply_detail_panel_window_size()
	if detail_panel != null and detail_panel.visible:
		_ensure_detail_panel_position()

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
	if event_ui_controller != null:
		event_ui_controller.refresh_static_texts()
	events_header.text = TextDB.get_text("ui.headers.events")
	roster_header.text = TextDB.get_text("ui.headers.roster")
	resource_header.text = TextDB.get_text("ui.headers.resources")
	lead_header.text = TextDB.get_text("ui.headers.leads")
	_apply_vertical_section_labels()

func _vertical_section_text(text: String) -> String:
	var normalized: String = text.strip_edges()
	if normalized.is_empty():
		return ""
	var chars: PackedStringArray = []
	for index in range(normalized.length()):
		chars.append(normalized.substr(index, 1))
	return "\n".join(chars)

func _apply_vertical_section_labels() -> void:
	_ensure_section_label_row(events_header, events_scroll)
	_ensure_section_label_row(roster_header, roster_scroll)
	_ensure_section_label_row(resource_header, resource_scroll)
	_ensure_section_label_row(lead_header, lead_scroll)

func _ensure_section_label_row(header: Label, content: Control) -> void:
	if header == null or content == null:
		return
	var current_parent: Node = header.get_parent()
	if current_parent == null:
		return
	if current_parent is HBoxContainer and bool((current_parent as HBoxContainer).get_meta("section_label_row", false)):
		_style_vertical_section_header(header)
		return
	var parent_box := current_parent as Container
	if parent_box == null or content.get_parent() != parent_box:
		return
	var insert_index: int = header.get_index()
	parent_box.remove_child(header)
	parent_box.remove_child(content)
	var row := HBoxContainer.new()
	row.name = "%sRow" % header.name
	row.set_meta("section_label_row", true)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = content.size_flags_vertical
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 6)
	parent_box.add_child(row)
	parent_box.move_child(row, insert_index)
	row.add_child(header)
	row.add_child(content)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_vertical_section_header(header)

func _style_vertical_section_header(header: Label) -> void:
	if header == null:
		return
	header.text = _vertical_section_text(header.text)
	header.autowrap_mode = TextServer.AUTOWRAP_OFF
	header.clip_text = false
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	header.size_flags_vertical = Control.SIZE_EXPAND_FILL
	header.custom_minimum_size = Vector2(22.0, 0.0)

func _apply_visual_styles() -> void:
	_apply_accent_button_theme(end_turn_button)
	_apply_accent_button_theme(toggle_log_button)
	_apply_accent_button_theme(popup_close)
	if popup_cancel != null:
		_apply_accent_button_theme(popup_cancel)
	var drawer_style: StyleBoxFlat = StyleBoxFlat.new()
	drawer_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.INK, 0.97)
	drawer_style.border_width_left = 2
	drawer_style.border_width_top = 2
	drawer_style.border_width_right = 2
	drawer_style.border_width_bottom = 2
	drawer_style.border_color = UI_PALETTE.alpha(UI_PALETTE.SLATE, 0.95)
	drawer_style.corner_radius_top_left = 8
	drawer_style.corner_radius_top_right = 8
	drawer_style.corner_radius_bottom_left = 8
	drawer_style.corner_radius_bottom_right = 8
	drawer_style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	drawer_style.shadow_size = 18
	detail_panel.add_theme_stylebox_override("panel", drawer_style)

	var icon_frame_style: StyleBoxFlat = StyleBoxFlat.new()
	icon_frame_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.SAGE.darkened(0.32), 1.0)
	icon_frame_style.border_width_left = 2
	icon_frame_style.border_width_top = 2
	icon_frame_style.border_width_right = 2
	icon_frame_style.border_width_bottom = 2
	icon_frame_style.border_color = UI_PALETTE.alpha(UI_PALETTE.SAGE.lightened(0.18), 0.90)
	icon_frame_style.corner_radius_top_left = 6
	icon_frame_style.corner_radius_top_right = 6
	icon_frame_style.corner_radius_bottom_left = 6
	icon_frame_style.corner_radius_bottom_right = 6
	icon_frame_style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	icon_frame_style.shadow_size = 8
	($Root/Layout/Desk/LeftSidebar/DetailPanel/DetailMargin/DetailVBox/DetailHeader/DetailIconFrame as PanelContainer).add_theme_stylebox_override("panel", icon_frame_style)

	var body_style: StyleBoxFlat = StyleBoxFlat.new()
	body_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.SLATE.darkened(0.22), 0.92)
	body_style.border_width_left = 1
	body_style.border_width_top = 1
	body_style.border_width_right = 1
	body_style.border_width_bottom = 1
	body_style.border_color = UI_PALETTE.alpha(UI_PALETTE.SLATE.lightened(0.08), 0.95)
	body_style.corner_radius_top_left = 8
	body_style.corner_radius_top_right = 8
	body_style.corner_radius_bottom_left = 8
	body_style.corner_radius_bottom_right = 8
	detail_body.add_theme_stylebox_override("normal", body_style)

	var event_dialog_style: StyleBoxFlat = StyleBoxFlat.new()
	event_dialog_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.INK, 0.97)
	event_dialog_style.border_width_left = 2
	event_dialog_style.border_width_top = 2
	event_dialog_style.border_width_right = 2
	event_dialog_style.border_width_bottom = 2
	event_dialog_style.border_color = UI_PALETTE.alpha(UI_PALETTE.SLATE.lightened(0.10), 0.95)
	event_dialog_style.corner_radius_top_left = 10
	event_dialog_style.corner_radius_top_right = 10
	event_dialog_style.corner_radius_bottom_left = 10
	event_dialog_style.corner_radius_bottom_right = 10
	event_dialog_style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	event_dialog_style.shadow_size = 16
	event_dialog.add_theme_stylebox_override("panel", event_dialog_style)

	var event_header_style: StyleBoxFlat = StyleBoxFlat.new()
	event_header_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.RUST, 0.98)
	event_header_style.border_width_left = 1
	event_header_style.border_width_top = 1
	event_header_style.border_width_right = 1
	event_header_style.border_width_bottom = 1
	event_header_style.border_color = UI_PALETTE.alpha(UI_PALETTE.VERMILION, 0.95)
	event_header_style.corner_radius_top_left = 8
	event_header_style.corner_radius_top_right = 8
	event_header_style.corner_radius_bottom_left = 8
	event_header_style.corner_radius_bottom_right = 8
	event_dialog_header.add_theme_stylebox_override("panel", event_header_style)
	var event_body_panel_style: StyleBoxFlat = body_style.duplicate() as StyleBoxFlat
	event_body_panel_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.SLATE.darkened(0.18), 0.94)
	event_dialog_body_panel.add_theme_stylebox_override("panel", event_body_panel_style)
	event_dialog_body.add_theme_stylebox_override("normal", body_style)
	var event_slot_panel_style: StyleBoxFlat = StyleBoxFlat.new()
	event_slot_panel_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.INK.darkened(0.08), 0.96)
	event_slot_panel_style.border_width_left = 1
	event_slot_panel_style.border_width_top = 1
	event_slot_panel_style.border_width_right = 1
	event_slot_panel_style.border_width_bottom = 1
	event_slot_panel_style.border_color = UI_PALETTE.alpha(UI_PALETTE.SLATE, 0.96)
	event_slot_panel_style.corner_radius_top_left = 8
	event_slot_panel_style.corner_radius_top_right = 8
	event_slot_panel_style.corner_radius_bottom_left = 8
	event_slot_panel_style.corner_radius_bottom_right = 8
	event_slot_panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	event_slot_panel_style.shadow_size = 8
	event_dialog_slot_panel.add_theme_stylebox_override("panel", event_slot_panel_style)

	var top_bar_style: StyleBoxFlat = StyleBoxFlat.new()
	top_bar_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.INK, 0.96)
	top_bar_style.border_width_left = 1
	top_bar_style.border_width_top = 1
	top_bar_style.border_width_right = 1
	top_bar_style.border_width_bottom = 1
	top_bar_style.border_color = UI_PALETTE.alpha(UI_PALETTE.SLATE, 0.96)
	top_bar_style.corner_radius_top_left = 8
	top_bar_style.corner_radius_top_right = 8
	top_bar_style.corner_radius_bottom_left = 8
	top_bar_style.corner_radius_bottom_right = 8
	top_bar_style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
	top_bar_style.shadow_size = 8
	top_bar_panel.add_theme_stylebox_override("panel", top_bar_style)

	if fire_panel != null:
		var fire_panel_style: StyleBoxFlat = StyleBoxFlat.new()
		fire_panel_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.RUST.darkened(0.25), 0.94)
		fire_panel_style.border_width_left = 1
		fire_panel_style.border_width_top = 1
		fire_panel_style.border_width_right = 1
		fire_panel_style.border_width_bottom = 1
		fire_panel_style.border_color = UI_PALETTE.alpha(UI_PALETTE.VERMILION, 0.92)
		fire_panel_style.corner_radius_top_left = 8
		fire_panel_style.corner_radius_top_right = 8
		fire_panel_style.corner_radius_bottom_left = 8
		fire_panel_style.corner_radius_bottom_right = 8
		fire_panel.add_theme_stylebox_override("panel", fire_panel_style)
		var rail: PanelContainer = fire_track.get_node_or_null("Rail") as PanelContainer
		if rail != null:
			var rail_style: StyleBoxFlat = StyleBoxFlat.new()
			rail_style.bg_color = UI_PALETTE.alpha(UI_PALETTE.INK, 0.96)
			rail_style.border_width_left = 1
			rail_style.border_width_top = 1
			rail_style.border_width_right = 1
			rail_style.border_width_bottom = 1
			rail_style.border_color = UI_PALETTE.alpha(UI_PALETTE.SLATE, 0.95)
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
	right_sidebar.visible = not minimal
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
		event_panel.custom_minimum_size = Vector2(0.0, LIST_CARD_HEIGHT + 22.0)
	toggle_log_button.visible = not minimal
	roster_scroll.custom_minimum_size = Vector2(0.0, LIST_CARD_HEIGHT + 10.0 if minimal else LIST_CARD_HEIGHT + 6.0)
	resource_scroll.custom_minimum_size = Vector2(0.0, 0.0 if minimal else LIST_CARD_HEIGHT + 6.0)
	lead_scroll.custom_minimum_size = Vector2(0.0, 0.0 if minimal else LIST_CARD_HEIGHT + 6.0)

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
	_apply_accent_button_theme(popup_cancel)
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
	top_info_attribute_labels.clear()
	top_info_attribute_arrow_labels.clear()
	var shown_turn: int = run_state.turn_index
	var total_turns: int = GameRules.settlement_turn() if GameRules.is_settlement_turn(shown_turn) else GameRules.playable_turns()
	var term_name: String = GameRules.current_term_name(shown_turn)
	var camp: Dictionary = GameRules.current_camp_attributes(run_state, characters)
	var term_label: Label = Label.new()
	term_label.text = TextDB.format_text("ui.status.term", [term_name, shown_turn, total_turns])
	top_info.add_child(term_label)
	for attribute_id in ["supplies", "forces", "cohesion", "strategy"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var label: Label = Label.new()
		label.text = _camp_status_text(attribute_id, int(camp.get(attribute_id, 0)))
		row.add_child(label)
		var arrow: Label = Label.new()
		arrow.visible = false
		arrow.add_theme_font_size_override("font_size", 20)
		row.add_child(arrow)
		top_info.add_child(row)
		top_info_attribute_labels[attribute_id] = label
		top_info_attribute_arrow_labels[attribute_id] = arrow
	_apply_story_event_attribute_preview()
	_refresh_fire_progress()

func _camp_status_text(attribute_id: String, value: int) -> String:
	var label_text: String = TextDB.get_text("system.camp_attributes.%s" % attribute_id, attribute_id)
	return "%s %d" % [label_text, value]

func _set_story_event_attribute_preview(preview: Dictionary) -> void:
	story_event_attribute_preview = preview.duplicate(true)
	_apply_story_event_attribute_preview()

func _clear_story_event_attribute_preview() -> void:
	story_event_attribute_preview.clear()
	_apply_story_event_attribute_preview()

func _apply_story_event_attribute_preview() -> void:
	for attribute_id_variant in top_info_attribute_labels.keys():
		var attribute_id: String = str(attribute_id_variant)
		var label: Label = top_info_attribute_labels.get(attribute_id) as Label
		var arrow: Label = top_info_attribute_arrow_labels.get(attribute_id) as Label
		if label == null:
			continue
		label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		label.scale = Vector2.ONE
		label.remove_theme_color_override("font_color")
		label.remove_theme_color_override("font_outline_color")
		label.remove_theme_constant_override("outline_size")
		if arrow != null:
			arrow.visible = false
			arrow.text = ""
			arrow.modulate = Color(1.0, 1.0, 1.0, 1.0)
			arrow.remove_theme_color_override("font_color")
			arrow.remove_theme_color_override("font_outline_color")
			arrow.remove_theme_constant_override("outline_size")
		if not story_event_attribute_preview.has(attribute_id):
			continue
		var direction: int = int(story_event_attribute_preview.get(attribute_id, 0))
		var accent: Color = UI_PALETTE.SAGE.lightened(0.24) if direction >= 0 else UI_PALETTE.VERMILION.lightened(0.16)
		label.modulate = accent
		label.add_theme_color_override("font_color", accent)
		label.add_theme_color_override("font_outline_color", accent.darkened(0.7))
		label.add_theme_constant_override("outline_size", 8)
		if arrow != null and direction != 0:
			arrow.visible = true
			arrow.text = "↑" if direction > 0 else "↓"
			arrow.modulate = accent
			arrow.add_theme_color_override("font_color", accent)
			arrow.add_theme_color_override("font_outline_color", accent.darkened(0.7))
			arrow.add_theme_constant_override("outline_size", 8)

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
	_focus_popup_overlay()
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
	_focus_popup_overlay()
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
	tutorial_ui_controller.build_dialog_if_needed()

func _show_tutorial_followup_if_needed() -> bool:
	return tutorial_ui_controller.show_tutorial_followup_if_needed()

func _try_show_tutorial_pre_report_dialog(report_turn_index: int, report_logs: Array[String], title_override: String, subtitle_override: String, body_override: String) -> bool:
	return tutorial_ui_controller.try_show_pre_report_dialog(report_turn_index, report_logs, title_override, subtitle_override, body_override)

func _start_tutorial_dialog(dialogue: Dictionary) -> void:
	tutorial_ui_controller.start_dialog(dialogue)

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
	tutorial_ui_controller.advance_dialog()

func _finish_tutorial_dialog() -> void:
	tutorial_ui_controller.finish_dialog()

func _on_tutorial_dialog_gui_input(event: InputEvent) -> void:
	tutorial_ui_controller._on_tutorial_dialog_gui_input(event)

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
	popup_effect_top_cover.color = UI_PALETTE.alpha(UI_PALETTE.RUST.darkened(0.28), 0.98)
	popup_effect_top_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_effect_overlay.add_child(popup_effect_top_cover)
	popup_effect_bottom_cover = ColorRect.new()
	popup_effect_bottom_cover.color = UI_PALETTE.alpha(UI_PALETTE.RUST.darkened(0.28), 0.98)
	popup_effect_bottom_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_effect_overlay.add_child(popup_effect_bottom_cover)
	popup_effect_seam = ColorRect.new()
	popup_effect_seam.color = UI_PALETTE.alpha(UI_PALETTE.PAPER, 0.88)
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
		"card_width": ACTION_SLOT_WIDTH,
		"art_height": ACTION_SLOT_ART_HEIGHT,
		"current_cards": board_manager.get_slot_cards(slot_id),
		"collapsed_height": ACTION_SLOT_HEIGHT,
		"expanded_height": ACTION_SLOT_HEIGHT
	}

func _slot_palette(slot_id: String) -> Dictionary:
	match slot_id:
		"governance":
			return {"panel": UI_PALETTE.INK, "art": UI_PALETTE.SLATE.darkened(0.12)}
		"research":
			return {"panel": UI_PALETTE.SLATE.darkened(0.16), "art": UI_PALETTE.SAGE.darkened(0.28)}
		"recruit":
			return {"panel": UI_PALETTE.INK.darkened(0.08), "art": UI_PALETTE.SLATE.darkened(0.18)}
		"audience":
			return {"panel": UI_PALETTE.RUST.darkened(0.32), "art": UI_PALETTE.VERMILION.darkened(0.36)}
		"rest":
			return {"panel": UI_PALETTE.SAGE.darkened(0.34), "art": UI_PALETTE.SAGE.darkened(0.24)}
		_:
			return {"panel": UI_PALETTE.INK, "art": UI_PALETTE.SLATE.darkened(0.12)}

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
	var has_visible_cards: bool = false
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
		has_visible_cards = true
	if has_visible_cards:
		return
	var placeholder := Control.new()
	placeholder.name = "LeadPlaceholder"
	placeholder.custom_minimum_size = Vector2(LIST_CARD_WIDTH, LIST_CARD_HEIGHT)
	placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lead_row.add_child(placeholder)

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
	window.apply_body_font_size(_current_body_font_size(), _scaled_line_spacing())
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
			"title": _event_title(data_event),
			"subtitle": _event_category_text(data_event.category),
			"body": _event_body(data_event),
			"image_path": data_event.art_path,
			"body_horizontal_alignment": HORIZONTAL_ALIGNMENT_LEFT,
			"body_vertical_alignment": VERTICAL_ALIGNMENT_TOP
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
	if event_ui_controller == null:
		return
	var dialog: Control = event_ui_controller.get_dialog_control()
	if dialog == null:
		return
	if event_dialog_layer != null:
		_raise_window_layer(event_dialog_layer)
		if dialog.get_parent() == event_dialog_layer:
			event_dialog_layer.move_child(dialog, event_dialog_layer.get_child_count() - 1)

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
	var footnote: String = _slot_detail_footnote(slot_id, assigned_cards)
	_detail_setup(
		TextDB.get_text("system.slots.%s.title" % slot_id),
		TextDB.get_text("ui.detail_panel.slot_subtitle"),
		body,
		_slot_art_path(slot_id),
		assigned_cards,
		footnote,
		focus_window,
		suppress_focus
	)

func _slot_detail_footnote(slot_id: String, assigned_cards: Array) -> String:
	var preview_text: String = _slot_roll_preview_text(slot_id, assigned_cards)
	if not preview_text.is_empty():
		return preview_text
	return TextDB.get_text("ui.detail_panel.slot_hint")

func _slot_roll_preview_text(slot_id: String, assigned_cards: Array) -> String:
	if turn_manager == null or run_state == null:
		return ""
	return _preview_dictionary_to_text(turn_manager.preview_slot_dice(run_state, slot_id, assigned_cards, characters))

func _event_dialog_hint(data_event: EventData) -> String:
	if data_event == null or story_event_manager == null or run_state == null or board_manager == null:
		return ""
	return _preview_dictionary_to_text(story_event_manager.preview_board_event_dice(run_state, data_event.id, board_manager.get_event_cards(data_event.id), characters, resources))

func _preview_dictionary_to_text(preview: Dictionary) -> String:
	if preview.is_empty():
		return ""
	if bool(preview.get("no_roll", false)):
		return TextDB.get_text("ui.detail_panel.roll_preview_no_roll")
	if preview.has("needs_resource_name"):
		return TextDB.format_text("ui.detail_panel.roll_preview_need_resource", [str(preview.get("needs_resource_name", ""))])
	var dice_count: int = int(preview.get("dice_count", 2))
	var modifier: float = float(preview.get("modifier", 0.0))
	var modifier_text: String = _format_signed_score_value(modifier)
	if bool(preview.get("no_fixed_dc", false)):
		return TextDB.format_text("ui.detail_panel.roll_preview_no_fixed_dc", [dice_count, modifier_text])
	var dc: float = float(preview.get("dc", 0.0))
	if dc <= 0.0:
		return ""
	var lines: Array[String] = []
	lines.append(_format_roll_requirement_text(dice_count, modifier_text, int(ceil(dc - modifier)), str(preview.get("pass_label", TextDB.get_text("ui.turn_results.pass_labels.success"))), false))
	var secondary_dc: float = float(preview.get("secondary_dc", 0.0))
	if secondary_dc > 0.0:
		lines.append(_format_roll_requirement_text(dice_count, modifier_text, int(ceil(secondary_dc - modifier)), str(preview.get("secondary_pass_label", TextDB.get_text("ui.turn_results.pass_labels.success"))), true))
	return "\n".join(lines)

func _format_roll_requirement_text(dice_count: int, modifier_text: String, required_roll: int, pass_label: String, secondary: bool) -> String:
	var label: String = pass_label.strip_edges()
	if label.is_empty():
		label = TextDB.get_text("ui.turn_results.pass_labels.success")
	if required_roll > 12:
		var impossible_key: String = "ui.detail_panel.roll_preview_secondary_impossible" if secondary else "ui.detail_panel.roll_preview_impossible"
		if secondary:
			return TextDB.format_text(impossible_key, [label])
		return TextDB.format_text(impossible_key, [dice_count, modifier_text, label])
	var clamped_required: int = maxi(2, required_roll)
	if secondary:
		return TextDB.format_text("ui.detail_panel.roll_preview_secondary", [label, clamped_required])
	return TextDB.format_text("ui.detail_panel.roll_preview", [dice_count, modifier_text, clamped_required, label])

func _format_signed_score_value(value_variant) -> String:
	var value: float = float(value_variant)
	var rounded_value: float = round(value)
	if absf(value - rounded_value) < 0.001:
		return "%+d" % int(rounded_value)
	return "%+.1f" % value

func _detail_setup(title: String, subtitle: String, body: String, icon_path: String, assigned_cards: Array, footnote: String, focus_window: bool = false, suppress_focus: bool = false) -> void:
	var detail_panel_was_visible: bool = detail_panel.visible
	detail_panel_open = true
	detail_panel_open_token += 1
	detail_panel.visible = detail_panel_was_visible
	detail_panel.modulate = Color.WHITE
	_apply_detail_panel_window_size()
	_ensure_detail_panel_position()
	if detail_panel_was_visible and not suppress_focus and focus_window:
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
	if detail_panel_was_visible:
		call_deferred("_apply_detail_panel_window_size")
	else:
		detail_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
		detail_panel.visible = true
		call_deferred("_finalize_detail_panel_open", detail_panel_open_token, focus_window, suppress_focus)

func _finalize_detail_panel_open(token: int, focus_window: bool, suppress_focus: bool) -> void:
	if detail_panel == null or not detail_panel_open or token != detail_panel_open_token:
		return
	_apply_detail_panel_window_size()
	_ensure_detail_panel_position()
	await get_tree().process_frame
	if detail_panel == null or not detail_panel_open or token != detail_panel_open_token:
		return
	_apply_detail_panel_window_size()
	_ensure_detail_panel_position()
	await get_tree().process_frame
	if detail_panel == null or not detail_panel_open or token != detail_panel_open_token:
		return
	_apply_detail_panel_window_size()
	_ensure_detail_panel_position()
	detail_panel.modulate = Color.WHITE
	detail_panel.visible = true
	if not suppress_focus:
		_focus_detail_panel()

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
	card_width = clampf(card_width, 132.0, LIST_CARD_WIDTH)
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
	if story_event_manager != null and run_state != null and story_event_manager.is_story_board_event(run_state, data_event.id):
		return _format_event_description_body(story_event_manager.describe_board_event(run_state, data_event.id))
	var sections: Array[String] = []
	var formatted_description: String = _format_event_description_body(data_event.description)
	if not formatted_description.is_empty():
		sections.append(formatted_description)
	var rules_text: String = event_manager.describe_event_rules(data_event, run_state)
	if not rules_text.strip_edges().is_empty():
		sections.append(rules_text)
	return "\n\n".join(sections)

func _event_title(data_event: EventData) -> String:
	if story_event_manager != null and run_state != null and story_event_manager.is_story_board_event(run_state, data_event.id):
		return story_event_manager.board_event_title(run_state, data_event.id)
	return data_event.title

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

func _story_event_allows_assignment(target_id: String, payload: Dictionary) -> bool:
	if story_event_manager == null or run_state == null:
		return true
	if payload.is_empty():
		return false
	var normalized_target_id: String = target_id.strip_edges()
	if normalized_target_id.contains("@replace="):
		normalized_target_id = normalized_target_id.get_slice("@replace=", 0)
	if normalized_target_id.contains("#"):
		normalized_target_id = normalized_target_id.get_slice("#", 0)
	var event_id: String = normalized_target_id
	var slot_type: String = str(payload.get("card_type", ""))
	if normalized_target_id.contains(":"):
		event_id = normalized_target_id.get_slice(":", 0)
		slot_type = normalized_target_id.get_slice(":", 1)
	if not story_event_manager.is_story_board_event(run_state, event_id):
		return true
	return story_event_manager.can_assign_to_board_event(run_state, event_id, payload, slot_type)

func _on_card_quick_assign_requested(payload: Dictionary) -> void:
	if payload.is_empty():
		return
	var preserve_event_dialog_position: bool = event_ui_controller != null and event_ui_controller.is_dialog_visible()
	if preserve_event_dialog_position:
		event_ui_controller.remember_dialog_position()
	var target: Dictionary = _find_quick_assign_target(payload)
	if target.is_empty():
		run_state.log_entries.append(TextDB.get_text("logs.board.quick_assign_failed"))
		_play_ui_sound("assign_fail")
		_refresh_board()
		if preserve_event_dialog_position:
			event_ui_controller.restore_dialog_position_after_refresh(get_viewport_rect().size)
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
	if preserve_event_dialog_position:
		event_ui_controller.restore_dialog_position_after_refresh(get_viewport_rect().size)

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
	if not _story_event_allows_assignment("%s:%s" % [event_id, slot_type], payload):
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
	var preserve_event_dialog_position: bool = event_ui_controller != null and event_ui_controller.is_dialog_visible()
	if preserve_event_dialog_position:
		event_ui_controller.remember_dialog_position()
	var target_info: Dictionary = _parse_drop_request_target(target_id)
	var tutorial_target_id: String = str(target_info.get("tutorial_target_id", ""))
	var resolved_target_id: String = str(target_info.get("resolved_target_id", ""))
	var replace_uid: String = str(target_info.get("replace_uid", ""))
	if not _tutorial_allows_assignment(tutorial_target_id, payload) or not _story_event_allows_assignment(resolved_target_id if not resolved_target_id.is_empty() else tutorial_target_id, payload):
		run_state.log_entries.append(TextDB.get_text("logs.board.invalid_drop"))
		_play_ui_sound("assign_fail")
		_refresh_board()
		if preserve_event_dialog_position:
			event_ui_controller.restore_dialog_position_after_refresh(get_viewport_rect().size)
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
	if preserve_event_dialog_position:
		event_ui_controller.restore_dialog_position_after_refresh(get_viewport_rect().size)

func _on_event_dialog_close_pressed() -> void:
	if event_ui_controller != null:
		event_ui_controller.close_dialog()

func _on_event_dialog_header_gui_input(event: InputEvent) -> void:
	if event_ui_controller != null:
		event_ui_controller.handle_header_input(event, get_global_mouse_position())

func _close_detail_panel() -> void:
	selected_slot_id = ""
	detail_panel_open = false
	detail_panel_open_token += 1
	dragging_detail_panel = false
	detail_panel.modulate = Color.WHITE
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
	_focus_popup_overlay()
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
	_focus_popup_overlay()
	detail_overlay.visible = true

func _focus_popup_overlay() -> void:
	if detail_overlay == null:
		return
	detail_overlay.z_as_relative = false
	detail_overlay.z_index = 4096
	move_child(detail_overlay, get_child_count() - 1)

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
	var tutorial_active_before: bool = tutorial_manager != null and run_state != null and tutorial_manager.is_active(run_state)
	var logs: Array[String] = turn_manager.resolve_turn(run_state, board_manager, event_manager, relation_manager, characters, resources, tutorial_manager, story_event_manager)
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
	var just_completed_tutorial: bool = tutorial_active_before and not tutorial_active and int(run_state.flags.get("tutorial_last_report_step", 0)) == 5
	if not tutorial_active and not just_completed_tutorial and story_event_manager != null:
		var queued_story_events: Array[Dictionary] = story_event_manager.queue_events_after_turn(run_state, resolved_turn_index)
		if not queued_story_events.is_empty():
			story_event_manager.sync_active_board_events(run_state, events)
		for queued_variant in queued_story_events:
			var queued_event: Dictionary = queued_variant as Dictionary
			if story_event_manager.event_skips_choice(str(queued_event.get("event_id", ""))):
				continue
			var queued_title: String = story_event_manager.event_title(str(queued_event.get("event_id", "")))
			if queued_title.is_empty():
				continue
			var queued_line: String = TextDB.format_text("story_events.logs.queued", [queued_title])
			report_logs.append(queued_line)
			run_state.log_entries.append(queued_line)
		if not queued_story_events.is_empty():
			_refresh_board()
			_save_system_game()
	var post_turn_payload: Dictionary = {
		"turn_index": report_turn_index,
		"logs": report_logs.duplicate(true),
		"title": report_title_override,
		"subtitle": report_subtitle_override,
		"body": report_body_override,
		"show_report": should_show_report
	}
	var result_presentations: Array = turn_manager.consume_result_presentations()
	if _start_turn_result_sequence(result_presentations, post_turn_payload):
		return
	if not tutorial_active and not just_completed_tutorial and _start_story_event_sequence(post_turn_payload):
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
	if startup_cover_active or _system_menu_visible() or run_state.game_over or detail_overlay.visible or tutorial_dialog_active or turn_result_active or story_event_active:
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
