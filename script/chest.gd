extends Area2D
class_name Chest

@export_category("Chest Settings")
@export var chest_id: String = "chest_01"
@export var is_opened: bool = false
@export var chest_ui: PackedScene

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Changed type hint from Control to CanvasLayer (or Node)
var active_ui: CanvasLayer = null

func _ready() -> void:
	if not is_in_group("Items"):
		add_to_group("Items")
		
	_update_visual_state()

func interact() -> void:
	if not is_opened:
		is_opened = true
		_update_visual_state()
	
	open_ui()

func open_ui() -> void:
	if active_ui:
		return
		
	if chest_ui:
		var ui_instance = chest_ui.instantiate()
		get_tree().current_scene.add_child(ui_instance)
		active_ui = ui_instance
		
		# Pause the game so the player stops moving/attacking while looting
		get_tree().paused = true
		
		if active_ui.has_signal("ui_closed"):
			active_ui.ui_closed.connect(_on_ui_closed)
	else:
		print("Warning: No Chest UI Scene assigned to chest!")

func _on_ui_closed() -> void:
	active_ui = null
	# Unpause the game when closing the chest
	get_tree().paused = false

func _update_visual_state() -> void:
	if not sprite:
		return
		
	if not sprite.is_playing():
		sprite.play("chestOpenClose")
		
	if is_opened:
		sprite.frame = 1
		sprite.pause()
	else:
		sprite.frame = 0
		sprite.pause()
