extends Node

enum inputMode { KEYBOARD, TOUCH }
const SETTINGS_PATH := "user://input_settings.cfg"

# Keyboard is the safe default; touchscreen controls are enabled by an explicit choice.
var currentInputMode := inputMode.KEYBOARD

func _ready() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		return
	var saved_mode := str(settings.get_value("controls", "input_mode", "keyboard"))
	currentInputMode = inputMode.TOUCH if saved_mode == "touchscreen" else inputMode.KEYBOARD

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
