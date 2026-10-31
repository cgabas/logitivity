extends Node

# Global player inventory array holding item dictionaries
var player_items: Array[Dictionary] = [
	{
		"id": "coin",
		"name": "Gold Coin",
		"icon": preload("res://temporarySprite/coin.png"),
		"quantity": 5
	}
]

# Max slots in the player's inventory grid
@export var max_slots: int = 12

# Function to add an item globally
const MAX_STACK = 64

func add_item(item_id: String, item_name: String, icon: Texture2D, quantity: int) -> bool:
	# Try to stack with existing items first
	for item in player_items:
		if item.get("id") == item_id and item.get("quantity", 0) < MAX_STACK:
			item["quantity"] += quantity
			return true
			
	# Otherwise, find an empty slot or append if under limit
	if player_items.size() < max_slots:
		player_items.append({
			"id": item_id,
			"name": item_name,
			"icon": icon,
			"quantity": quantity
		})
		return true
		
	return false # Inventory full_process(delta: float) -> void:
	pass
