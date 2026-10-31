extends Control

const UI_FONT := preload("res://UI/fonts_setting/VCR.ttf")
const MAIN_MENU_SCENE := "res://UI/mainmenu.tscn"
const INVENTORY_BUTTON_NORMAL := preload("res://UI/texture/hint_box.png")
const INVENTORY_BUTTON_PRESSED := preload("res://UI/texture/hint_box_pressed.png")
const PAUSE_RESUME := 0
const PAUSE_MAIN_MENU := 1
const PAUSE_TOGGLE_INPUT := 2

@onready var casterProgressBarTest: ProgressBar = $Indicator/manaVisual/casterProgressBar_TEST
@onready var casterHealthProgressBarTest: ProgressBar = $Indicator/healthVisual/casterHealthProgressBar_TEST
@onready var casterProgressBar: TextureProgressBar = $Indicator/manaVisual/casterProgressBar
@onready var casterHealthProgressBar: TextureProgressBar = $Indicator/healthVisual/casterHealthProgressBar
@onready var casterLabel: Label = $Indicator/manaVisual/casterLabel
@onready var menu_button: MenuButton = $Indicator/MenuButton

var inventory_button: Button
var defence_bar: TextureProgressBar
var defence_label: Label

#MAKE THIS CASTER FOLLOWS THE CAMERA OR THE PLAYER INSTEAD
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu_button.custom_minimum_size = Vector2(76.0, 64.0)
	menu_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_setup_pause_menu()
	_setup_inventory_button()
	_setup_defence_bar()
	var classType: Variant = SaveManager.data.get("flags", {}).get("isFromHogward")
	#display word mana if player class was mage, warrior otherwise (Unknown if classless)
	if classType != null:
		casterLabel.text = "Mana" if SaveManager.data["flags"]["isFromHogward"] else "Energy"
	else:
		casterLabel.text = "Unknown"
	#get_tree().debug_collisions_hint = true

func _setup_inventory_button() -> void:
	inventory_button = Button.new()
	inventory_button.name = "InventoryButton"
	inventory_button.text = "INV"
	inventory_button.custom_minimum_size = Vector2(72.0, 64.0)
	inventory_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inventory_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	inventory_button.focus_mode = Control.FOCUS_NONE
	inventory_button.add_theme_font_override("font", UI_FONT)
	inventory_button.add_theme_font_size_override("font_size", 13)
	inventory_button.add_theme_color_override("font_color", Color.WHITE)
	inventory_button.add_theme_color_override("font_hover_color", Color(0.55, 0.92, 1.0))
	inventory_button.add_theme_stylebox_override("normal", _inventory_button_style(INVENTORY_BUTTON_NORMAL))
	inventory_button.add_theme_stylebox_override("pressed", _inventory_button_style(INVENTORY_BUTTON_PRESSED))
	inventory_button.add_theme_stylebox_override("hover", _inventory_button_style(INVENTORY_BUTTON_NORMAL))
	inventory_button.add_theme_stylebox_override("disabled", _inventory_button_style(INVENTORY_BUTTON_PRESSED))
	var indicator: HBoxContainer = $Indicator
	indicator.add_child(inventory_button)
	indicator.move_child(inventory_button, indicator.get_node("VSeparator").get_index())
	inventory_button.pressed.connect(_on_inventory_button_pressed)
	inventory_button.visible = GlobalInputDetection.inputType() != 0

func _setup_defence_bar() -> void:
	var health_visual: VBoxContainer = $Indicator/healthVisual
	var health_label: Label = $Indicator/healthVisual/healthLabel
	defence_bar = casterHealthProgressBar.duplicate() as TextureProgressBar
	defence_bar.name = "defenceProgressBar"
	defence_bar.min_value = 0.0
	defence_bar.max_value = 100.0
	defence_bar.value = 0.0
	health_visual.add_child(defence_bar)
	health_visual.move_child(defence_bar, health_label.get_index() + 1)
	defence_label = health_label.duplicate() as Label
	defence_label.name = "defenceLabel"
	defence_label.text = "Defence"
	health_visual.add_child(defence_label)
	health_visual.move_child(defence_label, defence_bar.get_index() + 1)
	defence_bar.hide()
	defence_label.hide()

func _inventory_button_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 8.0
	style.texture_margin_top = 8.0
	style.texture_margin_right = 8.0
	style.texture_margin_bottom = 8.0
	return style

func _on_inventory_button_pressed() -> void:
	var player_view := get_parent()
	if player_view != null and player_view.has_method("toggle_inventory_from_ui"):
		player_view.call("toggle_inventory_from_ui")

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
func _process(_delta: float) -> void:
	#please make this only changing when an external variable wants to interfere 
	var player_data: Dictionary = SaveManager.data.get("player", {})
	casterHealthProgressBar.value = float(player_data.get("health", 100.0))
	casterProgressBar.value = float(player_data.get("caster", 100.0))
	var current_defence := int(player_data.get("defence", 0))
	var max_defence := maxi(1, int(player_data.get("maxDefence", 100)))
	defence_bar.max_value = max_defence
	defence_bar.value = current_defence
	defence_bar.visible = current_defence > 0
	defence_label.visible = current_defence > 0
	var flags: Dictionary = SaveManager.data.get("flags", {})
	var movement_only: bool = flags.get("isTutorialDone", false) != true and str(flags.get("tutorial_stage", "")) == "move_to_orb"
	if inventory_button != null:
		inventory_button.visible = GlobalInputDetection.inputType() != 0 and not movement_only
	menu_button.visible = not movement_only
