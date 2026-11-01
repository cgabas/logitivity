extends CharacterBody2D

#woi Ray & Syafi, kamu orang boleh adjust dia punya kelajuan kat sini nanti!
const SPEED: float = 200.0
const FRAME_UNCLASS = preload("res://sprite/unclass.tres")
const FRAME_MAGE = preload("res://sprite/mage_class.tres")
const FRAME_WARRIOR = preload("res://sprite/warrior_class.tres")
const KATANA_TEXTURE = preload("res://sprite/weapon/katana_sprite.png")
const SPELL_VFX = preload("res://script/spell_vfx.gd") # Friend's new VFX feature
const BARRIER_THORN_DAMAGE: int = 12
const BARRIER_DAMAGE_MULTIPLIER: float = 0.8
const WIND_PUSH_DECELERATION: float = 1100.0
const POTION_THROW_SCRIPT := preload("res://script/potion_throw.gd")
const POTION_AIM_INDICATOR_SCRIPT := preload("res://script/potion_aim_indicator.gd")
const POTION_MIN_THROW_DISTANCE: float = 96.0
const POTION_MAX_THROW_DISTANCE: float = 360.0
const POTION_MAX_PULL_DISTANCE: float = 180.0
@export var mana_regen_per_second: float = 3.0

# --- CORE VARIABLES ---
var isAttacking: bool = false
var isAlive: bool = true
var health: float = 100.0
var maxHealth: float = 100.0
var mana: float = 100.0
var maxMana: float = 100.0
var defence: int = 0
var maxDefence: int = 100
var attack: int = 25
var maxAttack: int = 25
var crit_rate: float = 0.0
var crit_rate_before_potion: float = 0.0
var speed_potion_time_left: float = 0.0
var attack_potion_time_left: float = 0.0
var crit_potion_time_left: float = 0.0
var poison_potion_time_left: float = 0.0
var poison_potion_tick_time: float = 0.0
var selected_potion_id: String = ""
var potion_hold_active: bool = false
var mobile_potion_action: bool = false
var potion_aim_direction: Vector2 = Vector2.DOWN
var potion_throw_distance: float = POTION_MIN_THROW_DISTANCE
var potion_mouse_pull_origin: Vector2 = Vector2.ZERO
var potion_aim_indicator: Node2D = null
var recordLastDirection: Vector2 = Vector2.DOWN
var itemsInTouch: int = 0
var currItem: Area2D = null
var equipped_warrior_skill: String = "flash_step"
var water_barrier_time_left: float = 0.0
var fire_barrier_time_left: float = 0.0
var wind_push_velocity: Vector2 = Vector2.ZERO
var earth_barrier: StaticBody2D = null
var water_barrier_visual: Line2D = null
var fire_barrier_visual: Line2D = null

# --- KATANA VARIABLES ---
var katanaBaseOffset: Vector2 = Vector2.ZERO
var katanaBaseRotation: float = 0.0
var katanaBaseScale: Vector2 = Vector2.ONE
var katanaFloatTime: float = 0.0
var isKatanaSwinging: bool = false

# --- FLASH STEP VARIABLES ---
var isDashing: bool = false
var dashSpeed: float = 900.0
var enemiesHitInDash: Array = []

# --- ONREADY NODES ---
@onready var playerAnimationClass: AnimatedSprite2D = $playerAnimatedSprite
@onready var katanaSprite: AnimatedSprite2D = $WarriorKatana # Re-linked to your Scene Tree Node
@onready var playerRange: Area2D = $playerRange
@onready var playerRangeShape: CollisionShape2D = $playerRange/range
@onready var hint: Sprite2D = $hint
@onready var labelHint: Label = $hint/Label
@onready var playerLight: PointLight2D = $playerLight
@onready var spellCaster: Node = $spellCaster

func _ready() -> void:
	#Use the saved health value so enemy hits update the same value shown in the HUD.
	health = float(SaveManager.data["player"]["health"])
	maxHealth = float(SaveManager.data["player"]["maxHealth"])
	mana = float(SaveManager.data["player"]["caster"])
	maxMana = float(SaveManager.data["player"]["maxCaster"])
	defence = maxi(0, int(SaveManager.data["player"].get("defence", 0)))
	maxDefence = maxi(0, int(SaveManager.data["player"].get("maxDefence", 100)))
	attack = maxi(1, int(SaveManager.data["player"].get("attack", 25)))
	maxAttack = maxi(1, int(SaveManager.data["player"].get("maxAttack", 25)))
	crit_rate = clampf(float(SaveManager.data["player"].get("crit_rate", 0.0)), 0.0, 1.0)
	crit_rate_before_potion = crit_rate
	var saved_skill := str(SaveManager.data["player"].get("equipped_skill", ""))
	if not saved_skill.is_empty():
		equipped_warrior_skill = saved_skill
	var saved_facing: Dictionary = SaveManager.data["player"].get("facing_direction", {"x": 0.0, "y": 1.0})
	var facing_vector := Vector2(float(saved_facing.get("x", 0.0)), float(saved_facing.get("y", 1.0)))
	if facing_vector != Vector2.ZERO:
		recordLastDirection = facing_vector
	isAlive = health > 0.0

	#insert player inside player friendly group
	self.add_to_group("Friendly")
	self.add_to_group("player")
	self.add_to_group("allies")
	#hide input hint by default
	hint.visible = false
	#connect area detection from orbs area2d
	playerRange.area_entered.connect(playerRange_Entered)
	playerRange.area_exited.connect(playerRange_Exited)
	
	# Connect Katana animation signal
	if katanaSprite != null:
		katanaBaseScale = katanaSprite.scale
		katanaSprite.animation_finished.connect(_on_katana_anim_finished)
	# --- CONNECT BUTTON B (BASIC ATTACK) ---
	var mobile_attack_button := get_node_or_null("playerView/MobileControl/CanvasLayer/buttonB") as TouchScreenButton
	if mobile_attack_button != null:
		mobile_attack_button.action = &""
		if not mobile_attack_button.pressed.is_connected(_on_mobile_attack_pressed):
			mobile_attack_button.pressed.connect(_on_mobile_attack_pressed)
		if not mobile_attack_button.released.is_connected(_on_mobile_attack_released):
			mobile_attack_button.released.connect(_on_mobile_attack_released)

	# --- CONNECT BUTTON P (POTION THROW) ---
	var mobile_potion_button := get_node_or_null("playerView/MobileControl/CanvasLayer/buttonPotion") as TouchScreenButton
	if mobile_potion_button != null:
		mobile_potion_button.action = &""
		if not mobile_potion_button.pressed.is_connected(_on_mobile_potion_pressed):
			mobile_potion_button.pressed.connect(_on_mobile_potion_pressed)
		if not mobile_potion_button.released.is_connected(_on_mobile_potion_released):
			mobile_potion_button.released.connect(_on_mobile_potion_released)
	
	#switch class outfit based on class
	if SaveManager.data["flags"]["isFromHogward"] != null:
		playerLight.visible = true
		if SaveManager.data["flags"]["isFromHogward"]:
			# Mage Class
			playerAnimationClass.sprite_frames = FRAME_MAGE
			if katanaSprite: katanaSprite.visible = false
		else:
			# Warrior Class
			playerAnimationClass.sprite_frames = FRAME_WARRIOR
			if katanaSprite: 
				katanaSprite.visible = true
				katanaSprite.play("float")
			updateKatanaDirection()
	else:
		# Unclassed
		playerLight.visible = false
		playerAnimationClass.sprite_frames = FRAME_UNCLASS
		if katanaSprite: katanaSprite.visible = false

func _physics_process(delta: float) -> void:
	if not isAlive:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	#only update hint label text when the hint is actually visible on screen
	if hint.visible:
		labelHint.text = "Press  E" if GlobalInputDetection.inputType() == 0 else "Press  A"
	playerMovementFunction(delta)
	move_and_slide()

func _process(delta: float) -> void:
	_process_potion_timers(delta)
	if potion_hold_active:
		_update_potion_aim()
	water_barrier_time_left = maxf(0.0, water_barrier_time_left - delta)
	if water_barrier_time_left == 0.0 and is_instance_valid(water_barrier_visual):
		water_barrier_visual.queue_free()
		water_barrier_visual = null
	fire_barrier_time_left = maxf(0.0, fire_barrier_time_left - delta)
	if fire_barrier_time_left == 0.0 and is_instance_valid(fire_barrier_visual):
		fire_barrier_visual.queue_free()
		fire_barrier_visual = null

	if isAlive and mana < maxMana:
		# Regenerate the mage's mana or the warrior's energy at the same base rate.
		var real_delta := delta / maxf(Engine.time_scale, 0.01)
		set_mana(mana + mana_regen_per_second * real_delta)

	if katanaSprite != null and katanaSprite.visible:
		katanaFloatTime += delta
		katanaSprite.position = katanaBaseOffset + Vector2(0.0, sin(katanaFloatTime * 3.0) * 1.5)

#-----------------------------------------------
#              PLAYER MOVEMENT
#-----------------------------------------------
func playerMovementFunction(delta: float) -> void:
	# --- DASH PHYSICS OVERRIDE ---
	if isDashing:
		velocity = recordLastDirection * dashSpeed
		
		for area in playerRange.get_overlapping_areas():
			var enemy_node := area.get_parent()
			if enemy_node and not enemiesHitInDash.has(enemy_node) and enemy_node.has_method("takeDamage"):
				enemy_node.takeDamage(outgoing_damage(50), global_position)
				enemiesHitInDash.append(enemy_node) 
			elif area.has_method("takeDamage") and not enemiesHitInDash.has(area):
				area.takeDamage(outgoing_damage(50), global_position)
				enemiesHitInDash.append(area)
		return # Exit early so normal movement is disabled!

	# --- 1. GENERAL ACTIONS ---
	if Input.is_action_just_pressed("player_do"):
		if has_selected_potion():
			@warning_ignore("confusable_local_declaration")
			var tutorial_stage := str(SaveManager.data.get("flags", {}).get("tutorial_stage", "complete"))
			if tutorial_stage != "potion_throw":
				_drink_selected_potion()
		else:
			playerBehaviourFunction()
		
	# --- 2. CLASS-SPECIFIC ABILITIES ---
	var is_mage: bool = (SaveManager.data["flags"]["isFromHogward"] == true)
	var tutorial_stage := str(SaveManager.data.get("flags", {}).get("tutorial_stage", "complete"))
	var combat_allowed: bool = SaveManager.data.get("flags", {}).get("isTutorialDone", false) == true or tutorial_stage in ["attack", "fight", "potion_finish", "potion_throw", "potion_poison_wait", "potion_drink_select", "potion_drink"]
	
	# --test--
	if is_mage:
		# === MAGE CONTROLS ===
		if Input.is_action_just_pressed("player_attack") and combat_allowed:
			spellCaster.call("open_canvas")
	else:
		# === WARRIOR CONTROLS ===
		if Input.is_action_just_pressed("player_attack") and combat_allowed:
			playerAttackFunction()
			
	# --- INDEPENDENT SKILL CHECK (Fixed Indentation) ---
	if Input.is_action_just_pressed("player_skill") and _has_warrior_skill_unlocked():
		match equipped_warrior_skill:
			"flash_step":
				performFlashStep()
			"uppercut":
				performUppercut()
				
	# --- SEPARATED POTION THROW LOGIC FOR PC ---
	# (You will need to map a new Input map action for this, e.g., "player_throw_potion")
	if Input.is_action_just_pressed("player_throw_potion"):
		if has_selected_potion() and _can_throw_selected_potion():
			_begin_potion_action()
			
	if Input.is_action_just_released("player_throw_potion") and potion_hold_active:
		_end_potion_action()
		
	if potion_hold_active:
		velocity = Vector2.ZERO
		playerAnimationFunction(Vector2.ZERO)
		return
		
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed_multiplier := 1.2 if speed_potion_time_left > 0.0 else 1.0
	velocity = direction * SPEED * speed_multiplier + wind_push_velocity
	wind_push_velocity = wind_push_velocity.move_toward(Vector2.ZERO, WIND_PUSH_DECELERATION * delta)
	playerAnimationFunction(direction)
#-----------------------------------------------
#              PLAYER BEHAVIOUR & COMBAT
#-----------------------------------------------
func playerBehaviourFunction() -> void:
	#interact with non-combat items if needed
	if currItem != null and currItem.has_method("interact"):
		currItem.interact()

func has_selected_potion() -> bool:
	return not selected_potion_id.is_empty() and _inventory_has_potion(selected_potion_id)

func select_potion(item_id: String) -> void:
	var registry := load("res://script/item_registry.gd")
	var item_data: Dictionary = registry.get_item(item_id)
	if item_data.get("type") == "potion" and _inventory_has_potion(item_id):
		selected_potion_id = item_id
	else:
		selected_potion_id = ""

# --- PURE ATTACK BUTTON (e.g. Button B) ---
func _on_mobile_attack_pressed() -> void:
	if SaveManager.data.get("flags", {}).get("isFromHogward") != true:
		var flags: Dictionary = SaveManager.data.get("flags", {})
		var stage := str(flags.get("tutorial_stage", "complete"))
		# ADDED potion tutorial stages to the allowed combat list
		if flags.get("isTutorialDone", false) == true or stage in ["attack", "fight", "potion_finish", "potion_throw", "potion_poison_wait", "potion_drink_select", "potion_drink"]:
			playerAttackFunction()

func _on_mobile_attack_released() -> void:
	pass # Attack doesn't need a release action unless you want to add charge attacks later


# --- NEW DEDICATED POTION BUTTON ---
# Connect this to your new Mobile Potion Button's 'pressed' signal
func _on_mobile_potion_pressed() -> void:
	if has_selected_potion():
		if not _can_throw_selected_potion():
			return
		mobile_potion_action = true
		_begin_potion_action()

# Connect this to your new Mobile Potion Button's 'released' signal
func _on_mobile_potion_released() -> void:
	if mobile_potion_action:
		mobile_potion_action = false
		_end_potion_action()

func _begin_potion_action() -> void:
	if not has_selected_potion() or potion_hold_active:
		return
	potion_hold_active = true
	potion_aim_direction = recordLastDirection
	potion_throw_distance = POTION_MIN_THROW_DISTANCE
	potion_mouse_pull_origin = get_global_mouse_position()
	potion_aim_indicator = Node2D.new()
	potion_aim_indicator.name = "PotionAimIndicator"
	potion_aim_indicator.set_script(POTION_AIM_INDICATOR_SCRIPT)
	potion_aim_indicator.z_index = 40
	add_child(potion_aim_indicator)
	_update_potion_aim()

func _end_potion_action() -> void:
	if not potion_hold_active:
		return
	potion_hold_active = false
	if is_instance_valid(potion_aim_indicator):
		potion_aim_indicator.queue_free()
	potion_aim_indicator = null
	if has_selected_potion():
		_throw_selected_potion(potion_aim_direction, potion_throw_distance)

func _update_potion_aim() -> void:
	var pull_vector := Vector2.ZERO
	if GlobalInputDetection.inputType() == 0:
		pull_vector = get_global_mouse_position() - potion_mouse_pull_origin
	else:
		pull_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if pull_vector.length_squared() > 0.0001:
		var pull_strength := clampf(pull_vector.length() / POTION_MAX_PULL_DISTANCE, 0.0, 1.0)
		potion_aim_direction = -pull_vector.normalized()
		potion_throw_distance = lerpf(POTION_MIN_THROW_DISTANCE, POTION_MAX_THROW_DISTANCE, pull_strength)
	if is_instance_valid(potion_aim_indicator):
		potion_aim_indicator.call("set_aim", potion_aim_direction, potion_throw_distance)

func _drink_selected_potion() -> void:
	var potion_id := selected_potion_id
	if _consume_inventory_potion(potion_id):
		apply_potion(potion_id)
		var current_scene := get_tree().current_scene
		if current_scene != null and current_scene.has_method("tutorial_potion_drank"):
			current_scene.call("tutorial_potion_drank", potion_id)

func _can_throw_selected_potion() -> bool:
	var tutorial_stage := str(SaveManager.data.get("flags", {}).get("tutorial_stage", "complete"))
	return tutorial_stage not in ["potion_select", "potion_poison_wait", "potion_drink_select", "potion_drink"]

func _throw_selected_potion(aim_direction: Vector2, throw_distance: float) -> void:
	var potion_id := selected_potion_id
	if not _consume_inventory_potion(potion_id):
		return
	var potion := Node2D.new()
	potion.set_script(POTION_THROW_SCRIPT)
	potion.global_position = global_position
	potion.call("setup", potion_id, aim_direction, throw_distance)
	get_tree().current_scene.add_child(potion)

func return_potion_to_inventory(item_id: String) -> void:
	var item_data: Dictionary = load("res://script/item_registry.gd").get_item(item_id)
	if item_data.is_empty():
		return
	var inventory: Variant = SaveManager.data.get("inventory", [])
	if not inventory is Array:
		inventory = []
	var found := false
	for item in inventory:
		if item is Dictionary and str(item.get("id", "")) == item_id:
			item["count"] = int(item.get("count", 0)) + 1
			found = true
			break
	if not found:
		inventory.append({"id": item_id, "name": str(item_data.get("name", item_id)), "type": "potion", "count": 1})
	SaveManager.data["inventory"] = inventory
	selected_potion_id = item_id
	SaveManager.saveGame()

func _inventory_has_potion(item_id: String) -> bool:
	var items: Variant = SaveManager.data.get("inventory", [])
	if not items is Array:
		return false
	for item in items:
		if item is Dictionary and str(item.get("id", "")) == item_id and int(item.get("count", 1)) > 0:
			return true
	return false

func _consume_inventory_potion(item_id: String) -> bool:
	var items: Variant = SaveManager.data.get("inventory", [])
	if not items is Array:
		return false
	for index in range(items.size()):
		var item: Variant = items[index]
		if item is Dictionary and str(item.get("id", "")) == item_id:
			var count := int(item.get("count", 1))
			if count <= 1:
				items.remove_at(index)
			else:
				item["count"] = count - 1
			SaveManager.data["inventory"] = items
			if not _inventory_has_potion(item_id):
				selected_potion_id = ""
		SaveManager.saveGame()
		return true
	return false

func apply_potion(item_id: String) -> void:
	var effect_vfx := "heal"
	match item_id:
		"potion_healing":
			if isAlive:
				health = minf(maxHealth, health + maxf(1.0, float(roundi(maxHealth * 0.2))))
				SaveManager.data["player"]["health"] = health
		"potion_defence":
			defence = mini(maxDefence, defence + maxi(1, roundi(float(maxDefence) * 0.2)))
			SaveManager.data["player"]["defence"] = defence
		"potion_speed":
			speed_potion_time_left = 60.0
			effect_vfx = "wind"
		"potion_attack":
			attack_potion_time_left = 60.0
			effect_vfx = "fire"
		"potion_crit":
			if crit_potion_time_left <= 0.0:
				crit_rate_before_potion = crit_rate
			crit_rate = minf(1.0, crit_rate + randf_range(0.05, 0.20))
			crit_potion_time_left = 60.0
			effect_vfx = "wind"
		"potion_poison":
			poison_potion_time_left = 20.0
			poison_potion_tick_time = 0.0
			effect_vfx = "poison"
	SPELL_VFX.spawn(get_tree().current_scene, effect_vfx, global_position, 1.2)
	SaveManager.saveGame()

func _process_potion_timers(delta: float) -> void:
	speed_potion_time_left = maxf(0.0, speed_potion_time_left - delta)
	attack_potion_time_left = maxf(0.0, attack_potion_time_left - delta)
	crit_potion_time_left = maxf(0.0, crit_potion_time_left - delta)
	if crit_potion_time_left == 0.0:
		crit_rate = crit_rate_before_potion
	if poison_potion_time_left > 0.0:
		poison_potion_tick_time -= delta
		if poison_potion_tick_time <= 0.0:
			poison_potion_tick_time = 1.0
			takeDamage(5, global_position)
			SPELL_VFX.spawn(get_tree().current_scene, "poison", global_position, 0.9)
		poison_potion_time_left = maxf(0.0, poison_potion_time_left - delta)

func outgoing_damage(base_damage: int) -> int:
	var damage := float(base_damage)
	if attack_potion_time_left > 0.0:
		damage += float(roundi(float(maxAttack) * 0.2))
	if randf() < crit_rate:
		damage *= 2.0
	return maxi(1, roundi(damage))

func critical_power(base_power: float) -> float:
	var adjusted_power := base_power * (1.2 if attack_potion_time_left > 0.0 else 1.0)
	return adjusted_power * 2.0 if randf() < crit_rate else adjusted_power

#melee damage for warrior
func playerAttackFunction() -> void:
	if SaveManager.data["flags"]["isFromHogward"] == true:
		return
	if isAttacking or isDashing:
		return
		
	isAttacking = true
	playKatanaSwing()
	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene.has_method("tutorial_warrior_attack"):
		current_scene.call("tutorial_warrior_attack")
	
	#check all Area2Ds currently inside playerRange
	for area in playerRange.get_overlapping_areas():
		var enemy_node := area.get_parent()
		
		#deal 25 damage if the parent node
		if enemy_node and enemy_node.has_method("takeDamage"):
			enemy_node.takeDamage(outgoing_damage(attack), global_position)
		# Or if takeDamage() is directly on the Area2D itself
		elif area.has_method("takeDamage"):
			area.takeDamage(outgoing_damage(attack), global_position)
			
	#small 0.25s attack cooldown so the player can't spam-click infinitely
	await get_tree().create_timer(0.25).timeout
	isAttacking = false

#-----------------------------------------------
#              FLASH STEP SKILL
#-----------------------------------------------
func performFlashStep() -> void:
	if isDashing or mana < 30.0:
		return
		
	set_mana(mana - 30.0)
	isDashing = true
	enemiesHitInDash.clear() 
	
	# Turn blue and swing!
	playerAnimationClass.modulate = Color(0.5, 0.8, 2.0, 0.8)
	playKatanaSwing()
	
	await get_tree().create_timer(0.15).timeout
	
	isDashing = false
	playerAnimationClass.modulate = Color.WHITE

#-----------------------------------------------
#              UPPERCUT SKILLS
#-----------------------------------------------
func performUppercut() -> void:
	if isAttacking or isDashing or mana < 45.0:
		return
		
	set_mana(mana - 45.0)
	isAttacking = true
	
	# Windup Visuals: Turn orange/red and make the Katana massive
	playerAnimationClass.modulate = Color(1.0, 0.4, 0.0, 1.0)
	if katanaSprite != null:
		katanaSprite.scale = katanaBaseScale * 2.0
	
	playKatanaSwing()
	
	# A tiny 0.1s delay gives it that heavy, weighty Wynncraft windup feel
	await get_tree().create_timer(0.1).timeout
	
	# The Explosion: Temporarily expand the playerRange to hit a wider AoE
	playerRangeShape.scale = Vector2(2.5, 2.5)
	
	# Deal massive damage to all enemies caught in the expanded blast
	for area in playerRange.get_overlapping_areas():
		var enemy_node := area.get_parent()
		if enemy_node and enemy_node.has_method("takeDamage"):
			enemy_node.takeDamage(outgoing_damage(85), global_position) # 85 burst damage
		elif area.has_method("takeDamage"):
			area.takeDamage(outgoing_damage(85), global_position)
			
	# Cooldown and Reset
	await get_tree().create_timer(0.25).timeout
	
	# Revert hitbox, visuals, and sword size back to normal
	playerRangeShape.scale = Vector2(1.0, 1.0)
	playerAnimationClass.modulate = Color.WHITE
	if katanaSprite != null:
		katanaSprite.scale = katanaBaseScale
		
	isAttacking = false

func _has_warrior_skill_unlocked() -> bool:
	if SaveManager.data.get("flags", {}).get("isFromHogward") != false:
		return false
	var tree: Variant = SaveManager.data.get("treeOfLife", {})
	if not tree is Dictionary:
		return false
	var unlocked: Array = tree.get("unlocked_skills", [])
	return unlocked.has(equipped_warrior_skill)

#-----------------------------------------------
#              KATANA ANIMATION LOGIC
#-----------------------------------------------
func playKatanaSwing() -> void:
	if katanaSprite == null:
		return

	isKatanaSwinging = true
	katanaSprite.rotation = 0 

	match recordLastDirection:
		Vector2.UP:
			katanaSprite.play("attack_up")
		Vector2.DOWN:
			katanaSprite.play("attack_down") 
		_: 
			katanaSprite.play("basic_attack")

func _on_katana_anim_finished() -> void:
	if katanaSprite != null and katanaSprite.animation in ["basic_attack", "attack_up", "attack_down"]:
		isKatanaSwinging = false
		katanaSprite.play("float")
		updateKatanaDirection() 

func updateKatanaDirection() -> void:
	if katanaSprite == null:
		return

	match recordLastDirection:
		Vector2.UP:
			katanaBaseOffset = Vector2(0.0, -10.0)
			katanaBaseRotation = PI / 4.0
			katanaSprite.show_behind_parent = true 
		Vector2.DOWN:
			katanaBaseOffset = Vector2(0.0, 10.0)
			katanaBaseRotation = 3.0 * PI / 4.0
			katanaSprite.show_behind_parent = false 
		Vector2.LEFT:
			katanaBaseOffset = Vector2(-10.0, 0.0)
			katanaBaseRotation = -PI / 4.0
			katanaSprite.show_behind_parent = false
			katanaSprite.flip_h = false
		Vector2.RIGHT:
			katanaBaseOffset = Vector2(10.0, 0.0)
			katanaBaseRotation = PI / 4.0
			katanaSprite.show_behind_parent = false
			katanaSprite.flip_h = true

	if not isKatanaSwinging:
		katanaSprite.rotation = katanaBaseRotation

#-----------------------------------------------
#              STATS & DAMAGE
#-----------------------------------------------
func takeDamage(damage: int, _attackerGlobalPos: Vector2) -> void:
	if not isAlive or damage <= 0:
		return

	var remaining_damage := damage
	if defence > 0:
		var absorbed := mini(defence, remaining_damage)
		defence -= absorbed
		remaining_damage -= absorbed
		SaveManager.data["player"]["defence"] = defence
	if water_barrier_time_left > 0.0 or fire_barrier_time_left > 0.0:
		remaining_damage = maxi(1, roundi(float(remaining_damage) * BARRIER_DAMAGE_MULTIPLIER)) if remaining_damage > 0 else 0
	health = clampf(health - remaining_damage, 0.0, maxHealth)
	SaveManager.data["player"]["health"] = health

	#Briefly flash the player so the melee hit is visible.
	var flash_tween := create_tween()
	flash_tween.tween_property(playerAnimationClass, "modulate", Color.RED, 0.08)
	flash_tween.tween_property(playerAnimationClass, "modulate", Color.WHITE, 0.08)

	if health <= 0.0:
		isAlive = false
		velocity = Vector2.ZERO
		var player_view := get_node_or_null("playerView")
		if player_view != null and player_view.has_method("show_game_over"):
			player_view.call("show_game_over")

func takeMeleeDamage(damage: int, attacker: Node2D) -> void:
	if attacker == null or not is_instance_valid(attacker):
		return
	if is_melee_attack_blocked(attacker):
		return
	takeDamage(damage, attacker.global_position)
	if fire_barrier_time_left > 0.0 and attacker.has_method("takeDamage"):
		attacker.call("takeDamage", BARRIER_THORN_DAMAGE, global_position, 0.0)
		SPELL_VFX.spawn(get_tree().current_scene, "fire", attacker.global_position, 0.75)

func is_melee_attack_blocked(attacker: Node2D) -> bool:
	if not is_instance_valid(earth_barrier) or attacker == null:
		return false
	var query := PhysicsRayQueryParameters2D.create(attacker.global_position, global_position)
	query.exclude = [attacker.get_rid(), get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == earth_barrier

func cast_earth_barrier(duration: float = 4.0) -> void:
	if is_instance_valid(earth_barrier):
		earth_barrier.queue_free()
	var barrier := StaticBody2D.new()
	barrier.name = "EarthBarrier"
	barrier.add_to_group("player_earth_barriers")
	barrier.collision_layer = 1
	barrier.collision_mask = 1
	var direction := recordLastDirection.normalized()
	barrier.position = global_position + direction * 42.0
	barrier.rotation = PI * 0.5 if absf(direction.x) > absf(direction.y) else 0.0
	var shape_node := CollisionShape2D.new()
	var wall_shape := RectangleShape2D.new()
	wall_shape.size = Vector2(54.0, 16.0)
	shape_node.shape = wall_shape
	barrier.add_child(shape_node)
	var wall := Polygon2D.new()
	wall.polygon = PackedVector2Array([Vector2(-27, -8), Vector2(27, -8), Vector2(27, 8), Vector2(-27, 8)])
	wall.color = Color(0.48, 0.31, 0.17, 0.96)
	barrier.add_child(wall)
	var wall_edge := Line2D.new()
	wall_edge.points = PackedVector2Array([Vector2(-27, -8), Vector2(27, -8), Vector2(27, 8), Vector2(-27, 8)])
	wall_edge.closed = true
	wall_edge.width = 2.0
	wall_edge.default_color = Color(0.92, 0.7, 0.42)
	barrier.add_child(wall_edge)
	get_tree().current_scene.add_child(barrier)
	barrier.global_position = global_position + direction * 42.0
	earth_barrier = barrier
	SPELL_VFX.spawn(get_tree().current_scene, "earth", barrier.global_position, 1.4)
	get_tree().create_timer(duration).timeout.connect(_expire_earth_barrier.bind(barrier))

func _expire_earth_barrier(barrier: StaticBody2D) -> void:
	if is_instance_valid(barrier):
		barrier.queue_free()
	if earth_barrier == barrier:
		earth_barrier = null

func cast_water_barrier(duration: float = 10.0) -> void:
	water_barrier_time_left = duration
	water_barrier_visual = _ensure_barrier_visual(water_barrier_visual, Color(0.38, 0.82, 1.0, 0.78))
	SPELL_VFX.spawn(get_tree().current_scene, "water", global_position, 1.8)

func cast_fire_barrier(duration: float = 10.0) -> void:
	fire_barrier_time_left = duration
	fire_barrier_visual = _ensure_barrier_visual(fire_barrier_visual, Color(1.0, 0.34, 0.12, 0.88))
	SPELL_VFX.spawn(get_tree().current_scene, "fire", global_position, 1.8)

func _ensure_barrier_visual(existing: Line2D, barrier_color: Color) -> Line2D:
	if is_instance_valid(existing):
		existing.default_color = barrier_color
		return existing
	var ring := Line2D.new()
	ring.name = "SpellBarrierRing"
	ring.closed = true
	ring.width = 3.0
	ring.default_color = barrier_color
	ring.z_index = 2
	var points := PackedVector2Array()
	for i in 49:
		var angle := TAU * float(i) / 48.0
		points.append(Vector2.from_angle(angle) * 32.0)
	ring.points = points
	add_child(ring)
	return ring

func cast_wind_burst(direction: Vector2, power: float = 1.0) -> void:
	if direction == Vector2.ZERO:
		return
	wind_push_velocity = direction.normalized() * 650.0 * maxf(power, 0.5)
	SPELL_VFX.spawn(get_tree().current_scene, "wind", global_position, 1.8)

func set_mana(value: float) -> void:
	mana = clampf(value, 0.0, maxMana)
	SaveManager.data["player"]["caster"] = mana

func apply_spell(element: String, power: float, reach: float, _attackerGlobalPos: Vector2 = Vector2.ZERO) -> void:
	if element == "heal":
		if not isAlive:
			return
		health = minf(maxHealth, health + maxf(1.0, 30.0 * power * reach))
		SaveManager.data["player"]["health"] = health
		# --- FRIEND'S NEW VFX KEPT INTACT HERE ---
		SPELL_VFX.spawn(get_tree().current_scene, "heal", global_position, 1.5)
		var heal_tween := create_tween()
		heal_tween.tween_property(playerAnimationClass, "modulate", Color.LIME_GREEN, 0.12)
		heal_tween.tween_property(playerAnimationClass, "modulate", Color.WHITE, 0.12)
	else:
		takeDamage(maxi(1, roundi(20.0 * power)), _attackerGlobalPos)

#-----------------------------------------------
#               ITEM DETECTION
#-----------------------------------------------
func playerRange_Entered(area: Area2D) -> void:
	if area.is_in_group("Items"):
		itemsInTouch += 1
		currItem = area
		hint.visible = true
	elif area.is_in_group("Tutor"):
		playerLight.visible = false

func playerRange_Exited(area: Area2D) -> void:
	if area.is_in_group("Items"):
		itemsInTouch -= 1
		if itemsInTouch <= 0:
			itemsInTouch = 0
			currItem = null
			hint.visible = false

#-----------------------------------------------
#              PLAYER ANIMATION
#-----------------------------------------------
func playerAnimationFunction(playerDirection: Vector2) -> void:
	#1.if not moving, play the idle animation for the last facing direction and exit
	if playerDirection == Vector2.ZERO:
		playerAnimationFunction_IdleHandler(recordLastDirection)
		updateKatanaDirection()
		return
	
	#2.snap analog joystick/diagonal vectors into a clean 4-way cardinal direction
	if abs(playerDirection.x) > abs(playerDirection.y):
		recordLastDirection = Vector2.RIGHT if playerDirection.x > 0 else Vector2.LEFT
	else:
		recordLastDirection = Vector2.DOWN if playerDirection.y > 0 else Vector2.UP
	
	#3.play walk animation and update hitbox/hint offsets based on facing direction
	match recordLastDirection:
		Vector2.UP:
			playerAnimationClass.play("walk_up")
			playerRangeShape.position = Vector2(0, -13)
			hint.position = Vector2(5, 22)
		Vector2.DOWN:
			playerAnimationClass.play("walk_down")
			playerRangeShape.position = Vector2(0, 13)
			hint.position = Vector2(5, -17)
		Vector2.LEFT:
			playerAnimationClass.play("walk_left")
			playerRangeShape.position = Vector2(-13, 5)
			hint.position = Vector2(25, 5)
		Vector2.RIGHT:
			playerAnimationClass.play("walk_right")
			playerRangeShape.position = Vector2(13, 5)
			hint.position = Vector2(-15, 5)
	updateKatanaDirection()

func playerAnimationFunction_IdleHandler(lastDirection: Vector2) -> void:
	match lastDirection:
		Vector2.UP:
			playerAnimationClass.play("idle_up")
		Vector2.DOWN:
			playerAnimationClass.play("idle_down")
		Vector2.LEFT:
			playerAnimationClass.play("idle_left")
		Vector2.RIGHT:
			playerAnimationClass.play("idle_right")
		_:
			playerAnimationClass.play("idle_down")
