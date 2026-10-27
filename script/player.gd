extends CharacterBody2D

#woi Ray & Syafi, kamu orang boleh adjust dia punya kelajuan kat sini nanti!
const SPEED: float = 200.0
const FRAME_UNCLASS = preload("res://sprite/unclass.tres")
const FRAME_MAGE = preload("res://sprite/mage_class.tres")
const FRAME_WARRIOR = preload("res://sprite/warrior_class.tres")

var isAttacking: bool = false
var recordLastDirection: Vector2 = Vector2.DOWN
var itemsInTouch: int = 0
var currItem: Area2D = null

@onready var playerAnimationClass: AnimatedSprite2D = $playerAnimatedSprite
@onready var playerRange: Area2D = $playerRange
@onready var playerRangeShape: CollisionShape2D = $playerRange/range
@onready var hint: Sprite2D = $hint
@onready var labelHint: Label = $hint/Label
@onready var playerLight: PointLight2D = $playerLight

func _ready() -> void:
	#insert player inside player friendly group
	self.add_to_group("Friendly")
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
	else:
		playerLight.visible = false
		playerAnimationClass.sprite_frames = FRAME_UNCLASS

func _physics_process(_delta: float) -> void:
	#only update hint label text when the hint is actually visible on screen
	if hint.visible:
		labelHint.text = "Press  E" if GlobalInputDetection.inputType() == 0 else "Press  A"
	playerMovementFunction()
	move_and_slide()

#-----------------------------------------------
#              PLAYER MOVEMENT
#-----------------------------------------------
func playerMovementFunction() -> void:
	#1.interact with items/orbs
	if Input.is_action_just_pressed("player_do"):
		playerBehaviourFunction()
		
	#2.attack enemies
	if Input.is_action_just_pressed("player_attack"):
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
