extends CharacterBody2D

#woi Ray & Syafi, kamu orang boleh adjust dia punya kelajuan kat sini nanti!
const SPEED: float = 300.0
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

func _ready() -> void:
	hint.visible = false
	#connect area detection from orbs area2d
	playerRange.area_entered.connect(playerRange_Entered)
	playerRange.area_exited.connect(playerRange_Exited)
	
	#switch class outfit based on class
	if SaveManager.data["flags"]["isFromHogward"] != null:
		if SaveManager.data["flags"]["isFromHogward"]:
			playerAnimationClass.sprite_frames = FRAME_MAGE
		else:
			playerAnimationClass.sprite_frames = FRAME_WARRIOR
	else:
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
	if Input.is_action_just_pressed("player_do"):
		playerBehaviourFunction()
		
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	playerAnimationFunction(direction)

#-----------------------------------------------
#              PLAYER BEHAVIOUR
#-----------------------------------------------
func playerBehaviourFunction() -> void:
	pass

#-----------------------------------------------
#               ITEM DETECTION
#-----------------------------------------------
func playerRange_Entered(area: Area2D) -> void:
	if area.is_in_group("Items"):
		itemsInTouch += 1
		currItem = area
		hint.visible = true

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
			hint.position = Vector2(-57.5, -105)
		Vector2.LEFT:
			playerAnimationClass.play("walk_left")
			playerRangeShape.position = Vector2(-13, 5)
			hint.position = Vector2(25, 5)
		Vector2.RIGHT:
			playerAnimationClass.play("walk_right")
			playerRangeShape.position = Vector2(13, 5)
			hint.position = Vector2(5, -17)

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
