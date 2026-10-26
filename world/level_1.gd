extends Node2D
@onready var player: CharacterBody2D = $player
#collision nodes for the orbs (not including self which is this mageOrb where this script is attached to)
@onready var warriorOrb: Area2D = $"classesPick/warriorOrb"
@onready var mageOrb: Area2D = $classesPick/mageOrb
@onready var playerRange: Area2D = $playerRange
#labels on the orbs
@onready var warriorLabel: Label = $classesPick/warriorOrb/warriorLabel
@onready var mageLabel: Label = $classesPick/mageOrb/mageLabel

#true for mage, false for warrior
var selectClassType: bool

func _ready() -> void:
	#set initial position if saved position is 0
	if SaveManager.data["player"]["position"]["x"] == null && SaveManager.data["player"]["position"]["y"] == null:
		player.position.x = get_viewport().get_visible_rect().size.x / 2
		player.position.y = get_viewport().get_visible_rect().size.y / 2
	else:
		player.position.x = SaveManager.data["player"]["position"]["x"]
		player.position.y = SaveManager.data["player"]["position"]["y"]
	
	#initiate orbs animations
	orbMovingPattern()

func _process(delta: float) -> void:
	if Input.is_anything_pressed():
		SaveManager.data["player"]["position"]["x"] = player.position.x
		SaveManager.data["player"]["position"]["y"] = player.position.y

#========================================
#               FUNCTIONS
#========================================
func orbMovingPattern() -> void:
	position = Vector2(530.00, 90.00)
	warriorOrb.position = Vector2(630.00, 90.00)
	var startPos_MAGE := position
	var startPos_WARRIOR := warriorOrb.position
	
	#loop tween that locked with godot physics process
	var tween_1 := create_tween().set_loops()
	var tween_2 := create_tween().set_loops()
	tween_1.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween_2.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	
	#floating animation
	#mage
	tween_1.tween_property(mageOrb, "position", startPos_MAGE + Vector2(0, -20), 3)
	tween_1.tween_property(mageOrb, "position", startPos_MAGE, 1.5)
	#warrior
	tween_2.tween_property(warriorOrb, "position", startPos_WARRIOR + Vector2(0, -20), 2.5)
	tween_2.tween_property(warriorOrb, "position", startPos_WARRIOR, 1.5)

#========================================
#              CONTROLS
#========================================
#only display the label below the orbs when player entered these orbs Area2D

#TODO: Add class selection for player class
func _on_warrior_orb_area_entered(area: Area2D) -> void:
	if area.name == "playerRange":
		warriorLabel.visible = true
func _on_warrior_orb_area_exited(area: Area2D) -> void:
	if area.name == "playerRange":
		warriorLabel.visible = false
func _on_mage_orb_area_entered(area: Area2D) -> void:
	if area.name == "playerRange":
		mageLabel.visible = true
func _on_mage_orb_area_exited(area: Area2D) -> void:
	if area.name == "playerRange":
		mageLabel.visible = false
