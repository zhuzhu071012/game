extends PanelContainer
class_name FloatingDetailWindow

signal close_requested(window)
signal focus_requested(window)
signal drag_requested(window, mouse_global_position)

const DEFAULT_SIZE := Vector2(560.0, 420.0)
const ART_SIZE := Vector2(168.0, 224.0)

var window_payload: Dictionary = {}
var fixed_window_size: Vector2 = DEFAULT_SIZE
var size_lock_active: bool = false

var header_panel: PanelContainer
var title_label: Label
var subtitle_label: Label
var close_button: Button
var art_frame: PanelContainer
var art_texture: TextureRect
var art_placeholder: Label
var art_container: Control
var body_panel: PanelContainer
var body_label: RichTextLabel

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_ui()
	_apply_payload()
	call_deferred("_apply_fixed_window_size")

func setup(payload: Dictionary) -> void:
	window_payload = payload.duplicate(true)
	_ensure_ui()
	_apply_payload()
	call_deferred("_apply_fixed_window_size")

func apply_title_font(font_resource: Font) -> void:
	if font_resource == null:
		return
	_ensure_ui()
	if title_label != null:
		title_label.add_theme_font_override("font", font_resource)

func apply_body_font_size(font_size: int) -> void:
	if font_size <= 0:
		return
	_ensure_ui()
	if body_label != null:
		body_label.add_theme_font_size_override("normal_font_size", font_size)
		body_label.add_theme_constant_override("line_separation", 4)
		body_label.add_theme_constant_override("line_spacing", 4)
		body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _ensure_ui() -> void:
	if header_panel != null:
		return
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.05, 0.07, 0.98)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.33, 0.37, 0.42, 0.96)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	panel_style.shadow_size = 14
	add_theme_stylebox_override("panel", panel_style)
	custom_minimum_size = DEFAULT_SIZE
	size = DEFAULT_SIZE
	gui_input.connect(_on_panel_gui_input)
	resized.connect(_on_window_resized)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	header_panel = PanelContainer.new()
	header_panel.custom_minimum_size = Vector2(0.0, 42.0)
	header_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	header_panel.gui_input.connect(_on_header_gui_input)
	var header_style: StyleBoxFlat = StyleBoxFlat.new()
	header_style.bg_color = Color(0.11, 0.14, 0.18, 0.98)
	header_style.border_width_left = 1
	header_style.border_width_top = 1
	header_style.border_width_right = 1
	header_style.border_width_bottom = 1
	header_style.border_color = Color(0.39, 0.45, 0.52, 0.96)
	header_style.corner_radius_top_left = 8
	header_style.corner_radius_top_right = 8
	header_style.corner_radius_bottom_left = 8
	header_style.corner_radius_bottom_right = 8
	header_panel.add_theme_stylebox_override("panel", header_style)
	vbox.add_child(header_panel)

	var header_margin: MarginContainer = MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 10)
	header_margin.add_theme_constant_override("margin_top", 6)
	header_margin.add_theme_constant_override("margin_right", 10)
	header_margin.add_theme_constant_override("margin_bottom", 6)
	header_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_panel.add_child(header_margin)

	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	header_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_margin.add_child(header_row)

	var title_box: VBoxContainer = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.add_child(title_box)

	title_label = Label.new()
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_box.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.modulate = Color(0.80, 0.85, 0.90, 1.0)
	subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_box.add_child(subtitle_label)

	close_button = Button.new()
	close_button.custom_minimum_size = Vector2(76.0, 30.0)
	close_button.text = TextDB.get_text("ui.buttons.close")
	close_button.pressed.connect(_on_close_pressed)
	header_row.add_child(close_button)

	var content_row: HBoxContainer = HBoxContainer.new()
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", 10)
	content_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(content_row)

	art_frame = PanelContainer.new()
	art_frame.custom_minimum_size = ART_SIZE
	art_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art_style: StyleBoxFlat = StyleBoxFlat.new()
	art_style.bg_color = Color(0.12, 0.12, 0.14, 0.98)
	art_style.border_width_left = 2
	art_style.border_width_top = 2
	art_style.border_width_right = 2
	art_style.border_width_bottom = 2
	art_style.border_color = Color(0.48, 0.50, 0.54, 0.92)
	art_style.corner_radius_top_left = 8
	art_style.corner_radius_top_right = 8
	art_style.corner_radius_bottom_left = 8
	art_style.corner_radius_bottom_right = 8
	art_frame.add_theme_stylebox_override("panel", art_style)
	content_row.add_child(art_frame)

	var art_margin: MarginContainer = MarginContainer.new()
	art_margin.add_theme_constant_override("margin_left", 4)
	art_margin.add_theme_constant_override("margin_top", 4)
	art_margin.add_theme_constant_override("margin_right", 4)
	art_margin.add_theme_constant_override("margin_bottom", 4)
	art_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.add_child(art_margin)

	art_container = Control.new()
	art_container.custom_minimum_size = Vector2(ART_SIZE.x - 8.0, ART_SIZE.y - 8.0)
	art_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_margin.add_child(art_container)

	art_texture = TextureRect.new()
	art_texture.anchor_right = 1.0
	art_texture.anchor_bottom = 1.0
	art_texture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art_texture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_container.add_child(art_texture)

	art_placeholder = Label.new()
	art_placeholder.anchor_right = 1.0
	art_placeholder.anchor_bottom = 1.0
	art_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	art_placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	art_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_container.add_child(art_placeholder)

	body_panel = PanelContainer.new()
	body_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var body_style: StyleBoxFlat = StyleBoxFlat.new()
	body_style.bg_color = Color(0.05, 0.07, 0.10, 0.96)
	body_style.border_width_left = 1
	body_style.border_width_top = 1
	body_style.border_width_right = 1
	body_style.border_width_bottom = 1
	body_style.border_color = Color(0.23, 0.28, 0.34, 0.96)
	body_style.corner_radius_top_left = 8
	body_style.corner_radius_top_right = 8
	body_style.corner_radius_bottom_left = 8
	body_style.corner_radius_bottom_right = 8
	body_panel.add_theme_stylebox_override("panel", body_style)
	content_row.add_child(body_panel)

	var body_margin: MarginContainer = MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 10)
	body_margin.add_theme_constant_override("margin_top", 8)
	body_margin.add_theme_constant_override("margin_right", 10)
	body_margin.add_theme_constant_override("margin_bottom", 8)
	body_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_panel.add_child(body_margin)

	body_label = RichTextLabel.new()
	body_label.bbcode_enabled = true
	body_label.fit_content = false
	body_label.scroll_active = true
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_margin.add_child(body_label)

func _apply_payload() -> void:
	if title_label == null:
		return
	fixed_window_size = window_payload.get("window_size", DEFAULT_SIZE)
	_apply_fixed_window_size()
	var art_size: Vector2 = window_payload.get("art_size", ART_SIZE)
	art_frame.custom_minimum_size = art_size
	if art_container != null:
		art_container.custom_minimum_size = Vector2(maxf(0.0, art_size.x - 8.0), maxf(0.0, art_size.y - 8.0))
	title_label.text = str(window_payload.get("title", ""))
	subtitle_label.text = str(window_payload.get("subtitle", ""))
	subtitle_label.visible = false
	body_label.text = str(window_payload.get("body", ""))
	var image_path: String = str(window_payload.get("image_path", ""))
	var texture: Texture2D = null
	if not image_path.is_empty() and ResourceLoader.exists(image_path):
		texture = load(image_path) as Texture2D
	art_texture.texture = texture
	art_placeholder.text = str(window_payload.get("title", TextDB.get_text("ui.fallback.card")))
	art_placeholder.visible = texture == null
	art_frame.visible = texture != null or bool(window_payload.get("show_art_placeholder", true))

func _apply_fixed_window_size() -> void:
	if fixed_window_size == Vector2.ZERO:
		return
	if size_lock_active:
		return
	size_lock_active = true
	custom_minimum_size = fixed_window_size
	size = fixed_window_size
	size_lock_active = false

func _on_window_resized() -> void:
	if size_lock_active:
		return
	if fixed_window_size == Vector2.ZERO:
		return
	if absf(size.x - fixed_window_size.x) > 0.5 or absf(size.y - fixed_window_size.y) > 0.5:
		call_deferred("_apply_fixed_window_size")

func _on_close_pressed() -> void:
	emit_signal("close_requested", self)

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			emit_signal("focus_requested", self)

func _on_header_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			emit_signal("focus_requested", self)
			emit_signal("drag_requested", self, get_global_mouse_position())
			accept_event()