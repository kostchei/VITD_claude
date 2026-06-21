# Roaming Hazards

A summary of the "Roaming Hazards" page from *The Vast in the Dark*. Where
[generating-the-vast.md](generating-the-vast.md) stocks the map with **static**
terrain, this system adds **mobile** dangers that wander the 6-mile (Local) hex
map day by day. Each hazard is a die physically sitting on a hex; the dice are
moved each day so the danger can be **tracked, predicted, and navigated around**.

> Scale: the "6-mile hex map" is the **Local** map — a 37-hex field where each
> hex = 1 mile (same map the terrain generator builds). Hazards roam on it.

---

## 1. The roaming procedure

1. **Place:** roll **1d6** for how many dice to drop (**1–6**), then drop that
   many six-sided dice onto the 6-mile (Local) hex map.
2. **A die on a hex = a hazard** there that must be avoided or dealt with. Read
   the die's face on the **d6 Roaming Hazards** table to learn *what* it is.
3. The dice **stay on the map** between days — each represents a mobile,
   ongoing event, not a one-off roll.
4. **Move (each day):** for every die on the map, roll **1d6** and move that die
   one hex in the matching direction (the d6 faces map to the 6 flat-top hex
   neighbours).
5. **Collisions / edges:** if a die would land on a hex already holding a die,
   or would move off the edge of the map, **re-drop** that die randomly onto the
   map.

So the map holds a fixed population (whatever the initial **1d6** rolled — 1 to 6
hazards), each drifting one hex per day, re-seeded whenever it collides or leaves
the area.

---

## 2. d6 Roaming Hazards table

| d6 | Hazard | Effect (short) | How to avoid / end it |
|----|--------|----------------|------------------------|
| 1 | **Warband** | 5d6 Cutthroats led by a Demagogue; attacks on sight. | Won't pursue into Ruins or a Settlement. Slay the **Demagogue** to destroy the hazard. |
| 2 | **Maelstrom** | Violent air columns; those caught are flung **1 mile** in a random direction and take **3d20** damage. | Hide in ruins / strong shelter for the duration. |
| 3 | **Crawlherd** | **1d20** Crawl roaming wastes & ruins. | Settlements have defenses. Slay all the Crawl to destroy it. |
| 4 | **Collapse** | A mile-wide ceiling chunk falls; every Traveler gains a level of **exhaustion** (running) or is crushed. | Any Ruins/Settlements on the hex have a **2-in-6** chance of being reduced to **Wastes**. |
| 5 | **Void Lightning** | Jet-black bolts; anyone wearing/wielding metal has a **3-in-6** chance to be struck for **10d6** (killed = disintegrated). | Strip off all metal, or hide in ruins. |
| 6 | **Singing Sand** | Non-solid/dusty ground turns to quicksand. | Those caught **Save v. Breath** or sink; reach high or solid ground to avoid. |

### Demagogue (Warband leader) statblock

- **HD** 5 · **HP** 30 · **Move** Standard
- **Defense** As Plate · **Weapon** Lodestone Blade 1d10
- **Magic** knows **1d3** random spells
- **Voice of the Dark** — Save v. Charm whenever the Demagogue speaks, or become frightened
- **Artifact of Power** — carries a random artifact (pg. 29)

---

## 3. Pseudocode

```text
# ----- Setup -------------------------------------------------------------

HAZARD_NAME(face):                        # d6 Roaming Hazards table
    if face == 1: return WARBAND
    if face == 2: return MAELSTROM
    if face == 3: return CRAWLHERD
    if face == 4: return COLLAPSE
    if face == 5: return VOID_LIGHTNING
    if face == 6: return SINGING_SAND

place_hazards(map):                       # map = the 37-hex Local map
    hazards = []
    count = random 1..6                   # roll 1d6 for how many dice to drop
    for i in 1..count:
        hex = random empty hex in map     # one die per hex
        hazards.append(Hazard(
            hex  = hex,
            kind = HAZARD_NAME(random 1..6)   # the die's face value
        ))
    return hazards


# ----- Daily tick --------------------------------------------------------
# A d6 maps to the 6 flat-top hex directions.

HEX_DIR(roll):                            # roll 1..6 -> neighbour offset
    return SIX_DIRECTIONS[roll - 1]

advance_day(map, hazards):
    for h in hazards:
        dest = neighbor(h.hex, HEX_DIR(random 1..6))
        if (not map.contains(dest)) or occupied(dest, hazards):
            # off the edge, or bumped another die: re-drop
            h.hex = random empty hex in map
        else:
            h.hex = dest
    return hazards

occupied(hex, hazards):
    return any h in hazards where h.hex == hex


# ----- Encounter (party shares a hex with a hazard) ----------------------

resolve(h, party):
    switch h.kind:
        WARBAND:        # 5d6 cutthroats + Demagogue; won't enter ruins/settlement
            if party.hex.terrain in (RUINS, SETTLEMENTS): no pursuit
            else: combat;  if Demagogue slain: remove h
        MAELSTROM:      # unless sheltering in ruins
            if not sheltered(party): fling(party, 1 mile, random dir); damage 3d20
        CRAWLHERD:      # 1d20 Crawl; settlements are safe
            if party.hex.terrain != SETTLEMENTS: combat
            if all Crawl slain: remove h
        COLLAPSE:
            for t in party: t.exhaustion += 1   # or crushed if not running
            if party.hex.terrain in (RUINS, SETTLEMENTS) and roll_2_in_6():
                party.hex.terrain = WASTES
        VOID_LIGHTNING:
            for t in party where t.wears_metal:
                if roll_3_in_6(): t.take(10d6)  # if dies -> disintegrated
        SINGING_SAND:
            if party on loose ground and not on high/solid ground:
                save_v_breath() or sink
```

---

## 4. Notes for implementation

- Hazards layer **on top of** generated terrain — they reference the same Local
  `HexMap`, they don't replace tiles (except **Collapse**, which can permanently
  turn a hex's Ruins/Settlement into Wastes).
- Population is self-maintaining at its initial **1d6** count: re-dropping on
  collision/edge keeps the count constant rather than letting hazards cluster or
  leak off-map.
- The movement die does double duty in the book: a d6 picks one of the 6 hex
  directions (so reuse the same `SIX_DIRECTIONS` ordering used by the hex math).
- "X-in-6" effects (Collapse 2-in-6, Void Lightning 3-in-6) are just `roll d6
  <= X`.
