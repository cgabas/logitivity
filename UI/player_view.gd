extends CanvasLayer

@onready var mobileControl: Control = $MobileControl



#enable mobile ui control if touchscreen is avaliable
func _process(delta: float) -> void:
	if GlobalInputDetection.inputType() == 0:
		mobileControl.visible = false
	else:
		mobileControl.visible = true
