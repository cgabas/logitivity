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
var confirmOverwritePopup: Control

enum PopupType { NONE, CONFIRM_OVERWRITE, NAME_PROMPT }

#======================================
#          INITIAL FUNCTION
#======================================
func _ready() -> void:
	_style_new_game_confirmation()
	_create_settings_window()
	_create_overwrite_confirmation_popup()
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
	if confirmOverwritePopup != null:
		confirmOverwritePopup.visible = false
	namePromptWindow.visible = false
	
	if visibility:
		match which:
			PopupType.CONFIRM_OVERWRITE:
				confirmOverwritePopup.visible = true
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

func _create_overwrite_confirmation_popup() -> void:
	startNewConfirm.hide()
	confirmOverwritePopup = Control.new()
	confirmOverwritePopup.name = "OverwriteConfirmationPopup"
	confirmOverwritePopup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirmOverwritePopup.mouse_filter = Control.MOUSE_FILTER_STOP
	confirmOverwritePopup.visible = false
	canvasLayer.add_child(confirmOverwritePopup)

	var panel := PanelContainer.new()
	panel.name = "ConfirmationPanel"
	panel.anchor_left = 0.15
	panel.anchor_top = 0.20
	panel.anchor_right = 0.85
	panel.anchor_bottom = 0.80
	panel.add_theme_stylebox_override("panel", _texture_style(BUTTON_NORMAL))
	confirmOverwritePopup.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 28)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(content)

	var message := Label.new()
	message.text = "Wait! You had a saved game here! Doing so will result in losing all of your hardwork. Are you sure about this? :0"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_override("font", UI_FONT)
	message.add_theme_font_size_override("font_size", 26)
	message.add_theme_color_override("font_color", Color.WHITE)
	message.add_theme_color_override("font_outline_color", Color(0.08, 0.035, 0.025))
	message.add_theme_constant_override("outline_size", 3)
	content.add_child(message)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 32)
	content.add_child(buttons)

	var confirm_button := Button.new()
	confirm_button.text = "Yup!"
	confirm_button.custom_minimum_size = Vector2(240.0, 82.0)
	_style_texture_button(confirm_button)
	_pad_texture_button(confirm_button, 28.0, 18.0)
	confirm_button.add_theme_font_size_override("font_size", 24)
	confirm_button.pressed.connect(_on_start_new_confirm_confirmed)
	buttons.add_child(confirm_button)

	var cancel_button := Button.new()
	cancel_button.text = "Never Mind"
	cancel_button.custom_minimum_size = Vector2(240.0, 82.0)
	_style_texture_button(cancel_button)
	_pad_texture_button(cancel_button, 28.0, 18.0)
	cancel_button.add_theme_font_size_override("font_size", 24)
	cancel_button.pressed.connect(_on_start_new_confirm_canceled)
	buttons.add_child(cancel_button)

func _create_settings_window() -> void:
	settingsWindow = Window.new()
	settingsWindow.title = "Settings"
	settingsWindow.size = Vector2i(720, 480)
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
	layout.offset_left = 42.0
	layout.offset_top = 36.0
	layout.offset_right = -42.0
	layout.offset_bottom = -36.0
	layout.add_theme_constant_override("separation", 24)

	var heading := Label.new()
	heading.text = "INPUT SETTINGS"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 30)
	layout.add_child(heading)

	var input_label := Label.new()
	input_label.text = "Choose how you control the game"
	input_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	input_label.add_theme_font_size_override("font_size", 22)
	layout.add_child(input_label)

	inputModeOption = OptionButton.new()
	inputModeOption.add_item("Keyboard")
	inputModeOption.add_item("Touchscreen")
	inputModeOption.custom_minimum_size = Vector2(0.0, 72.0)
	inputModeOption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_texture_button(inputModeOption)
	_pad_texture_button(inputModeOption, 30.0, 16.0)
	inputModeOption.add_theme_font_size_override("font_size", 28)
	inputModeOption.item_selected.connect(_on_input_mode_selected)
	var options_popup := inputModeOption.get_popup()
	options_popup.add_theme_stylebox_override("panel", _texture_style(BUTTON_NORMAL))
	options_popup.add_theme_font_override("font", UI_FONT)
	options_popup.add_theme_font_size_override("font_size", 30)
	options_popup.add_theme_constant_override("item_start_padding", 32)
	options_popup.add_theme_constant_override("item_end_padding", 32)
	options_popup.add_theme_constant_override("v_separation", 38)
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
	done_button.custom_minimum_size = Vector2(0.0, 72.0)
	_style_texture_button(done_button)
	_pad_texture_button(done_button, 30.0, 16.0)
	done_button.add_theme_font_size_override("font_size", 24)
	done_button.pressed.connect(_close_settings_window)
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

func _pad_texture_button(button: Button, horizontal: float, vertical: float) -> void:
	for state in ["normal", "pressed", "hover", "disabled"]:
		var style := button.get_theme_stylebox(state).duplicate() as StyleBox
		style.content_margin_left = horizontal
		style.content_margin_right = horizontal
		style.content_margin_top = vertical
		style.content_margin_bottom = vertical
		button.add_theme_stylebox_override(state, style)

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

func _close_settings_window() -> void:
	if is_instance_valid(settingsWindow):
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
