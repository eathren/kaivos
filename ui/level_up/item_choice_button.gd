extends Button

## Individual item choice button

@onready var item_name_label: Label = %ItemNameLabel
@onready var item_description: RichTextLabel = %ItemDescription
@onready var stack_label: Label = %StackLabel
@onready var icon_rect: TextureRect = %IconRect

var item: TechItem = null

func setup(p_item: TechItem, current_stack: int) -> void:
	"""Setup button with item data"""
	item = p_item
	
	if not item:
		return
	
	# Set name with rarity color
	item_name_label.text = item.display_name
	item_name_label.modulate = item.get_rarity_color()
	
	# Set description
	item_description.clear()
	item_description.append_text(item.get_description(current_stack + 1))
	
	# Show stack count if not first stack
	if current_stack > 0:
		stack_label.text = "Stack: %d -> %d" % [current_stack, current_stack + 1]
		stack_label.show()
	else:
		stack_label.hide()
	
	# Set icon if available
	if item.icon:
		icon_rect.texture = item.icon
		icon_rect.show()
	else:
		icon_rect.hide()

func add_banish_button(callback: Callable) -> void:
	"""Add a banish button to this item choice"""
	var banish_btn = Button.new()
	banish_btn.text = "Banish"
	banish_btn.tooltip_text = "Remove this item from future level-ups"
	banish_btn.pressed.connect(func():
		callback.call()
		queue_free()  # Remove this button after banishing
	)
	
	# Add to the VBoxContainer
	var vbox = get_node("VBoxContainer")
	if vbox:
		vbox.add_child(banish_btn)
