# You are a Traveler (rules p6–8)

Summary + pseudocode for the Traveler chapter: Quirks, Inventory, Exhaustion,
Grit & Flesh, and The Harrowing. Built rule-by-rule per
[rules-implementation-process.md](rules-implementation-process.md); each section
notes its module + test and whether it's implemented yet.

## Traveler Quirks (p6) — ✅ implemented

A **1d20** table of odd abilities picked up from time in the Vast. At character
creation or advancement a Traveler may randomly select one quirk. **Ruin
Plucker (#1)** may be taken multiple times; every other quirk is unique.

> [scripts/core/traveler_quirks.gd](scripts/core/traveler_quirks.gd) ·
> [tests/test_traveler_quirks.gd](tests/test_traveler_quirks.gd)

```text
QUIRKS = [1..20]  # id, name, description; only Ruin Plucker is repeatable

quirk(id):              return QUIRKS[id]           # 1..20
roll(rng):              return rng 1..20
can_take(id, held):     return repeatable(id) or id not in held
roll_takeable(held,rng): roll until can_take(); error if none left
```

Each quirk's *effect* (e.g. Long-walker +6 mi/day, Ruin Plucker +1 slot,
Hollow Fortitude 3-in-6 to skip exhaustion) wires into its system as that system
is built; this pass is the table + the selection rule.

## Ability scores — ✅ implemented (project decision: DCC-style)

The zine is system-agnostic but its character sheet uses the six standard
abilities **STR / DEX / CON / INT / WIS / CHA**. Per project decision we use
**DCC-style** math: each ability is **3d6** (3–18), and the modifier is
`floor((score − 10) / 2)`, giving **−4** (at 3) through **+4** (at 18). These
bonuses feed inventory slots (CON), Grit (CON) and Flesh (highest).

> [scripts/core/abilities.gd](scripts/core/abilities.gd) ·
> [tests/test_abilities.gd](tests/test_abilities.gd)

```text
modifier(score) = floor((score - 10) / 2)     # 3 -> -4 ... 10 -> 0 ... 18 -> +4
roll_score(rng) = 3d6
```

## Inventory (p7) — pending

Slots = **Constitution bonus**. Items cost 1–4 slots. In a settlement you may
dedicate slots to a purpose at **10 coin/slot** and draw items later. Packs:
Bindle +2 (20c), Sack +6 (80c), Backpack +10 (120c). Cargo: Pulk 10 slots
(12 mi/day if pulled alone), Sleigh 20 slots (12 mi/day if ≤2 pull).

## Exhaustion (p7) — pending

Damage representing erosion, not wounds. Gain a level on: lost sleep, severe
wound, a day without food, or pushing too hard (forced march). A full day's rest
(no travel) removes one level. A **7th** level is a Harrowing hardship.

## Grit & Flesh (p7) — ✅ implemented

Replaces Hit Points. **Grit** = 1d8/level + CON modifier; lost first; heals
1d6/day (2d6 on a full rest day). **Flesh** = Level + highest ability modifier;
lost only after Grit; can't heal until a Settlement/medic, then 1/day; each
Flesh point lost records an injury on a random stat (disadvantage with it).
Reaching 0 Flesh is the "dropped to 0 hit points" Harrowing hardship.

> [scripts/core/traveler.gd](scripts/core/traveler.gd) ·
> [tests/test_traveler_health.gd](tests/test_traveler_health.gd)

```text
grit_max  = sum(1d8 for each level) + CON_mod        # floored at 1
flesh_max = level + highest_ability_mod              # floored at 1

take_damage(n): grit absorbs first; overflow cuts Flesh 1-by-1, each lost
                Flesh point -> one injury on a random stat (disadvantage)
heal_grit(rest): + (2d6 if rest else 1d6), capped at grit_max
heal_flesh():    + 1 (Settlement/medic only), capped at flesh_max
```

> Assumptions flagged: CON mod added **once** (not per level); both pools
> **floored at 1** (the page states no minimum); injuries persist (the page
> doesn't define their removal — left to Settlement/medic discretion).

## The Harrowing (p8) — pending

Pick **5 memories/drives**. On a hardship (drop to 0, gain a 7th exhaustion
level, an object/place effect, a great tragedy) there's a chance to lose one.
Lose the 5th → slain / become an NPC / wander into the dark.
