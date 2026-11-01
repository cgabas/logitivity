extends CanvasLayer

const UI_FONT := preload("res://UI/fonts_setting/VCR.ttf")
const DEATH_TITLE_FONT := preload("res://UI/fonts_setting/OldLondon.ttf")
const BUTTON_NORMAL := preload("res://UI/texture/button_unpressed.png")
const BUTTON_PRESSED := preload("res://UI/texture/button_pressed.png")
const BUTTON_HOVER := preload("res://UI/texture/button_hover.png")
const BUTTON_DISABLED := preload("res://UI/texture/button_disable.png")
const GOLD_COIN := preload("res://sprite/items/coin.png")
const MAGE_ORB := preload("res://UI/texture/mage_orb.png")
const WARRIOR_ORB := preload("res://UI/texture/warrior_orb.png")
const ARROW_NODE_ICON := preload("res://UI/texture/canvas_outline_arrow_up.png")
const WAVE_NODE_ICON := preload("res://UI/texture/canvas_outline_asterisk.png")
const BLOCK_NODE_ICON := preload("res://UI/texture/canvas_outline_block.png")
const DASH_NODE_ICON := preload("res://UI/texture/effect_speed.png")
const KNOCKBACK_NODE_ICON := preload("res://UI/texture/effect_knockback.png")
const ITEM_REGISTRY := preload("res://script/item_registry.gd")

@onready var mobileControl: Control = $MobileControl

var inventory_menu: Control
var inventory_items: VBoxContainer
var inventory_coins_label: Label
var inventory_title: Label
var inventory_hint_label: Label
var inventory_close_button: Button
var inventory_tabs: TabContainer
var skill_points_label: Label
var skill_graph: Control
var game_over_menu: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_inventory_menu()
	_create_game_over_menu()

# Enable mobile UI controls when touchscreen mode is selected.
func _process(_delta: float) -> void:
	var mage_canvas := get_node_or_null("mageCanvasUI") as Control
	var drawing_spell: bool = mage_canvas != null and mage_canvas.visible
	var touch_controls_enabled: bool = GlobalInputDetection.inputType() != 0 and not drawing_spell
	mobileControl.visible = touch_controls_enabled
	var touch_action_layer := mobileControl.get_node_or_null("CanvasLayer") as CanvasLayer
	if touch_action_layer != null:
		touch_action_layer.visible = touch_controls_enabled

func _unhandled_input(event: InputEvent) -> void:
	if inventory_menu != null and inventory_menu.visible:
		if event.is_action_pressed("open_inventory") or event.is_action_pressed("ui_cancel"):
			if not _requires_tutorial_inventory_choice():
				_close_inventory()
			get_viewport().set_input_as_handled()
		return

	var flags: Dictionary = SaveManager.data.get("flags", {})
	var movement_only: bool = flags.get("isTutorialDone", false) != true and str(flags.get("tutorial_stage", "")) == "move_to_orb"
	if event.is_action_pressed("open_inventory") and not movement_only and not get_tree().paused:
		_open_inventory()
		get_viewport().set_input_as_handled()

func toggle_inventory_from_ui() -> void:
	if game_over_menu != null and game_over_menu.visible:
		return
	if inventory_menu != null and inventory_menu.visible:
		_close_inventory()
	elif not get_tree().paused:
		_open_inventory()

func _create_inventory_menu() -> void:
	inventory_menu = Control.new()
	inventory_menu.name = "InventoryMenu"
	inventory_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inventory_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	inventory_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	inventory_menu.visible = false
	add_child(inventory_menu)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.025, 0.018, 0.045, 0.78)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	inventory_menu.add_child(dimmer)

	var panel := PanelContainer.new()
	panel.name = "InventoryPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -250.0
	panel.offset_top = -205.0
	panel.offset_right = 250.0
	panel.offset_bottom = 205.0
	panel.add_theme_stylebox_override("panel", _popup_style())
	inventory_menu.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	var header := HBoxContainer.new()
	content.add_child(header)
	inventory_title = Label.new()
	inventory_title.text = "PLAYER INVENTORY"
	inventory_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_title.add_theme_font_override("font", UI_FONT)
	inventory_title.add_theme_font_size_override("font_size", 24)
	inventory_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.62))
	header.add_child(inventory_title)

	inventory_close_button = _make_button("CLOSE", Vector2(112.0, 42.0))
	inventory_close_button.pressed.connect(_close_inventory)
	header.add_child(inventory_close_button)
	inventory_tabs = TabContainer.new()
	inventory_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_tabs.tab_changed.connect(_on_inventory_tab_changed)
	content.add_child(inventory_tabs)
	var items_page := VBoxContainer.new()
	items_page.name = "Items"
	items_page.add_theme_constant_override("separation", 14)
	inventory_tabs.add_child(items_page)
	var skills_page := VBoxContainer.new()
	skills_page.name = "Skill Tree"
	skills_page.add_theme_constant_override("separation", 12)
	inventory_tabs.add_child(skills_page)

	var coin_row := HBoxContainer.new()
	coin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	coin_row.add_theme_constant_override("separation", 10)
	items_page.add_child(coin_row)
	var coin_icon := TextureRect.new()
	coin_icon.texture = GOLD_COIN
	coin_icon.custom_minimum_size = Vector2(36.0, 36.0)
	coin_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_row.add_child(coin_icon)
	inventory_coins_label = Label.new()
	inventory_coins_label.add_theme_font_override("font", UI_FONT)
	inventory_coins_label.add_theme_font_size_override("font_size", 19)
	inventory_coins_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	coin_row.add_child(inventory_coins_label)

	var divider := HSeparator.new()
	items_page.add_child(divider)
	var items_heading := Label.new()
	items_heading.text = "ITEMS"
	items_heading.add_theme_font_override("font", UI_FONT)
	items_heading.add_theme_font_size_override("font_size", 17)
	items_heading.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	items_page.add_child(items_heading)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	items_page.add_child(scroll)
	inventory_items = VBoxContainer.new()
	inventory_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_items.add_theme_constant_override("separation", 6)
	scroll.add_child(inventory_items)

	inventory_hint_label = Label.new()
	inventory_hint_label.text = "F / Y: close inventory    •    Esc: close"
	inventory_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inventory_hint_label.add_theme_font_override("font", UI_FONT)
	inventory_hint_label.add_theme_font_size_override("font_size", 13)
	inventory_hint_label.add_theme_color_override("font_color", Color(0.72, 0.72, 0.8))
	items_page.add_child(inventory_hint_label)
	_create_skill_tree_page(skills_page)

func _create_skill_tree_page(page: VBoxContainer) -> void:
	page.alignment = BoxContainer.ALIGNMENT_CENTER
	page.add_theme_constant_override("separation", 4)
	skill_points_label = Label.new()
	skill_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_points_label.add_theme_font_override("font", UI_FONT)
	skill_points_label.add_theme_font_size_override("font_size", 16)
	skill_points_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	page.add_child(skill_points_label)
	skill_graph = Control.new()
	skill_graph.name = "SkillTreeGraph"
	skill_graph.custom_minimum_size = Vector2(420.0, 248.0)
	skill_graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(skill_graph)
	var graph_backdrop := StyleBoxFlat.new()
	graph_backdrop.bg_color = Color(0.035, 0.105, 0.17, 0.98)
	graph_backdrop.border_color = Color(0.12, 0.29, 0.4, 1.0)
	graph_backdrop.set_border_width_all(1)
	graph_backdrop.set_corner_radius_all(8)
	var graph_panel := PanelContainer.new()
	graph_panel.name = "GraphBackdrop"
	graph_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	graph_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	graph_panel.add_theme_stylebox_override("panel", graph_backdrop)
	skill_graph.add_child(graph_panel)
	skill_graph.move_child(graph_panel, 0)

func _create_game_over_menu() -> void:
	game_over_menu = Control.new()
	game_over_menu.name = "GameOverMenu"
	game_over_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	game_over_menu.visible = false
	add_child(game_over_menu)

	var red_background := ColorRect.new()
	red_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	red_background.color = Color(0.25, 0.012, 0.035, 0.92)
	red_background.mouse_filter = Control.MOUSE_FILTER_STOP
	game_over_menu.add_child(red_background)

	var panel := PanelContainer.new()
	panel.name = "DeathPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -310.0
	panel.offset_top = -205.0
	panel.offset_right = 310.0
	panel.offset_bottom = 205.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.075, 0.018, 0.035, 0.97)
	panel_style.border_color = Color(0.72, 0.18, 0.2, 1.0)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(8)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.7)
	panel_style.shadow_size = 14
	panel.add_theme_stylebox_override("panel", panel_style)
	game_over_menu.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 22)
	margin.add_child(content)

	var title := Label.new()
	title.text = "Thou art slain!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", DEATH_TITLE_FONT)
	title.add_theme_font_size_override("font_size", 68)
	title.add_theme_color_override("font_color", Color(1.0, 0.83, 0.78))
	title.add_theme_color_override("font_outline_color", Color(0.12, 0.0, 0.02))
	title.add_theme_constant_override("outline_size", 6)
	content.add_child(title)

	var message := Label.new()
	message.text = "Your journey ends here."
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_override("font", UI_FONT)
	message.add_theme_font_size_override("font_size", 20)
	message.add_theme_color_override("font_color", Color(0.9, 0.78, 0.78))
	content.add_child(message)

	var retry_button := _make_button("TRY AGAIN", Vector2(230.0, 54.0))
	retry_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry_button.pressed.connect(_retry_after_game_over)
	content.add_child(retry_button)
	var menu_button := _make_button("RETURN TO MAIN MENU", Vector2(300.0, 54.0))
	menu_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_button.pressed.connect(_return_to_main_menu)
	content.add_child(menu_button)

func show_game_over() -> void:
	if game_over_menu == null or game_over_menu.visible:
		return
	if inventory_menu != null:
		inventory_menu.hide()
	game_over_menu.show()
	get_tree().paused = true

func _retry_after_game_over() -> void:
	var player_data: Dictionary = SaveManager.data.get("player", {})
	player_data["health"] = player_data.get("maxHealth", 100.0)
	player_data["caster"] = player_data.get("maxCaster", 100.0)
	player_data["position"] = {"x": null, "y": null}
	SaveManager.data["player"] = player_data
	get_tree().paused = false
	get_tree().reload_current_scene()

func _return_to_main_menu() -> void:
	get_tree().paused = false
	SaveManager.saveGame()
	get_tree().change_scene_to_file("res://UI/mainmenu.tscn")

func _popup_style() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = BUTTON_NORMAL
	style.texture_margin_left = 32.0
	style.texture_margin_top = 32.0
	style.texture_margin_right = 32.0
	style.texture_margin_bottom = 32.0
	style.content_margin_left = 30.0
	style.content_margin_top = 24.0
	style.content_margin_right = 30.0
	style.content_margin_bottom = 24.0
	return style

func _make_button(text_value: String, min_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(min_size.x * 1.05 if min_size.x > 0.0 else 0.0, min_size.y * 1.12)
	button.add_theme_font_override("font", UI_FONT)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color(0.6, 0.93, 1.0))
	button.add_theme_stylebox_override("normal", _button_style(BUTTON_NORMAL))
	button.add_theme_stylebox_override("pressed", _button_style(BUTTON_PRESSED))
	button.add_theme_stylebox_override("hover", _button_style(BUTTON_HOVER))
	button.add_theme_stylebox_override("disabled", _button_style(BUTTON_DISABLED))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button

func _button_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 22.0
	style.texture_margin_top = 22.0
	style.texture_margin_right = 22.0
	style.texture_margin_bottom = 22.0
	return style

func _open_inventory() -> void:
	_refresh_inventory()
	inventory_menu.show()
	get_tree().paused = true

func _close_inventory() -> void:
	if inventory_menu == null or not inventory_menu.visible:
		return
	if _requires_tutorial_inventory_choice():
		return
	inventory_menu.hide()
	get_tree().paused = false

func _refresh_inventory() -> void:
	var player_data: Dictionary = SaveManager.data.get("player", {})
	inventory_coins_label.text = "%d Gold Coins" % int(player_data.get("coins", 0))
	_refresh_skill_tree()
	if inventory_hint_label != null:
		if _requires_tutorial_potion_selection():
			var tutorial_stage := str(SaveManager.data.get("flags", {}).get("tutorial_stage", ""))
			if tutorial_stage == "potion_drink_select":
				inventory_title.text = "CHOOSE A STAT POTION"
				inventory_hint_label.text = "Select a stat potion, then tap A / press E to drink it."
			else:
				inventory_title.text = "CHOOSE POISON"
				inventory_hint_label.text = "Select Poison, then hold attack to aim and release to throw."
		elif _requires_tutorial_skill_choice():
			inventory_hint_label.text = "Choose one skill to continue the tutorial."
		else:
			inventory_hint_label.text = "F / Y: close inventory    •    Esc: close"
	for child in inventory_items.get_children():
		inventory_items.remove_child(child)
		child.queue_free()

	var saved_items: Variant = SaveManager.data.get("inventory", [])
	if not saved_items is Array or saved_items.is_empty():
		_add_inventory_label("No items in your inventory yet.")
		return
	for item in saved_items:
		var item_name := "Item"
		var item_count := 1
		var item_icon: Texture2D
		if item is Dictionary:
			item_name = str(item.get("name", item.get("id", "Item")))
			item_count = maxi(1, int(item.get("count", 1)))
			var item_data := ITEM_REGISTRY.get_item(str(item.get("id", "")))
			if not item_data.is_empty():
				item_icon = item_data.get("icon") as Texture2D
				if item_data.get("type") == "potion":
					var item_id := str(item.get("id", ""))
					var player_node := get_tree().get_first_node_in_group("player")
					var selected := player_node != null and str(player_node.get("selected_potion_id")) == item_id
					var tutorial_stage := str(SaveManager.data.get("flags", {}).get("tutorial_stage", ""))
					var allowed_for_tutorial := tutorial_stage != "potion_select" or item_id == "potion_poison"
					if tutorial_stage == "potion_drink_select":
						allowed_for_tutorial = item_id in ["potion_attack", "potion_crit", "potion_defence", "potion_speed"]
					var potion_button := _make_button(("SELECTED  " if selected else "SELECT  ") + item_name + "  x%d" % item_count, Vector2(0.0, 48.0))
					potion_button.disabled = not allowed_for_tutorial
					potion_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					potion_button.icon = item_icon
					potion_button.expand_icon = false
					potion_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
					potion_button.pressed.connect(_select_inventory_potion.bind(item_id))
					inventory_items.add_child(potion_button)
					continue
		else:
			item_name = str(item)
		_add_inventory_label("%s  x%d" % [item_name, item_count], item_icon)

func _add_inventory_label(text_value: String, icon_texture: Texture2D = null) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	inventory_items.add_child(row)
	if icon_texture != null:
		var icon := TextureRect.new()
		icon.texture = icon_texture
		icon.custom_minimum_size = Vector2(36.0, 36.0)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
	var label := Label.new()
	label.text = text_value
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.95))
	row.add_child(label)

func _select_inventory_potion(item_id: String) -> void:
	var player_node := get_tree().get_first_node_in_group("player")
	if player_node != null and player_node.has_method("select_potion"):
		player_node.call("select_potion", item_id)
		inventory_close_button.disabled = false
		var current_scene := get_tree().current_scene
		if current_scene != null and current_scene.has_method("tutorial_potion_selected"):
			current_scene.call("tutorial_potion_selected", item_id)
		_close_inventory()

func _requires_tutorial_skill_choice() -> bool:
	var flags: Dictionary = SaveManager.data.get("flags", {})
	return flags.get("isTutorialDone", false) != true and str(flags.get("tutorial_stage", "")) == "skill_choice"

func _requires_tutorial_inventory_choice() -> bool:
	var flags: Dictionary = SaveManager.data.get("flags", {})
	return flags.get("isTutorialDone", false) != true and str(flags.get("tutorial_stage", "")) in ["skill_choice", "potion_select", "potion_drink_select"]

func _requires_tutorial_potion_selection() -> bool:
	var flags: Dictionary = SaveManager.data.get("flags", {})
	return flags.get("isTutorialDone", false) != true and str(flags.get("tutorial_stage", "")) in ["potion_select", "potion_drink_select"]

func open_tutorial_skill_tree() -> void:
	if inventory_menu == null:
		return
	_refresh_inventory()
	inventory_tabs.current_tab = 1
	inventory_close_button.disabled = true
	inventory_menu.show()
	get_tree().paused = true

func open_tutorial_potion_inventory() -> void:
	if inventory_menu == null:
		return
	_refresh_inventory()
	inventory_tabs.current_tab = 0
	inventory_title.text = "CHOOSE A STAT POTION" if str(SaveManager.data.get("flags", {}).get("tutorial_stage", "")) == "potion_drink_select" else "CHOOSE POISON"
	inventory_close_button.disabled = true
	inventory_menu.show()
	get_tree().paused = true

func _refresh_skill_tree() -> void:
	if skill_points_label == null or skill_graph == null:
		return
	var player_data: Dictionary = SaveManager.data.get("player", {})
	var points := int(player_data.get("skill_points", 0))
	var forced_choice := _requires_tutorial_skill_choice()
	skill_points_label.text = "Skill Points: %d   •   Choose one node" % points if forced_choice else "Skill Points: %d" % points
	for child in skill_graph.get_children():
		if child.name != "GraphBackdrop":
			skill_graph.remove_child(child)
			child.queue_free()
	var graph_width := maxf(skill_graph.size.x, 420.0)
	var center_x := graph_width * 0.5
	var is_mage: bool = SaveManager.data.get("flags", {}).get("isFromHogward") == true
	if is_mage:
		_draw_skill_connection(Vector2(center_x, 61.0), Vector2(center_x, 91.0), true)
		_draw_skill_connection(Vector2(center_x, 145.0), Vector2(center_x, 157.0), true)
		_draw_skill_connection(Vector2(center_x - 103.0, 157.0), Vector2(center_x + 103.0, 157.0), true)
		_draw_skill_connection(Vector2(center_x - 103.0, 157.0), Vector2(center_x - 103.0, 170.0), true)
		_draw_skill_connection(Vector2(center_x + 103.0, 157.0), Vector2(center_x + 103.0, 170.0), true)
		_add_skill_node("class_root", "MAGE", center_x, 34.0, MAGE_ORB, true, false)
		_add_skill_node("arrow", "ARROW", center_x, 118.0, ARROW_NODE_ICON, true, false)
		var tree: Variant = SaveManager.data.get("treeOfLife", {})
		var unlocked: Array = tree.get("unlocked_outlines", ["arrow"]) if tree is Dictionary else ["arrow"]
		_add_skill_node("asterisk", "WAVE", center_x - 103.0, 197.0, WAVE_NODE_ICON, unlocked.has("asterisk"), points > 0, "", "Unlocks the Wave outline for area magic.")
		_add_skill_node("line", "BLOCK", center_x + 103.0, 197.0, BLOCK_NODE_ICON, unlocked.has("line"), points > 0, "", "Unlocks the Block outline for barriers and utility spells.")
	else:
		var tree: Variant = SaveManager.data.get("treeOfLife", {})
		var unlocked_skills: Array = tree.get("unlocked_skills", []) if tree is Dictionary else []
		_draw_skill_connection(Vector2(center_x, 61.0), Vector2(center_x, 106.0), true)
		_draw_skill_connection(Vector2(center_x - 103.0, 106.0), Vector2(center_x + 103.0, 106.0), true)
		_draw_skill_connection(Vector2(center_x - 103.0, 106.0), Vector2(center_x - 103.0, 158.0), true)
		_draw_skill_connection(Vector2(center_x + 103.0, 106.0), Vector2(center_x + 103.0, 158.0), true)
		_add_skill_node("class_root", "WARRIOR", center_x, 34.0, WARRIOR_ORB, true, false)
		_add_skill_node("flash_step", "DASH", center_x - 103.0, 185.0, DASH_NODE_ICON, unlocked_skills.has("flash_step"), points > 0, "", "Unlocks Dash on the player_skill input.")
		_add_skill_node("uppercut", "KNOCKBACK", center_x + 103.0, 185.0, KNOCKBACK_NODE_ICON, unlocked_skills.has("uppercut"), points > 0, "", "Unlocks a heavy strike that knocks an enemy back.")

func _draw_skill_connection(from_point: Vector2, to_point: Vector2, connected: bool) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([from_point, to_point])
	line.width = 4.0
	line.default_color = Color(0.32, 0.72, 0.91, 0.95) if connected else Color(0.18, 0.28, 0.35, 0.8)
	line.z_index = 1
	skill_graph.add_child(line)

func _add_skill_node(skill_id: String, title_text: String, center_x: float, center_y: float, icon: Texture2D, unlocked: bool, can_buy: bool, glyph: String = "", description: String = "") -> void:
	var button := Button.new()
	button.name = "Skill_" + skill_id
	button.position = Vector2(center_x - 27.0, center_y - 27.0)
	button.size = Vector2(54.0, 54.0)
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = description if not description.is_empty() else title_text
	button.disabled = not can_buy or unlocked or skill_id == "class_root" or skill_id == "arrow"
	var node_style := StyleBoxFlat.new()
	node_style.bg_color = Color(0.22, 0.57, 0.75, 1.0) if unlocked else (Color(0.94, 0.73, 0.16, 1.0) if can_buy else Color(0.20, 0.32, 0.40, 1.0))
	node_style.border_color = Color(0.69, 0.9, 0.98, 1.0) if can_buy and not unlocked else Color(0.56, 0.77, 0.84, 1.0)
	node_style.set_border_width_all(2)
	node_style.set_corner_radius_all(27)
	node_style.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
	node_style.shadow_size = 4
	button.add_theme_stylebox_override("normal", node_style)
	button.add_theme_stylebox_override("hover", node_style)
	button.add_theme_stylebox_override("pressed", node_style)
	button.add_theme_stylebox_override("disabled", node_style)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_font_override("font", UI_FONT)
	button.add_theme_font_size_override("font_size", 22)
	if icon != null:
		var icon_view := TextureRect.new()
		icon_view.texture = icon
		icon_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_view.offset_left = 10.0
		icon_view.offset_top = 10.0
		icon_view.offset_right = -10.0
		icon_view.offset_bottom = -10.0
		icon_view.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon_view)
	else:
		button.text = glyph
	if not button.disabled:
		button.pressed.connect(_select_skill.bind(skill_id))
	button.z_index = 3
	skill_graph.add_child(button)
	if skill_id in ["class_root", "arrow"]:
		return
	var caption := Label.new()
	caption.text = title_text
	caption.position = Vector2(center_x - 56.0, center_y + 31.0)
	caption.size = Vector2(112.0, 20.0)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_override("font", UI_FONT)
	caption.add_theme_font_size_override("font_size", 11)
	caption.add_theme_color_override("font_color", Color(0.92, 0.93, 0.96) if unlocked or can_buy else Color(0.54, 0.63, 0.68))
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.z_index = 4
	skill_graph.add_child(caption)

func _on_inventory_tab_changed(tab_index: int) -> void:
	inventory_title.text = "SKILL TREE" if tab_index == 1 else "PLAYER INVENTORY"

func _select_skill(skill_id: String) -> void:
	var player_data: Dictionary = SaveManager.data.get("player", {})
	var points := int(player_data.get("skill_points", 0))
	if points <= 0:
		return
	player_data["skill_points"] = points - 1
	SaveManager.data["player"] = player_data
	var tree: Variant = SaveManager.data.get("treeOfLife", {})
	if not tree is Dictionary:
		tree = {"unlocked_outlines": ["arrow"], "unlocked_skills": []}
	if SaveManager.data.get("flags", {}).get("isFromHogward") == true:
		var outlines: Array = tree.get("unlocked_outlines", ["arrow"])
		if not outlines.has(skill_id):
			outlines.append(skill_id)
		tree["unlocked_outlines"] = outlines
	else:
		var skills: Array = tree.get("unlocked_skills", [])
		if not skills.has(skill_id):
			skills.append(skill_id)
		tree["unlocked_skills"] = skills
		player_data["equipped_skill"] = skill_id
		var player := get_tree().get_first_node_in_group("player")
		if player != null:
			player.set("equipped_warrior_skill", skill_id)
	SaveManager.data["treeOfLife"] = tree
	SaveManager.saveGame()
	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene.has_method("tutorial_skill_selected"):
		current_scene.call("tutorial_skill_selected", skill_id)
	inventory_close_button.disabled = false
	if _requires_tutorial_inventory_choice():
		inventory_menu.hide()
		get_tree().paused = false
	else:
		_close_inventory()
	_refresh_inventory()
