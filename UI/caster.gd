extends Control

const UI_FONT := preload("res://UI/fonts_setting/VCR.ttf")
const MAIN_MENU_SCENE := "res://UI/mainmenu.tscn"
const PAUSE_RESUME := 0
const PAUSE_MAIN_MENU := 1
const PAUSE_TOGGLE_INPUT := 2

@onready var casterProgressBarTest: ProgressBar = $Indicator/manaVisual/casterProgressBar_TEST
@onready var casterHealthProgressBarTest: ProgressBar = $Indicator/healthVisual/casterHealthProgressBar_TEST
@onready var casterProgressBar: TextureProgressBar = $Indicator/manaVisual/casterProgressBar
@onready var casterHealthProgressBar: TextureProgressBar = $Indicator/healthVisual/casterHealthProgressBar
@onready var casterLabel: Label = $Indicator/manaVisual/casterLabel
@onready var menu_button: MenuButton = $Indicator/MenuButton

#MAKE THIS CASTER FOLLOWS THE CAMERA OR THE PLAYER INSTEAD
func _ready() -> void:
	_setup_pause_menu()
	var classType = SaveManager.data["flags"]["isFromHogward"]
	#display word mana if player class was mage, warrior otherwise (Unknown if classless)
	if classType != null:
		casterLabel.text = "Mana" if SaveManager.data["flags"]["isFromHogward"] else "Energy"
	else:
		casterLabel.text = "Unknown"
	#get_tree().debug_collisions_hint = true

func _setup_pause_menu() -> void:
	var popup := menu_button.get_popup()
	popup.clear()
	popup.add_item("Resume", PAUSE_RESUME)
	popup.add_item("Input: " + GlobalInputDetection.inputModeName(), PAUSE_TOGGLE_INPUT)
	popup.add_item("Return to Main Menu", PAUSE_MAIN_MENU)
	popup.process_mode = Node.PROCESS_MODE_ALWAYS
	popup.add_theme_font_override("font", UI_FONT)
	popup.add_theme_font_size_override("font_size", 18)
	popup.add_theme_color_override("font_color", Color(0.92, 0.9, 1.0))
	popup.add_theme_color_override("font_hover_color", Color(0.55, 0.92, 1.0))
	popup.add_theme_color_override("font_pressed_color", Color.WHITE)
	popup.add_theme_color_override("font_disabled_color", Color(0.5, 0.48, 0.55))
	var popup_panel := StyleBoxFlat.new()
	popup_panel.bg_color = Color(0.08, 0.065, 0.12, 0.98)
	popup_panel.border_color = Color(0.61, 0.37, 0.26)
	popup_panel.set_border_width_all(2)
	popup_panel.set_corner_radius_all(6)
	popup_panel.content_margin_left = 10.0
	popup_panel.content_margin_right = 10.0
	popup_panel.content_margin_top = 8.0
	popup_panel.content_margin_bottom = 8.0
	popup_panel.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	popup_panel.shadow_size = 8
	popup.add_theme_stylebox_override("panel", popup_panel)
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.24, 0.19, 0.32, 1.0)
	hover_style.set_corner_radius_all(4)
	popup.add_theme_stylebox_override("hover", hover_style)
	popup.add_theme_constant_override("v_separation", 8)
	popup.about_to_popup.connect(_on_pause_menu_opening)
	popup.popup_hide.connect(_on_pause_menu_closed)
	popup.id_pressed.connect(_on_pause_menu_item_pressed)

func _on_pause_menu_opening() -> void:
	get_tree().paused = true

func _on_pause_menu_closed() -> void:
	if get_tree().paused:
		get_tree().paused = false

func _on_pause_menu_item_pressed(item_id: int) -> void:
	if item_id == PAUSE_RESUME:
		menu_button.get_popup().hide()
	elif item_id == PAUSE_TOGGLE_INPUT:
		GlobalInputDetection.toggleInputMode()
		var popup := menu_button.get_popup()
		var mode_item := popup.get_item_index(PAUSE_TOGGLE_INPUT)
		if mode_item >= 0:
			popup.set_item_text(mode_item, "Input: " + GlobalInputDetection.inputModeName())
	elif item_id == PAUSE_MAIN_MENU:
		get_tree().paused = false
		SaveManager.saveGame()
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#please make this only changing when an external variable wants to interfere 
	casterHealthProgressBar.value = SaveManager.data["player"]["health"]
	casterProgressBar.value = SaveManager.data["player"]["caster"]
