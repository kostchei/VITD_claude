# Settlements (rules p16–17)

Where Travelers rest, recover exhaustion, and resupply. On discovering a new
settlement, roll **1d6 each** for Population, Scarcity, and Atmosphere, then
stock its Locations and Factions.

## Settlement generation (p16) — ✅ implemented

> [scripts/core/settlements.gd](scripts/core/settlements.gd) ·
> [tests/test_settlements.gd](tests/test_settlements.gd)

```text
population(1d6):  1-3 Barren (1d3 locations, 1 faction)
                  4-5 Middling (1d6 locations, 1d3 factions)
                  6   Overcrowded (2d6 locations, 1d6 factions)
scarcity(1d6):    1 Desperate (sell only) · 2 Limited Inventory (buy 1d6 total) ·
                  3 Steep Prices (x2) · 4 Difficult Bargains (give up 1 item/buy) ·
                  5 Middling · 6 Bountiful (1 free extra when buying)
atmosphere(1d6):  Hidden / Piety / Mirth / Despair / Stoic / Primal (flavour)
generate(rng):    rolls all three + location_count + faction_count
```

> Reservoir / Paddock locations add **+1 to the Scarcity roll**; applied by the
> caller once locations are known (handled with the Locations table, #16).

## Settlement Locations 1d12 (p17) — ✅ implemented

> [scripts/core/settlement_locations.gd](scripts/core/settlement_locations.gd) ·
> [tests/test_settlement_locations.gd](tests/test_settlement_locations.gd)

A settlement has `location_count` of these (rolled 1d12 each). Each offers a
boon; **Reservoir** and **Paddock** also add **+1 to the Scarcity roll**.

```text
1 Storyteller (1-in-6/day extra exhaustion recovery) · 2 Scrap Smithy (repair/renew metal) ·
3 Apothecary (craft Hellfire/Hearthfire/Remedy/Malady) · 4 Pyromancer Foundry (Jarred Fire) ·
5 Magus Sanctum (lodestone -> Magic Scroll) · 6 Reservoir (+1 Scarcity) ·
7 Bazaar (barter common items) · 8 Cartographer Roost (buy Directions) ·
9 Lodestone Carver (1 Raw Lodestone -> 100 coin) · 10 Memorial Shrine (replace a lost
memory when a companion dies) · 11 Paddock (+1 Scarcity) · 12 Nomad Hold (recruit companions)
```

> Crafting recipes (Apothecary/Pyromancer monster-part tools) are captured as
> description data; their effects are a follow-up once combat/items exist.
> `total_scarcity_mod(ids)` feeds the +1s back into the Scarcity roll (#15).

## Travelers & Denizens (p18) — ✅ implemented

> [scripts/core/denizens.gd](scripts/core/denizens.gd) ·
> [tests/test_denizens.gd](tests/test_denizens.gd)

Eight named NPCs with service/quest hooks: **Nod** (bounty hunter), **Masque**
(secrets), **Flayed Dervish** (ally vs seven cutthroats), **Sindr** (five Holds
of Fire), **Old Tune** (flute for a song from the deep), **Hool** (Waste-Crier
to escort), **Skitter** (seeks an exit), **Dive** (pays for passage into the
deep). A catalog (data); quests hook into other systems as they exist.

## Settlement Factions (p19) — ✅ implemented

> [scripts/core/settlement_factions.gd](scripts/core/settlement_factions.gd) ·
> [tests/test_settlement_factions.gd](tests/test_settlement_factions.gd)

| Faction | Boon | Effect | Learn by |
|---|---|---|---|
| **Partisans of Flame** | Novice of the Fire | Craft Jarred Fire in **1d3 hours** with materials | Gift an artifact to a pyromancer |
| **Seeker Keepers** | Inscrutable Pockets | Once/day produce a poor common tool that breaks after use | Gift something important from before |
| **Black Helms** | There is Only Darkness | Per memory lost, gain **1d6 Grit** + an extra attack | Defeat one in ritual combat |
| **Grafters** | One Body | Move **1d6 Grit** from a willing host to heal **1 Flesh** | Assist their arts three times |

> Boon effects depend on crafting / combat / Grit-Flesh systems; this pass is the
> faction data + the dice helpers (`jarred_fire_hours`, `black_helm_grit`, `graft`).
