# Hex Game — Planning Document

> Working title: TBD
> Engine: **Godot 4.x** · Language: **GDScript** · Target: **Steam (Windows first)**
> Status: Planning — focus on **map + UI** before gameplay systems.

---

## 1. Vision (one paragraph)

A top-down, hex-based game played across **three nested scales** — Regional, Local, and
Dungeon. The player moves seamlessly between scales: a Regional hex zooms into a Local
hex map, and a site on the Local map descends into a Dungeon made of **stacked levels**,
each with its own hex layout. The first milestone is purely about getting the map and the
scale-switching UI to feel good — no combat, economy, or AI yet.

---

## 2. Core concepts

### 2.1 The three scales

| Scale | What it represents | Grid | Transition into it |
|-------|--------------------|------|--------------------|
| **Regional** | The overworld — biomes, mountains, kingdoms | Large hex grid | Game start / "zoom out" |
| **Local** | One Regional hex expanded — terrain, settlements, dungeon entrances | Medium hex grid | Select a Regional hex → "enter" |
| **Dungeon** | A site on a Local hex — multi-level interior | Small hex grid **per level** | Select a dungeon entrance → "descend" |

**Key design question (decided):** Each scale is its **own hex grid**, not a literal
geometric subdivision of the parent. A Regional hex *maps to* a generated Local grid; we
store the link, not a fractal subdivision. This keeps the data model simple and lets each
scale have art/size tuned independently.

### 2.2 Dungeon stacking

- A Dungeon is an ordered list of **levels** (level 0 = entrance, increasing = deeper).
- Each level is its own hex grid (`HexMap`) with its own layout.
- The UI must let the player move **between levels** (up/down) and show **which level**
  they're on (a vertical level indicator / mini elevator UI).
- Levels can be linked by stairs/shafts at specific hex coordinates (data: `from_hex`,
  `to_level`, `to_hex`).

---

## 3. Technical foundation

### 3.1 Hex grid math

- Use **axial coordinates** `(q, r)` internally; convert to **cube** `(x, y, z)` for
  distance/line/range algorithms. Reference: Red Blob Games "Hexagonal Grids".
- Pick an orientation up front: **pointy-top** (recommended for top-down strategy feel)
  vs flat-top. *Decision: pointy-top.*
- One reusable `HexGrid` utility (pure functions, no scene): `axial_to_pixel`,
  `pixel_to_axial`, `hex_distance`, `hex_neighbors`, `hex_range`, `hex_line`.
- Godot's `TileMapLayer` supports hex tile shapes natively — use it for rendering;
  keep our own coordinate math for logic so we aren't locked to TileMap internals.

### 3.2 Project structure (proposed)

```
res://
├── project.godot
├── scenes/
│   ├── Main.tscn              # root, owns ScaleManager + UI
│   ├── map/
│   │   ├── HexMapView.tscn     # renders one HexMap (used by all scales)
│   │   └── HexCursor.tscn      # hover/selection highlight
│   └── ui/
│       ├── HUD.tscn
│       ├── ScaleBar.tscn       # Regional/Local/Dungeon switcher
│       └── LevelStack.tscn     # dungeon up/down level indicator
├── scripts/
│   ├── core/
│   │   ├── hex_grid.gd          # pure hex math (static funcs)
│   │   ├── hex_map.gd           # data: tiles for one grid
│   │   └── scale_manager.gd     # owns current scale + transitions
│   ├── map/
│   │   └── hex_map_view.gd
│   └── ui/
│       ├── scale_bar.gd
│       └── level_stack.gd
├── data/
│   └── tiles/                   # terrain definitions (Resources)
└── assets/
    ├── tiles/                   # hex sprites
    └── ui/
```

### 3.3 Data model (first pass)

```
HexMap
  scale: enum { REGIONAL, LOCAL, DUNGEON }
  width, height (or radius)
  tiles: Dictionary  key = Vector2i(q, r)  ->  HexTile

HexTile
  coord: Vector2i (q, r)
  terrain: StringName
  # scale-specific extras added later (links to child maps, etc.)

WorldState
  regional: HexMap
  local_maps: Dictionary   key = regional coord -> HexMap
  dungeons:   Dictionary   key = local coord    -> Dungeon

Dungeon
  levels: Array[HexMap]      # index = depth
  links:  Array[LevelLink]   # stairs/shafts between levels
```

> **Coding rule (from project conventions): no silent fallbacks.** If a coordinate, map,
> or level is missing, raise an error (`push_error` + `assert`) rather than returning a
> default. Bugs should surface loudly.

---

## 4. UI plan (the current priority)

1. **Scale switcher** — persistent bar showing the three scales; current one highlighted.
   Switching is context-aware (you can only enter Local from a selected Regional hex).
2. **Breadcrumb** — "Region › Greenvale › Old Mine — Level 2" so the player always knows
   where they are in the nesting.
3. **Level stack widget** (Dungeon scale only) — vertical strip of levels, current one
   highlighted, up/down buttons, click a level to jump (if discovered).
4. **Hex hover/selection** — cursor highlight, tile info panel (coord + terrain for now).
5. **Camera** — pan (drag / WASD / edge), zoom (wheel), clamped to map bounds.

### Transition feel
- Selecting a hex to "enter" plays a quick zoom-in + fade to the child map.
- "Ascend"/"surface" reverses it. Keep transitions <300ms so navigation stays snappy.

---

## 5. Milestones

### M1 — Hex foundation
- [ ] `hex_grid.gd` math + a test scene that draws a single grid and highlights the hex
      under the mouse.
- [ ] Camera pan/zoom with bounds clamping.

### M2 — One reusable map view
- [ ] `HexMap` data + `HexMapView` renders any `HexMap` regardless of scale.
- [ ] Tile info panel on hover/click.

### M3 — Scale switching
- [ ] `ScaleManager` + `ScaleBar` UI.
- [ ] Regional → Local → (back) transitions with placeholder generated maps.
- [ ] Breadcrumb UI.

### M4 — Dungeon stacking
- [ ] `Dungeon` with multiple `HexMap` levels.
- [ ] `LevelStack` widget: navigate up/down, jump to level, level links (stairs).

### M5 — Steam-ready shell
- [ ] Main menu, pause, settings (resolution/fullscreen).
- [ ] Export template + `GodotSteam` integration smoke test (app shows in Steam, basic
      achievement fires).

> Gameplay (units, turns, combat, generation quality) is intentionally **out of scope**
> until M1–M4 feel good.

---

## 6. Steam / distribution notes

- Ship **Windows** first; Godot also exports Linux/macOS cheaply later.
- Use **GodotSteam** (GDExtension build) for Steamworks: achievements, cloud saves,
  rich presence.
- Reserve the Steam app ID early (it gates store-page setup and depot uploads).
- Keep builds reproducible: export presets committed, version stamped in-game.

---

## 7. Open questions / decisions to revisit

- [ ] Turn-based vs real-time movement? (affects nothing in M1–M4, decide before M5+)
- [ ] Map sizes per scale (Regional radius? Local radius? Dungeon level radius?)
- [ ] Procedural generation vs hand-authored maps for the vertical slice.
- [ ] Save format (Godot `Resource` serialization vs custom JSON).
- [ ] Art style / tile resolution (pixel art vs clean vector-ish flat).

---

## 8. Decisions log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-06-20 | Engine: Godot 4, language GDScript | Free, native 2D + hex TileMap, fast iteration, easy Steam export |
| 2026-06-20 | Three scales are independent linked grids, not fractal subdivisions | Simpler data model; each scale tuned independently |
| 2026-06-20 | Pointy-top hexes, axial coords (cube for algorithms) | Standard, well-documented (Red Blob Games) |
| 2026-06-20 | Map + UI before any gameplay systems | De-risk the core navigation feel first |
| 2026-06-20 | Regional = 10 wide × 8 high (80 hexes), rectangular | Per design |
| 2026-06-20 | Local = hexagonal region, radius 3 (~6 flat-to-flat, 37 sub-hexes) | "6 across flat edge to flat edge"; flat-to-flat ≈ 0.87× long axis, so radius 3 = 7 long / ~6 flat-to-flat |
| 2026-06-20 | 1 local sub-hex = 1 mile | Per design |
| 2026-06-20 | Dungeon = **square grid**, up to 6 stacked levels | Per design — dungeon uses a grid, not hexes; rooms via procgen later |
| 2026-06-20 | Prototype renders via custom `_draw()` (colored polygons), not TileMap | No art assets yet; code-driven so it runs immediately |
| 2026-06-20 | Pinned to Godot **4.7-stable** (mono build, GDScript) | Latest installed version; mono runs GDScript with no .NET SDK required |
