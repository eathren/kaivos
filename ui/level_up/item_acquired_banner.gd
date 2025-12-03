extends PanelContainer

## Banner that appears at bottom of screen when item is acquired

@onready var icon_rect: TextureRect = %IconRect
@onready var item_name_label: Label = %ItemNameLabel
@onready var description_label: Label = %DescriptionLabel

var display_time: float = 3.0
var fade_time: float = 0.5
var timer: float = 0.0

func _ready() -> void:
	modulate.a = 0.0

func show_item(item: TechItem, stack_count: int) -> void:
	"""Display item acquisition"""
	if not item:
		return
	
	# Set icon
	if item.icon:
		icon_rect.texture = item.icon
		icon_rect.show()
	else:
		icon_rect.hide()
	
	# Set name with stack count
	var name_text = item.display_name
	if stack_count > 1:
		name_text += " x%d" % stack_count
	item_name_label.text = name_text
	item_name_label.modulate = item.get_rarity_color()
	
	# Set description (first line only for banner)
	var desc = item.description.split("\n")[0]
	if desc.length() > 100:
		desc = desc.substr(0, 97) + "..."
	description_label.text = desc
	
	# Animate in
	timer = 0.0
	show()
	
	# Fade in
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_time)

func _process(delta: float) -> void:
	if not visible:
		return
	
	timer += delta
	
	# Start fading out
	if timer >= display_time:
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, fade_time)
		tween.finished.connect(func(): queue_free())
		set_process(false)
