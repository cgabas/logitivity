extends Control

@onready var startNewBtn: Button = $VBoxContainer/HBoxContainer/ButtonContainer/StartNew
@onready var continueBtn: Button = $VBoxContainer/HBoxContainer/ButtonContainer/Continue
@onready var settingBtn: Button = $VBoxContainer/HBoxContainer/ButtonContainer/Setting
@onready var exitBtn: Button = $VBoxContainer/HBoxContainer/ButtonContainer/Exit
@onready var startNewConfirm: ConfirmationDialog = $CanvasLayer/StartNewConfirm
@onready var playerNameField: LineEdit = $CanvasLayer/namePromptWindow/HBoxContainer/VBoxContainer/playerNameField
@onready var namePromptWindow: Window = $CanvasLayer/namePromptWindow
@onready var canvasLayer: CanvasLayer = $CanvasLayer
@onready var colorRect: ColorRect = $CanvasLayer/ColorRect

#access the max health and stats inside the JSON file
var confirm_startNew := false

#======================================
#          INITIAL FUNCTION
#======================================
func _ready() -> void:
	#gray the continue button if the player never play this game before
	#and allow player to start new without confirmation popup
	if !SaveManager.hasSaveFile():
		continueBtn.disabled = true
		confirm_startNew = true

#======================================
#            PROCESS
#======================================
#func _process(delta: float) -> void:
	#pass

#control which popup to appear
func popupControl(visibility: bool, which: int = 0) -> void:
	canvasLayer.visible = visibility
	colorRect.visible = visibility
	match which:
		1: startNewConfirm.visible = visibility
		2: namePromptWindow.visible = visibility
		_:
			namePromptWindow.visible = visibility
			startNewConfirm.visible = visibility

func startGame() -> void:
	#confirmation on user action (if they had save data)
	if SaveManager.hasSaveFile():
		popupControl(true, 1)
	else:
		#create a new user data and overrides the previous one (if any)
		SaveManager.startNew()
		#request user name
		popupControl(true, 2)
		#direct user to the first scene for them to do a tutorial
		var firstScene: String = SaveManager.data.get("current_area", "res://world/level_1.tscn")
		get_tree().change_scene_to_file(firstScene)

#======================================
#              BUTTONS
#======================================

#start new
func _on_start_new_pressed() -> void:
	startGame()

#continue
func _on_continue_pressed() -> void:
	SaveManager.loadGame()
	var currentScene: String = SaveManager.data.get("current_area")
	get_tree().change_scene_to_file(currentScene)

#setting
func _on_setting_pressed() -> void:
	pass # Replace with function body.

#exit
#save game first and then quit
func _on_exit_pressed() -> void:
	SaveManager.saveGame()
	get_tree().quit()

#create new game, call a func to create a new game
func _on_start_new_confirm_confirmed() -> void:
	#check the file first and verify its directory before deletion
	if SaveManager.hasSaveFile():
		var dir = DirAccess.open(SaveManager.USER_SAVE_PATH.get_base_dir())
		if dir:
			var deletionMsg = dir.remove(SaveManager.USER_SAVE_PATH.get_file())
			if deletionMsg == OK:
				print("[SYSTEM] User file deleted!")
			else:
				print("[SYSTEM] Failed to delete file -> ", deletionMsg)
		else:
			print("[SYSTEM] Failed to access the directory")
	else:
		print("[SYSTEM] User file does not exist!")
	#close popup
	popupControl(false)
	#restart the mainmenu
	get_tree().reload_current_scene()
#close popup
func _on_start_new_confirm_canceled() -> void:
	popupControl(false)

#confirm name
func playerHasEnteredName() -> void:
	#take the string from the input field (playerNameField)
	if playerNameField.text is String && not "":
		SaveManager.data["player"]["name"] = playerNameField.text
		SaveManager.saveGame()
		#hide the window
		popupControl(false)
