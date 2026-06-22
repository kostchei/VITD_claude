# Build Roadmap — Top 10

A prioritized list of what to build next, measured against the **current code**
(not the original [PLANNING.md](PLANNING.md) vision). Ordered as a sensible build
sequence: traversal & state first, then the keystone party model and the
resolution layers it unblocks, then content and the dungeon scale.

> Guiding rule (project convention): **no silent fallbacks** — missing data or
> an impossible state raises (`assert`), it never degrades quietly.

## Where the code stands today

**Solid:** terrain generation (regional + local), roaming-hazard placement &
daily drift, the Wastes tables (weather / encounter / curiosity), and the Local
travel loop (party token, 1 hex = 1 mile, a day closes on 18 mi or Rest → rolls
weather + encounter, drifts hazards, resets the stint). Persistence covers maps
+ hazards.

**Everything below is stubbed, rolled-but-not-applied, or absent.**

---

## Tier A — make travel actually traverse the world

### 1. Continuous 1-mile Local grid (chunked per-region generation)
Travel is trapped inside one standalone **37-hex hexagon** per regional hex
([`HexMap.make_local`](scripts/core/hex_map.gd) + [`generate_local`](scripts/core/vast_gen.gd)),
and the only way out is Back → Regional → re-enter (which rebuilds the map and
resets the party). Replace that discrete model with **one continuous 1-mile
axial grid**, where the regional map is just a **6× zoom-out overlay**: each
1-mile hex belongs to whichever regional hex its centre rounds to (fine→coarse
hex rounding) — a gapless, overlap-free partition by construction, no tiling
tricks. A 6-mile-across regional hex holds **~36 one-mile hexes** (6² area);
that's what the old 37-hex hexagon was approximating.
- **Build:** a continuous fine-hex store generated **on demand in chunks per
  regional hex**; a 1-mile hex's terrain is rolled keyed by its parent regional
  hex's type (Wastes/Ruins/Pillars), the parent found by rounding. The Local
  view renders the fine hexes around the party and pans across the field;
  **edge-crossing is automatic** (walk toward ungenerated hexes → generate that
  region's chunk). Pillars regions stay impassable; world-edge regional hexes
  bound the field.
- **Replaces:** the old "edge-crossing teleport" idea — no seams, no re-entry
  abstraction.
- **Touches:** `hex_map.gd` (or a new continuous-grid type), `vast_gen.gd`,
  `hex_map_view.gd`, `main.gd`. **Depends on:** none. **Effort:** M–L (data-model
  refactor). **Done already:** free pan + ⌖ Recentre button.

### 2. Travel / party-state persistence
`party_local`, `miles_today`, and the travel day live only in `main.gd` and
reset on re-entering a local map. With #1 letting the party roam one continuous
field, this state and the generated fine-hex chunks must survive saves.
- **Build:** extend `WorldSave` (bump version) to store the party's position +
  current stint/day, and persist generated fine-hex chunks (keyed by regional
  hex to keep saves bounded).
- **Touches:** `world_save.gd`, `main.gd`. **Depends on:** pairs with #1.
  **Effort:** S–M.

---

## Tier B — the keystone, then the resolution layers it unblocks

### 3. Party & Traveler model (stats · HP · rations · exhaustion · inventory · coin)
**The keystone.** `wastes.gd` has a `Traveler` (rations + exhaustion) but the
game passes an empty `[]`, so nothing is tracked. No HP, no ability scores (for
*Save v. Breath/Charm*), no coin, no inventory. This blocks ration upkeep, the
forced march, saves, combat, trade, and curiosity rewards all at once.
- **Build:** a real `Party`/`Traveler` with HP, the saving stats, exhaustion,
  rations, coin, and a small item list; pass it into `Wastes.spend_day`.
- **Touches:** new `party.gd`, `wastes.gd`, `main.gd`. **Depends on:** none —
  but everything in this tier depends on it. **Effort:** M.

### 4. Saves + damage / HP / death application
Weather and hazard effects are currently only *reported as text*
(`DayReport.pending_effects`): Wind Blast / Stone Hail / Grit Slide (3d6), and
the hazard hits (Maelstrom 3d20, Void Lightning 10d6, …). Nothing rolls a save
or loses HP.
- **Build:** shared `save(stat)` / `roll_x_in_6(x)` helpers, apply damage to
  Travelers, handle death/exhaustion-out.
- **Touches:** `wastes.gd`, `hazard_set.gd`, new combat/util module.
  **Depends on:** #3. **Effort:** M.

### 5. Encounter resolution
We roll group size + mood, then stop. No combat, no Merchant/Caravan **trade**
(coin limits), no faction/disposition behaviour for Nomads/Bandits/Cutthroats/
Pilgrims.
- **Build:** a resolution step per encounter kind — combat-lite, trade UI, and
  mood-driven outcomes.
- **Touches:** new `encounter_resolve.gd`, `main.gd`. **Depends on:** #3, #4.
  **Effort:** L.

### 6. Roaming-hazard resolution
Hazards drift but landing on the party does nothing. Includes the missing
**world-mutation hook** — Collapse can permanently turn a Ruins/Settlement hex
into Wastes (see [roaming-hazards.md](roaming-hazards.md) §3).
- **Build:** resolve each `HazardSet.Kind` when the party shares its hex
  (Warband/Demagogue, Crawlherd, Collapse terrain change, etc.).
- **Touches:** `hazard_set.gd`, `main.gd`, `vast_gen`/map for the terrain
  change. **Depends on:** #3, #4. **Effort:** M.

### 7. Curiosities — surfacing, investigate/dig, shelter, rewards
The 1d20 Curiosities exist as data but never appear in play. This is the
"stop at an interesting thing → dig → fight → rest" loop. **Shelter** (the
counter to harmful weather) and rewards (rations / lodestone / treasure) live
here.
- **Build:** surface a curiosity on a hex, an **Investigate** action, the
  shelter flag's effect on weather, and apply rewards.
- **Touches:** `wastes.gd` (already has the table + shelter flags), `main.gd`,
  `hex_map_view.gd`. **Depends on:** #3 for rewards; surfacing can start before.
  **Effort:** M.

---

## Tier C — content & the dungeon scale

### 8. Non-Wastes terrain day-tables
`Wastes.spend_day` asserts `terrain == WASTES`; Ruins/Settlement hexes just print
"no table yet." Their weather/encounter tables aren't transcribed or built.
- **Build:** transcribe the Ruins/Settlement pages into terrain-keyed tables;
  `spend_day` selects by `hex.terrain` (the routine is already terrain-agnostic).
- **Touches:** new docs + `wastes.gd` (or sibling table modules). **Depends on:**
  source pages. **Effort:** M.

### 9. Forced-march UI
`Wastes.spend_day` already takes `push_extra_marches` (+6 mi per exhaustion),
but `main.gd` always passes 0 — no way to choose to push past 18.
- **Build:** a toggle/button to spend exhaustion for extra distance.
- **Touches:** `main.gd`. **Depends on:** #3 (exhaustion must matter).
  **Effort:** S.

### 10. Dungeon procgen + content + persistence + level links
The whole Dungeon scale is a stub — `Dungeon.make_empty` only, no rooms, no
stairs between levels, no content, and dungeons aren't persisted (regenerated
lazily).
- **Build:** room/corridor generation per level, stair/shaft links between the
  6 levels, content/encounters, and saving dungeons.
- **Touches:** `dungeon.gd`, `dungeon_level.gd`, `dungeon_view.gd`,
  `world_save.gd`. **Depends on:** #3 for content. **Effort:** L.

---

## Suggested order

```
1 → 2        (travel can finally cross the world, and the journey persists)
3            (the keystone — unblocks the rest of Tier B)
4 → 5 → 6 → 7 (resolution: saves, encounters, hazards, curiosities)
8 → 9        (content + forced-march polish)
10           (the dungeon scale, its own large effort)
```

Items 1–2 deliver the most visible gameplay for the least work and don't depend
on the party model, so they're the recommended immediate next step. Item 3 is
the gate for all of Tier B.
