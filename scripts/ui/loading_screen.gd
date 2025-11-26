extends Control

## Loading screen UI that can be shown/hidden

@onready var label: Label = $Label
@onready var progress_bar: ProgressBar = $ProgressBar

func _ready() -> void:
	visible = false
	if label:
		label.text = "Loading..."
	if progress_bar:
		progress_bar.visible = false

func show_loading() -> void:
	visible = true
	if label:
		label.text = "Loading..."

func hide_loading() -> void:
	visible = false

func set_progress(value: float) -> void:
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = clamp(value * 100.0, 0.0, 100.0)

