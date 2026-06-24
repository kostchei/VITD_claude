# The Pillars (rules p14–15)

The titanic lodestone columns and the tunnels honeycombing their bases. Two
chapters of mechanics: **being at a Pillar** (mining + a pillar encounter table)
and **delving its tunnels** (tunnel/event/loot tables).

## Delving the Pillars (p15) — ✅ implemented

> [scripts/core/pillar_delve.gd](scripts/core/pillar_delve.gd) ·
> [tests/test_pillar_delve.gd](tests/test_pillar_delve.gd)

Timing: tunnel→tunnel **10 min**, searching a tunnel **30 min**. On entering a
tunnel roll its **Shape & Size** (1d6) then **Loot**. Going deeper repeats with
**+1 to the Loot roll per depth**. Roll an **Event** on every new tunnel/search,
**+1 per previous roll**. Duplicate tunnel numbers mean the path splits.

```text
tunnel(1d6):              Constricting Squeeze / Sheer Drop / Tight Halls /
                          Winding Tunnel / Jagged Ascent / Cavernous
event(1d6 + prev_rolls):  1-3 Chill Fog · 4 Wind Blast · 5 Cyclops · 6 Decay ·
                          7 Medusa · 8 Harpies · 9 Collapse · 10 Hallucination ·
                          11 Harmonics · 12 Ogre · 13 Ego Sink · 14 Shade ·
                          15+ Call of the Dark
loot(1d6 + depth):        1-3 Forgotten Corpse · 4-6 Raw Lodestone(1d10) ·
                          7 Lodestone Idols · 8 Abandoned Supplies ·
                          9 Raw Lodestone(2d10) · 10 Lone Survivor ·
                          11 Lodestone Mural · 12 Corpse Pile · 13 Artifact ·
                          14+ Hoard(2d20 Raw Lodestone)
```

> Event/loot **effects** (saves, monster spawns, reward dice, the "Call of the
> Dark" exhaustion/memory cost) are reported by name; they wire into the
> encounter/combat/reward layers as those land.

## Mining the Pillars (p14) — ✅ implemented

> [scripts/core/pillars.gd](scripts/core/pillars.gd) ·
> [tests/test_pillars.gd](tests/test_pillars.gd)

Per hour: **Gathering** = 1d2 Raw Lodestone + 1d6 to the encounter roll;
**Mining** (needs tools) = 1d6 Raw Lodestone + 2d6 to the encounter roll. Each
Raw Lodestone = 1 slot; refined at a settlement = **1d10×10 coins**.

```text
gather(rng) = { lodestone: 1d2, encounter_mod: 1d6 }
mine(rng)   = { lodestone: 1d6, encounter_mod: 2d6 }   # requires tools
refine_value(rng) = 1d10 * 10                          # per Raw Lodestone
```

## Pillar encounter table (p14) — ✅ implemented

Read on **1d6 + mining/gathering modifier** (distinct from the Wastes table):

```text
encounter(1d6 + mod):
  1-2 Nothing · 3 Lost Travelers · 4 Lodestone Miners(+mood) · 5 Merchants ·
  6 Cyclops · 7 Bandits(+mood) · 8 Harpies · 9 Cutthroats(+mood) · 10 Medusa ·
  11 Cyclops(2d6) · 12 Ogre · 13 Harpies(2d6) · 14 Shade · 15+ Griffon
```

> Lodestone Miners' mood as printed reads "1-2 / 2-4 / 5-6" (overlaps at 2);
> implemented as a clean even split **1-2 Territorial, 3-4 Curious, 5-6
> Friendly**. Bandit/Cutthroat moods match the Wastes table.
