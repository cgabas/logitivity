extends Control

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

enum PopupType { NONE, CONFIRM_OVERWRITE, NAME_PROMPT }

#======================================
#          INITIAL FUNCTION
#======================================
func _ready() -> void:
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

#======================================
#              BUTTONS
#======================================
func _on_start_new_pressed() -> void:
	startGame()

func _on_continue_pressed() -> void:
	SaveManager.loadGame()
	var currentScene: String = SaveManager.data.get("current_area", "res://world/level_1.tscn")
	get_tree().change_scene_to_file(currentScene)

# Setting - SOON TO BE ADDED
func _on_setting_pressed() -> void:
	pass

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
