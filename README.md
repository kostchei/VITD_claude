# VastDark — Vast in the Dark hex map generator

A 3-scale top-down hex map for **Godot 4.7** (GDScript), implementing the
procedural map generation from *The Vast in the Dark*. The map is rolled with
dice, rendered in a parchment book style, and persisted between sessions.

See [generating-the-vast.md](generating-the-vast.md) for the full generation
rules (the dice procedure transcribed from the source book),
[roaming-hazards.md](roaming-hazards.md) for the mobile dangers that wander the
Local map, and [wastes-weather-encounters.md](wastes-weather-encounters.md) for
the daily weather / encounter / curiosity tables used while crossing the Wastes.

## Scales

| Scale | Grid | Size |
|-------|------|------|
| Regional | hex (rectangular) | 10 × 8 = 80 hexes, each = 6 miles |
| Local | hex (hexagon-of-hexes) | radius 3 → 37 sub-hexes, each = 1 mile |
| Dungeon | square grid | 16 × 12, up to 6 stacked levels |

## Generation

Implemented in [scripts/core/vast_gen.gd](scripts/core/vast_gen.gd):

- **Regional** — drop **8 dice**, one per hex; read d6: `1` = Wastes,
  `2–4` = Ruins, `5–6` = Pillars. Empty hexes become Wastes.
- **Local** — roll `1d6` for density (`1–3` → 6 dice, `4–5` → 12, `6` → 32),
  then read each die against a table **keyed by the parent regional hex**:
  - parent **Ruins** → `1` Wastes, `2–4` Ruins, `5–6` Settlements
  - parent **Wastes** → `1–4` Wastes, `5–6` Ruins
  - parent **Pillars** → not stocked (filled solid, impassable)

Terrain is drawn as line-art glyphs over parchment fills: battlements for
Ruins, battlements + a flag for Settlements (`assets/markers/*.svg`); Pillars
read as cool-grey hexes; Wastes are bare paper.

## Persistence

On launch the world is **loaded** from `user://vast_world.json` if present,
otherwise a fresh regional map is rolled and saved. Exploring a Local hex
generates and saves that sub-map too, so the world is stable across sessions.
Use the **⟳ New Map** button (top bar) to roll a new world — it confirms first,
then replaces the saved world. See
[scripts/core/world_save.gd](scripts/core/world_save.gd).

## Run it

Uses **Godot 4.7-stable** (mono build runs GDScript fine; no .NET SDK needed).

1. Open the Godot project manager → **Import** → select `project.godot`.
2. Press **F5** (Run).

> Note: launch the real Godot exe directly, not the WinGet `godot` shim — the
> shim breaks the mono build's `.NET assemblies` lookup.

## Controls

- **Right-drag** (or middle-drag) = pan · **wheel** = zoom · **WASD / arrows** = move.
- **Hover** highlights a tile; **single-click** selects it (Regional), or on the
  **Local** map steps the party onto an adjacent hex (**1 mile**; 18 miles = a
  day, which rolls weather + an encounter).
- **Double-click** a hex to go deeper: Regional → Local → Dungeon.
- **Backspace** (or **◂ Back**) goes up a scale.
- In a Dungeon: **Q / E** (or PageUp/PageDown), or the **Levels** panel, move
  between the 6 stacked levels.
- Top **Regional / Local / Dungeon** buttons jump between scales once entered.

## Layout

```
project.godot
scenes/Main.tscn            # trivial root; everything is built in code
assets/markers/             # ruin.svg, settlement.svg (terrain glyphs)
scripts/
  main.gd                   # world state, persistence, scale transitions, UI
  core/
    hex_grid.gd             # pure axial hex math (static)
    hex_tile.gd             # one tile (coord + terrain)
    hex_map.gd              # rectangular (Regional) / hexagonal (Local) maps
    vast_gen.gd             # dice-based terrain generation
    hazard_set.gd           # roaming hazards (mobile dangers on the Local map)
    wastes.gd               # daily weather / encounter / curiosity tables + movement & upkeep
    world_save.gd           # JSON save/load of the generated world
    dungeon.gd              # stack of levels
    dungeon_level.gd        # one square-grid level
  map/
    hex_map_view.gd         # draws + picks any HexMap (terrain colors + glyphs)
    dungeon_view.gd         # draws + picks one DungeonLevel
    world_camera.gd         # pan / zoom
.tools/                     # screenshot harness (not part of the game)
```
