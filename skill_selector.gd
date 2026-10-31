extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	self.hide() # Ensures it starts closed

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_close_menu()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("toggle_skill_menu"):
		# Prevent crash if the flags dictionary isn't loaded yet
		if not SaveManager.data.has("flags"):
			return
			
		# ONLY toggle the UI if the player is explicitly a Warrior (false)
		# This automatically blocks Mage (true) and Unknown (null)
		if SaveManager.data["flags"].get("isFromHogward") == false:
			if not visible and get_tree().paused:
				return
			self.visible = not self.visible
			get_tree().paused = visible
			get_viewport().set_input_as_handled()

# Connect this to your UI Button's 'pressed' signal

func _on_btn_skill_1_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set("equipped_warrior_skill", "flash_step")
		_close_menu()
		print("Equipped Flash Step")


func _on_btn_skill_2_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set("equipped_warrior_skill", "uppercut")
		_close_menu()
		print("Equipped Uppercut")

func _close_menu() -> void:
	hide()
	get_tree().paused = false
