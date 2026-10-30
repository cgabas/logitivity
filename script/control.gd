extends CanvasLayer

signal ui_closed

const UI_FONT := preload("res://UI/fonts_setting/VCR.ttf")
const BUTTON_NORMAL := preload("res://UI/texture/button_unpressed.png")
const BUTTON_PRESSED := preload("res://UI/texture/button_pressed.png")
const BUTTON_HOVER := preload("res://UI/texture/button_hover.png")
const BUTTON_DISABLED := preload("res://UI/texture/button_disable.png")

@onready var panel: Panel = $InventoryPanel
@onready var title_label: Label = $InventoryPanel/TitleLabel
@onready var item_grid: GridContainer = $InventoryPanel/ItemGrid
@onready var close_button: Button = %CloseButton
@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	# Ensure process mode stays active even if game pauses
	process_mode = PROCESS_MODE_ALWAYS
	_style_menu()
	close_button.pressed.connect(_on_close_pressed)
	status_label.text = "This chest is empty for now."

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

	item_grid.position = Vector2(24.0, 76.0)
	item_grid.size = Vector2(472.0, 226.0)
	item_grid.columns = 4

	status_label.position = Vector2(24.0, 126.0)
	status_label.size = Vector2(472.0, 36.0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_override("font", UI_FONT)
	status_label.add_theme_font_size_override("font_size", 16)
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

func _button_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 12.0
	style.texture_margin_top = 12.0
	style.texture_margin_right = 12.0
	style.texture_margin_bottom = 12.0
	return style

# Handles mobile touch taps and keyboard events
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
