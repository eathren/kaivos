# Lighting & Occlusion Setup Guide

## 🌟 Adding Lights to Your Game

### 1. **Wall Tilemap Occlusion**

To make walls block light:

1. Open **`assets/art/tilesets/ground_tileset.png`** in Godot
2. Go to **TileSet** editor (at the bottom when you select the TileMapLayer)
3. Select your **wall tile** (atlas coordinates 1,1)
4. In the **TileSet** panel on the right, scroll down to find **Occlusion**
5. Click **+** to add an occluder
6. Draw a polygon around the tile (usually just a square covering the whole tile)
7. Save

**Quick way:**
- Select wall tile in TileSet editor
- Physics → Occlusion Layer 0 → Click "+" 
- Draw polygon covering the tile (click corners, press Enter)

### 2. **Player Ship Already Has Occluder** ✅
You mentioned you already added a `LightOccluder2D` to the player ship - perfect!

### 3. **Add Lights to Scenes**

#### Example: Add Light to Player Ship
```gdscript
# In player_ship.tscn or via code:
var light := PointLight2D.new()
light.texture = preload("res://path/to/light_texture.png")  # Optional
light.energy = 1.5
light.texture_scale = 2.0
light.color = Color(1, 0.9, 0.7)  # Warm white
light.shadow_enabled = true  # Enable shadows from occluders
add_child(light)
```

Or add via editor:
1. Open `entities/player/ships/player_ship/player_ship.tscn`
2. Right-click `PlayerShip` node → Add Child Node
3. Search for `PointLight2D`
4. Configure in Inspector:
   - **Enabled**: On
   - **Energy**: 1.0-2.0
   - **Texture Scale**: 1.0-3.0
   - **Color**: Choose your color
   - **Shadow → Enabled**: ✅ (for wall shadows)

### 4. **Trawler Light**

Add a big light to the trawler's front:

```gdscript
# In trawler.tscn
[node name="FrontLight" type="PointLight2D" parent="."]
position = Vector2(0, -145)  # Front of trawler
energy = 2.0
texture_scale = 5.0
color = Color(1, 0.8, 0.5, 1)  # Warm mining light
shadow_enabled = true
```

### 5. **Ambient Light**

To prevent total darkness, add a `CanvasModulate`:

1. In your level scene (`level_mine.tscn`)
2. Add node → `CanvasModulate`
3. Set **Color** to dark gray: `Color(0.2, 0.2, 0.2, 1)`
   - This gives 20% ambient light
   - Adjust to taste (0.1 = darker, 0.3 = lighter)

### 6. **Enemy Eyes Glow** 👁️

Make enemies visible in darkness:

```gdscript
# In imp.tscn
[node name="EyeLight" type="PointLight2D" parent="."]
energy = 0.5
texture_scale = 0.5
color = Color(1, 0, 0, 1)  # Red eyes
shadow_enabled = false
```

## 🎨 Lighting Presets

### Mining Game (Claustrophobic)
```gdscript
# level_mine.tscn
CanvasModulate.color = Color(0.1, 0.1, 0.15, 1)  # Very dark blue

# PlayerShip light
energy = 1.5
texture_scale = 2.0
color = Color(1, 0.9, 0.7)  # Warm helmet light

# Trawler light
energy = 3.0
texture_scale = 8.0
color = Color(1, 0.7, 0.3)  # Bright mining floodlight
```

### Spooky Cave
```gdscript
CanvasModulate.color = Color(0.05, 0.08, 0.12, 1)  # Almost black
# Small, flickering lights on entities
```

### Bright Underground
```gdscript
CanvasModulate.color = Color(0.4, 0.4, 0.5, 1)  # Bright enough to see
# Lights are accent only
```

## 🔧 Performance Tips

### Optimize Shadows
- Only enable shadows on important lights (player, trawler)
- Enemy/bullet lights shouldn't cast shadows
- Use `shadow_filter = FILTER_NONE` for better performance

### Light Limits
- Keep total lights on screen < 20-30
- Use `Light2D.enabled = false` for off-screen entities
- Consider light culling:

```gdscript
func _process(_delta: float) -> void:
	# Only enable light if on screen
	if is_on_screen():
		$Light2D.enabled = true
	else:
		$Light2D.enabled = false

func is_on_screen() -> bool:
	var viewport_rect := get_viewport_rect()
	var camera := get_viewport().get_camera_2d()
	if not camera:
		return true
	var screen_rect := Rect2(camera.global_position - viewport_rect.size / 2, viewport_rect.size)
	return screen_rect.has_point(global_position)
```

## 🎬 Quick Start Checklist

- [ ] Add `CanvasModulate` to level (Color: 0.2, 0.2, 0.2)
- [ ] Add `PointLight2D` to PlayerShip (shadow_enabled = true)
- [ ] Add `PointLight2D` to Trawler front (large, bright)
- [ ] Add occlusion polygon to wall tiles in TileSet editor
- [ ] Verify `LightOccluder2D` on PlayerShip (you did this!)
- [ ] Optional: Add small lights to enemies (red/orange)
- [ ] Test and adjust ambient light level

## 🌈 Light Colors Reference

```gdscript
# Warm/Fire
Color(1, 0.6, 0.2)   # Orange flame
Color(1, 0.8, 0.4)   # Mining lamp
Color(1, 0.9, 0.7)   # Warm white

# Cool/Tech
Color(0.5, 0.7, 1)   # Blue tech
Color(0.3, 1, 0.8)   # Cyan screen glow
Color(0.2, 1, 0.4)   # Green terminal

# Danger
Color(1, 0, 0)       # Red alarm
Color(1, 0.3, 0)     # Enemy eyes
Color(1, 0.8, 0)     # Yellow warning
```

Enjoy your atmospheric lighting! 🌟

