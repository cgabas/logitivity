extends Node

@export var player: Node2D
@export var canvas: Control
@export var projectile_scene: PackedScene
@export var burst_scene: PackedScene
@export var backfire_fx: PackedScene
@export var use_drawn_direction := true

const PROJECTILE_SCRIPT = preload("res://script/projectile.gd")
const BURST_SCRIPT = preload("res://script/burst.gd")
const SPELL_FLASH_SCRIPT = preload("res://script/spell_flash.gd")
const FIZZLE_COST := 5.0
const MISCAST_RISK := {"fire": 0.55, "earth": 0.4, "water": 0.3, "wind": 0.35, "poison": 0.7, "heal": 0.25}
const MISCAST_DAMAGE := {"fire": 12, "earth": 10, "water": 7, "wind": 8, "poison": 16, "heal": 6}

var parser := SpellParser.new()

func _ready() -> void:
	if player == null:
		player = get_parent() as Node2D
	if canvas == null and player != null:
		canvas = player.get_node_or_null("playerView/mageCanvasUI") as Control
	if player == null or canvas == null:
		push_error("SpellCaster needs a player parent and playerView/mageCanvasUI.")
		return

	if not canvas.is_connected("cast_requested", _on_cast):
		canvas.connect("cast_requested", _on_cast)
	canvas.hide()
	if _is_mage():
		_ensure_open_spell_action()
		var mobile_spell_button := player.get_node_or_null("playerView/MobileControl/CanvasLayer/buttonB") as TouchScreenButton
		if mobile_spell_button != null:
			mobile_spell_button.action = "open_spell"
			if not mobile_spell_button.pressed.is_connected(open_canvas):
				mobile_spell_button.pressed.connect(open_canvas)

func _unhandled_input(event: InputEvent) -> void:
	if _is_mage() and canvas != null and event.is_action_pressed("open_spell") and not canvas.visible:
		open_canvas()
		get_viewport().set_input_as_handled()

func open_canvas() -> void:
	if _is_mage() and canvas != null and not canvas.visible:
		canvas.call("open")

func _ensure_open_spell_action() -> void:
	if not InputMap.has_action("open_spell"):
		InputMap.add_action("open_spell")
	if InputMap.action_get_events("open_spell").is_empty():
		var key_event := InputEventKey.new()
		key_event.physical_keycode = KEY_Q
		InputMap.action_add_event("open_spell", key_event)

func _is_mage() -> bool:
	return player != null and SaveManager.data["flags"]["isFromHogward"] == true

func _on_cast(strokes: Array, center: Vector2, radius: float) -> void:
	var spell := parser.parse(strokes, center, radius)
	canvas.call("close")
	if player == null or not player.has_method("set_mana"):
		return

	if not spell.valid:
		_fizzle(FIZZLE_COST, spell.fail_reason)
		_maybe_miscast(spell)
		return
	var current_mana := float(player.get("mana"))
	if current_mana < spell.mana_cost:
		_fizzle(minf(FIZZLE_COST, current_mana), "not enough mana")
		return
	_set_mana(current_mana - spell.mana_cost)
	if _maybe_miscast(spell):
		return

	var quality_power := lerpf(0.5, 1.0, clampf(spell.quality, 0.0, 1.0))
	var power := quality_power * spell.strength
	_spawn_cast_flash(spell.sigil)
	match spell.outline:
		"line", "seal":
			_backfire(spell, power)
		"arrow":
			_cast_arrow(spell, power)
		"asterisk":
			_cast_burst(spell, power)
		_:
			_fizzle(FIZZLE_COST, "unsupported spell outline")

func _maybe_miscast(spell: SpellData) -> bool:
	if not MISCAST_RISK.has(spell.sigil):
		return false
	# Poorly drawn circles and outlines make the spell unstable. Better drawings
	# reduce the chance to zero; poison and fire have the strongest backlash.
	var instability := clampf((0.75 - spell.quality) / 0.75, 0.0, 1.0)
	if spell.sigil_score < 0.45:
		instability = maxf(instability, clampf((0.45 - spell.sigil_score) / 0.45, 0.0, 1.0))
	var chance := float(MISCAST_RISK[spell.sigil]) * instability
	if chance <= 0.0 or randf() >= chance:
		return false
	var damage := int(MISCAST_DAMAGE[spell.sigil])
	if player.has_method("takeDamage"):
		player.call("takeDamage", damage, player.global_position)
	_spawn_cast_flash(spell.sigil)
	print("Miscast! ", spell.sigil, " spell hurt its caster.")
	return true

func _cast_arrow(spell: SpellData, power: float) -> void:
	var aim_directions := spell.aims.duplicate()
	if not use_drawn_direction or aim_directions.is_empty():
		aim_directions = [_dir_to_nearest_enemy()]
	for dir in aim_directions:
		var p := _make_effect(projectile_scene, PROJECTILE_SCRIPT, 8.0)
		get_tree().current_scene.add_child(p)
		p.global_position = player.global_position
		p.call("setup", spell.sigil, dir, 300.0 * spell.reach, power)
		await get_tree().create_timer(0.08).timeout

func _cast_burst(spell: SpellData, power: float) -> void:
	var b := _make_effect(burst_scene, BURST_SCRIPT, 32.0)
	get_tree().current_scene.add_child(b)
	b.global_position = player.global_position
	b.call("setup", spell.sigil, 120.0 * spell.reach, power)

func _spawn_cast_flash(element: String) -> void:
	var flash := Node2D.new()
	flash.set_script(SPELL_FLASH_SCRIPT)
	flash.z_index = 6
	get_tree().current_scene.add_child(flash)
	flash.global_position = player.global_position
	flash.call("setup", element, 48.0)

func _backfire(spell: SpellData, power: float) -> void:
	if backfire_fx:
		var fx := backfire_fx.instantiate()
		get_tree().current_scene.add_child(fx)
		fx.global_position = player.global_position
	player.call("apply_spell", spell.sigil, power * 0.8, 1.0)

func _fizzle(mana_lost: float, reason: String) -> void:
	if player != null and player.has_method("set_mana"):
		_set_mana(float(player.get("mana")) - mana_lost)
	print("Fizzle: ", reason)

func _set_mana(value: float) -> void:
	player.call("set_mana", value)

func _make_effect(scene: PackedScene, effect_script: Script, collision_radius: float) -> Area2D:
	var effect: Area2D
	if scene != null:
		effect = scene.instantiate() as Area2D
	else:
		effect = Area2D.new()
		effect.set_script(effect_script)
		var collision := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = collision_radius
		collision.shape = circle
		effect.add_child(collision)
	effect.collision_layer = 0
	effect.collision_mask = 1
	effect.z_index = 5
	return effect

func _dir_to_nearest_enemy() -> Vector2:
	var best := Vector2.RIGHT
	var best_d := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		var d := player.global_position.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = (e.global_position - player.global_position).normalized()
	return best
