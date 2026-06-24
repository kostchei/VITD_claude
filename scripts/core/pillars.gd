class_name Pillars
## Being at a Pillar (rules p14): mining/gathering lodestone (which draws
## attention — adding to the encounter roll) and the Pillar-specific encounter
## table, read on 1d6 + that mining modifier.
## No silent fallbacks: out-of-range rolls raise (assert).

const RAW_LODESTONE_SLOTS := 1   # each Raw Lodestone fills 1 inventory slot

# --- Mining the Pillars (per hour) ---

## Gathering by hand: 1d2 Raw Lodestone, +1d6 to the day's encounter roll.
static func gather(rng: RandomNumberGenerator) -> Dictionary:
	return {"lodestone": rng.randi_range(1, 2), "encounter_mod": _roll(rng, 1, 6)}


## Mining with tools: 1d6 Raw Lodestone, +2d6 to the day's encounter roll.
static func mine(rng: RandomNumberGenerator) -> Dictionary:
	return {"lodestone": rng.randi_range(1, 6), "encounter_mod": _roll(rng, 2, 6)}


## Coin value of one Raw Lodestone refined at a settlement: 1d10 x 10.
static func refine_value(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(1, 10) * 10


# --- Pillar encounter table (1d6 + mining modifier) ---

enum Encounter {
	NOTHING, LOST_TRAVELERS, LODESTONE_MINERS, MERCHANTS, CYCLOPS, BANDITS,
	HARPIES, CUTTHROATS, MEDUSA, CYCLOPS_2D6, OGRE, HARPIES_2D6, SHADE, GRIFFON,
}

enum Mood { NONE, TERRITORIAL, CURIOUS, FRIENDLY, CRAZED, TRIBUTE, RECRUIT }

const ENCOUNTER_NAMES := {
	Encounter.NOTHING: "Nothing",
	Encounter.LOST_TRAVELERS: "Lost Travelers",
	Encounter.LODESTONE_MINERS: "Lodestone Miners",
	Encounter.MERCHANTS: "Merchants",
	Encounter.CYCLOPS: "Cyclops",
	Encounter.BANDITS: "Bandits",
	Encounter.HARPIES: "Harpies",
	Encounter.CUTTHROATS: "Cutthroats",
	Encounter.MEDUSA: "Medusa",
	Encounter.CYCLOPS_2D6: "Cyclops (swarm)",
	Encounter.OGRE: "Ogre",
	Encounter.HARPIES_2D6: "Harpies (flock)",
	Encounter.SHADE: "Shade",
	Encounter.GRIFFON: "Griffon",
}


## Encounter for a roll = 1d6 + mining/gathering modifier (>= 1).
static func encounter(roll: int) -> int:
	assert(roll >= 1, "encounter: roll must be >= 1, got %d" % roll)
	if roll <= 2:
		return Encounter.NOTHING
	match roll:
		3: return Encounter.LOST_TRAVELERS
		4: return Encounter.LODESTONE_MINERS
		5: return Encounter.MERCHANTS
		6: return Encounter.CYCLOPS
		7: return Encounter.BANDITS
		8: return Encounter.HARPIES
		9: return Encounter.CUTTHROATS
		10: return Encounter.MEDUSA
		11: return Encounter.CYCLOPS_2D6
		12: return Encounter.OGRE
		13: return Encounter.HARPIES_2D6
		14: return Encounter.SHADE
	return Encounter.GRIFFON  # 15+


## Whether an encounter rolls a 1d6 Mood.
static func has_mood(enc: int) -> bool:
	return enc == Encounter.LODESTONE_MINERS or enc == Encounter.BANDITS or enc == Encounter.CUTTHROATS


## 1d6 Mood for an encounter that has one. Caller checks has_mood() first.
## Lodestone Miners: the page's "1-2 / 2-4 / 5-6" overlaps at 2; read as a clean
## even split 1-2 Territorial, 3-4 Curious, 5-6 Friendly (flagged in the doc).
static func mood(enc: int, roll: int) -> int:
	assert(roll >= 1 and roll <= 6, "mood: 1d6 out of range: %d" % roll)
	match enc:
		Encounter.LODESTONE_MINERS:
			if roll <= 2:
				return Mood.TERRITORIAL
			if roll <= 4:
				return Mood.CURIOUS
			return Mood.FRIENDLY
		Encounter.BANDITS:
			if roll <= 2:
				return Mood.CRAZED
			if roll <= 5:
				return Mood.TRIBUTE
			return Mood.CURIOUS
		Encounter.CUTTHROATS:
			if roll <= 3:
				return Mood.CRAZED
			if roll <= 5:
				return Mood.TRIBUTE
			return Mood.RECRUIT
	assert(false, "mood: encounter %d has no Mood" % enc)
	return Mood.NONE


## Headcount of an encountered group (its own dice).
static func group_size(enc: int, rng: RandomNumberGenerator) -> int:
	match enc:
		Encounter.NOTHING: return 0
		Encounter.LOST_TRAVELERS: return _roll(rng, 1, 6)
		Encounter.LODESTONE_MINERS: return _roll(rng, 1, 6)
		Encounter.MERCHANTS: return _roll(rng, 1, 3)
		Encounter.CYCLOPS: return _roll(rng, 1, 6)
		Encounter.BANDITS: return _roll(rng, 1, 6)
		Encounter.HARPIES: return _roll(rng, 1, 3)
		Encounter.CUTTHROATS: return _roll(rng, 1, 6)
		Encounter.MEDUSA: return _roll(rng, 1, 3)
		Encounter.CYCLOPS_2D6: return _roll(rng, 2, 6)
		Encounter.OGRE: return 1
		Encounter.HARPIES_2D6: return _roll(rng, 2, 6)
		Encounter.SHADE: return 1
		Encounter.GRIFFON: return 1
	assert(false, "group_size: unknown encounter %d" % enc)
	return 0


# --- internal ---

static func _roll(rng: RandomNumberGenerator, n: int, sides: int) -> int:
	var total := 0
	for i in range(n):
		total += rng.randi_range(1, sides)
	return total
