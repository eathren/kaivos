# GoStick Control System

## Overview
The GoStick is an interactive lever on the Trawler that controls its movement state and drill audio.

## Controls
- **Press E** when near the GoStick to cycle through states

## States

### 🛑 STOP (Pointing Left ←)
- Trawler velocity: 0
- Drill animation: OFF
- Drill audio: SILENT
- Use when: Stopped to repair, manage crew, or plan

### ▲ GO (Pointing Up ↑)
- Trawler velocity: Normal speed
- Drill animation: ACTIVE
- Drill audio: PLAYING
- Use when: Normal mining operations

### ⚡ BURST (Pointing Right →)
- Trawler velocity: 2x normal speed (turbo)
- Drill animation: ACTIVE
- Drill audio: PLAYING
- Use when: Need to move quickly through areas

## Visual States
```
    ←  STOP     |  Lever points LEFT
    ↑  GO       |  Lever points UP
    →  BURST    |  Lever points RIGHT
```

## Technical Details

### Files
- `entities/vehicles/trawler/go_stick.gd` - GoStick script
- `entities/vehicles/trawler/go_stick.tscn` - GoStick scene
- `entities/vehicles/trawler/trawler.gd` - Updated with GoStick integration
- `entities/vehicles/trawler/drill.gd` - Updated with set_active() method

### Integration
1. GoStick emits `state_changed(stick_state)` signal
2. Trawler receives signal via `_on_go_stick_state_changed()`
3. Trawler calls `set_movement_state()` to change movement
4. Trawler calls `_update_drill_state()` to sync drill
5. Drill updates animation and audio accordingly

### Interaction Area
- Radius: 40 pixels
- Collision mask: Layer 3 (Player)
- Shows "[E] Toggle Speed" label when player is nearby

## Customization

### Change Stick Position
In `trawler.tscn`, adjust the GoStick node position. Default is `(0, -80)` (center-top of trawler).

### Change Interaction Key
Edit the `interaction_key` export variable in `go_stick.gd` or in the Inspector.

### Change Speed Multipliers
In `trawler.gd`, edit:
- `burst_multiplier` export (default: 2.0)
- `base_speed` from ship_stats resource

### Custom Stick Texture
Replace the PlaceholderTexture2D in `go_stick.tscn` with your own stick/lever sprite.
