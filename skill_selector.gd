extends CanvasLayer

func _ready() -> void:
	self.hide() # Ensures it starts closed

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_skill_menu"):
		
		# Prevent crash if the flags dictionary isn't loaded yet
		if not SaveManager.data.has("flags"):
			return
			
		# ONLY toggle the UI if the player is explicitly a Warrior (false)
		# This automatically blocks Mage (true) and Unknown (null)
		if SaveManager.data["flags"].get("isFromHogward") == false:
			self.visible = not self.visible

# Connect this to your UI Button's 'pressed' signal

func _on_btn_skill_1_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.equipped_warrior_skill = "flash_step"
		print("Equipped Flash Step")


func _on_btn_skill_2_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.equipped_warrior_skill = "uppercut"
		print("Equipped Uppercut")
