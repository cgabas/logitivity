extends Node

enum inputMode { KEYBOARD, TOUCH }
#touch input mode by default
var currentInputMode := inputMode.TOUCH

func _input(event: InputEvent) -> void:
	#for Keyboard and Controller
	if event is InputEventKey || event is InputEventJoypadButton || event is InputEventJoypadMotion:
		if currentInputMode != inputMode.KEYBOARD:
			currentInputMode = inputMode.KEYBOARD
	#for touch input
	elif event is InputEventScreenTouch || event is InputEventScreenDrag:
		if currentInputMode != inputMode.TOUCH:
			currentInputMode = inputMode.TOUCH

#0 for keyboard and controller, 1 for touch
func inputType() -> int:
	if currentInputMode == inputMode.KEYBOARD:
		return 0
	else:
		return 1
