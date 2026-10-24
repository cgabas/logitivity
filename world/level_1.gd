extends Node2D
@onready var player: CharacterBody2D = $player

func _ready() -> void:
	#set initial position if saved position is 0
	if SaveManager.data["player"]["position"]["x"] == null && SaveManager.data["player"]["position"]["y"] == null:
		player.position.x = get_viewport().get_visible_rect().size.x / 2
		player.position.y = get_viewport().get_visible_rect().size.y / 2
	else:
		player.position.x = SaveManager.data["player"]["position"]["x"]
		player.position.y = SaveManager.data["player"]["position"]["y"]

func _process(delta: float) -> void:
	if Input.is_anything_pressed():
		SaveManager.data["player"]["position"]["x"] = player.position.x
		SaveManager.data["player"]["position"]["y"] = player.position.y
