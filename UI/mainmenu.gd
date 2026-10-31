extends Control

const SETTINGS_THEME := preload("res://UI/fonts_setting/mainMenuConf.tres")
const UI_FONT := preload("res://UI/fonts_setting/VCR.ttf")
const BUTTON_NORMAL := preload("res://UI/texture/button_unpressed.png")
const BUTTON_PRESSED := preload("res://UI/texture/button_pressed.png")
const BUTTON_HOVER := preload("res://UI/texture/button_hover.png")
const BUTTON_DISABLED := preload("res://UI/texture/button_disable.png")

#buttons
@onready var startNewBtn: Button = $VBoxContainer/HBoxContainer/ButtonContainer/StartNew
@onready var continueBtn: Button = $VBoxContainer/HBoxContainer/ButtonContainer/Continue
@onready var settingBtn: Button = $VBoxContainer/HBoxContainer/ButtonContainer/Setting
@onready var exitBtn: Button = $VBoxContainer/HBoxContainer/ButtonContainer/Exit

#popups & UI
@onready var canvasLayer: CanvasLayer = $CanvasLayer
@onready var colorRect: ColorRect = $CanvasLayer/ColorRect
@onready var startNewConfirm: ConfirmationDialog = $CanvasLayer/StartNewConfirm
@onready var namePromptWindow: Window = $CanvasLayer/namePromptWindow
@onready var playerNameField: LineEdit = $CanvasLayer/namePromptWindow/HBoxContainer/VBoxContainer/playerNameField

var settingsWindow: Window
var inputModeOption: OptionButton

enum PopupType { NONE, CONFIRM_OVERWRITE, NAME_PROMPT }

#======================================
#          INITIAL FUNCTION
#======================================
func _ready() -> void:
	_style_new_game_confirmation()
	_create_settings_window()
	#hide all popups on startup
	popupControl(false)
	
	#disable Continue button if no save file exists
	continueBtn.disabled = not SaveManager.hasSaveFile()

#======================================
#             FUNCTIONS
#======================================
func popupControl(visibility: bool, which: PopupType = PopupType.NONE) -> void:
	canvasLayer.visible = visibility
	colorRect.visible = visibility
	
	#always hide both windows first to prevent overlap
	startNewConfirm.visible = false
	namePromptWindow.visible = false
	
	if visibility:
		match which:
			PopupType.CONFIRM_OVERWRITE:
				startNewConfirm.popup_centered()
			PopupType.NAME_PROMPT:
				namePromptWindow.visible = true
				playerNameField.clear()
				playerNameField.grab_focus() # Automatically focuses the text box for typing

func startGame() -> void:
	#ask for confirmation if the player already has save data
	if SaveManager.hasSaveFile():
		popupControl(true, PopupType.CONFIRM_OVERWRITE)
	else:
		SaveManager.startNew()
		popupControl(true, PopupType.NAME_PROMPT)

func _create_settings_window() -> void:
	settingsWindow = Window.new()
	settingsWindow.title = "Settings"
	settingsWindow.size = Vector2i(440, 280)
	settingsWindow.unresizable = true
	settingsWindow.borderless = true
	settingsWindow.transparent = true
	settingsWindow.transparent_bg = true
	settingsWindow.transient = true
	settingsWindow.exclusive = true
	settingsWindow.theme = SETTINGS_THEME
	settingsWindow.close_requested.connect(_on_settings_close_requested)
	add_child(settingsWindow)
	settingsWindow.hide()
	var backdrop := TextureRect.new()
	backdrop.name = "TexturedBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.texture = BUTTON_NORMAL
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settingsWindow.add_child(backdrop)

	var layout := VBoxContainer.new()
	settingsWindow.add_child(layout)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 28.0
	layout.offset_top = 24.0
	layout.offset_right = -28.0
	layout.offset_bottom = -24.0
	layout.add_theme_constant_override("separation", 14)

	var heading := Label.new()
	heading.text = "INPUT SETTINGS"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 24)
	layout.add_child(heading)

	var input_label := Label.new()
	input_label.text = "Choose how you control the game"
	input_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(input_label)

	inputModeOption = OptionButton.new()
	inputModeOption.add_item("Keyboard")
	inputModeOption.add_item("Touchscreen")
	inputModeOption.custom_minimum_size = Vector2(0.0, 46.0)
	inputModeOption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_texture_button(inputModeOption)
	inputModeOption.item_selected.connect(_on_input_mode_selected)
	var options_popup := inputModeOption.get_popup()
	options_popup.add_theme_stylebox_override("panel", _texture_style(BUTTON_NORMAL))
	options_popup.add_theme_font_override("font", UI_FONT)
	options_popup.add_theme_color_override("font_color", Color(0.92, 0.9, 1.0))
	options_popup.add_theme_color_override("font_hover_color", Color(0.55, 0.92, 1.0))
	layout.add_child(inputModeOption)

	var hint := Label.new()
	hint.text = "Touchscreen mode shows the on-screen controls."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(hint)

	var done_button := Button.new()
	done_button.text = "DONE"
	done_button.custom_minimum_size = Vector2(0.0, 46.0)
	_style_texture_button(done_button)
	done_button.pressed.connect(settingsWindow.hide)
	layout.add_child(done_button)

func _style_new_game_confirmation() -> void:
	startNewConfirm.borderless = true
	startNewConfirm.unresizable = true
	startNewConfirm.theme = startNewConfirm.theme.duplicate() as Theme
	startNewConfirm.theme.set_stylebox("panel", "Panel", _texture_style(BUTTON_NORMAL))
	startNewConfirm.theme.set_color("font_color", "Label", Color(0.94, 0.91, 1.0))
	startNewConfirm.theme.set_color("font_outline_color", "Label", Color(0.04, 0.03, 0.07))
	var dialog_label := startNewConfirm.get_label()
	dialog_label.add_theme_font_override("font", UI_FONT)
	dialog_label.add_theme_font_size_override("font_size", 22)
	_style_texture_button(startNewConfirm.get_ok_button())
	_style_texture_button(startNewConfirm.get_cancel_button())

func _style_texture_button(button: Button) -> void:
	button.add_theme_font_override("font", UI_FONT)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color(0.55, 0.92, 1.0))
	button.add_theme_stylebox_override("normal", _texture_style(BUTTON_NORMAL))
	button.add_theme_stylebox_override("pressed", _texture_style(BUTTON_PRESSED))
	button.add_theme_stylebox_override("hover", _texture_style(BUTTON_HOVER))
	button.add_theme_stylebox_override("disabled", _texture_style(BUTTON_DISABLED))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _texture_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 24.0
	style.texture_margin_top = 24.0
	style.texture_margin_right = 24.0
	style.texture_margin_bottom = 24.0
	return style

#======================================
#              BUTTONS
#======================================
func _on_start_new_pressed() -> void:
	startGame()

func _on_continue_pressed() -> void:
	SaveManager.loadGame()
	var currentScene: String = SaveManager.data.get("current_area", "res://world/level_1.tscn")
	get_tree().change_scene_to_file(currentScene)

func _on_setting_pressed() -> void:
	inputModeOption.select(GlobalInputDetection.inputType())
	settingsWindow.popup_centered()

func _on_input_mode_selected(index: int) -> void:
	GlobalInputDetection.setInputMode(index)

func _on_settings_close_requested() -> void:
	settingsWindow.hide()

func _on_exit_pressed() -> void:
	get_tree().quit()

#======================================
#           POPUP SIGNALS
#======================================
func _on_start_new_confirm_confirmed() -> void:
	if SaveManager.hasSaveFile():
		var err := DirAccess.remove_absolute(SaveManager.USER_SAVE_PATH)
		if err == OK:
			print("[SYSTEM] User save file deleted!")
		else:
			print("[SYSTEM] Failed to delete save file -> Error code: ", err)
	
	#disable Continue button, initialize fresh data, and jump straight to Name Prompt
	continueBtn.disabled = true
	SaveManager.startNew()
	popupControl(true, PopupType.NAME_PROMPT)

func _on_start_new_confirm_canceled() -> void:
	popupControl(false)

func playerHasEnteredName() -> void:
	#strip leading/trailing spaces and verify the name is not blank
	var clean_name := playerNameField.text.strip_edges()
	
	if not clean_name.is_empty():
		SaveManager.data["player"]["name"] = clean_name
		SaveManager.saveGame()
		popupControl(false)
		
		var firstScene: String = SaveManager.data.get("current_area", "res://world/level_1.tscn")
		get_tree().change_scene_to_file(firstScene)
