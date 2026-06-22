class_name Traveler
## A Traveler's health model: Grit & Flesh (rules p7), which replace Hit Points.
##   Grit  = 1d8 per level + CON modifier; superficial; lost first; heals fast.
##   Flesh = Level + highest ability modifier; serious; lost only after Grit;
##           each point lost records an injury on a random stat (disadvantage),
##           and Flesh heals only at a Settlement/medic (1/day).
## This class grows with the Traveler chapter (exhaustion, inventory, memories,
## quirks added by later rules). No silent fallbacks: bad input raises (assert).

var traveler_name: String = "Traveler"
var level: int = 1
var scores: Dictionary = {}          # Abilities.Ability -> score (3-18)

var grit_max: int = 1
var grit: int = 1
var flesh_max: int = 1
var flesh: int = 1
var injuries: Array = []             # [{ "ability": Abilities.Ability, "note": String }]

# Exhaustion (rules p7): damage from erosion, not wounds. A 7th level is a
# Harrowing hardship (see The Harrowing). Reasons a level is gained:
enum ExhaustionCause { LOST_SLEEP, SEVERELY_WOUNDED, NO_FOOD, PUSHED_TOO_HARD }
const EXHAUSTION_HARROWING_LEVEL := 7
var exhaustion: int = 0

# The Harrowing (rules p8): 5 memories/drives. A hardship may cost one; losing
# the 5th means the Traveler is slain / becomes an NPC / wanders into the dark.
enum HarrowingHardship { DROPPED_TO_ZERO, SEVENTH_EXHAUSTION, OBJECT_OR_PLACE, GREAT_TRAGEDY }
enum HarrowedFate { SLAIN, BECOME_NPC, WANDER }
const MEMORY_COUNT := 5
var memories: Array = []              # the chosen memories/drives (strings)


## Build a fresh Traveler from a level + ability scores. Grit is rolled (1d8 per
## level + CON mod), Flesh is Level + highest mod; both start full. Floored at 1
## (the rules state no minimum; a Traveler must have at least 1 of each).
static func create(name: String, level: int, scores: Dictionary, rng: RandomNumberGenerator) -> Traveler:
	assert(level >= 1, "Traveler.create: level must be >= 1")
	assert(scores.has(Abilities.Ability.CON), "Traveler.create: scores missing CON")
	var t := Traveler.new()
	t.traveler_name = name
	t.level = level
	t.scores = scores.duplicate()
	t.grit_max = roll_grit_max(level, scores, rng)
	t.grit = t.grit_max
	t.flesh_max = flesh_max_for(level, scores)
	t.flesh = t.flesh_max
	return t


## Grit maximum: 1d8 per level + CON modifier (added once), floored at 1.
static func roll_grit_max(level: int, scores: Dictionary, rng: RandomNumberGenerator) -> int:
	var total := Abilities.modifier(scores[Abilities.Ability.CON])
	for i in range(level):
		total += rng.randi_range(1, 8)
	return maxi(1, total)


## Flesh maximum: Level + highest ability modifier, floored at 1.
static func flesh_max_for(level: int, scores: Dictionary) -> int:
	return maxi(1, level + Abilities.highest_modifier(scores))


## Apply `amount` damage: Grit absorbs first, the overflow cuts Flesh. Each point
## of Flesh lost records an injury on a random stat (disadvantage with it).
## Returns the amount of Flesh actually lost.
func take_damage(amount: int, rng: RandomNumberGenerator) -> int:
	assert(amount >= 0, "take_damage: negative amount")
	var to_grit := mini(grit, amount)
	grit -= to_grit
	var overflow := amount - to_grit
	var flesh_lost := 0
	while overflow > 0 and flesh > 0:
		flesh -= 1
		flesh_lost += 1
		overflow -= 1
		injuries.append({"ability": _random_ability(rng), "note": "injury"})
	return flesh_lost


## Daily Grit healing: 1d6, or 2d6 on a full day of rest. Capped at grit_max.
func heal_grit(full_rest: bool, rng: RandomNumberGenerator) -> int:
	var amount := rng.randi_range(1, 6)
	if full_rest:
		amount += rng.randi_range(1, 6)
	var before := grit
	grit = mini(grit_max, grit + amount)
	return grit - before


## Flesh healing — only valid at a Settlement / medic, 1 per day. Capped.
func heal_flesh_in_settlement() -> int:
	var before := flesh
	flesh = mini(flesh_max, flesh + 1)
	return flesh - before


## True once Flesh hits 0 (the "dropped to 0 hit points" Harrowing hardship).
func is_down() -> bool:
	return flesh <= 0


## Gain one (or more) levels of exhaustion. Returns true if this pushed the
## Traveler to the 7th level — itself a Harrowing hardship (see The Harrowing).
## (The Hollow Fortitude quirk's 3-in-6 skip is applied by the caller for now.)
func gain_exhaustion(_cause: int = ExhaustionCause.PUSHED_TOO_HARD, amount: int = 1) -> bool:
	assert(amount >= 1, "gain_exhaustion: amount must be >= 1")
	var was_below := exhaustion < EXHAUSTION_HARROWING_LEVEL
	exhaustion += amount
	return was_below and exhaustion >= EXHAUSTION_HARROWING_LEVEL


## A full day of rest (no travel) removes one level of exhaustion (min 0).
func rest_full_day() -> void:
	exhaustion = maxi(0, exhaustion - 1)


## At/over the 7th level — the threshold that triggers a Harrowing hardship.
func is_overexhausted() -> bool:
	return exhaustion >= EXHAUSTION_HARROWING_LEVEL


## Does the Traveler have an injury recorded on this ability (disadvantage)?
func has_injury(ability: int) -> bool:
	for inj in injuries:
		if inj["ability"] == ability:
			return true
	return false


func _random_ability(rng: RandomNumberGenerator) -> int:
	var all := Abilities.Ability.values()
	return all[rng.randi_range(0, all.size() - 1)]


# --- The Harrowing (rules p8) ---

## Choose the Traveler's 5 memories/drives (on first entering the Vast).
func set_memories(chosen: Array) -> void:
	assert(chosen.size() == MEMORY_COUNT, "set_memories: need exactly %d" % MEMORY_COUNT)
	memories = chosen.duplicate()


## Lose one random memory to the Harrowing. Returns true if it was the **last**
## one (the Traveler is now Harrowed — see harrowed_fate). Asserts if none left.
func lose_memory(rng: RandomNumberGenerator) -> bool:
	assert(not memories.is_empty(), "lose_memory: no memories remain")
	memories.remove_at(rng.randi_range(0, memories.size() - 1))
	return memories.is_empty()


## Resolve a hardship: the book says only "there is a chance" to lose a memory —
## the odds are left to the GM, so the caller supplies `chance_in_6` (0-6).
## Rolls 1d6; on <= chance, lose a memory. Returns { lost, harrowed }.
func resolve_hardship(_cause: int, chance_in_6: int, rng: RandomNumberGenerator) -> Dictionary:
	assert(chance_in_6 >= 0 and chance_in_6 <= 6, "resolve_hardship: chance_in_6 out of range")
	var lost := false
	var harrowed := false
	if rng.randi_range(1, 6) <= chance_in_6 and not memories.is_empty():
		lost = true
		harrowed = lose_memory(rng)
	return {"lost": lost, "harrowed": harrowed}


## True once every memory is gone.
func is_harrowed() -> bool:
	return memories.is_empty()


## When Harrowed, the Traveler is slain, becomes an NPC, or wanders into the dark.
func harrowed_fate(rng: RandomNumberGenerator) -> int:
	assert(is_harrowed(), "harrowed_fate: not yet Harrowed")
	var fates := HarrowedFate.values()
	return fates[rng.randi_range(0, fates.size() - 1)]
