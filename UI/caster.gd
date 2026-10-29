extends Control

@onready var casterProgressBarTest: ProgressBar = $Indicator/manaVisual/casterProgressBar_TEST
@onready var casterHealthProgressBarTest: ProgressBar = $Indicator/healthVisual/casterHealthProgressBar_TEST
@onready var casterProgressBar: TextureProgressBar = $Indicator/manaVisual/casterProgressBar
@onready var casterHealthProgressBar: TextureProgressBar = $Indicator/healthVisual/casterHealthProgressBar
@onready var casterLabel: Label = $Indicator/manaVisual/casterLabel

#MAKE THIS CASTER FOLLOWS THE CAMERA OR THE PLAYER INSTEAD
func _ready() -> void:
	var classType = SaveManager.data["flags"]["isFromHogward"]
	#display word mana if player class was mage, warrior otherwise (Unknown if classless)
	if classType != null:
		casterLabel.text = "Mana" if SaveManager.data["flags"]["isFromHogward"] else "Energy"
	else:
		casterLabel.text = "Unknown"
	#get_tree().debug_collisions_hint = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#please make this only changing when an external variable wants to interfere 
	casterHealthProgressBar.value = SaveManager.data["player"]["health"]
	casterProgressBar.value = SaveManager.data["player"]["caster"]
