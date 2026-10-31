extends Area2D
class_name Chest

@export_category("Chest Settings")
@export var chest_id: String = "chest_01"
@export var is_opened: bool = false
@export var chest_ui: PackedScene

# Chest loot data array with coin, health potion, and mana potion
@export var items: Array[Dictionary] = [
	{
		"id": "coin",
		"name": "Gold Coin",
		"icon": preload("res://temporarySprite/coin.png"),
		"quantity": 10
	},
	{
		"id": "health_potion",
		"name": "Health Potion",
		"icon": preload("res://temporarySprite/HealthPot.png"),
		"quantity": 2
	},
	{
		"id": "mana_potion",
		"name": "Mana Potion",
		"icon": preload("res://temporarySprite/manaPot.png"),
		"quantity": 1
	}
]

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var active_ui: CanvasLayer = null

func _ready() -> void:
	if not is_in_group("Items"):
		add_to_group("Items")
	if sprite.sprite_frames.has_animation("chestOpenClose"):
		sprite.sprite_frames.set_animation_loop("chestOpenClose", false)
	_update_visual_state()

func interact() -> void:
	if active_ui != null:
		return
	is_opened = true
	sprite.stop()
	sprite.frame = 0
	sprite.play("chestOpenClose")
	open_ui()

func open_ui() -> void:
	if active_ui:
		return
		
	if chest_ui:
		var ui_instance = chest_ui.instantiate()
		get_tree().current_scene.add_child(ui_instance)
		active_ui = ui_instance
		
		# Pass both the items list AND the chest reference (self) to the UI script
		if active_ui.has_method("set_chest_data"):
			active_ui.set_chest_data(items, self)
		
		get_tree().paused = true
		
		if active_ui.has_signal("ui_closed"):
			active_ui.ui_closed.connect(_on_ui_closed)
	else:
		print("Warning: No Chest UI Scene assigned to chest!")

func _on_ui_closed() -> void:
	active_ui = null
	get_tree().paused = false
	is_opened = false
	sprite.stop()
	sprite.frame = 1
	sprite.play_backwards("chestOpenClose")

func _update_visual_state() -> void:
	if not sprite:
		return
	sprite.stop()
	sprite.frame = 1 if is_opened else 0
