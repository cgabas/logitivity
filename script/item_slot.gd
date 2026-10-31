extends Panel
class_name ItemSlot

@onready var item_icon: TextureRect = %ItemIcon
@onready var quantity_label: Label = %QuantityLabel

# Call this function to display item data inside the slot
func display_item(texture: Texture2D, quantity: int = 1) -> void:
	# If there is no texture, or the quantity drops to 0 or lower, clear the slot entirely
	if not texture or quantity <= 0:
		clear_slot()
		return
		
	item_icon.texture = texture
	item_icon.visible = true
	
	# Only show quantity label if there's more than 1 item in the stack
	if quantity > 1:
		quantity_label.text = str(quantity)
		quantity_label.visible = true
	else:
		quantity_label.text = ""
		quantity_label.visible = false

# Call this function to wipe the slot clean (empty slot)
func clear_slot() -> void:
	item_icon.texture = null
	item_icon.visible = false
	quantity_label.text = ""
	quantity_label.visible = false
