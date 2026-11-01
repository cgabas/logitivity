extends Node2D

@onready var player: CharacterBody2D = $player

#orb nodes & labels
@onready var warriorOrb: Area2D = $classesPick/warriorOrb
@onready var mageOrb: Area2D = $classesPick/mageOrb
@onready var warriorLabel: Label = $classesPick/warriorOrb/warriorLabel
@onready var mageLabel: Label = $classesPick/mageOrb/mageLabel
@onready var classesPick: Node2D = $classesPick

#confirmation UI nodes
@onready var classConfirmCanv: CanvasLayer = $ClassConfirmCanv
@onready var skillSelector: CanvasLayer = $ClassConfirmCanv/skill_selector
@onready var classConfirmBG: TextureRect = $ClassConfirmCanv/ClassConfirmBG
@onready var classConfirmWindow: Window = $ClassConfirmCanv/ClassConfirmWindow
@onready var windowContentMsgMage: Label = $ClassConfirmCanv/ClassConfirmWindow/VBoxContainer/CenterContainer/WindowContentMsg2
@onready var windowContentMsgWarrior: Label = $ClassConfirmCanv/ClassConfirmWindow/VBoxContainer/CenterContainer/WindowContentMsg
@onready var orbRoomLight: PointLight2D = $PointLight2D
@onready var door: TileMapLayer = $Door
@onready var tutorArea: Area2D = $TutorialArea/tutorArea
@onready var chest: Chest = $TutorialArea/Chest
@onready var tutorialEnemy: CharacterBody2D = $TutorialArea/step1/enemyTutorial
@onready var attackTutorialLabel: Label = $TutorialArea/step1/Label
var potionTutorialEnemy: CharacterBody2D = null

#true = Mage, false = Warrior, null = None selected
var selectClassType: Variant = null
var tutorial_stage := "move_to_orb"
var mage_tutorial_spells: Array[String] = []
var hall_enemy_template: CharacterBody2D = null
var hall_spawn_timer: float = 0.0
var hall_spawn_count: int = 0
var hall_boss: CharacterBody2D = null
var hall_boss_spawned: bool = false
var hall_start_y: float = 0.0
var hall_end_y: float = 0.0
var hall_center_x: float = 0.0
var hall_half_width: float = 304.0
var hall_boss_room_half_width: float = 496.0
var hall_boss_room_depth: float = 896.0
const WARRIOR_ORB_PROMPT := "Choose the Warrior orb.\nPress E / Tap A to choose."
const MAGE_ORB_PROMPT := "Choose the Mage orb.\nPress E / Tap A to choose."

func _ready() -> void:
	# Keep the warrior skill menu outside the confirmation layer, which is hidden after class selection.
	skillSelector.reparent(self)
	if is_instance_valid(tutorialEnemy):
		hall_enemy_template = tutorialEnemy.duplicate() as CharacterBody2D
		if hall_enemy_template != null:
			hall_enemy_template.name = "HallGoblinTemplate"
			hall_enemy_template.set("target_player", null)
			hall_enemy_template.set("isAlive", true)
			hall_enemy_template.set("health", 100)
	# Center the chest in the tutorial room using the tutorial area's bounds.
	var room_bounds := tutorArea.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if room_bounds != null:
		chest.position = tutorArea.position + room_bounds.position
		hall_center_x = room_bounds.global_position.x
		hall_start_y = room_bounds.global_position.y + room_bounds.shape.get_rect().size.y * 0.5
		hall_end_y = hall_start_y + 4200.0
		# Keep the default tutorial enemy beside the chest while preserving saved positions.
		var current_scene := get_tree().current_scene
		var saved_enemies: Variant = SaveManager.data.get("enemies", {})
		if current_scene != null and saved_enemies is Dictionary:
			var enemy_key := current_scene.scene_file_path + "::" + str(current_scene.get_path_to(tutorialEnemy))
			if not saved_enemies.has(enemy_key):
				tutorialEnemy.position = chest.position + Vector2(180.0, 0.0)
	_build_hall_and_boss_room()
	_update_attack_tutorial_label()
	var flags: Dictionary = SaveManager.data.get("flags", {})
	tutorial_stage = str(flags.get("tutorial_stage", "move_to_orb"))
	if flags.get("isTutorialDone", false) == true:
		tutorial_stage = "complete"
	elif tutorial_stage == "potion_finish":
		tutorial_stage = "potion_drink_select"
		SaveManager.data["flags"]["tutorial_stage"] = tutorial_stage
	elif tutorial_stage == "potion_throw":
		tutorial_stage = "potion_select"
		SaveManager.data["flags"]["tutorial_stage"] = tutorial_stage
	elif tutorial_stage == "potion_drink":
		tutorial_stage = "potion_drink_select"
		SaveManager.data["flags"]["tutorial_stage"] = tutorial_stage
	elif flags.get("isFromHogward") != null and tutorial_stage == "move_to_orb":
		tutorial_stage = "enter_room"
		SaveManager.data["flags"]["tutorial_stage"] = tutorial_stage
	#1.register orbs into the "Items" group
	warriorOrb.add_to_group("Items")
	mageOrb.add_to_group("Items")
	tutorArea.add_to_group("Tutor")
	
	#2.hide labels and popup at startup
	warriorLabel.visible = false
	mageLabel.visible = false
	showConfirmationPopup(false)
	
	#3.load saved player position (or center player on screen if no save exists)
	var saved_pos: Dictionary = SaveManager.data["player"]["position"]
	if saved_pos["x"] == null || saved_pos["y"] == null:
		player.position = get_viewport_rect().size / 2.0
	else:
		player.position = Vector2(saved_pos["x"], saved_pos["y"])
	
	#4.check if player is classless or not
	if SaveManager.data["flags"]["isFromHogward"] == null:
		door.visible = true
		door.collision_enabled = true
		orbsVisible(true)
		#5.start floating orb animations(if classless)
		orbMovingPattern()
	else:
		door.visible = false
		door.collision_enabled = false
		orbsVisible(false)
	_setup_tutorial_stage()
	if tutorial_stage == "skill_choice":
		call_deferred("_open_tutorial_skill_choice")
	elif tutorial_stage in ["potion_select", "potion_drink_select"]:
		call_deferred("_open_tutorial_potion_inventory")

func _physics_process(_delta: float) -> void:
	#open confirmation popup when pressing interact ("player_do") near an orb
	if Input.is_action_just_pressed("player_do") and selectClassType != null and tutorial_stage == "move_to_orb":
		windowContentMsgMage.visible = (selectClassType == true)
		windowContentMsgWarrior.visible = (selectClassType == false)
		showConfirmationPopup(true)

func _process(delta: float) -> void:
	_update_attack_tutorial_label()
	_update_mobile_action_buttons()
	#track player position in SaveManager while moving
	if player.velocity != Vector2.ZERO:
		SaveManager.data["player"]["position"]["x"] = player.position.x
		SaveManager.data["player"]["position"]["y"] = player.position.y
	_update_hall_encounters(delta)

func _build_hall_and_boss_room() -> void:
	if hall_start_y <= 0.0:
		return
	var source_floor := get_node_or_null("Floor") as TileMapLayer
	if source_floor == null or source_floor.tile_set == null:
		return
	var floor_layer := TileMapLayer.new()
	floor_layer.name = "CombatHallFloor"
	floor_layer.tile_set = source_floor.tile_set
	floor_layer.z_index = -1
	add_child(floor_layer)
	var tile_size := source_floor.tile_set.tile_size
	var hall_left := hall_center_x - hall_half_width
	var hall_right := hall_center_x + hall_half_width
	var floor_top := hall_start_y - float(tile_size.y)
	var floor_bottom := hall_end_y + hall_boss_room_depth
	var tile_y_start := floori(floor_top / float(tile_size.y))
	var tile_y_end := ceili(floor_bottom / float(tile_size.y))
	for y in range(tile_y_start, tile_y_end):
		var left_edge := hall_left
		var right_edge := hall_right
		if y * tile_size.y >= hall_end_y:
			left_edge = hall_center_x - hall_boss_room_half_width
			right_edge = hall_center_x + hall_boss_room_half_width
		var row_left := floori(left_edge / float(tile_size.x))
		var row_right := ceili(right_edge / float(tile_size.x))
		for x in range(row_left, row_right):
			floor_layer.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)

	_add_hall_wall("HallWestWall", Vector2(hall_center_x - hall_half_width, (hall_start_y + hall_end_y) * 0.5), Vector2(20.0, hall_end_y - hall_start_y))
	_add_hall_wall("HallEastWall", Vector2(hall_center_x + hall_half_width, (hall_start_y + hall_end_y) * 0.5), Vector2(20.0, hall_end_y - hall_start_y))
	var boss_room_center_y := hall_end_y + hall_boss_room_depth * 0.5
	_add_hall_wall("BossWestWall", Vector2(hall_center_x - hall_boss_room_half_width, boss_room_center_y), Vector2(20.0, hall_boss_room_depth))
	_add_hall_wall("BossEastWall", Vector2(hall_center_x + hall_boss_room_half_width, boss_room_center_y), Vector2(20.0, hall_boss_room_depth))
	_add_hall_wall("BossSouthWall", Vector2(hall_center_x, hall_end_y + hall_boss_room_depth), Vector2(hall_boss_room_half_width * 2.0, 20.0))

func _add_hall_wall(wall_name: String, wall_position: Vector2, wall_size: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.name = wall_name
	wall.collision_layer = 1
	wall.collision_mask = 1
	wall.position = wall_position
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = wall_size
	collision.shape = rectangle
	wall.add_child(collision)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2(-wall_size.x * 0.5, -wall_size.y * 0.5), Vector2(wall_size.x * 0.5, -wall_size.y * 0.5), Vector2(wall_size.x * 0.5, wall_size.y * 0.5), Vector2(-wall_size.x * 0.5, wall_size.y * 0.5)])
	visual.color = Color(0.16, 0.11, 0.12, 1.0)
	wall.add_child(visual)
	add_child(wall)

func _update_hall_encounters(delta: float) -> void:
	if not SaveManager.data.get("flags", {}).get("isTutorialDone", false) or hall_enemy_template == null:
		return
	var player_y := player.global_position.y
	if player_y >= hall_start_y + 96.0 and player_y < hall_end_y - 96.0:
		hall_spawn_timer -= delta
		if hall_spawn_timer <= 0.0 and _alive_hall_goblin_count() < 3:
			_spawn_hall_goblin()
			hall_spawn_timer = 4.5
	if player_y >= hall_end_y - 72.0 and not SaveManager.data.get("flags", {}).get("hall_boss_defeated", false):
		_spawn_hall_boss()

func _alive_hall_goblin_count() -> int:
	var count := 0
	for goblin in get_tree().get_nodes_in_group("hall_goblins"):
		if is_instance_valid(goblin) and goblin.get("isAlive") == true:
			count += 1
	return count

func _spawn_hall_goblin() -> void:
	hall_spawn_count += 1
	var goblin := hall_enemy_template.duplicate() as CharacterBody2D
	if goblin == null:
		return
	goblin.name = "HallGoblin_%04d" % hall_spawn_count
	goblin.set("is_giant_boss", false)
	goblin.set("health_multiplier", 1.0)
	goblin.set("damage_multiplier", 1.0)
	goblin.set("movement_multiplier", 1.0)
	goblin.set("isAlive", true)
	goblin.set("health", 100)
	goblin.set("target_player", null)
	var facing: Vector2 = player.get("recordLastDirection")
	var spawn_position := player.global_position - facing * 150.0 + Vector2(randf_range(-110.0, 110.0), 0.0)
	spawn_position.x = clampf(spawn_position.x, hall_center_x - hall_half_width + 64.0, hall_center_x + hall_half_width - 64.0)
	spawn_position.y = clampf(spawn_position.y, hall_start_y + 80.0, hall_end_y - 100.0)
	goblin.global_position = spawn_position
	add_child(goblin)
	goblin.add_to_group("hall_goblins")
	goblin.remove_from_group("Enemies")
	_set_spawned_enemy_active(goblin, true)

func _spawn_hall_boss() -> void:
	if hall_boss_spawned or hall_enemy_template == null:
		return
	hall_boss_spawned = true
	hall_boss = hall_enemy_template.duplicate() as CharacterBody2D
	if hall_boss == null:
		return
	hall_boss.name = "HallBoss"
	hall_boss.set("is_giant_boss", true)
	hall_boss.set("health_multiplier", 10.0)
	hall_boss.set("damage_multiplier", 10.0)
	hall_boss.set("movement_multiplier", 1.0)
	hall_boss.set("isAlive", true)
	hall_boss.set("health", 1000)
	hall_boss.set("target_player", null)
	hall_boss.scale *= 2.0
	hall_boss.global_position = Vector2(hall_center_x, hall_end_y + hall_boss_room_depth * 0.48)
	add_child(hall_boss)
	_set_spawned_enemy_active(hall_boss, true)
	if hall_boss.has_signal("died"):
		hall_boss.connect("died", _on_hall_boss_defeated, CONNECT_ONE_SHOT)

func _set_spawned_enemy_active(enemy: CharacterBody2D, active: bool) -> void:
	enemy.visible = active
	enemy.set_physics_process(active)
	var sprite := enemy.get_node_or_null("enemyTutorialSprite") as AnimatedSprite2D
	if sprite != null:
		sprite.modulate = Color.WHITE
		sprite.play("idle")
	for path in ["enemyTutorialShape", "enemyTutorialArea/enemyTutorialAreaShape"]:
		var shape := enemy.get_node_or_null(path) as CollisionShape2D
		if shape != null:
			shape.set_deferred("disabled", not active)
	var health_bar := enemy.get_node_or_null("enemyHealthBar") as TextureProgressBar
	if health_bar != null:
		health_bar.show()

func _on_hall_boss_defeated() -> void:
	var flags: Dictionary = SaveManager.data.get("flags", {})
	flags["hall_boss_defeated"] = true
	SaveManager.data["flags"] = flags
	SaveManager.saveGame()

func _update_mobile_action_buttons() -> void:
	var view := player.get_node_or_null("playerView")
	if view == null:
		return
	var mobile := view.get_node_or_null("MobileControl")
	if mobile == null:
		return
	var actions := mobile.get_node_or_null("CanvasLayer")
	if actions == null:
		return
	var touch_enabled := GlobalInputDetection.inputType() != 0
	var class_interaction_ready := tutorial_stage != "move_to_orb" or selectClassType != null
	var combat_ready := tutorial_stage in ["attack", "fight", "potion_throw", "complete"]
	var button_a := actions.get_node_or_null("buttonA") as TouchScreenButton
	var button_b := actions.get_node_or_null("buttonB") as TouchScreenButton
	var button_skill := actions.get_node_or_null("buttonSkill") as TouchScreenButton
	var has_warrior_skill: bool = SaveManager.data.get("flags", {}).get("isFromHogward") == false and player.has_method("_has_warrior_skill_unlocked") and player.call("_has_warrior_skill_unlocked") == true
	if button_a != null:
		button_a.visible = touch_enabled and class_interaction_ready
	if button_b != null:
		button_b.visible = touch_enabled and combat_ready
	if button_skill != null:
		button_skill.visible = touch_enabled and has_warrior_skill and tutorial_stage != "move_to_orb"
	var a_label := actions.get_node_or_null("Label2") as Label
	var b_label := actions.get_node_or_null("Label") as Label
	var skill_label := actions.get_node_or_null("SkillLabel") as Label
	if a_label != null:
		a_label.visible = touch_enabled and class_interaction_ready
	if b_label != null:
		b_label.visible = touch_enabled and combat_ready
	if skill_label != null:
		skill_label.visible = touch_enabled and has_warrior_skill and tutorial_stage != "move_to_orb"

func _update_attack_tutorial_label() -> void:
	if tutorial_stage == "move_to_orb":
		attackTutorialLabel.text = "Move around, then approach an orb to choose your class."
		return
	if tutorial_stage == "enter_room":
		attackTutorialLabel.text = "Enter the tutorial room to begin combat training."
		return
	if tutorial_stage == "fight":
		attackTutorialLabel.text = "Defeat the goblin!"
		return
	if tutorial_stage == "open_chest":
		attackTutorialLabel.text = "The goblin is defeated. Open the chest."
		return
	if tutorial_stage == "skill_choice":
		attackTutorialLabel.text = "Open your inventory and choose a skill."
		return
	if tutorial_stage == "potion_select":
		attackTutorialLabel.text = "Select the Poison Potion in your inventory."
		return
	if tutorial_stage == "potion_throw":
		attackTutorialLabel.text = "Hold B, aim with the joystick, then release to throw." if GlobalInputDetection.inputType() != 0 else "Hold %s, aim with the mouse, then release to throw." % _get_attack_key_name()
		return
	if tutorial_stage == "potion_poison_wait":
		attackTutorialLabel.text = "Poison is working. Keep your distance until the goblin falls."
		return
	if tutorial_stage == "potion_drink_select":
		attackTutorialLabel.text = "Poison defeated the goblin. Select your stat potion in Inventory."
		return
	if tutorial_stage == "potion_drink":
		attackTutorialLabel.text = "Tap A to drink your potion." if GlobalInputDetection.inputType() != 0 else "Press E to drink your potion."
		return
	if tutorial_stage == "complete":
		attackTutorialLabel.hide()
		return
	attackTutorialLabel.show()
	var is_mage: bool = SaveManager.data.get("flags", {}).get("isFromHogward") == true
	if tutorial_stage == "attack" and is_mage:
		var needed := "fire" if not mage_tutorial_spells.has("fire") else "earth"
		var mage_prompt := "Draw %s + one dot + Arrow" % needed.capitalize()
		mage_prompt += " (Tap B)" if GlobalInputDetection.inputType() != 0 else " (Press Space)"
		attackTutorialLabel.text = mage_prompt
		return
	var prompt := "Tap B To Attack"
	if GlobalInputDetection.inputType() == 0:
		prompt = "Press SPACE To Attack"
		for action_event in InputMap.action_get_events("player_attack"):
			if action_event is InputEventKey:
				var key_event := action_event as InputEventKey
				var key_code := key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
				var key_name := OS.get_keycode_string(key_code)
				if not key_name.is_empty():
					prompt = "Press " + key_name.to_upper() + " To Attack"
					break
	if attackTutorialLabel.text != prompt:
		attackTutorialLabel.text = prompt

func _get_attack_key_name() -> String:
	for action_event in InputMap.action_get_events("player_attack"):
		if action_event is InputEventKey:
			var key_event := action_event as InputEventKey
			var key_code := key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
			var key_name := OS.get_keycode_string(key_code)
			if not key_name.is_empty():
				return key_name.to_upper()
	return "ATTACK"

#========================================
#               FUNCTIONS
#========================================
func _set_tutorial_stage(stage: String) -> void:
	tutorial_stage = stage
	SaveManager.data["flags"]["tutorial_stage"] = stage
	SaveManager.saveGame()
	_setup_tutorial_stage()

func _setup_tutorial_stage() -> void:
	var active := tutorial_stage != "complete"
	attackTutorialLabel.visible = active and tutorial_stage != "move_to_orb"
	var enemy_active := tutorial_stage in ["fight", "open_chest", "skill_choice"]
	if is_instance_valid(tutorialEnemy):
		tutorialEnemy.visible = enemy_active
		tutorialEnemy.set_physics_process(enemy_active)
		for path in ["enemyTutorialShape", "enemyTutorialArea/enemyTutorialAreaShape"]:
			var shape := tutorialEnemy.get_node_or_null(path) as CollisionShape2D
			if shape != null:
				shape.set_deferred("disabled", not enemy_active)
	if tutorial_stage in ["potion_throw", "potion_poison_wait"]:
		_ensure_potion_tutorial_goblin()
	if is_instance_valid(potionTutorialEnemy):
		var potion_enemy_active := tutorial_stage in ["potion_throw", "potion_poison_wait"]
		potionTutorialEnemy.visible = potion_enemy_active
		potionTutorialEnemy.set_physics_process(potion_enemy_active)
		if tutorial_stage == "potion_poison_wait":
			potionTutorialEnemy.set("target_player", null)
		for path in ["enemyTutorialShape", "enemyTutorialArea/enemyTutorialAreaShape"]:
			var shape := potionTutorialEnemy.get_node_or_null(path) as CollisionShape2D
			if shape != null:
				shape.set_deferred("disabled", not potion_enemy_active)
	var chest_active := tutorial_stage in ["open_chest", "skill_choice"]
	chest.visible = chest_active or tutorial_stage == "complete"
	chest.set_deferred("monitoring", chest_active)
	var chest_shape := chest.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if chest_shape != null:
		chest_shape.set_deferred("disabled", not chest_active)
	if tutorial_stage == "fight" and (not is_instance_valid(tutorialEnemy) or tutorialEnemy.get("isAlive") != true):
		_set_tutorial_stage("open_chest")
	elif tutorial_stage == "open_chest":
		var saved_chests: Variant = SaveManager.data.get("chests", {})
		if saved_chests is Dictionary and saved_chests.get("tutorial_chest", false) == true:
			_set_tutorial_stage("skill_choice")
			call_deferred("_open_tutorial_skill_choice")

func _open_tutorial_skill_choice() -> void:
	var view := player.get_node_or_null("playerView")
	if view != null and view.has_method("open_tutorial_skill_tree"):
		view.call("open_tutorial_skill_tree")

func _open_tutorial_potion_inventory() -> void:
	if tutorial_stage not in ["potion_select", "potion_drink_select"]:
		return
	var view := player.get_node_or_null("playerView")
	if view != null and view.has_method("open_tutorial_potion_inventory"):
		view.call("open_tutorial_potion_inventory")

func _ensure_potion_tutorial_goblin() -> void:
	if is_instance_valid(potionTutorialEnemy):
		return
	var existing := get_node_or_null("TutorialArea/step1/PotionTutorialGoblin") as CharacterBody2D
	if existing != null:
		potionTutorialEnemy = existing
		return
	var saved_enemy_data: Dictionary = {}
	var current_scene := get_tree().current_scene
	if current_scene != null:
		var saved_enemies: Variant = SaveManager.data.get("enemies", {})
		var saved_key := current_scene.scene_file_path + "::TutorialArea/step1/PotionTutorialGoblin"
		if saved_enemies is Dictionary:
			var saved_value: Variant = saved_enemies.get(saved_key, {})
			if saved_value is Dictionary:
				saved_enemy_data = saved_value
	potionTutorialEnemy = tutorialEnemy.duplicate() as CharacterBody2D
	if potionTutorialEnemy == null:
		return
	potionTutorialEnemy.name = "PotionTutorialGoblin"
	potionTutorialEnemy.set("isAlive", true)
	potionTutorialEnemy.set("health", 25)
	potionTutorialEnemy.set("shield_health", 0)
	potionTutorialEnemy.set("target_player", null)
	tutorialEnemy.get_parent().add_child(potionTutorialEnemy)
	if saved_enemy_data.is_empty():
		potionTutorialEnemy.global_position = player.global_position + Vector2(180.0, 0.0)
	potionTutorialEnemy.visible = true
	potionTutorialEnemy.set_physics_process(true)
	var sprite := potionTutorialEnemy.get_node_or_null("enemyTutorialSprite") as AnimatedSprite2D
	if sprite != null:
		sprite.modulate = Color.WHITE
		sprite.play("idle")
	var health_bar := potionTutorialEnemy.get_node_or_null("enemyHealthBar") as TextureProgressBar
	if health_bar != null:
		health_bar.max_value = 25.0
		health_bar.value = float(potionTutorialEnemy.get("health"))
		health_bar.show()
	for path in ["enemyTutorialShape", "enemyTutorialArea/enemyTutorialAreaShape"]:
		var shape := potionTutorialEnemy.get_node_or_null(path) as CollisionShape2D
		if shape != null:
			shape.set_deferred("disabled", false)

func tutorial_warrior_attack() -> void:
	if tutorial_stage == "attack" and SaveManager.data["flags"].get("isFromHogward") == false:
		_set_tutorial_stage("fight")

func tutorial_spell_cast(sigil: String, outline: String, modifier_count: int) -> void:
	if tutorial_stage != "attack" or SaveManager.data["flags"].get("isFromHogward") != true:
		return
	if outline != "arrow" or modifier_count != 1 or not ["fire", "earth"].has(sigil):
		return
	if not mage_tutorial_spells.has(sigil):
		mage_tutorial_spells.append(sigil)
	if mage_tutorial_spells.has("fire") and mage_tutorial_spells.has("earth"):
		_set_tutorial_stage("fight")
	_update_attack_tutorial_label()

func get_tutorial_next_mage_sigil() -> String:
	return "earth" if mage_tutorial_spells.has("fire") else "fire"

func tutorial_enemy_defeated() -> void:
	if tutorial_stage == "fight":
		_set_tutorial_stage("open_chest")
	elif tutorial_stage == "potion_poison_wait":
		_set_tutorial_stage("potion_drink_select")
		call_deferred("_open_tutorial_potion_inventory")

func _on_tutorial_chest_closed() -> void:
	if tutorial_stage == "open_chest":
		_set_tutorial_stage("skill_choice")
		_open_tutorial_skill_choice()

func tutorial_skill_selected(_skill_id: String) -> void:
	if tutorial_stage == "skill_choice":
		_set_tutorial_stage("potion_select")
		call_deferred("_open_tutorial_potion_inventory")

func tutorial_potion_selected(_item_id: String) -> void:
	if tutorial_stage == "potion_select" and _item_id == "potion_poison":
		_set_tutorial_stage("potion_throw")
		SaveManager.saveGame()
	elif tutorial_stage == "potion_drink_select" and _item_id != "potion_poison":
		_set_tutorial_stage("potion_drink")

func tutorial_potion_landed() -> void:
	if tutorial_stage == "potion_throw":
		_set_tutorial_stage("potion_poison_wait")

func tutorial_potion_drank(item_id: String) -> void:
	if tutorial_stage == "potion_drink" and item_id != "potion_poison":
		SaveManager.data["flags"]["isTutorialDone"] = true
		_set_tutorial_stage("complete")

func tutorial_potion_missed() -> void:
	if tutorial_stage == "potion_throw":
		_update_attack_tutorial_label()

func orbsVisible(isVisible: bool) -> void:
	classesPick.visible = isVisible
	warriorOrb.visible = isVisible
	mageOrb.visible = isVisible
	orbRoomLight.visible = isVisible
	
	#only do this if isVisible is set to false
	if !isVisible:
		#clear class selection
		selectClassType = null
		
		#hide visual nodes
		classesPick.visible = isVisible
		warriorOrb.visible = isVisible
		mageOrb.visible = isVisible
		orbRoomLight.visible = isVisible
		
		#remove orbs from group Items
		mageOrb.remove_from_group("Items")
		warriorOrb.remove_from_group("Items")
		
		#disable area2d for both orbs
		mageOrb.set_deferred("monitoring", false)
		mageOrb.set_deferred("monitorable", false)
		warriorOrb.set_deferred("monitoring", false)
		warriorOrb.set_deferred("monitorable", false)

func showConfirmationPopup(isShow: bool) -> void:
	classConfirmCanv.visible = isShow
	classConfirmBG.visible = isShow
	classConfirmWindow.visible = isShow

func orbMovingPattern() -> void:
	mageOrb.position = Vector2(530.0, 90.0)
	warriorOrb.position = Vector2(630.0, 90.0)
	
	var startPos_MAGE := mageOrb.position
	var startPos_WARRIOR := warriorOrb.position
	
	#loop tweens synced to physics frames
	var tween_mage := create_tween().set_loops().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	var tween_warrior := create_tween().set_loops().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	
	#mage floating animation
	tween_mage.tween_property(mageOrb, "position", startPos_MAGE + Vector2(0, -20), 3.0)
	tween_mage.tween_property(mageOrb, "position", startPos_MAGE, 1.5)
	
	#warrior floating animation
	tween_warrior.tween_property(warriorOrb, "position", startPos_WARRIOR + Vector2(0, -20), 2.5)
	tween_warrior.tween_property(warriorOrb, "position", startPos_WARRIOR, 1.5)

#script for tutorial step
func tutorialMode() -> void:
	if tutorial_stage == "enter_room":
		_set_tutorial_stage("attack")
	elif tutorial_stage == "attack":
		_update_attack_tutorial_label()

#========================================
#               CONTROLS
#========================================
func _on_warrior_orb_area_entered(area: Area2D) -> void:
	if area.name == "playerRange":
		warriorLabel.text = WARRIOR_ORB_PROMPT
		warriorLabel.visible = true
		selectClassType = false # false = Warrior

func _on_warrior_orb_area_exited(area: Area2D) -> void:
	if area.name == "playerRange":
		warriorLabel.visible = false
		if selectClassType == false:
			selectClassType = null

func _on_mage_orb_area_entered(area: Area2D) -> void:
	if area.name == "playerRange":
		mageLabel.text = MAGE_ORB_PROMPT
		mageLabel.visible = true
		selectClassType = true # true = Mage

func _on_mage_orb_area_exited(area: Area2D) -> void:
	if area.name == "playerRange":
		mageLabel.visible = false
		if selectClassType == true:
			selectClassType = null

#close door and initiate tutorial mode script
func _on_tutor_area_area_entered(area: Area2D) -> void:
	if area.name == "playerRange":
		door.visible = true
		door.collision_enabled = true
		tutorialMode()

#========================================
#          CONFIRMATION POPUP
#========================================
func _on_confirm_pressed() -> void:
	SaveManager.data["flags"]["isFromHogward"] = selectClassType
	SaveManager.data["flags"]["tutorial_stage"] = "enter_room"
	SaveManager.saveGame()
	#reload so that the character for player appears
	get_tree().reload_current_scene()
	#reload game save
	SaveManager.loadGame()
	showConfirmationPopup(false)

func _on_cancel_pressed() -> void:
	showConfirmationPopup(false)
