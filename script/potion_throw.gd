extends Node2D

const ITEM_REGISTRY := preload("res://script/item_registry.gd")
const SPLASH_RADIUS := 57.6
const MIN_THROW_DISTANCE := 112.0
const MAX_THROW_DISTANCE := 360.0
const FLIGHT_TIME := 0.38

var potion_id := ""
var direction := Vector2.RIGHT
var throw_distance := MIN_THROW_DISTANCE
var start_position := Vector2.ZERO
var end_position := Vector2.ZERO
var elapsed := 0.0

func setup(item_id: String, facing: Vector2, distance: float) -> void:
	potion_id = item_id
	direction = facing.normalized() if facing != Vector2.ZERO else Vector2.DOWN
	throw_distance = clampf(distance, MIN_THROW_DISTANCE, MAX_THROW_DISTANCE)
	start_position = global_position
	end_position = start_position + direction * throw_distance

func _ready() -> void:
	var item_data := ITEM_REGISTRY.get_item(potion_id)
	var potion_sprite := Sprite2D.new()
	potion_sprite.texture = item_data.get("icon") as Texture2D
	potion_sprite.scale = Vector2(0.65, 0.65)
	add_child(potion_sprite)
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	var flight_duration := FLIGHT_TIME * (0.45 + 0.55 * throw_distance / MAX_THROW_DISTANCE)
	var progress := clampf(elapsed / flight_duration, 0.0, 1.0)
	var arc_height := 28.0 * throw_distance / MAX_THROW_DISTANCE
	global_position = start_position.lerp(end_position, progress) + Vector2.UP * sin(progress * PI) * arc_height
	if progress >= 1.0:
		_detonate()
		queue_free()

func _detonate() -> void:
	var hit_enemy := false
	var current_scene := get_tree().current_scene
	var tutorial_stage := str(SaveManager.data.get("flags", {}).get("tutorial_stage", "complete"))
	var splash_radius := 96.0 if tutorial_stage == "potion_throw" else SPLASH_RADIUS
	var affected: Array[Node] = _get_splash_targets(splash_radius)
	for target in affected:
		if target.has_method("apply_potion"):
			target.call("apply_potion", potion_id)
			if target.is_in_group("enemies") or target.is_in_group("Enemies"):
				hit_enemy = true
	if tutorial_stage == "potion_throw":
		if hit_enemy and current_scene != null and current_scene.has_method("tutorial_potion_landed"):
			current_scene.call("tutorial_potion_landed")
		elif not hit_enemy:
			var player := get_tree().get_first_node_in_group("player")
			if player != null and player.has_method("return_potion_to_inventory"):
				player.call("return_potion_to_inventory", potion_id)
			if current_scene != null and current_scene.has_method("tutorial_potion_missed"):
				current_scene.call("tutorial_potion_missed")
	var splash := Node2D.new()
	get_tree().current_scene.add_child(splash)
	splash.global_position = end_position
	var ring := Line2D.new()
	ring.closed = true
	ring.width = 3.0
	ring.default_color = Color(0.6, 0.9, 1.0, 0.9)
	var points := PackedVector2Array()
	for i in 25:
		points.append(Vector2.from_angle(TAU * float(i) / 24.0) * splash_radius)
	ring.points = points
	splash.add_child(ring)
	var tween := splash.create_tween()
	tween.tween_property(ring, "scale", Vector2(1.25, 1.25), 0.2)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.2)
	tween.tween_callback(splash.queue_free)

func _get_splash_targets(splash_radius: float) -> Array[Node]:
	var affected: Array[Node] = []
	var circle := CircleShape2D.new()
	circle.radius = splash_radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, end_position)
	query.collision_mask = 0x7FFFFFFF
	query.collide_with_areas = true
	query.collide_with_bodies = true
	for result in get_world_2d().direct_space_state.intersect_shape(query, 64):
		var node := result.get("collider") as Node
		while is_instance_valid(node) and not _is_potion_target(node):
			node = node.get_parent()
		if is_instance_valid(node) and not affected.has(node):
			affected.append(node)

	# Keep a center-distance fallback for entities whose collision layer is not
	# included in physics queries, while the shape query handles their full hitbox.
	for group_name in ["player", "enemies", "Enemies"]:
		for candidate in get_tree().get_nodes_in_group(group_name):
			if candidate is Node2D and _is_potion_target(candidate) \
				and candidate.global_position.distance_to(end_position) <= splash_radius \
				and not affected.has(candidate):
				affected.append(candidate)
	return affected

func _is_potion_target(node: Node) -> bool:
	return node.is_in_group("player") or node.is_in_group("enemies") or node.is_in_group("Enemies")

