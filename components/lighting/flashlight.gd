@tool
extends PointLight2D
class_name Flashlight

enum FlashlightType { SMALL, MEDIUM, LARGE, SPOTLIGHT }

@export var flashlight_type: FlashlightType = FlashlightType.MEDIUM:
	set(value):
		flashlight_type = value
		_update_all()

@export var light_enabled: bool  = true

@export var cast_shadows: bool = true:
	set(value):
		cast_shadows = value
		_update_shadows()

@export var warm_color: bool = true:
	set(value):
		warm_color = value
		_update_color()

# Optional overrides. Set to 0 to use type defaults.
@export var radius_override: float = 0.0:
	set(value):
		radius_override = max(0.0, value)
		_update_radius()

@export var intensity_override: float = 0.0:
	set(value):
		intensity_override = max(0.0, value)
		_update_energy()

# Per type defaults in world units, not arbitrary scale
var _radius_by_type := {
	FlashlightType.SMALL: 96.0,
	FlashlightType.MEDIUM: 160.0,
	FlashlightType.LARGE: 256.0,
	FlashlightType.SPOTLIGHT: 192.0,
}

var _energy_by_type := {
	FlashlightType.SMALL: 0.9,
	FlashlightType.MEDIUM: 1.2,
	FlashlightType.LARGE: 1.6,
	FlashlightType.SPOTLIGHT: 1.4,
}

var _warm_color := Color(1.0, 0.96, 0.88, 1.0)
var _cool_color := Color(0.9, 0.95, 1.0, 1.0)

func _ready() -> void:
	_update_all()

func _update_all() -> void:
	if not is_inside_tree():
		return
	_update_radius()
	_update_energy()
	_update_color()
	_update_shadows()

func _update_radius() -> void:
	if not texture:
		return

	# Decide desired radius in pixels
	var target_radius := radius_override
	if target_radius <= 0.0:
		target_radius = _radius_by_type[flashlight_type]

	# Texture scale = desired radius / texture radius
	# Assume square texture, radius is half width
	var tex_radius = max(1.0, float(texture.get_width()) * 0.5)
	texture_scale = target_radius / tex_radius

func _update_energy() -> void:
	var base = _energy_by_type[flashlight_type]
	energy = intensity_override if intensity_override > 0.0 else base

func _update_color() -> void:
	color = _warm_color if warm_color else _cool_color

func _update_shadows() -> void:
	shadow_enabled = cast_shadows
	if cast_shadows:
		shadow_filter = SHADOW_FILTER_PCF5

func set_flashlight_enabled(enabled: bool) -> void:
	light_enabled = enabled

func set_intensity(multiplier: float) -> void:
	intensity_override = clamp(multiplier, 0.0, 3.0)
	_update_energy()

func set_radius(radius: float) -> void:
	radius_override = max(0.0, radius)
	_update_radius()
