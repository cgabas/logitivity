extends CanvasLayer
@onready var mobileControl: Control = $".."

func _physics_process(delta: float) -> void:
	visible = mobileControl.visible
