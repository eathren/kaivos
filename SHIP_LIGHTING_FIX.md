# 🚀 Player Ship Lighting Setup

## What You Need:
1. **PointLight2D** - Faint ambient glow around ship
2. **PointLight2D** - Directional "headlight" beam (NOT DirectionalLight2D!)

## ❌ What You Have Wrong:
- `DirectionalLight2D` - This is for SUN/MOON, not ship lights!
  - Lights the ENTIRE scene
  - Doesn't rotate with objects
  - Used for day/night cycles

## ✅ Correct Setup:

### Delete DirectionalLight2D, Replace with Two PointLight2Ds:

```
PlayerShip
├── PointLight2D (AmbientGlow)  ← Faint circle around ship
└── PointLight2D (Headlight)    ← Directional beam pointing forward
```

## 🔧 Configuration:

### 1. Ambient Glow (Small Circle)
```gdscript
[node name="AmbientGlow" type="PointLight2D" parent="."]
enabled = true
energy = 0.8                    # Faint
texture_scale = 1.5             # Small radius (1.5 = ~48px)
color = Color(0.9, 0.9, 1, 1)   # Soft white-blue
blend_mode = 0                  # Add
shadow_enabled = false          # No shadows needed for ambient
```

### 2. Headlight (Forward Beam)
```gdscript
[node name="Headlight" type="PointLight2D" parent="."]
position = Vector2(0, -10)      # Slightly forward of ship
rotation = 0                    # Inherits ship rotation
enabled = true
energy = 1.5                    # Bright beam
texture_scale = 3.0             # Larger reach (~96px)
color = Color(1, 0.95, 0.85, 1) # Warm white (headlight color)
blend_mode = 0                  # Add
shadow_enabled = true           # Cast shadows from walls!
shadow_filter = 1               # PCF5 (smooth shadows)
```

## 🎨 Using Light Textures for Cone/Beam:

For a proper **headlight beam**, use a directional texture:

### Option 1: Use Built-in Gradient
Set `texture_scale` larger and position it forward - it'll naturally look like a beam.

### Option 2: Create a Cone Texture
1. Create a 256x256 image in GIMP/Photoshop
2. White cone shape (wide at top, narrow at bottom)
3. Radial gradient fade
4. Save as PNG
5. Import to Godot
6. Set as `texture` property on Headlight

Example texture (you can make this):
```
    ███     ← Wide
    ███
    ███
    ██
    █       ← Narrow
```

### Option 3: Quick Fix - No Texture
Just use settings:
```gdscript
# Headlight
energy = 2.0
texture_scale = 4.0
range_layer_min = 0
range_layer_max = 0
range_z_min = -100
range_z_max = 100
```

And position it **FORWARD** of the ship:
```gdscript
position = Vector2(0, -15)  # 15 pixels in front
```

As the ship rotates, the light rotates with it (because it's a child node).

