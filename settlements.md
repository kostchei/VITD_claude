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

## Settlement Locations 1d12 (p17) — pending (#16)

Storyteller, Scrap Smithy, Apothecary, Pyromancer Foundry, Magus Sanctum,
Reservoir, Bazaar, Cartographer Roost, Lodestone Carver, Memorial Shrine,
Paddock, Nomad Hold — each a boon (e.g. Lodestone Carver: Raw Lodestone → 100
coins; Storyteller: 1-in-6/day extra exhaustion recovery; Memorial Shrine:
replace a lost memory when a companion dies). Count by Population.
