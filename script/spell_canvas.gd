extends Control

signal cast_requested(strokes: Array, center: Vector2, radius: float)

const INK := Color(0.45, 0.9, 1.0)
const BUTTON_UNPRESSED := preload("res://UI/texture/button_unpressed.png")
const BUTTON_PRESSED := preload("res://UI/texture/button_pressed.png")
const BUTTON_HOVER := preload("res://UI/texture/button_hover.png")
const BUTTON_DISABLED := preload("res://UI/texture/button_disable.png")
const BUTTON_FONT := preload("res://UI/fonts_setting/VCR.ttf")
const TUTORIAL_FONT := preload("res://UI/fonts_setting/VCR.ttf")
const TUTORIAL_SIGIL_FIRE := preload("res://UI/texture/canvas_sigil_fire.png")
const TUTORIAL_SIGIL_EARTH := preload("res://UI/texture/canvas_sigil_earth.png")
const TUTORIAL_MODIFIER := preload("res://UI/texture/canvas_modifier.png")
const TUTORIAL_ARROW := preload("res://UI/texture/canvas_outline_arrow_up.png")
const DRAWING_TIME_SCALE := 0.15
var strokes: Array[PackedVector2Array] = []
var current := PackedVector2Array()
var drawing := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_create_action_buttons()
	hide()

func _create_action_buttons() -> void:
	var cast_button := _create_textured_button("CastSpellButton", "CAST")
	cast_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	cast_button.offset_left = -164.0
	cast_button.offset_top = -84.0
	cast_button.offset_right = -32.0
	cast_button.offset_bottom = -28.0
	add_child(cast_button)
	cast_button.pressed.connect(cast)

	var cancel_button := _create_textured_button("CancelSpellButton", "CANCEL")
	cancel_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	cancel_button.offset_left = 32.0
	cancel_button.offset_top = -84.0
	cancel_button.offset_right = 164.0
	cancel_button.offset_bottom = -28.0
	add_child(cancel_button)
	cancel_button.pressed.connect(close)

func _create_textured_button(button_name: String, label_text: String) -> TextureButton:
	var button := TextureButton.new()
	button.name = button_name
	button.texture_normal = BUTTON_UNPRESSED
	button.texture_pressed = BUTTON_PRESSED
	button.texture_hover = BUTTON_HOVER
	button.texture_disabled = BUTTON_DISABLED
	button.custom_minimum_size = Vector2(132.0, 56.0)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.focus_mode = Control.FOCUS_NONE
	var label := Label.new()
	label.text = label_text
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", BUTTON_FONT)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	button.add_child(label)
	return button

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and visible:
		Engine.time_scale = 1.0

func center_pos() -> Vector2:
	return size * 0.5

func ring_radius() -> float:
	return minf(size.x, size.y) * 0.5 * 0.95

func open() -> void:
	clear()
	show()
	Engine.time_scale = DRAWING_TIME_SCALE
	queue_redraw()

func close() -> void:
	clear()
	hide()
	Engine.time_scale = 1.0

func clear() -> void:
	strokes.clear()
	current = PackedVector2Array()
	drawing = false
	queue_redraw()

func cast() -> void:
	if not strokes.is_empty():
		cast_requested.emit(strokes.duplicate(), center_pos(), ring_radius())

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_pointer_button(event.position, event.button_index, event.pressed)
	elif event is InputEventScreenTouch:
		_handle_pointer_button(event.position, MOUSE_BUTTON_LEFT, event.pressed)
	elif event is InputEventMouseMotion:
		_append_pointer_position(event.position)
	elif event is InputEventScreenDrag:
		_append_pointer_position(event.position)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		cast()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _handle_pointer_button(position: Vector2, button_index: int, pressed: bool) -> void:
	if button_index == MOUSE_BUTTON_LEFT:
		if pressed:
			current = PackedVector2Array([position])
			drawing = true
		elif drawing:
			drawing = false
			strokes.append(current)
	elif button_index == MOUSE_BUTTON_RIGHT and pressed and not strokes.is_empty():
		strokes.pop_back()
	queue_redraw()
	accept_event()

func _append_pointer_position(position: Vector2) -> void:
	if not drawing or current.is_empty():
		return
	if current[-1].distance_to(position) > 4.0:
		current.append(position)
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.06, 0.14, 0.9))
	var c := center_pos()
	var r := ring_radius()
	var guide := Color(0.5, 0.7, 1.0, 0.35)
	draw_arc(c, r, 0, TAU, 96, guide, 2.0)
	draw_arc(c, r * SpellParser.MOD_FRAC, 0, TAU, 96, guide, 2.0)
	draw_arc(c, r * SpellParser.SIGIL_FRAC, 0, TAU, 96, guide, 2.0)
	if _is_mage_tutorial_active():
		_draw_mage_tutorial_guide(c, r)
	for s in strokes:
		_draw_stroke(s)
	if drawing:
		_draw_stroke(current)

func _is_mage_tutorial_active() -> bool:
	var flags: Dictionary = SaveManager.data.get("flags", {})
	return flags.get("isFromHogward") == true \
		and flags.get("isTutorialDone", false) != true \
		and str(flags.get("tutorial_stage", "")) == "attack"

func _draw_mage_tutorial_guide(center: Vector2, radius: float) -> void:
	var next_sigil := "fire"
	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene.has_method("get_tutorial_next_mage_sigil"):
		next_sigil = str(current_scene.call("get_tutorial_next_mage_sigil"))

	# Ghost sketches show the actual stroke locations the parser expects.
	var ghost_color := Color(0.48, 0.88, 1.0, 0.22)
	var inner_radius := radius * 0.25
	var sigil_path := PackedVector2Array()
	if next_sigil == "earth":
		sigil_path = PackedVector2Array([
			center + Vector2(-inner_radius, -inner_radius),
			center + Vector2(inner_radius, -inner_radius),
			center + Vector2(inner_radius, inner_radius),
			center + Vector2(-inner_radius, inner_radius),
			center + Vector2(-inner_radius, -inner_radius)
		])
	else:
		sigil_path = PackedVector2Array([
			center + Vector2(-inner_radius, inner_radius),
			center + Vector2(0.0, -inner_radius),
			center + Vector2(inner_radius, inner_radius),
			center + Vector2(-inner_radius, inner_radius)
		])
	draw_polyline(sigil_path, ghost_color, 4.0, true)

	var modifier_position := center + Vector2(0.0, -radius * 0.49)
	draw_circle(modifier_position, 8.0, Color(0.92, 0.82, 0.38, 0.24))
	draw_arc(modifier_position, 11.0, 0.0, TAU, 24, Color(1.0, 0.93, 0.56, 0.35), 2.0)

	# One radial arrow in the outer band is the required outline example.
	var arrow_tail := center + Vector2(radius * 0.91, 0.0)
	var arrow_tip := center + Vector2(radius * 0.63, 0.0)
	var arrow_color := Color(0.52, 0.87, 1.0, 0.24)
	draw_line(arrow_tail, arrow_tip, arrow_color, 4.0, true)
	draw_line(arrow_tip, arrow_tip + Vector2(radius * 0.1, -radius * 0.065), arrow_color, 4.0, true)
	draw_line(arrow_tip, arrow_tip + Vector2(radius * 0.1, radius * 0.065), arrow_color, 4.0, true)

	# The supplied component icons identify which ring each sketch belongs in.
	var guide_panel := Rect2(Vector2(18.0, 124.0), Vector2(218.0, 270.0))
	draw_rect(guide_panel, Color(0.035, 0.035, 0.09, 0.88), true)
	draw_rect(guide_panel, Color(0.3, 0.73, 0.91, 0.75), false, 2.0)
	draw_string(TUTORIAL_FONT, Vector2(32.0, 151.0), "SPELL GUIDE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.7, 0.93, 1.0))
	var sigil_icon: Texture2D = TUTORIAL_SIGIL_EARTH if next_sigil == "earth" else TUTORIAL_SIGIL_FIRE
	draw_texture_rect(sigil_icon, Rect2(Vector2(31.0, 164.0), Vector2(38.0, 38.0)), false, Color.WHITE)
	draw_string(TUTORIAL_FONT, Vector2(78.0, 180.0), "CENTER: " + next_sigil.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color.WHITE)
	draw_string(TUTORIAL_FONT, Vector2(78.0, 197.0), "Draw its sigil here", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(0.76, 0.81, 0.9))
	draw_texture_rect(TUTORIAL_MODIFIER, Rect2(Vector2(31.0, 231.0), Vector2(38.0, 38.0)), false, Color.WHITE)
	draw_string(TUTORIAL_FONT, Vector2(78.0, 246.0), "MIDDLE: 1 DOT", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color.WHITE)
	draw_string(TUTORIAL_FONT, Vector2(78.0, 263.0), "One modifier only", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(0.76, 0.81, 0.9))
	draw_texture_rect(TUTORIAL_ARROW, Rect2(Vector2(31.0, 298.0), Vector2(38.0, 38.0)), false, Color.WHITE)
	draw_string(TUTORIAL_FONT, Vector2(78.0, 313.0), "OUTER: ARROW", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color.WHITE)
	draw_string(TUTORIAL_FONT, Vector2(78.0, 330.0), "Point toward center", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(0.76, 0.81, 0.9))

func _draw_stroke(s: PackedVector2Array) -> void:
	if s.size() > 1 and StrokeUtil.path_length(s) > 6.0:
		draw_polyline(s, INK, 4.0, true)
	elif s.size() > 0:
		draw_circle(s[0], 4.0, INK)
