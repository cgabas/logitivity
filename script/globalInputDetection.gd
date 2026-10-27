extends Node

enum inputMode { KEYBOARD, TOUCH }
#touch input mode by default
var currentInputMode := inputMode.TOUCH

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if currentInputMode != inputMode.KEYBOARD:
			currentInputMode = inputMode.KEYBOARD
	elif event is InputEventJoypadMotion or event is InputEventScreenTouch or event is InputEventScreenDrag:
		if currentInputMode != inputMode.TOUCH:
			currentInputMode = inputMode.TOUCH

#0 for keyboard, 1 for touch
func inputType() -> int:
	if currentInputMode == inputMode.KEYBOARD:
		return 0
	else:
		return 1
