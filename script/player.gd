extends CharacterBody2D

#woi Ray & Syafi, kamu orang boleh adjust dia punya kelajuan kat sini nanti!
const SPEED = 300.0
var isAttacking: bool = false
var recordLastDirection: Vector2 = Vector2.ZERO
@onready var playerAnimationClass: AnimatedSprite2D = $playerAnimatedSprite

func _ready() -> void:
	pass

#main function for this sprite
func _physics_process(_delta: float) -> void:
	playerMovementFunction()
	move_and_slide()

#-----------------------------------------------
#              PLAYER MOVEMENT
#-----------------------------------------------
#process player's movement
func playerMovementFunction() -> void:
	#peform player behaviour
	if Input.is_action_just_pressed("player_do"):
		playerBehaviourFunction()
		#peform player movement
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	#pass direction(which contain vector2D) and call this function to 
	playerAnimationFunction(direction)

#-----------------------------------------------
#              PLAYER BEHAVIOUR
#-----------------------------------------------
func playerBehaviourFunction() -> void:
	pass

#-----------------------------------------------
#              PLAYER ANIMATION
#-----------------------------------------------
#to peform sprite animation based on user behaviour
#take vector 2d as argument
func playerAnimationFunction(playerDirection: Vector2) -> void:
	#NOTE: if the up/down sprite texture is avaliable, change this code later(this one is just for testing)
	#if player vector is 0, then the game will assume that there are no movement thus playing idle animation
	#only record when vector is not zero
	if playerDirection != Vector2.ZERO:
		if recordLastDirection.x == 0 || recordLastDirection.y == 0:
			recordLastDirection = playerDirection
		else:
			#handle diagonal movement
			if abs(playerDirection.x) > abs(playerDirection.y):
				recordLastDirection = Vector2.UP
			else:
				recordLastDirection = Vector2.DOWN
	
	#handle movement direction
	match playerDirection:
		Vector2.UP:
			playerAnimationClass.play("walk_up")
		Vector2.DOWN:
			playerAnimationClass.play("walk_down")
		Vector2.LEFT:
			playerAnimationClass.play("walk_left")
		Vector2.RIGHT:
			playerAnimationClass.play("walk_right")
		Vector2.ZERO:
			playerAnimationFunction_IdleHandler(recordLastDirection)

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
