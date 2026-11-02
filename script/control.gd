extends CanvasLayer

signal ui_closed

const UI_FONT := preload("res://UI/fonts_setting/VCR.ttf")
const BUTTON_NORMAL := preload("res://UI/texture/button_unpressed.png")
const BUTTON_PRESSED := preload("res://UI/texture/button_pressed.png")
const BUTTON_HOVER := preload("res://UI/texture/button_hover.png")
const BUTTON_DISABLED := preload("res://UI/texture/button_disable.png")
const GOLD_COIN := preload("res://sprite/items/coin.png")
const MAGE_SKILL_ORB := preload("res://UI/texture/mage_orb.png")
const WARRIOR_SKILL_ORB := preload("res://UI/texture/warrior_orb.png")
const ITEM_REGISTRY := preload("res://script/item_registry.gd")

const ITEM_SLOT_SCENE = preload("res://sprite/item_slot.tscn")

@onready var panel: Panel = $InventoryPanel
@onready var title_label: Label = $InventoryPanel/TitleLabel
@onready var item_grid: GridContainer = $InventoryPanel/ItemGrid
@onready var close_button: Button = %CloseButton
@onready var status_label: Label = $InventoryPanel/StatusLabel

# Reference to the chest node currently being looted
var current_chest: Chest = null 

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_style_menu()
	close_button.pressed.connect(_on_close_pressed)
	status_label.text = "Open a chest to see its contents."

func _style_menu() -> void:
	var background := get_node("DimBackground") as ColorRect
	background.color = Color(0.035, 0.025, 0.065, 0.82)

	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -260.0
	panel.offset_top = -190.0
	panel.offset_right = 260.0
	panel.offset_bottom = 190.0
	
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.09, 0.075, 0.14, 0.98)
	panel_style.border_color = Color(0.61, 0.37, 0.26)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(8)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	panel_style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", panel_style)

	title_label.text = "CHEST INVENTORY"
	title_label.position = Vector2(24.0, 18.0)
	title_label.size = Vector2(320.0, 40.0)
	title_label.add_theme_font_override("font", UI_FONT)
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.82, 0.68))
	title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	title_label.add_theme_constant_override("outline_size", 3)

	# Position the grid box clearly below the title
	item_grid.position = Vector2(24.0, 75.0)
	item_grid.size = Vector2(450.0, 160.0)
	item_grid.columns = 4

	status_label.position = Vector2(24.0, 320.0)
	status_label.size = Vector2(472.0, 32.0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.text = "This chest is empty for now."
	status_label.add_theme_font_override("font", UI_FONT)
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.84))
	status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	status_label.add_theme_constant_override("outline_size", 2)

	close_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close_button.offset_left = -184.0
	close_button.offset_top = 18.0
	close_button.offset_right = -24.0
	close_button.offset_bottom = 76.0
	close_button.add_theme_font_override("font", UI_FONT)
	close_button.add_theme_font_size_override("font_size", 18)
	close_button.add_theme_color_override("font_color", Color.WHITE)
	close_button.add_theme_color_override("font_hover_color", Color(0.55, 0.92, 1.0))
	close_button.add_theme_stylebox_override("normal", _button_style(BUTTON_NORMAL))
	close_button.add_theme_stylebox_override("pressed", _button_style(BUTTON_PRESSED))
	close_button.add_theme_stylebox_override("hover", _button_style(BUTTON_HOVER))
	close_button.add_theme_stylebox_override("disabled", _button_style(BUTTON_DISABLED))
	close_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func show_chest_reward(amount: int, already_claimed: bool, includes_skill_orb: bool = false, potion_ids: Array = []) -> void:
	for child in item_grid.get_children():
		item_grid.remove_child(child)
		child.queue_free()
	if already_claimed:
		status_label.text = "This chest has already been looted."
		return

	title_label.text = "CHEST REWARD"
	var potion_count := potion_ids.size()
	status_label.text = "You collected %d Gold Coins, 1 Skill Point, and %d potions!" % [amount, potion_count] if includes_skill_orb and potion_count > 1 else ("You collected %d Gold Coins, 1 Skill Point, and a potion!" % amount if includes_skill_orb and potion_count == 1 else ("You collected %d Gold Coins and 1 Skill Point!" % amount if includes_skill_orb else "You collected %d Gold Coins!" % amount))
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.14, 0.11, 0.18, 1.0)
	card_style.border_color = Color(0.72, 0.56, 0.3)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(6)
	_add_reward_card(GOLD_COIN, "%d Gold Coins" % amount, Color(1.0, 0.86, 0.42), card_style)
	if includes_skill_orb:
		var orb_icon := MAGE_SKILL_ORB if SaveManager.data.get("flags", {}).get("isFromHogward") == true else WARRIOR_SKILL_ORB
		_add_reward_card(orb_icon, "1 Skill Point", Color(0.65, 0.9, 1.0), card_style)
	for potion_id in potion_ids:
		var potion_data := ITEM_REGISTRY.get_item(str(potion_id))
		if not potion_data.is_empty():
			_add_reward_card(potion_data.get("icon") as Texture2D, str(potion_data.get("name", "Potion")), Color(0.75, 0.95, 0.7), card_style)

func _add_reward_card(icon_texture: Texture2D, label_text: String, label_color: Color, card_style: StyleBoxFlat) -> void:
	var reward_card := PanelContainer.new()
	reward_card.custom_minimum_size = Vector2(108.0, 150.0)
	reward_card.add_theme_stylebox_override("panel", card_style)
	item_grid.add_child(reward_card)
	var contents := VBoxContainer.new()
	contents.alignment = BoxContainer.ALIGNMENT_CENTER
	contents.add_theme_constant_override("separation", 8)
	reward_card.add_child(contents)
	var icon := TextureRect.new()
	icon.texture = icon_texture
	icon.custom_minimum_size = Vector2(52.0, 52.0)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	contents.add_child(icon)
	var reward_label := Label.new()
	reward_label.text = label_text
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_label.add_theme_font_override("font", UI_FONT)
	reward_label.add_theme_font_size_override("font_size", 14)
	reward_label.add_theme_color_override("font_color", label_color)
	contents.add_child(reward_label)

func _button_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 12.0
	style.texture_margin_top = 12.0
	style.texture_margin_right = 12.0
	style.texture_margin_bottom = 12.0
	return style

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("player_do") or event.is_action_pressed("ui_cancel"):
		_close_ui()
		get_viewport().set_input_as_handled()

func _on_close_pressed() -> void:
	_close_ui()

func _on_dim_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_close_ui()
	elif event is InputEventScreenTouch and event.pressed:
		_close_ui()

func _close_ui() -> void:
	ui_closed.emit()
	queue_free()

# Receives the array of items and the chest node reference from chest.gd
func set_chest_data(chest_items: Array[Dictionary], chest_node: Chest = null, total_slots: int = 12) -> void:
	current_chest = chest_node
	
	# Clear out any default children first
	for child in item_grid.get_children():
		child.queue_free()
		
	# Instantiate all slots
	for i in range(total_slots):
		var slot = ITEM_SLOT_SCENE.instantiate()
		item_grid.add_child(slot)
		
		# If this slot index has an item, display it and connect click event
		if i < chest_items.size() and not chest_items[i].is_empty():
			var item = chest_items[i]
			slot.display_item(item.get("icon"), item.get("quantity", 1))
			
			# Connect click input directly to loot this slot index
			var slot_index = i
			slot.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					_on_chest_slot_clicked(slot_index)
				elif event is InputEventScreenTouch and event.pressed:
					_on_chest_slot_clicked(slot_index)
			)
		else:
			slot.clear_slot()
			
	# Update status label
	if chest_items.is_empty() or chest_items.all(func(item): return item.is_empty()):
		status_label.text = "This chest is empty."
	else:
		status_label.text = ""

# Call this when the player clicks on slot index `slot_index` in the chest UI
func _on_chest_slot_clicked(slot_index: int) -> void:
	if not current_chest or slot_index >= current_chest.items.size():
		return
		
	var item = current_chest.items[slot_index]
	
	# If the slot is already empty, do nothing
	if item.is_empty() or item.get("quantity", 0) <= 0:
		return
		
	# Try adding the item to the global player inventory manager
	var added_successfully = InventoryManager.add_item(
		item.get("id"),
		item.get("name"),
		item.get("icon"),
		item.get("quantity")
	)
	
	if added_successfully:
		# If successfully added, clear that slot from the chest's data array
		current_chest.items[slot_index] = {} 
		
		# Refresh the UI grid immediately to reflect the change
		set_chest_data(current_chest.items, current_chest)
