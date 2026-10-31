extends Area2D

const COLORS := {"fire": Color.ORANGE_RED, "earth": Color.SADDLE_BROWN, "water": Color.DODGER_BLUE,
	"wind": Color.LIGHT_CYAN, "poison": Color.PURPLE, "heal": Color.LIME_GREEN}

var element := "fire"
var max_radius := 120.0
var radius := 0.0
var color := Color.WHITE
var power := 1.0
var elapsed := 0.0
var duration := 0.42
var hit_targets: Array[Node] = []

func setup(spell_element: String, wave_radius: float, spell_power: float) -> void:
	element = spell_element
	max_radius = maxf(wave_radius, 1.0)
	color = COLORS.get(element, Color.WHITE)
	power = spell_power
	radius = 0.0
	monitoring = false
	monitorable = false
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	radius = max_radius * clampf(elapsed / duration, 0.0, 1.0)
	_hit_wave_targets()
	queue_redraw()
	if elapsed >= duration:
		var fade := create_tween()
		fade.tween_property(self, "modulate:a", 0.0, 0.16)
		fade.tween_callback(queue_free)
		set_process(false)

func _hit_wave_targets() -> void:
	var targets: Array[Node] = get_tree().get_nodes_in_group("enemies")
	if element == "heal":
		targets.append_array(get_tree().get_nodes_in_group("allies"))
	for target in targets:
		if not is_instance_valid(target) or hit_targets.has(target):
			continue
		if not target.has_method("apply_spell"):
			continue
		var distance := global_position.distance_to(target.global_position)
		if distance <= radius:
			hit_targets.append(target)
			target.call("apply_spell", element, power, 1.0, global_position)

func _draw() -> void:
	if radius <= 0.0:
		return
	for ring_index in 4:
		var ring_radius := radius - ring_index * 13.0
		if ring_radius <= 0.0:
			continue
		var ring_color := color
		ring_color.a = 0.9 - ring_index * 0.16
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 64, ring_color, 3.0 - ring_index * 0.35, true)
	for spoke_index in 12:
		var angle := TAU * float(spoke_index) / 12.0
		var direction := Vector2.from_angle(angle)
		draw_line(direction * maxf(0.0, radius - 9.0), direction * radius, color, 2.0, true)
