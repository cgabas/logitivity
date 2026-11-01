extends RefCounted
class_name ItemRegistry

const ITEMS: Dictionary = {
	"potion_empty": {
		"name": "Empty Potion",
		"icon": preload("res://sprite/items/potion_empty.png"),
		"type": "empty_potion"
	},
	"potion_attack": {
		"name": "Attack Potion",
		"icon": preload("res://sprite/items/potion_attack.png"),
		"type": "potion"
	},
	"potion_crit": {
		"name": "Critical Potion",
		"icon": preload("res://sprite/items/potion_crit.png"),
		"type": "potion"
	},
	"potion_defence": {
		"name": "Defence Potion",
		"icon": preload("res://sprite/items/potion_defence.png"),
		"type": "potion"
	},
	"potion_healing": {
		"name": "Healing Potion",
		"icon": preload("res://sprite/items/potion_healing.png"),
		"type": "potion"
	},
	"potion_poison": {
		"name": "Poison Potion",
		"icon": preload("res://sprite/items/potion_poison.png"),
		"type": "potion"
	},
	"potion_speed": {
		"name": "Speed Potion",
		"icon": preload("res://sprite/items/potion_speed.png"),
		"type": "potion"
	}
}

static func get_item(item_id: String) -> Dictionary:
	var item: Variant = ITEMS.get(item_id, {})
	return item.duplicate() if item is Dictionary else {}

static func random_potion() -> Dictionary:
	var potion_ids: Array[String] = []
	for item_id in ITEMS:
		var item_data: Dictionary = ITEMS[item_id]
		if item_data.get("type") == "potion":
			potion_ids.append(str(item_id))
	if potion_ids.is_empty():
		return {}
	var selected_id := potion_ids[randi_range(0, potion_ids.size() - 1)]
	var selected_item := get_item(selected_id)
	selected_item["id"] = selected_id
	return selected_item

static func random_stat_potion() -> Dictionary:
	var potion_ids: Array[String] = ["potion_attack", "potion_crit", "potion_defence", "potion_speed"]
	var selected_id := potion_ids[randi_range(0, potion_ids.size() - 1)]
	var selected_item := get_item(selected_id)
	selected_item["id"] = selected_id
	return selected_item
