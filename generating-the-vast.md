# Generating The Vast

A summary of the two reference images describing the procedural map-generation
system for *The Vast* (VastDark). The method uses a flat-top hex map and a
handful of dice to quickly stock a region with terrain and locations, then lets
you "zoom in" on any single hex to generate it at finer detail.

> Hex orientation: both the Regional and Local maps use **flat-top** hexes.
> Six local (1-mile) hexes span one regional hex angle-to-angle.

---

## 1. The two scales

The system works at two zoom levels. The same dice-dropping procedure is reused
at each level; only the scale and the terrain lookup table change.

| Scale        | Each hex represents | Built by                                        |
|--------------|---------------------|-------------------------------------------------|
| **Regional** | 6 miles             | Dropping dice on a blank regional hex map        |
| **Local**    | 1 mile              | Subdividing a single regional hex into a 6-mile environment and dropping dice again |

The core idea: **drop dice randomly, read the face-up number, look it up on a
terrain table, and any hex without a die becomes Wastes.** The number of dice
you drop controls how dense the world is.

---

## 2. Regional Scale

Landscape and terrain features at 6 miles per hex.

1. Bring up a blank hex map. Each hex = 6 miles.
2. Drop **8 dice** onto the map (this build's chosen count for the given map size).
   Each die occupies **one hex, max one die per hex**.
3. For each hex a die landed on, read the face-up number and record the terrain.
4. Every remaining (empty) hex becomes **Wastes**.

### Regional terrain table (d6)

| d6  | Terrain  | Description                                                                       |
|-----|----------|-----------------------------------------------------------------------------------|
| 1   | Wastes   | Barren swaths of grey dust and sand, prone to sandstorms; little to find.          |
| 2–4 | Ruins    | Hives of erratic, crumbling architecture, sometimes populated with life.           |
| 5–6 | Pillars  | Enormous towers of stone, miles across, reaching up to an unseen ceiling.           |

### Amount of dice (world density)

More dice → more Ruins and more locations. Suggested ratios:

| Dice ratio        | Density   | Feel                                              |
|-------------------|-----------|---------------------------------------------------|
| 1 die per 6 hexes | Barren    | Little can be found in this wasteland.             |
| 1 die per 3 hexes | Sparse    | Yet enough worth exploring.                        |
| 1 die per hex     | Plentiful | A labyrinth of ruins to delve into and lose yourself. |

---

## 3. Local Scale

Any single regional hex can be subdivided into a **six-mile environment** and
populated the same way. Each local hex = 1 mile.

1. Select one hex from the Regional map.
2. Create the six-mile hex: a **37-hex** field of 1-mile hexes (each small hex = 1 mile).
3. **Roll 1d6 to set this local map's density**, which fixes the number of dice
   to drop (see table below).
4. Drop that many dice into the local map (one die per hex, max one).
5. Read each die and record the terrain. All remaining hexes become **Wastes**.

### Local density (1d6 → dice count)

Roll once per local map:

| 1d6 | Density   | Dice dropped |
|-----|-----------|--------------|
| 1–3 | Barren    | 6            |
| 4–5 | Sparse    | 12           |
| 6   | Plentiful | 32           |

The local terrain table depends on the **parent regional hex's type**. A regional
Ruins hex and a regional Wastes hex use different columns:

### Local terrain table (d6)

| d6  | Parent = Ruins | Parent = Wastes |
|-----|----------------|-----------------|
| 1   | Wastes         | Wastes          |
| 2–4 | Ruins          | Wastes          |
| 5   | Settlements    | Ruins           |
| 6   | Settlements    | Ruins           |

> A Ruins region yields denser, more developed local terrain (up to Settlements);
> a Wastes region yields mostly emptiness with the occasional Ruin.

### Pillars (special case)

Pillar hexes are considered **filled entirely** with massive cyclopean columns.
They are beyond exploring — you do not subdivide or stock them. (See pg. 12.)

---

## 4. Pseudocode

```text
# ----- Tables -------------------------------------------------------------

REGIONAL_TERRAIN(roll):
    if roll == 1:        return WASTES
    if roll in 2..4:     return RUINS
    if roll in 5..6:     return PILLARS

LOCAL_TERRAIN(roll, parentType):
    if parentType == RUINS:
        if roll == 1:        return WASTES
        if roll in 2..4:     return RUINS
        if roll in 5..6:     return SETTLEMENTS
    else if parentType == WASTES:
        if roll == 1:        return WASTES
        if roll in 2..4:     return WASTES
        if roll in 5..6:     return RUINS

LOCAL_DICE_COUNT():                       # roll 1d6 per local map
    roll = random 1..6
    if roll in 1..3:     return 6         # Barren
    if roll in 4..5:     return 12        # Sparse
    if roll == 6:        return 32        # Plentiful


# ----- Core procedure (shared by both scales) -----------------------------
# diceCount is fixed by the caller; each die lands in its own hex (max 1/hex).

generate(map, terrainTable, diceCount, parentType = none):
    # 1. default every hex to Wastes
    for hex in map.hexes:
        hex.terrain = WASTES

    # 2. drop dice into distinct random hexes
    targets = pick diceCount distinct random hexes from map
    for hex in targets:
        roll = random 1..6                # face-up number
        hex.terrain = terrainTable(roll, parentType)

    return map


# ----- Step 1: Regional generation ----------------------------------------

regional = blankHexMap(milesPerHex = 6)
generate(regional, REGIONAL_TERRAIN, diceCount = 8)


# ----- Step 2: Local generation (zoom into one regional hex) ---------------

generateLocal(regionalHex):
    if regionalHex.terrain == PILLARS:
        return "impassable — filled with cyclopean columns, not explorable"

    local = blankHexMap(milesPerHex = 1, hexCount = 37)
    return generate(local, LOCAL_TERRAIN, LOCAL_DICE_COUNT(),
                    parentType = regionalHex.terrain)
```

---

## 5. Terrain types reference

- **Wastes** — the default / empty fill. Grey dust and sand, sandstorms, little of interest.
- **Ruins** — crumbling architecture, sometimes inhabited; the main exploration content.
- **Pillars** — giant stone columns; impassable, not subdivided (regional only).
- **Settlements** — inhabited locations; only appear at the Local scale inside Ruins regions.
