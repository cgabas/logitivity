extends CharacterBody2D

#woi Ray & Syafi, kamu orang boleh adjust dia punya kelajuan kat sini nanti!
const SPEED: float = 200.0
const FRAME_UNCLASS = preload("res://sprite/unclass.tres")
const FRAME_MAGE = preload("res://sprite/mage_class.tres")
const FRAME_WARRIOR = preload("res://sprite/warrior_class.tres")
const KATANA_TEXTURE = preload("res://sprite/weapon/katana_sprite.png")
@export var mana_regen_per_second: float = 3.0

var isAttacking: bool = false
var isAlive: bool = true
var health: float = 100.0
var maxHealth: float = 100.0
var mana: float = 100.0
var maxMana: float = 100.0
var recordLastDirection: Vector2 = Vector2.DOWN
var katanaSprite: AnimatedSprite2D = null
var katanaBaseOffset: Vector2 = Vector2.ZERO
var katanaBaseRotation: float = 0.0
var katanaFloatTime: float = 0.0
var isKatanaSwinging: bool = false
var katanaSwingTween: Tween = null
var itemsInTouch: int = 0
var currItem: Area2D = null

@onready var playerAnimationClass: AnimatedSprite2D = $playerAnimatedSprite
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
	
	#switch class outfit based on class
	if SaveManager.data["flags"]["isFromHogward"] != null:
		playerLight.visible = true
		if SaveManager.data["flags"]["isFromHogward"]:
			playerAnimationClass.sprite_frames = FRAME_MAGE
		else:
			playerAnimationClass.sprite_frames = FRAME_WARRIOR
			createWarriorKatana()
	else:
		playerLight.visible = false
		playerAnimationClass.sprite_frames = FRAME_UNCLASS

func _physics_process(_delta: float) -> void:
	if not isAlive:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	#only update hint label text when the hint is actually visible on screen
	if hint.visible:
		labelHint.text = "Press  E" if GlobalInputDetection.inputType() == 0 else "Press  A"
	playerMovementFunction()
	move_and_slide()

func _process(delta: float) -> void:
	if isAlive and SaveManager.data["flags"]["isFromHogward"] == true and mana < maxMana:
		# Keep regeneration steady while the spell canvas slows the game for drawing.
		var real_delta := delta / maxf(Engine.time_scale, 0.01)
		set_mana(mana + mana_regen_per_second * real_delta)

	if katanaSprite == null:
		return

	katanaFloatTime += delta
	katanaSprite.position = katanaBaseOffset + Vector2(0.0, sin(katanaFloatTime * 3.0) * 1.5)

#-----------------------------------------------
#              PLAYER MOVEMENT
#-----------------------------------------------
func playerMovementFunction() -> void:
	#1.interact with items/orbs
	if Input.is_action_just_pressed("player_do"):
		playerBehaviourFunction()
		
	#2.attack enemies
	if Input.is_action_just_pressed("player_attack"):
		if SaveManager.data["flags"]["isFromHogward"] == true:
			spellCaster.call("open_canvas")
		else:
			playerAttackFunction()
		
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	playerAnimationFunction(direction)

#-----------------------------------------------
#              PLAYER BEHAVIOUR
#-----------------------------------------------
func playerBehaviourFunction() -> void:
	#interact with non-combat items if needed
	if currItem != null and currItem.has_method("interact"):
		currItem.interact()

func playerAttackFunction() -> void:
	if isAttacking:
		return
		
	isAttacking = true
	playKatanaSwing()
	
	#check all Area2Ds currently inside playerRange
	for area in playerRange.get_overlapping_areas():
		var enemy_node := area.get_parent()
		
		#deal 25 damage if the parent node
		if enemy_node and enemy_node.has_method("takeDamage"):
			enemy_node.takeDamage(25, global_position)
		# Or if takeDamage() is directly on the Area2D itself
		elif area.has_method("takeDamage"):
			area.takeDamage(25, global_position)
			
	#small 0.25s attack cooldown so the player can't spam-click infinitely
	await get_tree().create_timer(0.25).timeout
	isAttacking = false

func createWarriorKatana() -> void:
	var katana_frames := SpriteFrames.new()
	katana_frames.add_animation("float")
	katana_frames.set_animation_loop("float", true)
	katana_frames.set_animation_speed("float", 8.0)

	for frame_index in range(7):
		var frame_texture := AtlasTexture.new()
		frame_texture.atlas = KATANA_TEXTURE
		frame_texture.region = Rect2(frame_index * 64, 0, 64, 64)
		katana_frames.add_frame("float", frame_texture)

	katanaSprite = AnimatedSprite2D.new()
	katanaSprite.name = "warriorKatana"
	katanaSprite.sprite_frames = katana_frames
	katanaSprite.animation = "float"
	katanaSprite.scale = Vector2(0.35, 0.35)
	katanaSprite.flip_h = true
	add_child(katanaSprite)
	katanaSprite.play()
	updateKatanaDirection()

func playKatanaSwing() -> void:
	if katanaSprite == null:
		return

	if katanaSwingTween != null and katanaSwingTween.is_running():
		katanaSwingTween.kill()

	isKatanaSwinging = true
	katanaSprite.rotation = katanaBaseRotation - PI / 3.0
	katanaSwingTween = create_tween()
	katanaSwingTween.tween_property(katanaSprite, "rotation", katanaBaseRotation + PI / 3.0, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	katanaSwingTween.tween_property(katanaSprite, "rotation", katanaBaseRotation, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	katanaSwingTween.tween_callback(func() -> void:
		isKatanaSwinging = false
		katanaSprite.rotation = katanaBaseRotation
	)

func updateKatanaDirection() -> void:
	if katanaSprite == null:
		return

	match recordLastDirection:
		Vector2.UP:
			katanaBaseOffset = Vector2(0.0, -17.0)
			katanaBaseRotation = PI / 4.0
			katanaSprite.z_index = -1
		Vector2.DOWN:
			katanaBaseOffset = Vector2(0.0, 17.0)
			katanaBaseRotation = 3.0 * PI / 4.0
			katanaSprite.z_index = 1
		Vector2.LEFT:
			katanaBaseOffset = Vector2(-17.0, 0.0)
			katanaBaseRotation = -PI / 4.0
			katanaSprite.z_index = 1
		Vector2.RIGHT:
			katanaBaseOffset = Vector2(17.0, 0.0)
			katanaBaseRotation = PI / 4.0
			katanaSprite.z_index = 1

	if not isKatanaSwinging:
		katanaSprite.rotation = katanaBaseRotation

func takeDamage(damage: int, _attackerGlobalPos: Vector2) -> void:
	if not isAlive or damage <= 0:
		return

	health = clampf(health - damage, 0.0, maxHealth)
	SaveManager.data["player"]["health"] = health

	#Briefly flash the player so the melee hit is visible.
	var flash_tween := create_tween()
	flash_tween.tween_property(playerAnimationClass, "modulate", Color.RED, 0.08)
	flash_tween.tween_property(playerAnimationClass, "modulate", Color.WHITE, 0.08)

	if health <= 0.0:
		isAlive = false
		velocity = Vector2.ZERO

func set_mana(value: float) -> void:
	mana = clampf(value, 0.0, maxMana)
	SaveManager.data["player"]["caster"] = mana

func apply_spell(element: String, power: float, reach: float, _attackerGlobalPos: Vector2 = Vector2.ZERO) -> void:
	if element == "heal":
		if not isAlive:
			return
		health = minf(maxHealth, health + maxf(1.0, 30.0 * power * reach))
		SaveManager.data["player"]["health"] = health
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
