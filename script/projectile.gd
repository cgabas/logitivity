extends Area2D

const COLORS := {"fire": Color.ORANGE_RED, "earth": Color.SADDLE_BROWN, "water": Color.DODGER_BLUE,
	"wind": Color.LIGHT_CYAN, "poison": Color.PURPLE, "heal": Color.LIME_GREEN}

var element := "fire"
var dir := Vector2.RIGHT
var power := 1.0
var max_range := 300.0
var speed := 450.0
var travelled := 0.0

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func setup(e: String, d: Vector2, r: float, p: float) -> void:
	element = e
	dir = d
	max_range = r
	power = p
	rotation = d.angle()
	modulate = COLORS.get(e, Color.WHITE)
	queue_redraw()

func _physics_process(delta: float) -> void:
	var step := dir * speed * delta
	position += step
	travelled += step.length()
	if travelled >= max_range:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if element == "heal" and not body.is_in_group("allies"):
		return
	if element != "heal" and body.is_in_group("allies"):
		return
	if body.has_method("apply_spell"):
		body.call("apply_spell", element, power, 1.0, global_position)
		queue_free()
	elif not body.is_in_group("allies"):
		queue_free()

func _draw() -> void:
	var main := element_color()
	var glow := main
	glow.a = 0.3
	draw_line(Vector2(-28.0, 0.0), Vector2.ZERO, glow, 12.0, true)
	match element:
		"fire":
			draw_circle(Vector2.ZERO, 10.0, glow)
			draw_colored_polygon(PackedVector2Array([Vector2(-9, 0), Vector2(-2, -8), Vector2(2, -15), Vector2(7, -6), Vector2(10, 0), Vector2(5, 8), Vector2(-3, 9)]), main)
			draw_circle(Vector2(1, 0), 3.5, Color(1.0, 0.95, 0.72))
		"water":
			draw_circle(Vector2.ZERO, 9.0, glow)
			draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 24, main, 3.0, true)
			draw_circle(Vector2(2.0, -2.0), 3.0, Color(0.8, 0.96, 1.0))
			draw_circle(Vector2(-8.0, -7.0), 2.0, main)
		"earth":
			draw_colored_polygon(PackedVector2Array([Vector2(-11, 0), Vector2(-2, -9), Vector2(9, -5), Vector2(11, 2), Vector2(2, 10), Vector2(-7, 7)]), main)
			draw_line(Vector2(-2, -7), Vector2(3, 5), Color(0.9, 0.76, 0.5), 2.0, true)
		"wind":
			draw_arc(Vector2.ZERO, 9.0, deg_to_rad(-65.0), deg_to_rad(65.0), 20, main, 4.0, true)
			draw_arc(Vector2(-2.0, 0.0), 5.0, deg_to_rad(-60.0), deg_to_rad(60.0), 16, Color.WHITE, 2.0, true)
		"poison":
			draw_colored_polygon(PackedVector2Array([Vector2(0, -12), Vector2(8, -2), Vector2(7, 5), Vector2(3, 9), Vector2(-3, 9), Vector2(-7, 5), Vector2(-8, -2)]), main)
			draw_circle(Vector2(2.0, 2.0), 2.0, Color(0.9, 1.0, 0.55))
		"heal":
			draw_circle(Vector2.ZERO, 9.0, glow)
			draw_circle(Vector2.ZERO, 7.0, main)
			draw_line(Vector2(-4, 0), Vector2(4, 0), Color.WHITE, 3.0, true)
			draw_line(Vector2(0, -4), Vector2(0, 4), Color.WHITE, 3.0, true)
		_:
			draw_circle(Vector2.ZERO, 9.0, main)

func element_color() -> Color:
	return COLORS.get(element, Color.WHITE)
