class_name Abilities
## Ability scores for Travelers. The zine (p7 character sheet) uses the six
## standard abilities; the score/modifier math is DCC-style (project decision):
## roll 3d6 per ability, modifier = floor((score - 10) / 2), giving -4 (at 3)
## through +4 (at 18). Bonuses feed inventory slots (CON), Grit (CON) and Flesh
## (highest). No silent fallbacks: bad input raises (assert).

enum Ability { STR, DEX, CON, INT, WIS, CHA }

const NAMES := {
	Ability.STR: "STR",
	Ability.DEX: "DEX",
	Ability.CON: "CON",
	Ability.INT: "INT",
	Ability.WIS: "WIS",
	Ability.CHA: "CHA",
}


## DCC-style modifier: floor((score - 10) / 2). 3 -> -4 ... 18 -> +4.
static func modifier(score: int) -> int:
	assert(score >= 1, "modifier: score must be >= 1, got %d" % score)
	return floori((score - 10) / 2.0)


## Roll one ability score: 3d6 (range 3-18).
static func roll_score(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(1, 6) + rng.randi_range(1, 6) + rng.randi_range(1, 6)


## Roll a full set of the six abilities -> { Ability : score }.
static func roll_set(rng: RandomNumberGenerator) -> Dictionary:
	var out := {}
	for a in Ability.values():
		out[a] = roll_score(rng)
	return out


## The single highest ability modifier across a score set (used by Flesh).
static func highest_modifier(scores: Dictionary) -> int:
	assert(not scores.is_empty(), "highest_modifier: empty score set")
	var best := -999
	for a in scores:
		best = maxi(best, modifier(scores[a]))
	return best
