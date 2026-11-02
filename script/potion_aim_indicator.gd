extends Node2D

const MIN_THROW_DISTANCE := 112.0
const MAX_THROW_DISTANCE := 360.0
const SPLASH_RADIUS := 57.6
const DOT_SPACING := 16.0

var direction := Vector2.DOWN
var throw_distance := MIN_THROW_DISTANCE
var splash_radius := SPLASH_RADIUS

func set_aim(value: Vector2, distance: float, radius: float = SPLASH_RADIUS) -> void:
	if value.length_squared() > 0.01:
		direction = value.normalized()
	throw_distance = clampf(distance, MIN_THROW_DISTANCE, MAX_THROW_DISTANCE)
	splash_radius = maxf(radius, 0.0)
	queue_redraw()

func _draw() -> void:
	var arc_height := 28.0 * throw_distance / MAX_THROW_DISTANCE
	for dot_index in range(1, int(throw_distance / DOT_SPACING) + 1):
		var progress := float(dot_index) * DOT_SPACING / throw_distance
		var point := direction * (throw_distance * progress)
		point.y -= sin(progress * PI) * arc_height
		var radius := lerpf(2.2, 4.0, progress)
		draw_circle(point, radius, Color(0.48, 0.9, 1.0, 0.78))
	var landing := direction * throw_distance
	draw_circle(landing, splash_radius, Color(0.35, 0.78, 1.0, 0.11))
	for arc_index in 12:
		var start_angle := TAU * float(arc_index) / 12.0
		draw_arc(landing, splash_radius, start_angle, start_angle + 0.27, 12, Color(0.6, 0.91, 1.0, 0.85), 2.0, true)
	draw_circle(landing, 4.0, Color(0.8, 0.97, 1.0, 0.95))
