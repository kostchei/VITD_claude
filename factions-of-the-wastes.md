# Factions of the Wastes (rules p13)

The four wasteland factions, each offering a **learnable boon** once a Traveler
earns their trust. Data + boon identifiers + the one dice mechanic; the
conditional boon *effects* wire into exhaustion / inventory / trade as those
systems mature (like Traveler Quirks).

> [scripts/core/wastes_factions.gd](scripts/core/wastes_factions.gd) ·
> [tests/test_wastes_factions.gd](tests/test_wastes_factions.gd)

| Faction | Boon | Effect | Learn by |
|---|---|---|---|
| **Lodestone Brokers** | What's Fair is Fair | Barter common↔common and magic↔magic at no cost, any value gap | Assist a caravan on a full trade route |
| **Candlekeepers** | A Burden Shared | When an ally in reach would gain exhaustion or lose a memory, take a level of exhaustion instead | Join them on a call to action |
| **Dust Anglers** | Plenty From Nothing | With tools, spend a day to hunt **1d6 rations** of small game | Hunt and survive a week with them |
| **Pillar Worms** | Grit and Bear It | Gain a level of exhaustion to act as if you had a needed tool | Delve three separate Pillars |

```text
FACTIONS = { LODESTONE_BROKERS, CANDLEKEEPERS, DUST_ANGLERS, PILLAR_WORMS }
            -> { name, boon, boon_desc, learn }

dust_angler_hunt(rng) = 1d6 rations            # the only dice mechanic here
```

> Boon effects depend on systems still being built (trade, the exhaustion-swap,
> tool checks), so this pass is the faction data + the hunt roll; effects wire in
> as those systems land.
