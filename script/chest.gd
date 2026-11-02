extends Area2D
class_name Chest

const ITEM_REGISTRY := preload("res://script/item_registry.gd")

@export_category("Chest Settings")
@export var chest_id: String = "chest_01"
@export var is_opened: bool = false
@export var gold_coin_reward: int = 50
@export var skill_point_reward: int = 1
@export var chest_ui: PackedScene

# Chest loot data array with coin, health potion, and mana potion
@export var items: Array[Dictionary] = [
	{
		"id": "coin",
		"name": "Gold Coin",
		"icon": preload("res://temporarySprite/coin.png"),
		"quantity": 10
	},
	{
		"id": "health_potion",
		"name": "Health Potion",
		"icon": preload("res://temporarySprite/HealthPot.png"),
		"quantity": 2
	},
	{
		"id": "mana_potion",
		"name": "Mana Potion",
		"icon": preload("res://temporarySprite/manaPot.png"),
		"quantity": 1
	}
]

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var active_ui: CanvasLayer = null
var reward_claimed: bool = false
var reward_potion_ids: Array[String] = []

func _ready() -> void:
	if name == "Chest":
		chest_id = "tutorial_chest"
	if not is_in_group("Items"):
		add_to_group("Items")
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null:
		var save_data: Dictionary = save_manager.get("data")
		var saved_chests: Variant = save_data.get("chests", {})
		if saved_chests is Dictionary:
			reward_claimed = saved_chests.get(chest_id, false) == true
		if chest_id == "tutorial_chest" and reward_claimed and save_data.get("flags", {}).get("isTutorialDone", false) != true and not saved_chests.get("tutorial_potions_updated", false):
			reward_potion_ids = _ensure_tutorial_potions(save_data)
			save_manager.set("data", save_data)
			save_manager.call("saveGame")
	is_opened = reward_claimed
	if sprite.sprite_frames.has_animation("chestOpenClose"):
		sprite.sprite_frames.set_animation_loop("chestOpenClose", false)
	_update_visual_state()

func interact() -> void:
	if active_ui != null:
		return
	is_opened = true
	sprite.stop()
	sprite.frame = 0
	sprite.play("chestOpenClose")
	var was_claimed := reward_claimed
	if not reward_claimed:
		reward_claimed = true
		var save_manager := get_node_or_null("/root/SaveManager")
		if save_manager != null:
			var save_data: Dictionary = save_manager.get("data")
			var player_data: Dictionary = save_data.get("player", {})
			player_data["coins"] = int(player_data.get("coins", 0)) + gold_coin_reward
			player_data["skill_points"] = int(player_data.get("skill_points", 0)) + skill_point_reward
			save_data["player"] = player_data
			var inventory: Variant = save_data.get("inventory", [])
			if not inventory is Array:
				inventory = []
			if chest_id == "tutorial_chest":
				save_data["inventory"] = inventory
				reward_potion_ids = _ensure_tutorial_potions(save_data)
			else:
				var potion := ITEM_REGISTRY.random_potion()
				var potion_id := str(potion.get("id", ""))
				if not potion_id.is_empty():
					inventory.append(_potion_inventory_entry(potion_id))
					reward_potion_ids.append(potion_id)
				save_data["inventory"] = inventory
			var saved_chests: Variant = save_data.get("chests", {})
			if not saved_chests is Dictionary:
				save_data["chests"] = {}
			save_data["chests"][chest_id] = true
			save_manager.set("data", save_data)
			save_manager.call("saveGame")
	open_ui()
	if active_ui != null and active_ui.has_method("show_chest_reward"):
		active_ui.call("show_chest_reward", gold_coin_reward, was_claimed, not was_claimed, reward_potion_ids)

func _ensure_tutorial_potions(save_data: Dictionary) -> Array[String]:
	var inventory: Variant = save_data.get("inventory", [])
	if not inventory is Array:
		inventory = []
	var has_poison := false
	var stat_potion_id := ""
	for item in inventory:
		if not item is Dictionary:
			continue
		var item_id := str(item.get("id", ""))
		if item_id == "potion_poison":
			has_poison = true
		elif item_id in ["potion_attack", "potion_crit", "potion_defence", "potion_speed"] and stat_potion_id.is_empty():
			stat_potion_id = item_id
	if not has_poison:
		inventory.append(_potion_inventory_entry("potion_poison"))
	if stat_potion_id.is_empty():
		var stat_potion: Dictionary = ITEM_REGISTRY.random_stat_potion()
		stat_potion_id = str(stat_potion.get("id", "potion_attack"))
		inventory.append(_potion_inventory_entry(stat_potion_id))
	save_data["inventory"] = inventory
	var chests: Variant = save_data.get("chests", {})
	if not chests is Dictionary:
		chests = {}
	chests["tutorial_potions_updated"] = true
	save_data["chests"] = chests
	return ["potion_poison", stat_potion_id]

func _potion_inventory_entry(item_id: String) -> Dictionary:
	var item_data: Dictionary = ITEM_REGISTRY.get_item(item_id)
	return {"id": item_id, "name": str(item_data.get("name", item_id)), "type": "potion", "count": 1}

func open_ui() -> void:
	if active_ui:
		return
		
	if chest_ui:
		var ui_instance = chest_ui.instantiate()
		get_tree().current_scene.add_child(ui_instance)
		active_ui = ui_instance
		
		# Pass both the items list AND the chest reference (self) to the UI script
		if active_ui.has_method("set_chest_data"):
			active_ui.set_chest_data(items, self)
		
		get_tree().paused = true
		
		if active_ui.has_signal("ui_closed"):
			active_ui.ui_closed.connect(_on_ui_closed)
	else:
		print("Warning: No Chest UI Scene assigned to chest!")

func _on_ui_closed() -> void:
	active_ui = null
	get_tree().paused = false
	is_opened = false
	sprite.stop()
	sprite.frame = 1
	sprite.play_backwards("chestOpenClose")
	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene.has_method("_on_tutorial_chest_closed"):
		current_scene.call("_on_tutorial_chest_closed")

func _update_visual_state() -> void:
	if not sprite:
		return
	sprite.stop()
	sprite.frame = 1 if is_opened else 0
