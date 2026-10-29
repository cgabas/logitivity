extends Node2D

const COLORS := {
	"fire": Color.ORANGE_RED,
	"earth": Color.SADDLE_BROWN,
	"water": Color.DODGER_BLUE,
	"wind": Color.LIGHT_CYAN,
	"poison": Color.PURPLE,
	"heal": Color.LIME_GREEN
}

var color: Color = Color.WHITE
var radius: float = 8.0
var alpha: float = 1.0

func setup(element: String, max_radius: float = 48.0) -> void:
	color = COLORS.get(element, Color.WHITE)
	var tween := create_tween().set_parallel(true)
	tween.tween_method(_set_radius, 8.0, max_radius, 0.32)
	tween.tween_method(_set_alpha, 1.0, 0.0, 0.32)
	tween.chain().tween_callback(queue_free)

func _set_radius(value: float) -> void:
	radius = value
	queue_redraw()

func _set_alpha(value: float) -> void:
	alpha = value
	queue_redraw()

func _draw() -> void:
	var main_color := color
	main_color.a = alpha
	var inner_color := color
	inner_color.a = alpha * 0.45
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, main_color, 4.0, true)
	draw_arc(Vector2.ZERO, radius * 0.68, 0.0, TAU, 48, inner_color, 2.0, true)
	for i in 8:
		var angle := TAU * i / 8.0
		var start := Vector2.from_angle(angle) * (radius * 0.78)
		var finish := Vector2.from_angle(angle) * (radius * 0.98)
		draw_line(start, finish, main_color, 3.0, true)
