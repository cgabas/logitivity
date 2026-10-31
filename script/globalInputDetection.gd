extends Node

enum inputMode { KEYBOARD, TOUCH }
const SETTINGS_PATH := "user://input_settings.cfg"

# Keyboard is the safe default; touchscreen controls are enabled by an explicit choice.
var currentInputMode := inputMode.KEYBOARD

# Track active player inventory UI instance globally
const PLAYER_INVENTORY_SCENE = preload("res://sprite/player_inventory.tscn")
var active_inventory_ui: CanvasLayer = null

func _ready() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		return
	var saved_mode := str(settings.get_value("controls", "input_mode", "keyboard"))
	currentInputMode = inputMode.TOUCH if saved_mode == "touchscreen" else inputMode.KEYBOARD

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		toggle_player_inventory()
		get_viewport().set_input_as_handled()

func toggle_player_inventory() -> void:
	if active_inventory_ui:
		active_inventory_ui.queue_free()
		active_inventory_ui = null
		get_tree().paused = false
	else:
		if PLAYER_INVENTORY_SCENE:
			active_inventory_ui = PLAYER_INVENTORY_SCENE.instantiate()
			get_tree().current_scene.add_child(active_inventory_ui)
			get_tree().paused = true
			
			if active_inventory_ui.has_signal("ui_closed"):
				active_inventory_ui.ui_closed.connect(_on_inventory_closed)

func _on_inventory_closed() -> void:
	active_inventory_ui = null
	get_tree().paused = false

func setInputMode(mode: int) -> void:
	if mode != inputMode.KEYBOARD and mode != inputMode.TOUCH:
		return
	currentInputMode = mode
	var settings := ConfigFile.new()
	settings.set_value("controls", "input_mode", "touchscreen" if mode == inputMode.TOUCH else "keyboard")
	var error := settings.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save input preference: ", error)

func toggleInputMode() -> void:
	setInputMode(inputMode.TOUCH if currentInputMode == inputMode.KEYBOARD else inputMode.KEYBOARD)

func inputModeName() -> String:
	return "Touchscreen" if currentInputMode == inputMode.TOUCH else "Keyboard"

#0 for keyboard and controller, 1 for touch
func inputType() -> int:
	if currentInputMode == inputMode.KEYBOARD:
		return 0
	else:
		return 1
