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
var boss_victory_screen: CanvasLayer = null

#true = Mage, false = Warrior, null = None selected
var selectClassType: Variant = null
var tutorial_stage := "move_to_orb"
var mage_tutorial_spells: Array[String] = []
const WARRIOR_ORB_PROMPT := "Choose the Warrior orb.\nPress E / Tap A to choose."
const MAGE_ORB_PROMPT := "Choose the Mage orb.\nPress E / Tap A to choose."

func _ready() -> void:
	_clear_tutorial_room_barriers()
	# Keep the warrior skill menu outside the confirmation layer, which is hidden after class selection.
	skillSelector.reparent(self)
	# Center the chest in the tutorial room using the tutorial area's bounds.
	var room_bounds := tutorArea.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if room_bounds != null:
		chest.position = tutorArea.position + room_bounds.position
		# Keep the default tutorial enemy beside the chest while preserving saved positions.
		var current_scene := get_tree().current_scene
		var saved_enemies: Variant = SaveManager.data.get("enemies", {})
		if current_scene != null and saved_enemies is Dictionary:
			var enemy_key := current_scene.scene_file_path + "::" + str(current_scene.get_path_to(tutorialEnemy))
			if not saved_enemies.has(enemy_key):
				tutorialEnemy.position = chest.position + Vector2(180.0, 0.0)
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

func _clear_tutorial_room_barriers() -> void:
	var barrier_layer := get_node_or_null("Barrier") as TileMapLayer
	var room_shape := tutorArea.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if barrier_layer == null or room_shape == null or not room_shape.shape is RectangleShape2D:
		return
	var room_center := tutorArea.to_global(room_shape.position)
	var clear_half_size: Vector2 = (room_shape.shape as RectangleShape2D).size * 0.5 - Vector2(48.0, 48.0)
	if clear_half_size.x <= 0.0 or clear_half_size.y <= 0.0:
		return
	for cell in barrier_layer.get_used_cells():
		var tile_data := barrier_layer.get_cell_tile_data(cell)
		if tile_data == null:
			continue
		var has_collision := false
		for physics_layer in range(barrier_layer.tile_set.get_physics_layers_count()):
			if tile_data.get_collision_polygons_count(physics_layer) > 0:
				has_collision = true
				break
		if not has_collision:
			continue
		var tile_center := barrier_layer.to_global(barrier_layer.map_to_local(cell))
		var room_offset := tile_center - room_center
		if absf(room_offset.x) < clear_half_size.x and absf(room_offset.y) < clear_half_size.y:
			barrier_layer.erase_cell(cell)

func _physics_process(_delta: float) -> void:
	#open confirmation popup when pressing interact ("player_do") near an orb
	if Input.is_action_just_pressed("player_do") and selectClassType != null and tutorial_stage == "move_to_orb":
		windowContentMsgMage.visible = (selectClassType == true)
		windowContentMsgWarrior.visible = (selectClassType == false)
		showConfirmationPopup(true)

func _process(_delta: float) -> void:
	_update_attack_tutorial_label()
	_update_mobile_action_buttons()
	#track player position in SaveManager while moving
	if player.velocity != Vector2.ZERO:
		SaveManager.data["player"]["position"]["x"] = player.position.x
		SaveManager.data["player"]["position"]["y"] = player.position.y

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
	var touch_enabled: bool = GlobalInputDetection.inputType() != 0
	var class_interaction_ready := tutorial_stage != "move_to_orb" or selectClassType != null
	var combat_ready := tutorial_stage in ["attack", "fight", "potion_throw", "complete"]
	var potion_tutorial_ready: bool = tutorial_stage == "potion_throw" or SaveManager.data.get("flags", {}).get("isTutorialDone", false) == true
	var button_a := actions.get_node_or_null("buttonA") as TouchScreenButton
	var button_b := actions.get_node_or_null("buttonB") as TouchScreenButton
	var button_potion := actions.get_node_or_null("buttonPotion") as TouchScreenButton
	var button_skill := actions.get_node_or_null("buttonSkill") as TouchScreenButton
	var has_warrior_skill: bool = SaveManager.data.get("flags", {}).get("isFromHogward") == false and player.has_method("_has_warrior_skill_unlocked") and player.call("_has_warrior_skill_unlocked") == true
	if button_a != null:
		button_a.visible = touch_enabled and class_interaction_ready
	if button_b != null:
		button_b.visible = touch_enabled and combat_ready
	if button_potion != null:
		button_potion.visible = touch_enabled and potion_tutorial_ready
	if button_skill != null:
		button_skill.visible = touch_enabled and has_warrior_skill and tutorial_stage != "move_to_orb"
	var a_label := actions.get_node_or_null("Label2") as Label
	var b_label := actions.get_node_or_null("Label") as Label
	var potion_label := actions.get_node_or_null("Label3") as Label
	var skill_label := actions.get_node_or_null("SkillLabel") as Label
	if a_label != null:
		a_label.visible = touch_enabled and class_interaction_ready
	if b_label != null:
		b_label.visible = touch_enabled and combat_ready
	if potion_label != null:
		potion_label.visible = touch_enabled and potion_tutorial_ready
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
		attackTutorialLabel.text = "Hold P, pull with the joystick, then release to throw." if GlobalInputDetection.inputType() != 0 else "Hold %s, pull with the mouse, then release to throw." % _get_potion_throw_key_name()
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

func _get_potion_throw_key_name() -> String:
	for action_event in InputMap.action_get_events("player_throw_potion"):
		if action_event is InputEventKey:
			var key_event := action_event as InputEventKey
			var key_code := key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
			var key_name := OS.get_keycode_string(key_code)
			if not key_name.is_empty():
				return key_name.to_upper()
	return "P"

#========================================
#               FUNCTIONS
#========================================
func _set_tutorial_stage(stage: String) -> void:
	tutorial_stage = stage
	SaveManager.data["flags"]["tutorial_stage"] = stage
	SaveManager.saveGame()
	if stage == "complete":
		door.visible = false
		door.collision_enabled = false
	_setup_tutorial_stage()

func _setup_tutorial_stage() -> void:
	if tutorial_stage == "complete":
		door.visible = false
		door.collision_enabled = false
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

func show_boss_victory() -> void:
	if is_instance_valid(boss_victory_screen):
		return
	get_tree().paused = true
	boss_victory_screen = CanvasLayer.new()
	boss_victory_screen.name = "BossVictoryScreen"
	boss_victory_screen.layer = 100
	boss_victory_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(boss_victory_screen)

	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	boss_victory_screen.add_child(screen)

	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(1.0, 1.0, 1.0, 0.0)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	screen.add_child(background)

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	layout.position = Vector2(-260.0, -70.0)
	layout.size = Vector2(520.0, 140.0)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 28)
	screen.add_child(layout)

	var title := Label.new()
	title.text = "To be continued..."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color.BLACK)
	title.add_theme_font_size_override("font_size", 48)
	layout.add_child(title)

	var menu_button := Button.new()
	menu_button.text = "Main Menu"
	menu_button.custom_minimum_size = Vector2(240.0, 64.0)
	menu_button.add_theme_color_override("font_color", Color.BLACK)
	menu_button.add_theme_font_size_override("font_size", 24)
	menu_button.pressed.connect(_return_to_main_menu)
	layout.add_child(menu_button)
	menu_button.grab_focus()

	var fade := create_tween()
	fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade.tween_property(background, "color", Color.WHITE, 0.55)

func _return_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/mainmenu.tscn")

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
