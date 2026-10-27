extends Node2D

@onready var player: CharacterBody2D = $player

#orb nodes & labels
@onready var warriorOrb: Area2D = $classesPick/warriorOrb
@onready var mageOrb: Area2D = $classesPick/mageOrb
@onready var warriorLabel: Label = $classesPick/warriorOrb/warriorLabel
@onready var mageLabel: Label = $classesPick/mageOrb/mageLabel

#confirmation UI nodes
@onready var classConfirmCanv: CanvasLayer = $ClassConfirmCanv
@onready var classConfirmBG: TextureRect = $ClassConfirmCanv/ClassConfirmBG
@onready var classConfirmWindow: Window = $ClassConfirmCanv/ClassConfirmWindow
@onready var windowContentMsgMage: Label = $ClassConfirmCanv/ClassConfirmWindow/VBoxContainer/CenterContainer/WindowContentMsg2
@onready var windowContentMsgWarrior: Label = $ClassConfirmCanv/ClassConfirmWindow/VBoxContainer/CenterContainer/WindowContentMsg

#true = Mage, false = Warrior, null = None selected
var selectClassType: Variant = null

func _ready() -> void:
	#1.register orbs into the "Items" group
	warriorOrb.add_to_group("Items")
	mageOrb.add_to_group("Items")
	
	#2.hide labels and popup at startup
	warriorLabel.visible = false
	mageLabel.visible = false
	showConfirmationPopup(false)
	
	#3.load saved player position (or center player on screen if no save exists)
	var saved_pos: Dictionary = SaveManager.data["player"]["position"]
	if saved_pos["x"] == null or saved_pos["y"] == null:
		player.position = get_viewport_rect().size / 2.0
	else:
		player.position = Vector2(saved_pos["x"], saved_pos["y"])
	
	#4.start floating orb animations
	orbMovingPattern()

func _physics_process(_delta: float) -> void:
	#open confirmation popup when pressing interact ("player_do") near an orb
	if Input.is_action_just_pressed("player_do") and selectClassType != null:
		windowContentMsgMage.visible = (selectClassType == true)
		windowContentMsgWarrior.visible = (selectClassType == false)
		showConfirmationPopup(true)

func _process(_delta: float) -> void:
	#track player position in SaveManager while moving
	if player.velocity != Vector2.ZERO:
		SaveManager.data["player"]["position"]["x"] = player.position.x
		SaveManager.data["player"]["position"]["y"] = player.position.y

#========================================
#               FUNCTIONS
#========================================
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

#========================================
#               CONTROLS
#========================================
func _on_warrior_orb_area_entered(area: Area2D) -> void:
	if area.name == "playerRange":
		warriorLabel.visible = true
		selectClassType = false # false = Warrior

func _on_warrior_orb_area_exited(area: Area2D) -> void:
	if area.name == "playerRange":
		warriorLabel.visible = false
		if selectClassType == false:
			selectClassType = null

func _on_mage_orb_area_entered(area: Area2D) -> void:
	if area.name == "playerRange":
		mageLabel.visible = true
		selectClassType = true # true = Mage

func _on_mage_orb_area_exited(area: Area2D) -> void:
	if area.name == "playerRange":
		mageLabel.visible = false
		if selectClassType == true:
			selectClassType = null

#========================================
#          CONFIRMATION POPUP
#========================================
func _on_confirm_pressed() -> void:
	SaveManager.data["flags"]["isFromHogward"] = selectClassType
	SaveManager.saveGame()
	#reload so that the character for player appears
	get_tree().reload_current_scene()
	showConfirmationPopup(false)

func _on_cancel_pressed() -> void:
	showConfirmationPopup(false)
