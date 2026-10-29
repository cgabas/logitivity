extends CanvasLayer

signal ui_closed

@onready var close_button: Button = %CloseButton
@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	# Ensure process mode stays active even if game pauses
	process_mode = PROCESS_MODE_ALWAYS
	
	# Connect close button
	close_button.pressed.connect(_on_close_pressed)
	status_label.text = "                                  Chest Inventory"

# Handles mobile touch taps and keyboard events
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("player_do") or event.is_action_pressed("ui_cancel"):
		_close_ui()
		get_viewport().set_input_as_handled()

func _on_close_pressed() -> void:
	_close_ui()

func _close_ui() -> void:
	ui_closed.emit()
	queue_free()
