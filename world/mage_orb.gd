extends Node2D
@onready var warriorOrb: Node2D = $"../warriorOrb"

func _ready() -> void:
	orbMovingPattern()

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
	tween_1.tween_property(self, "position", startPos_MAGE + Vector2(0, -20), 3)
	tween_1.tween_property(self, "position", startPos_MAGE, 1.5)
	#warrior
	tween_2.tween_property(warriorOrb, "position", startPos_WARRIOR + Vector2(0, -20), 2.5)
	tween_2.tween_property(warriorOrb, "position", startPos_WARRIOR, 1.5)
