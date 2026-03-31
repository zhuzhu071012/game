extends PanelContainer
class_name CardView

signal target_drop_requested(target_id: String, payload: Dictionary)
signal card_clicked(card_id: String)
signal quick_assign_requested(payload: Dictionary)
signal remove_requested(payload: Dictionary)

const DEFAULT_CARD_WIDTH: float = 156.0
const COMPACT_PORTRAIT_WIDTH: float = 120.0
const COMPACT_PORTRAIT_HEIGHT: float = 160.0
const COMPACT_PORTRAIT_ART_HEIGHT: float = 116.0

var art_frame: PanelContainer
var art_texture: TextureRect
var art_label: Label
var title_label: Label
var subtitle_label: Label
var body_label: RichTextLabel
var assigned_label: Label
var stack_badge: PanelContainer
var stack_badge_label: Label

var card_payload: Dictionary = {}
var target_mode: bool = false
var accepted_drop: bool = false
var compact_mode: bool = false
var hovered: bool = false
var base_card_width: float = 188.0
var expanded_height: float = 286.0
var collapsed_height: float = 220.0
var hover_z_index: int = 100
var default_z_index: int = 0
var pending_click: bool = false
var press_position: Vector2 = Vector2.ZERO
var drag_started: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_layer_mode()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	default_z_index = z_index
	_bind_nodes()
	_apply_payload()

func setup(payload: Dictionary, as_target: bool = false) -> void:
	card_payload = payload.duplicate(true)
	target_mode = as_target
	compact_mode = bool(card_payload.get("compact_details", false))
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_layer_mode()
	default_z_index = z_index
	_bind_nodes()
	_apply_payload()

func _apply_layer_mode() -> void:
	var embedded: bool = bool(card_payload.get("embedded", false))
	z_as_relative = embedded
	if embedded:
		z_index = 0
		hover_z_index = 0
	else:
		if z_index < 0:
			z_index = 0
		hover_z_index = 6 if bool(card_payload.get("icon_button", false)) else 8

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			if not target_mode and not bool(card_payload.get("locked", false)):
				if bool(card_payload.get("assigned", false)) and not str(card_payload.get("uid", "")).is_empty() and bool(card_payload.get("removable", true)):
					emit_signal("remove_requested", card_payload.duplicate(true))
					accept_event()
				elif str(card_payload.get("card_type", "")) in ["character", "resource", "event", "risk"]:
					emit_signal("quick_assign_requested", _assignment_payload())
					accept_event()
			return
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			pending_click = true
			drag_started = false
			press_position = mouse_event.position
		else:
			var is_click: bool = pending_click and not drag_started and press_position.distance_to(mouse_event.position) <= 10.0
			pending_click = false
			if is_click:
				emit_signal("card_clicked", str(card_payload.get("id", "")))

func _bind_nodes() -> void:
	if art_frame == null:
		art_frame = get_node_or_null("Margin/VBox/ArtFrame") as PanelContainer
	if art_texture == null:
		art_texture = get_node_or_null("Margin/VBox/ArtFrame/ArtMargin/ArtContent/ArtTexture") as TextureRect
	if art_label == null:
		art_label = get_node_or_null("Margin/VBox/ArtFrame/ArtMargin/ArtContent/ArtLabel") as Label
	if title_label == null:
		title_label = get_node_or_null("Margin/VBox/Title") as Label
	if subtitle_label == null:
		subtitle_label = get_node_or_null("Margin/VBox/Subtitle") as Label
	if body_label == null:
		body_label = get_node_or_null("Margin/VBox/Body") as RichTextLabel
	if assigned_label == null:
		assigned_label = get_node_or_null("Margin/VBox/Assigned") as Label
	var art_content: Control = get_node_or_null("Margin/VBox/ArtFrame/ArtMargin/ArtContent") as Control
	if stack_badge == null and art_content != null:
		stack_badge = PanelContainer.new()
		stack_badge.name = "StackBadge"
		stack_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack_badge.anchor_left = 1.0
		stack_badge.anchor_top = 0.0
		stack_badge.anchor_right = 1.0
		stack_badge.anchor_bottom = 0.0
		stack_badge.offset_left = -38.0
		stack_badge.offset_top = 6.0
		stack_badge.offset_right = -6.0
		stack_badge.offset_bottom = 30.0
		art_content.add_child(stack_badge)
		stack_badge_label = Label.new()
		stack_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stack_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		stack_badge_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stack_badge_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		stack_badge.add_child(stack_badge_label)
	elif stack_badge != null and stack_badge_label == null:
		stack_badge_label = stack_badge.get_child(0) as Label
	for node in [art_frame, art_texture, art_label, title_label, subtitle_label, body_label, assigned_label, stack_badge, stack_badge_label, get_node_or_null("Margin"), get_node_or_null("Margin/VBox")]:
		if node != null and node is Control:
			(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

func _apply_payload() -> void:
	if card_payload.is_empty():
		return
	if title_label == null or subtitle_label == null or body_label == null or assigned_label == null:
		return
	base_card_width = float(card_payload.get("card_width", custom_minimum_size.x if custom_minimum_size.x > 0.0 else DEFAULT_CARD_WIDTH))
	expanded_height = float(card_payload.get("expanded_height", custom_minimum_size.y if custom_minimum_size.y > 0.0 else 252.0))
	collapsed_height = float(card_payload.get("collapsed_height", expanded_height - 66.0))
	title_label.text = str(card_payload.get("title", TextDB.get_text("ui.fallback.card")))
	subtitle_label.text = str(card_payload.get("subtitle", ""))
	body_label.text = str(card_payload.get("body", ""))
	assigned_label.text = str(card_payload.get("assigned_text", ""))
	compact_mode = bool(card_payload.get("compact_details", compact_mode))
	_apply_art()
	_apply_stack_badge()
	_refresh_compact_state()
	var explicit_tooltip: String = str(card_payload.get("tooltip_text", "")).strip_edges()
	tooltip_text = explicit_tooltip if not explicit_tooltip.is_empty() else ""
	_update_style(card_payload.get("color", Color(0.23, 0.19, 0.14)))

func _apply_art() -> void:
	if art_texture == null or art_label == null or art_frame == null:
		return
	var image_path: String = str(card_payload.get("image_path", ""))
	var image_texture: Texture2D = null
	if not image_path.is_empty() and ResourceLoader.exists(image_path):
		image_texture = load(image_path) as Texture2D
	art_texture.texture = image_texture
	var image_label_text: String = str(card_payload.get("image_label", card_payload.get("title", "")))
	art_label.text = image_label_text
	art_label.visible = image_texture == null
	if card_payload.has("art_label_color"):
		art_label.add_theme_color_override("font_color", card_payload.get("art_label_color", Color(1, 1, 1, 1)))
	if card_payload.has("art_label_font_size"):
		art_label.add_theme_font_size_override("font_size", int(card_payload.get("art_label_font_size", 16)))
	var art_style: StyleBoxFlat = StyleBoxFlat.new()
	art_style.bg_color = (card_payload.get("art_bg_color", card_payload.get("color", Color(0.23, 0.19, 0.14))) as Color).darkened(0.12)
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
	if bool(card_payload.get("icon_button", false)):
		art_style.bg_color = (card_payload.get("art_bg_color", Color(0.18, 0.18, 0.19)) as Color)
		art_style.border_width_left = 2
		art_style.border_width_top = 2
		art_style.border_width_right = 2
		art_style.border_width_bottom = 2
		art_style.border_color = Color(0.46, 0.46, 0.48, 0.90)
		art_style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
		art_style.shadow_size = 10
	elif bool(card_payload.get("drop_slot", false)):
		art_style.bg_color = Color(0.02, 0.03, 0.05, 0.98)
		art_style.border_width_left = 2
		art_style.border_width_top = 2
		art_style.border_width_right = 2
		art_style.border_width_bottom = 2
		art_style.border_color = Color(0.42, 0.42, 0.44, 0.90)
	art_frame.add_theme_stylebox_override("panel", art_style)

func _refresh_compact_state() -> void:
	if title_label == null or subtitle_label == null or body_label == null or assigned_label == null:
		return
	var show_details: bool = not compact_mode
	var show_title: bool = not bool(card_payload.get("hide_title", false))
	var show_subtitle: bool = (show_details or bool(card_payload.get("show_subtitle_in_compact", false))) and not bool(card_payload.get("hide_subtitle", false))
	var show_assigned: bool = (show_details or bool(card_payload.get("show_assigned_in_compact", false))) and not bool(card_payload.get("hide_assigned", false))
	var show_body: bool = show_details and not bool(card_payload.get("hide_body", false))
	title_label.visible = show_title and not title_label.text.strip_edges().is_empty()
	subtitle_label.visible = show_subtitle and not subtitle_label.text.strip_edges().is_empty()
	body_label.visible = show_body and not body_label.text.strip_edges().is_empty()
	assigned_label.visible = show_assigned and not assigned_label.text.strip_edges().is_empty()
	if art_frame != null and card_payload.has("art_height"):
		art_frame.custom_minimum_size = Vector2(0.0, float(card_payload.get("art_height", art_frame.custom_minimum_size.y)))
	var target_height: float = expanded_height if show_details else collapsed_height
	custom_minimum_size = Vector2(base_card_width, target_height)
	size = Vector2(size.x, target_height)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if target_mode or bool(card_payload.get("locked", false)):
		return null
	if bool(card_payload.get("assigned", false)) and not bool(card_payload.get("removable", true)):
		return null
	drag_started = true
	set_drag_preview(_build_drag_preview())
	return _assignment_payload()

func _assignment_payload() -> Dictionary:
	var payload: Dictionary = card_payload.duplicate(true)
	payload.erase("stack_count")
	payload["assigned"] = false
	payload["assigned_text"] = ""
	return payload

func _apply_stack_badge() -> void:
	if stack_badge == null or stack_badge_label == null:
		return
	var count: int = int(card_payload.get("stack_count", 0))
	var badge_text: String = str(card_payload.get("badge_text", "")).strip_edges()
	var use_custom_badge: bool = not badge_text.is_empty()
	if count <= 1 and not use_custom_badge:
		stack_badge.visible = false
		return
	stack_badge.visible = true
	stack_badge_label.text = badge_text if use_custom_badge else (str(count) if count < 100 else "99+")
	stack_badge_label.add_theme_font_size_override("font_size", 10 if use_custom_badge else 11)
	stack_badge.custom_minimum_size = Vector2(48.0, 24.0) if use_custom_badge else Vector2(32.0, 24.0)
	stack_badge.offset_left = -54.0 if use_custom_badge else -38.0
	stack_badge.offset_top = 6.0
	stack_badge.offset_right = -6.0
	stack_badge.offset_bottom = 30.0
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
	stack_badge.add_theme_stylebox_override("panel", badge_style)

func _build_drag_preview() -> Control:
	var preview: PanelContainer = PanelContainer.new()
	preview.custom_minimum_size = size if size != Vector2.ZERO else custom_minimum_size
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = card_payload.get("color", Color(0.23, 0.19, 0.14))
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.72, 0.72, 0.74)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	preview.add_theme_stylebox_override("panel", style)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 5)
	preview.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	margin.add_child(box)
	var art: ColorRect = ColorRect.new()
	art.custom_minimum_size = Vector2(0, float(card_payload.get("art_height", COMPACT_PORTRAIT_ART_HEIGHT)))
	art.color = (card_payload.get("art_bg_color", card_payload.get("color", Color(0.23, 0.19, 0.14))) as Color).darkened(0.08)
	box.add_child(art)
	var title: Label = Label.new()
	title.text = str(card_payload.get("title", TextDB.get_text("ui.fallback.card")))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	return preview

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not target_mode:
		return false
	var payload: Dictionary = data as Dictionary
	var slot_type: String = str(card_payload.get("drop_kind", ""))
	var current_cards: Array = card_payload.get("current_cards", [])
	var target_id: String = str(card_payload.get("target_id", ""))
	if slot_type == "event_character":
		accepted_drop = GameRules.can_drop_on_event_slot("character", payload, current_cards)
	elif slot_type == "event_resource":
		accepted_drop = GameRules.can_drop_on_event_slot("resource", payload, current_cards)
	elif str(card_payload.get("card_type", "")) == "event":
		accepted_drop = GameRules.can_drop_on_event(payload)
	else:
		accepted_drop = GameRules.can_drop_on_slot(target_id, payload, current_cards)
		if accepted_drop and not _matches_drop_slot_filter(payload):
			accepted_drop = false
		if not accepted_drop and target_id == "governance" and str(payload.get("id", "")) == "cao_cao":
			accepted_drop = _matches_drop_slot_filter(payload)
	_update_style(_target_color())
	return accepted_drop

func _matches_drop_slot_filter(payload: Dictionary) -> bool:
	if not bool(card_payload.get("drop_slot", false)):
		return true
	var payload_type: String = str(payload.get("card_type", ""))
	var payload_id: String = str(payload.get("id", ""))
	var slot_key: String = str(card_payload.get("slot_key", ""))
	var allowed_types: Array = card_payload.get("allowed_card_types", [])
	if not allowed_types.is_empty() and not allowed_types.has(payload_type):
		return false
	if slot_key == "recruit_money":
		return payload_type == "resource" and payload_id == "silver_pack"
	if slot_key == "recruit_task" and payload_type == "resource" and payload_id == "recruit_writ":
		return true
	var allowed_ids: Array = card_payload.get("allowed_card_ids", [])
	if not allowed_ids.is_empty():
		if payload_type == "risk":
			if not allowed_ids.has(payload_id):
				return false
		elif slot_key not in ["audience_guest", "rest_caregiver"]:
			if not allowed_ids.has(payload_id):
				return false
	var blocked_ids: Array = card_payload.get("blocked_card_ids", [])
	if blocked_ids.has(payload_id):
		return false
	var required_tags: Array = card_payload.get("required_tags", [])
	if not _rest_slot_filter_allows(payload):
		return false
	if required_tags.is_empty():
		return true
	var payload_tags: Array = payload.get("tags", [])
	for tag_variant in required_tags:
		if payload_tags.has(tag_variant):
			return true
	return false

func _rest_slot_filter_allows(payload: Dictionary) -> bool:
	var slot_key: String = str(card_payload.get("slot_key", ""))
	if slot_key not in ["rest_resource_1", "rest_caregiver"]:
		return true
	var current_cards: Array = card_payload.get("current_cards", [])
	var current_resource_id: String = ""
	var has_headwind: bool = false
	var caregiver_present: bool = false
	for card_variant in current_cards:
		var card: Dictionary = card_variant as Dictionary
		match str(card.get("card_type", "")):
			"resource":
				current_resource_id = str(card.get("id", ""))
			"risk":
				if str(card.get("id", "")) == "headwind":
					has_headwind = true
			"character":
				if str(card.get("id", "")) != "cao_cao":
					caregiver_present = true
	var payload_type: String = str(payload.get("card_type", ""))
	var payload_id: String = str(payload.get("id", ""))
	if slot_key == "rest_resource_1":
		if payload_type != "resource":
			return false
		if has_headwind:
			return payload_id == "calming_incense"
		if caregiver_present:
			return payload_id in ["silver_pack", "herbal_tonic"]
		return payload_id in ["silver_pack", "herbal_tonic", "calming_incense"]
	if payload_type == "risk":
		return payload_id == "headwind" and current_resource_id == "calming_incense"
	if payload_type == "character":
		if str(payload.get("id", "")) == "cao_cao":
			return false
		return current_resource_id in ["silver_pack", "herbal_tonic"]
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var assign_target_id: String = str(card_payload.get("assign_target_id", card_payload.get("target_id", card_payload.get("id", ""))))
	emit_signal("target_drop_requested", assign_target_id, data)
	accepted_drop = false
	_update_style(_target_color())

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		var was_drag_source: bool = drag_started
		pending_click = false
		drag_started = false
		if not was_drag_source:
			return
		if not is_drag_successful() and not target_mode:
			if bool(card_payload.get("assigned", false)) and bool(card_payload.get("removable", true)):
				emit_signal("remove_requested", card_payload.duplicate(true))
			else:
				modulate = Color(1.0, 0.7, 0.7)
				await get_tree().create_timer(0.18).timeout
				modulate = Color.WHITE

func _update_style(color: Color) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	var icon_button: bool = bool(card_payload.get("icon_button", false))
	var drop_slot: bool = bool(card_payload.get("drop_slot", false))
	style.bg_color = Color(0.06, 0.06, 0.07, 0.32) if icon_button else color.lightened(0.04 if hovered else 0.0)
	style.border_width_left = 0 if icon_button else (2 if drop_slot else 3)
	style.border_width_top = 0 if icon_button else (2 if drop_slot else 3)
	style.border_width_right = 0 if icon_button else (2 if drop_slot else 3)
	style.border_width_bottom = 0 if icon_button else (2 if drop_slot else 3)
	if accepted_drop:
		style.border_color = Color(0.90, 0.90, 0.92)
	elif hovered:
		style.border_color = Color(0.76, 0.76, 0.80) if (icon_button or drop_slot) else Color(0.82, 0.82, 0.85)
	else:
		style.border_color = Color(0.0, 0.0, 0.0, 0.0) if icon_button else (Color(0.42, 0.42, 0.44) if drop_slot else Color(0.50, 0.50, 0.52, 0.96))
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42) if icon_button else (Color(0.0, 0.0, 0.0, 0.50) if drop_slot else (Color(0.70, 0.70, 0.72, 0.16) if hovered else Color(0.0, 0.0, 0.0, 0.20)))
	style.shadow_size = 12 if icon_button else (8 if drop_slot else (16 if hovered else 6))
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	add_theme_stylebox_override("panel", style)

func _target_color() -> Color:
	return (card_payload.get("color", Color(0.16, 0.17, 0.18)) as Color).lightened(0.15 if accepted_drop else 0.0)

func _on_mouse_entered() -> void:
	hovered = true
	z_index = hover_z_index
	_update_style(card_payload.get("color", Color(0.23, 0.19, 0.14)))

func _on_mouse_exited() -> void:
	hovered = false
	z_index = default_z_index
	_update_style(card_payload.get("color", Color(0.23, 0.19, 0.14)))
