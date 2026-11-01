extends CanvasLayer

const TOUCH_BUTTON_NORMAL := preload("res://UI/texture/hint_box.png")
const TOUCH_BUTTON_PRESSED := preload("res://UI/texture/hint_box_pressed.png")

@onready var mobileControl: Control = $".."
@onready var buttonSkill: TouchScreenButton = $buttonSkill
@onready var skillLabel: Label = $SkillLabel

func _ready() -> void:
	buttonSkill.position = Vector2(909.0, 448.0)
	buttonSkill.scale = Vector2(3.0, 3.0)
	buttonSkill.texture_normal = TOUCH_BUTTON_NORMAL
	buttonSkill.texture_pressed = TOUCH_BUTTON_PRESSED
	var skill_shape := RectangleShape2D.new()
	skill_shape.size = Vector2(47.0, 47.0)
	buttonSkill.shape = skill_shape
	buttonSkill.hide()
	skillLabel.hide()
	skillLabel.label_settings = $Label.label_settings

func _physics_process(_delta: float) -> void:
	visible = mobileControl.visible
