extends Control

@onready var casterProgressBarTest: ProgressBar = $Indicator/manaVisual/casterProgressBar_TEST
@onready var casterHealthProgressBarTest: ProgressBar = $Indicator/healthVisual/casterHealthProgressBar_TEST

#MAKE THIS CASTER FOLLOWS THE CAMERA OR THE PLAYER INSTEAD
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#please make this only changing when an external variable wants to interfere 
	casterHealthProgressBarTest.value = SaveManager.data["player"]["health"]
	casterProgressBarTest.value = SaveManager.data["player"]["caster"]
