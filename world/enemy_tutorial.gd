extends CharacterBody2D

const SPEED: float = 180.0
const KNOCKBACK_FORCE: float = 250.0
const ATTACK_RANGE: float = 80.0 #scaled collision shapes prevent the goblin getting closer than this
const ATTACK_DAMAGE: int = 15
const ATTACK_COOLDOWN: float = 1.0

var target_player: CharacterBody2D = null
var health: int = 100
var isAlive: bool = true
var knockback_velocity: Vector2 = Vector2.ZERO
var attack_timer: float = 0.0

#nodes
@onready var enemyTutorialArea: Area2D = $enemyTutorialArea
@onready var enemyTutorialSprite: AnimatedSprite2D = $enemyTutorialSprite
@onready var enemyTutorialShape: CollisionShape2D = $enemyTutorialShape
@onready var enemyTutorialAreaShape: CollisionShape2D = $enemyTutorialArea/enemyTutorialAreaShape
@onready var enemyHealthBar: TextureProgressBar = $enemyHealthBar

func _ready() -> void:
	add_to_group("Enemies")
	add_to_group("enemies")
	enemyHealthBar.max_value = health
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
	if distance_to_player > ATTACK_RANGE:
		velocity = direction * SPEED
		if enemyTutorialSprite.sprite_frames.has_animation("walk"):
			enemyTutorialSprite.play("walk")
		else:
			enemyTutorialSprite.play("attack")
	else:
		#within reach -> Stop moving and attack the player on cooldown
		velocity = Vector2.ZERO
		enemyTutorialSprite.play("attack")
		
		if attack_timer <= 0.0:
			if target_player.has_method("takeDamage"):
				target_player.takeDamage(ATTACK_DAMAGE, global_position)
			attack_timer = ATTACK_COOLDOWN

func takeDamage(damage: int, attackerGlobalPos: Vector2) -> void:
	if not isAlive:
		return
		
	health -= damage
	enemyHealthBar.value = health
	
	#flash red briefly when hit
	var flash_tween := create_tween()
	flash_tween.tween_property(enemyTutorialSprite, "modulate", Color.RED, 0.08)
	flash_tween.tween_property(enemyTutorialSprite, "modulate", Color.WHITE, 0.08)
	
	if health <= 0:
		die()
	else:
		var knockback_dir := attackerGlobalPos.direction_to(global_position)
		knockback_velocity = knockback_dir * KNOCKBACK_FORCE

func apply_spell(element: String, power: float, _reach: float, attackerGlobalPos: Vector2 = Vector2.ZERO) -> void:
	if not isAlive or element == "heal":
		return
	var damage := maxi(1, roundi(20.0 * power))
	takeDamage(damage, attackerGlobalPos)

func die() -> void:
	isAlive = false
	velocity = Vector2.ZERO
	
	#disable collisions and hide health bar
	enemyTutorialShape.set_deferred("disabled", true)
	enemyTutorialAreaShape.set_deferred("disabled", true)
	enemyHealthBar.hide()
	
	#force the "death" animation not to loop, play it, and freeze on the last frame
	enemyTutorialSprite.sprite_frames.set_animation_loop("death", false)
	enemyTutorialSprite.play("death")
	await enemyTutorialSprite.animation_finished
	
	var last_frame_idx := enemyTutorialSprite.sprite_frames.get_frame_count("death") - 1
	enemyTutorialSprite.pause()
	enemyTutorialSprite.frame = last_frame_idx
