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
	# Initialize defaults when a scene is launched directly from the editor.
	# Normal New Game still replaces this with a fresh copy of the template.
	if hasSaveFile():
		loadGame()
	else:
		data = readJSON(TEMPLATE_SAVE_PATH)

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
	_capture_world_state()
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
	# Preserve old saves whose treeOfLife was stored as an array while migrating
	# it to the outline/skill structure used by the inventory skill-tree tab.
	if data.get("treeOfLife") is Array:
		data["treeOfLife"] = defaultData.get("treeOfLife", {}).duplicate(true)
	if not data.get("player") is Dictionary:
		data["player"] = {}
	data["player"]["skill_points"] = int(data["player"].get("skill_points", 0))
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

func _capture_world_state() -> void:
	if data.is_empty() or not data.has("player"):
		return
	var player_node := get_tree().get_first_node_in_group("player")
	if player_node != null:
		var facing: Vector2 = player_node.get("recordLastDirection")
		data["player"]["facing_direction"] = {"x": facing.x, "y": facing.y}
		var player_position: Vector2 = player_node.position
		data["player"]["position"] = {"x": player_position.x, "y": player_position.y}
		data["player"]["health"] = player_node.get("health")
		data["player"]["caster"] = player_node.get("mana")
		data["player"]["defence"] = player_node.get("defence")
		data["player"]["maxDefence"] = player_node.get("maxDefence")
		data["player"]["attack"] = player_node.get("attack")
		data["player"]["maxAttack"] = player_node.get("maxAttack")
		var saved_crit_rate: float = float(player_node.get("crit_rate"))
		if float(player_node.get("crit_potion_time_left")) > 0.0:
			saved_crit_rate = player_node.get("crit_rate_before_potion")
		data["player"]["crit_rate"] = saved_crit_rate
	if not data.has("enemies") or not data["enemies"] is Dictionary:
		data["enemies"] = {}
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	var scene_prefix := current_scene.scene_file_path + "::"
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if enemy.has_method("get_save_data"):
			var enemy_key: String = scene_prefix + str(current_scene.get_path_to(enemy))
			data["enemies"][enemy_key] = enemy.get_save_data()
