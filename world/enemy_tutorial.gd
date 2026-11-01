extends CharacterBody2D

signal died

const SPEED: float = 180.0
const KNOCKBACK_FORCE: float = 250.0
const ATTACK_RANGE: float = 80.0 #scaled collision shapes prevent the goblin getting closer than this
const ATTACK_DAMAGE: int = 15
const ATTACK_COOLDOWN: float = 1.0
const MAX_HEALTH: int = 100
const BURN_DURATION := 4.0
const POISON_DURATION := 4.0
const DAMAGE_OVER_TIME_INTERVAL := 1.0
const WET_DURATION := 3.5
const WET_SPEED_MULTIPLIER := 0.45
const WIND_KNOCKBACK_FORCE := 750.0
const SPELL_VFX = preload("res://script/spell_vfx.gd")

@export var health_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
@export var movement_multiplier: float = 1.0
@export var is_giant_boss: bool = false

var target_player: CharacterBody2D = null
var health: int = MAX_HEALTH
var max_health: int = MAX_HEALTH
var attack_damage: int = ATTACK_DAMAGE
var movement_speed: float = SPEED
var attack_range: float = ATTACK_RANGE
var defence: int = 0
var maxDefence: int = 100
var maxAttack: int = ATTACK_DAMAGE
var attack_potion_time_left := 0.0
var speed_potion_time_left := 0.0
var crit_potion_time_left := 0.0
var crit_rate := 0.0
var crit_rate_before_potion := 0.0
var isAlive: bool = true
var knockback_velocity: Vector2 = Vector2.ZERO
var attack_timer: float = 0.0
var shield_health: int = 0
var burn_time_left := 0.0
var burn_tick_time := 0.0
var burn_damage_per_tick := 0
var poison_time_left := 0.0
var poison_tick_time := 0.0
var poison_damage_per_tick := 0
var wet_time_left := 0.0

#nodes
@onready var enemyTutorialArea: Area2D = $enemyTutorialArea
@onready var enemyTutorialSprite: AnimatedSprite2D = $enemyTutorialSprite
@onready var enemyTutorialShape: CollisionShape2D = $enemyTutorialShape
@onready var enemyTutorialAreaShape: CollisionShape2D = $enemyTutorialArea/enemyTutorialAreaShape
@onready var enemyHealthBar: TextureProgressBar = $enemyHealthBar

func _ready() -> void:
	add_to_group("Enemies")
	add_to_group("enemies")
	max_health = maxi(1, roundi(float(MAX_HEALTH) * maxf(health_multiplier, 0.1)))
	attack_damage = maxi(1, roundi(float(ATTACK_DAMAGE) * maxf(damage_multiplier, 0.1)))
	movement_speed = SPEED * maxf(movement_multiplier, 0.1)
	attack_range = ATTACK_RANGE * (1.35 if is_giant_boss else 1.0)
	var enemy_defaults: Dictionary = SaveManager.data.get("enemy_defaults", {})
	maxDefence = maxi(0, int(enemy_defaults.get("maxDefence", 100)))
	if is_giant_boss:
		maxDefence *= 10
	defence = maxi(0, int(enemy_defaults.get("defence", 0)))
	maxAttack = maxi(1, int(enemy_defaults.get("maxAttack", ATTACK_DAMAGE)))
	if is_giant_boss:
		maxAttack *= 10
		health = max_health
	var saved_enemy: Dictionary = _get_saved_enemy_data()
	if not saved_enemy.is_empty():
		if saved_enemy.get("is_alive", true) != true:
			queue_free()
			return
		var saved_position: Dictionary = saved_enemy.get("position", {})
		if saved_position.has("x") and saved_position.has("y"):
			global_position = Vector2(float(saved_position["x"]), float(saved_position["y"]))
		health = clampi(int(saved_enemy.get("health", max_health)), 0, max_health)
		shield_health = maxi(0, int(saved_enemy.get("shield_health", 0)))
		defence = maxi(0, int(saved_enemy.get("defence", defence)))
		attack_potion_time_left = maxf(0.0, float(saved_enemy.get("attack_potion_time_left", 0.0)))
		speed_potion_time_left = maxf(0.0, float(saved_enemy.get("speed_potion_time_left", 0.0)))
		crit_potion_time_left = maxf(0.0, float(saved_enemy.get("crit_potion_time_left", 0.0)))
		crit_rate = clampf(float(saved_enemy.get("crit_rate", 0.0)), 0.0, 1.0)
		crit_rate_before_potion = float(saved_enemy.get("crit_rate_before_potion", crit_rate))
		burn_time_left = maxf(0.0, float(saved_enemy.get("burn_time_left", 0.0)))
		burn_tick_time = maxf(0.0, float(saved_enemy.get("burn_tick_time", 0.0)))
		burn_damage_per_tick = maxi(0, int(saved_enemy.get("burn_damage_per_tick", 0)))
		poison_time_left = maxf(0.0, float(saved_enemy.get("poison_time_left", 0.0)))
		poison_tick_time = maxf(0.0, float(saved_enemy.get("poison_tick_time", 0.0)))
		poison_damage_per_tick = maxi(0, int(saved_enemy.get("poison_damage_per_tick", 0)))
		wet_time_left = maxf(0.0, float(saved_enemy.get("wet_time_left", 0.0)))
		if saved_enemy.has("facing_left"):
			enemyTutorialSprite.flip_h = saved_enemy["facing_left"] == true
	enemyHealthBar.max_value = max_health
	enemyHealthBar.value = health
	enemyTutorialSprite.play("idle")
	
	#connect signals via code safely
	if not enemyTutorialArea.area_entered.is_connected(_on_enemy_tutorial_area_area_entered):
		enemyTutorialArea.area_entered.connect(_on_enemy_tutorial_area_area_entered)
	if not enemyTutorialArea.area_exited.is_connected(_on_enemy_tutorial_area_area_exited):
		enemyTutorialArea.area_exited.connect(_on_enemy_tutorial_area_area_exited)

func _physics_process(delta: float) -> void:
	if not isAlive:
		return
	_process_spell_status(delta)
	var current_scene := get_tree().current_scene
	if current_scene != null and str(current_scene.get("tutorial_stage")) == "potion_poison_wait":
		velocity = Vector2.ZERO
		enemyTutorialSprite.play("idle")
		move_and_slide()
		return
	attack_potion_time_left = maxf(0.0, attack_potion_time_left - delta)
	speed_potion_time_left = maxf(0.0, speed_potion_time_left - delta)
	crit_potion_time_left = maxf(0.0, crit_potion_time_left - delta)
	if crit_potion_time_left == 0.0:
		crit_rate = crit_rate_before_potion
		
	if attack_timer > 0.0:
		attack_timer -= delta
		
	#1.handle knockback smoothly
	if knockback_velocity.length() > 5.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 800.0 * delta)
		move_and_slide()
		return

	#2.chase and attack if the player is alive and in range
	if target_player != null and target_player.get("isAlive") != false:
		chaseAndAttack()
	else:
		velocity = Vector2.ZERO
		enemyTutorialSprite.play("idle")
		
	move_and_slide()

#===================================
#          AREA DETECTION
#===================================
func _on_enemy_tutorial_area_area_entered(area: Area2D) -> void:
	if not isAlive:
		return
	if area.name == "playerRange" or area.name == "playerHitbox" or area.is_in_group("Friendly"):
		#area.get_parent() grabs the actual Player CharacterBody2D node!
		if area.get_parent() is CharacterBody2D:
			target_player = area.get_parent()

func _on_enemy_tutorial_area_area_exited(area: Area2D) -> void:
	if target_player != null and area.get_parent() == target_player:
		target_player = null
		velocity = Vector2.ZERO
		if isAlive:
			enemyTutorialSprite.play("idle")

#===================================
#        COMBAT & MOVEMENT
#===================================
func chaseAndAttack() -> void:
	var distance_to_player := global_position.distance_to(target_player.global_position)
	var direction := global_position.direction_to(target_player.global_position)
	
	#flip goblin sprite horizontally to face the player
	if direction.x != 0:
		enemyTutorialSprite.flip_h = (direction.x < 0)
	
	#chase if outside attack reach
	if distance_to_player > attack_range:
		var speed_multiplier := WET_SPEED_MULTIPLIER if wet_time_left > 0.0 else 1.0
		if speed_potion_time_left > 0.0:
			speed_multiplier *= 1.2
		velocity = direction * movement_speed * speed_multiplier
		if enemyTutorialSprite.sprite_frames.has_animation("walk"):
			enemyTutorialSprite.play("walk")
		else:
			enemyTutorialSprite.play("attack")
	else:
		#within reach -> Stop moving and attack the player on cooldown
		velocity = Vector2.ZERO
		enemyTutorialSprite.play("attack")
		
		if attack_timer <= 0.0:
			if target_player.has_method("is_melee_attack_blocked") \
				and target_player.call("is_melee_attack_blocked", self):
				attack_timer = ATTACK_COOLDOWN
			elif target_player.has_method("takeMeleeDamage"):
				var outgoing_damage := attack_damage + (maxi(1, roundi(float(maxAttack) * 0.2)) if attack_potion_time_left > 0.0 else 0)
				if randf() < crit_rate:
					outgoing_damage *= 2
				target_player.call("takeMeleeDamage", outgoing_damage, self)
				attack_timer = ATTACK_COOLDOWN
			elif target_player.has_method("takeDamage"):
				target_player.takeDamage(attack_damage, global_position)
			attack_timer = ATTACK_COOLDOWN

func takeDamage(damage: int, attackerGlobalPos: Vector2, knockback_force: float = KNOCKBACK_FORCE, bypass_shield: bool = false) -> void:
	if not isAlive:
		return
	var remaining_damage := maxi(damage, 0)
	if not bypass_shield and defence > 0:
		var defence_absorbed := mini(defence, remaining_damage)
		defence -= defence_absorbed
		remaining_damage -= defence_absorbed
		if remaining_damage <= 0:
			_flash_hit(Color.DODGER_BLUE)
			return
	if not bypass_shield and shield_health > 0:
		var shield_absorbed := mini(shield_health, remaining_damage)
		shield_health -= shield_absorbed
		remaining_damage -= shield_absorbed
		if remaining_damage <= 0:
			_flash_hit(Color.DODGER_BLUE)
			return

	health = maxi(0, health - remaining_damage)
	enemyHealthBar.value = health
	
	#flash red briefly when hit
	_flash_hit(Color.RED)
	
	if health <= 0:
		die()
	elif knockback_force > 0.0:
		var knockback_dir := attackerGlobalPos.direction_to(global_position)
		knockback_velocity = knockback_dir * knockback_force

func _flash_hit(color: Color) -> void:
	var flash_tween := create_tween()
	flash_tween.tween_property(enemyTutorialSprite, "modulate", color, 0.08)
	flash_tween.tween_property(enemyTutorialSprite, "modulate", Color.WHITE, 0.08)

func apply_spell(element: String, power: float, reach: float, attackerGlobalPos: Vector2 = Vector2.ZERO) -> void:
	if not isAlive:
		return
	var spell_power := maxf(power, 0.1) * maxf(reach, 0.1)
	match element:
		"heal":
			health = mini(max_health, health + maxi(1, roundi(30.0 * spell_power)))
			enemyHealthBar.value = health
			SPELL_VFX.spawn(get_tree().current_scene, "heal", global_position, 1.5)
			_flash_hit(Color.LIME_GREEN)
		"fire":
			SPELL_VFX.spawn(get_tree().current_scene, "fire", global_position, 1.5)
			takeDamage(maxi(1, roundi(10.0 * spell_power)), attackerGlobalPos)
			if isAlive:
				burn_damage_per_tick = maxi(burn_damage_per_tick, maxi(1, roundi(4.0 * spell_power)))
				burn_time_left = maxf(burn_time_left, BURN_DURATION)
				burn_tick_time = DAMAGE_OVER_TIME_INTERVAL
		"water":
			SPELL_VFX.spawn(get_tree().current_scene, "water", global_position, 1.5)
			# Water hits directly as well as applying its wet slow effect.
			takeDamage(maxi(1, roundi(12.0 * spell_power)), attackerGlobalPos)
			if not isAlive:
				return
			wet_time_left = maxf(wet_time_left, WET_DURATION)
		"earth":
			SPELL_VFX.spawn(get_tree().current_scene, "earth", global_position, 1.8, 4)
			takeDamage(maxi(1, roundi(24.0 * spell_power)), attackerGlobalPos)
		"wind":
			SPELL_VFX.spawn(get_tree().current_scene, "wind", global_position, 1.6)
			takeDamage(maxi(1, roundi(18.0 * spell_power)), attackerGlobalPos, WIND_KNOCKBACK_FORCE)
		"poison":
			SPELL_VFX.spawn(get_tree().current_scene, "poison", global_position, 1.5)
			poison_damage_per_tick = maxi(poison_damage_per_tick, maxi(1, roundi(5.0 * spell_power)))
			poison_time_left = maxf(poison_time_left, POISON_DURATION)
			poison_tick_time = DAMAGE_OVER_TIME_INTERVAL

func apply_potion(item_id: String) -> void:
	if not isAlive:
		return
	match item_id:
		"potion_healing":
			health = mini(max_health, health + maxi(1, roundi(float(max_health) * 0.2)))
			enemyHealthBar.value = health
			SPELL_VFX.spawn(get_tree().current_scene, "heal", global_position, 1.2)
		"potion_defence":
			defence = mini(maxDefence, defence + maxi(1, roundi(float(maxDefence) * 0.2)))
			SPELL_VFX.spawn(get_tree().current_scene, "earth", global_position, 1.2)
		"potion_speed":
			speed_potion_time_left = 60.0
			SPELL_VFX.spawn(get_tree().current_scene, "wind", global_position, 1.2)
		"potion_attack":
			attack_potion_time_left = 60.0
			SPELL_VFX.spawn(get_tree().current_scene, "fire", global_position, 1.2)
		"potion_crit":
			if crit_potion_time_left <= 0.0:
				crit_rate_before_potion = crit_rate
			crit_rate = minf(1.0, crit_rate + randf_range(0.05, 0.20))
			crit_potion_time_left = 60.0
			SPELL_VFX.spawn(get_tree().current_scene, "wind", global_position, 1.2)
		"potion_poison":
			poison_damage_per_tick = maxi(poison_damage_per_tick, 5)
			poison_time_left = maxf(poison_time_left, 20.0)
			poison_tick_time = DAMAGE_OVER_TIME_INTERVAL
			SPELL_VFX.spawn(get_tree().current_scene, "poison", global_position, 1.2)
	SaveManager.saveGame()

func _process_spell_status(delta: float) -> void:
	if wet_time_left > 0.0:
		wet_time_left = maxf(0.0, wet_time_left - delta)

	if burn_time_left > 0.0:
		burn_tick_time -= delta
		if burn_tick_time <= 0.0:
			burn_tick_time = DAMAGE_OVER_TIME_INTERVAL
			takeDamage(burn_damage_per_tick, global_position, 0.0)
			if isAlive:
				SPELL_VFX.spawn(get_tree().current_scene, "fire", global_position, 1.0)
		burn_time_left = maxf(0.0, burn_time_left - delta)
		if burn_time_left == 0.0:
			burn_damage_per_tick = 0

	if poison_time_left > 0.0:
		poison_tick_time -= delta
		if poison_tick_time <= 0.0:
			poison_tick_time = DAMAGE_OVER_TIME_INTERVAL
			takeDamage(poison_damage_per_tick, global_position, 0.0, true)
			if isAlive:
				SPELL_VFX.spawn(get_tree().current_scene, "poison", global_position, 1.0)
		poison_time_left = maxf(0.0, poison_time_left - delta)
		if poison_time_left == 0.0:
			poison_damage_per_tick = 0

func die() -> void:
	isAlive = false
	velocity = Vector2.ZERO
	died.emit()
	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene.has_method("tutorial_enemy_defeated"):
		current_scene.call("tutorial_enemy_defeated")
	
	#disable collisions and hide health bar
	enemyTutorialShape.set_deferred("disabled", true)
	enemyTutorialAreaShape.set_deferred("disabled", true)
	enemyHealthBar.hide()
	SaveManager.saveGame()
	
	#force the "death" animation not to loop, play it, and freeze on the last frame
	enemyTutorialSprite.sprite_frames.set_animation_loop("death", false)
	enemyTutorialSprite.play("death")
	await enemyTutorialSprite.animation_finished
	
	var last_frame_idx := enemyTutorialSprite.sprite_frames.get_frame_count("death") - 1
	enemyTutorialSprite.pause()
	enemyTutorialSprite.frame = last_frame_idx

func _get_saved_enemy_data() -> Dictionary:
	var current_scene := get_tree().current_scene
	if current_scene == null or not SaveManager.data.has("enemies"):
		return {}
	var enemy_key := current_scene.scene_file_path + "::" + str(current_scene.get_path_to(self))
	var saved: Variant = SaveManager.data["enemies"].get(enemy_key, {})
	return saved if saved is Dictionary else {}

func get_save_data() -> Dictionary:
	return {
		"is_alive": isAlive,
		"health": health,
		"max_health": max_health,
		"position": {"x": global_position.x, "y": global_position.y},
		"shield_health": shield_health,
		"defence": defence,
		"attack_potion_time_left": attack_potion_time_left,
		"speed_potion_time_left": speed_potion_time_left,
		"crit_potion_time_left": crit_potion_time_left,
		"crit_rate": crit_rate,
		"crit_rate_before_potion": crit_rate_before_potion,
		"facing_left": enemyTutorialSprite.flip_h,
		"burn_time_left": burn_time_left,
		"burn_tick_time": burn_tick_time,
		"burn_damage_per_tick": burn_damage_per_tick,
		"poison_time_left": poison_time_left,
		"poison_tick_time": poison_tick_time,
		"poison_damage_per_tick": poison_damage_per_tick,
		"wet_time_left": wet_time_left
	}
