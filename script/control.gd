extends CanvasLayer

signal ui_closed

const UI_FONT := preload("res://UI/fonts_setting/VCR.ttf")
const BUTTON_NORMAL := preload("res://UI/texture/button_unpressed.png")
const BUTTON_PRESSED := preload("res://UI/texture/button_pressed.png")
const BUTTON_HOVER := preload("res://UI/texture/button_hover.png")
const BUTTON_DISABLED := preload("res://UI/texture/button_disable.png")

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
	
	# Populate the grid with slots
	_populate_grid(12)

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

	# Push the status label lower down so it occupies its own space below the grid
	status_label.position = Vector2(24.0, 260.0)
	status_label.size = Vector2(450.0, 30.0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.text = "This chest is empty for now."
	status_label.add_theme_font_override("font", UI_FONT)
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.84))
	status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	status_label.add_theme_constant_override("outline_size", 2)

	close_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close_button.offset_left = -164.0
	close_button.offset_top = 18.0
	close_button.offset_right = -24.0
	close_button.offset_bottom = 68.0
	close_button.add_theme_font_override("font", UI_FONT)
	close_button.add_theme_font_size_override("font_size", 16)
	close_button.add_theme_color_override("font_color", Color.WHITE)
	close_button.add_theme_color_override("font_hover_color", Color(0.55, 0.92, 1.0))
	close_button.add_theme_stylebox_override("normal", _button_style(BUTTON_NORMAL))
	close_button.add_theme_stylebox_override("pressed", _button_style(BUTTON_PRESSED))
	close_button.add_theme_stylebox_override("hover", _button_style(BUTTON_HOVER))
	close_button.add_theme_stylebox_override("disabled", _button_style(BUTTON_DISABLED))
	close_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _populate_grid(slot_count: int) -> void:
	if not ITEM_SLOT_SCENE or not item_grid:
		return

	for child in item_grid.get_children():
		child.queue_free()
		
	for i in range(slot_count):
		var slot = ITEM_SLOT_SCENE.instantiate()
		item_grid.add_child(slot)

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
