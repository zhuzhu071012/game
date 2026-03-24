extends PanelContainer
class_name CardView

signal target_drop_requested(target_id: String, payload: Dictionary)
signal card_clicked(card_id: String)
signal quick_assign_requested(payload: Dictionary)
signal remove_requested(payload: Dictionary)

var art_frame: PanelContainer
var art_texture: TextureRect
var art_label: Label
var title_label: Label
var subtitle_label: Label
var body_label: RichTextLabel
var assigned_label: Label

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
	z_as_relative = false
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
	_bind_nodes()
	_apply_payload()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			if not target_mode and not bool(card_payload.get("locked", false)):
				if bool(card_payload.get("assigned", false)) and not str(card_payload.get("uid", "")).is_empty() and bool(card_payload.get("removable", true)):
					emit_signal("remove_requested", card_payload.duplicate(true))
					accept_event()
				elif str(card_payload.get("card_type", "")) in ["character", "resource"]:
					emit_signal("quick_assign_requested", card_payload.duplicate(true))
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
	for node in [art_frame, art_texture, art_label, title_label, subtitle_label, body_label, assigned_label, get_node_or_null("Margin"), get_node_or_null("Margin/VBox")]:
		if node != null and node is Control:
			(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

func _apply_payload() -> void:
	if card_payload.is_empty():
		return
	if title_label == null or subtitle_label == null or body_label == null or assigned_label == null:
		return
	base_card_width = custom_minimum_size.x if custom_minimum_size.x > 0.0 else 156.0
	expanded_height = float(card_payload.get("expanded_height", custom_minimum_size.y if custom_minimum_size.y > 0.0 else 252.0))
	collapsed_height = float(card_payload.get("collapsed_height", expanded_height - 66.0))
	title_label.text = str(card_payload.get("title", TextDB.get_text("ui.fallback.card")))
	subtitle_label.text = str(card_payload.get("subtitle", ""))
	body_label.text = str(card_payload.get("body", ""))
	assigned_label.text = str(card_payload.get("assigned_text", ""))
	compact_mode = bool(card_payload.get("compact_details", compact_mode))
	_apply_art()
	_refresh_compact_state()
	tooltip_text = ""
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
	if target_mode or bool(card_payload.get("locked", false)) or bool(card_payload.get("assigned", false)):
		return null
	drag_started = true
	set_drag_preview(_build_drag_preview())
	return card_payload

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
	art.custom_minimum_size = Vector2(0, 112)
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
		if not accepted_drop and target_id == "governance" and str(payload.get("id", "")) == "cao_cao":
			accepted_drop = true
	_update_style(_target_color())
	return accepted_drop

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	emit_signal("target_drop_requested", str(card_payload.get("target_id", card_payload.get("id", ""))), data)
	accepted_drop = false
	_update_style(_target_color())

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		pending_click = false
		drag_started = false
		if not is_drag_successful() and not target_mode:
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
