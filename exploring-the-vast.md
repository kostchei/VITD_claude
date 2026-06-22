# Exploring the Vast (rules p9)

Summary + pseudocode for the "Exploring the Vast" page. The day-to-day travel
budget (18 mi/day, +6 per exhaustion, 1 ration/day) lives in
[wastes-weather-encounters.md](wastes-weather-encounters.md) §4; this page adds
**Navigation** — the daily orienteering check — and the compass rule.

> Implemented in [scripts/core/navigation.gd](scripts/core/navigation.gd),
> tested in [tests/test_navigation.gd](tests/test_navigation.gd).

## Travel guidelines (p9)

- On foot, average **18 miles/day** (24h) before needing rest.
- **+6 miles/day** for a level of exhaustion (forced march).
- **1 ration/day** or gain a level of exhaustion.
- Encounters and weather occur **by terrain**.
- **Compasses point only to the nearest Pillar** (pg. 12) — not implemented yet.

## Navigation Roll

Each day the party tries to traverse, roll **1d6**: a **6** navigates
successfully; **1–5** means **Lost**. Each prepared **asset** lessens the lost
chance by 1, down to **0-in-6**:

- **Landmark** — visual reference (usually Pillars)
- **Directions** — written maps / spoken words
- **Tool** — lodestone pendant, spyglass, divining magic
- **Light** — torch, lantern, magic
- **Dead Reckoning** — you have made this exact journey before

So with `n` assets you are Lost on a roll `≤ (5 − n)` (clamped at 0). Worked
example from the book: a party with 4 assets is Lost **only on a 1**, and then
only ever suffers **"Late"**.

### Becoming Lost — effects by remaining lost-chance

| Lost chance (threshold) | Effect | Result |
|---|---|---|
| 1 | **Late** | 6 miles short of destination |
| 2 | **Off course** | 6 miles away, random direction |
| 3 | **Dangerously off course** | 12 miles away |
| 4–5 | **Utterly lost** | keep rolling until a success; that many days are spent before you return to where you started |

> The book pins **threshold 1 → Late** (the example). The 2/3 and 4–5 bands are
> our documented reading of "determined by their original chances of becoming
> lost"; flagged for review if the source intends a different split.

```text
LOST_THRESHOLD(asset_count):            # d6 <= this => Lost
    return clamp(5 - asset_count, 0, 5)

IS_LOST(roll, threshold):               # roll in 1..6
    return roll <= threshold

LOST_EFFECT(threshold):
    if threshold <= 0: return NONE
    if threshold == 1: return LATE                    # anchor (book example)
    if threshold == 2: return OFF_COURSE
    if threshold == 3: return DANGEROUSLY_OFF_COURSE
    return UTTERLY_LOST                               # 4-5

navigate(asset_count, rng):
    t   = LOST_THRESHOLD(asset_count)
    roll = rng 1..6
    lost = IS_LOST(roll, t)
    return { roll, threshold: t, lost,
             effect: LOST_EFFECT(t) if lost else NONE,
             miles_penalty: { NONE:0, LATE:6, OFF_COURSE:6,
                              DANGEROUSLY_OFF_COURSE:12, UTTERLY_LOST:-1 } }
```

## Not yet built (todos)

- **Compass → nearest Pillar**: at any position, point to the nearest regional
  Pillars hex (needs the regional map; trivial once wired).
- Applying the Navigation Roll + Lost effects into the travel loop (`main.gd`):
  a daily check, asset selection UI, and the mile penalties / "utterly lost"
  multi-day resolution. The mechanics module is done; the integration is not.
