extends Area2D

const COLORS := {"fire": Color.ORANGE_RED, "earth": Color.SADDLE_BROWN, "water": Color.DODGER_BLUE,
	"wind": Color.LIGHT_CYAN, "poison": Color.PURPLE, "heal": Color.LIME_GREEN}

var radius := 100.0
var color := Color.WHITE

func setup(element: String, r: float, power: float) -> void:
	radius = r
	color = COLORS.get(element, Color.WHITE)
	var cs := $CollisionShape2D
	cs.shape = cs.shape.duplicate()
	cs.shape.radius = r
	monitoring = true
	queue_redraw()
	await get_tree().physics_frame
	await get_tree().physics_frame
	for b in get_overlapping_bodies():
		if element == "heal" and not b.is_in_group("allies"):
			continue
		if element != "heal" and not b.is_in_group("enemies"):
			continue
		if b.has_method("apply_spell"):
			b.call("apply_spell", element, power, 1.0, global_position)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)

func _draw() -> void:
	var fill := color
	fill.a = 0.35
	draw_circle(Vector2.ZERO, radius, fill)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, color, 3.0, true)
