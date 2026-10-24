extends CharacterBody2D

#woi Ray & Syafi, kamu orang boleh adjust dia punya kelajuan kat sini nanti!
const SPEED = 300.0
var isAttacking: bool = false
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
	if playerDirection.x != 0 || playerDirection.y != 0:
		playerAnimationClass.play("run")
		#determine the direction based on the value of x inside this vector
		if playerDirection.x > 0:
			playerAnimationClass.flip_h = false
		elif playerDirection.x < 0:
			playerAnimationClass.flip_h = true
	else:
		playerAnimationClass.play("idle")
