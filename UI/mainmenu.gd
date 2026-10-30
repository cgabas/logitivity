extends Control

const SETTINGS_THEME := preload("res://UI/fonts_setting/mainMenuConf.tres")

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
				startNewConfirm.visible = true
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
	settingsWindow.transient = true
	settingsWindow.exclusive = true
	settingsWindow.theme = SETTINGS_THEME
	settingsWindow.close_requested.connect(_on_settings_close_requested)
	add_child(settingsWindow)
	settingsWindow.hide()

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
	inputModeOption.item_selected.connect(_on_input_mode_selected)
	layout.add_child(inputModeOption)

	var hint := Label.new()
	hint.text = "Touchscreen mode shows the on-screen controls."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(hint)

	var done_button := Button.new()
	done_button.text = "DONE"
	done_button.custom_minimum_size = Vector2(0.0, 46.0)
	done_button.pressed.connect(settingsWindow.hide)
	layout.add_child(done_button)

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
