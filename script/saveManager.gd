extends Node

#NOTE TO SELF: change this if needed in the near future
const TEMPLATE_SAVE_PATH = "res://temp/defaultSaves.json"
const USER_SAVE_PATH = "user://playerStats.json"

#temp storage for player stats
var data: Dictionary = {}

#======================================
#              INITIAL
#======================================
func _ready() -> void:
	#creating a temp duplicate of the data itself to prevent data corrupt when game crash
	OS.set_use_file_access_save_and_swap(true)

#======================================
#           GAMES FUNCTIONS
#======================================

#quit game if 'X' on window was pressed
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		saveGame()
		get_tree().quit()

#return TRUE if user file containing their game stats didn't exist
func hasSaveFile() -> bool:
	return FileAccess.file_exists(USER_SAVE_PATH)

#start a new game
func startNew() -> void:
	data = readJSON(TEMPLATE_SAVE_PATH)
	#create new file
	saveGame()

#save game data inside Dictionary -> 'data'
func saveGame() -> void:
	var fileObj := FileAccess.open(USER_SAVE_PATH, FileAccess.WRITE)
	#quit func if read file are failed
	if fileObj == null:
		push_error("[ERROR] Failed to save game -> ", FileAccess.get_open_error())
		return
	#use \t because I'am using tab key to indent my JSON
	fileObj.store_string(JSON.stringify(data, "\t"))
	fileObj.close()

#load existing game from user JSON
func loadGame() -> bool:
	#check if save file exist
	if !hasSaveFile():
		push_warning("[WARNING] No save file was found to continue! -> ")
		return false
		#check user data integrity
	data = readJSON(USER_SAVE_PATH)
	#merge any new data key if found missing
	var defaultData := readJSON(TEMPLATE_SAVE_PATH)
	mergeMissingKey(data, defaultData)
	return true

#to read JSON file duh...
func readJSON(path: String) -> Dictionary:
	#return empty dictionary if the file didn't exits
	if !FileAccess.file_exists(path):
		push_error("[NOTICE] JSON file not found, at -> ", path)
		return {}
	#open the file for reading and feed it to JSON parsing function
	var file := FileAccess.open(path, FileAccess.READ)
	var parsedString = JSON.parse_string(file.get_as_text())
	#return parsed string of the JSON if the data type is correct
	return parsedString if parsedString is Dictionary else {}

#find if there is any missing key and patch it with the current one
func mergeMissingKey(target: Dictionary, patch: Dictionary) -> void:
	for key in patch:
		if !target.has(key):
			target[key] = patch[key]
		elif (target[key] is Dictionary) && (patch[key] is Dictionary):
			mergeMissingKey(target[key], patch[key])
