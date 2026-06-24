class_name Settlements
## Settlement generation (rules p16): on discovering a settlement, roll 1d6 each
## for Population, Scarcity, and Atmosphere. Population fixes how many Locations
## and Factions it has. No silent fallbacks: out-of-range rolls raise (assert).

enum Population { BARREN, MIDDLING, OVERCROWDED }
enum Scarcity { DESPERATE, LIMITED_INVENTORY, STEEP_PRICES, DIFFICULT_BARGAINS, MIDDLING, BOUNTIFUL }
enum Atmosphere { HIDDEN, PIETY, MIRTH, DESPAIR, STOIC, PRIMAL }

const POPULATION_NAMES := {
	Population.BARREN: "Barren", Population.MIDDLING: "Middling", Population.OVERCROWDED: "Overcrowded",
}
const SCARCITY_NAMES := {
	Scarcity.DESPERATE: "Desperate",
	Scarcity.LIMITED_INVENTORY: "Limited Inventory",
	Scarcity.STEEP_PRICES: "Steep Prices",
	Scarcity.DIFFICULT_BARGAINS: "Difficult Bargains",
	Scarcity.MIDDLING: "Middling",
	Scarcity.BOUNTIFUL: "Bountiful",
}
const ATMOSPHERE_NAMES := {
	Atmosphere.HIDDEN: "Hidden", Atmosphere.PIETY: "Piety", Atmosphere.MIRTH: "Mirth",
	Atmosphere.DESPAIR: "Despair", Atmosphere.STOIC: "Stoic", Atmosphere.PRIMAL: "Primal",
}


## Population from 1d6: 1-3 Barren, 4-5 Middling, 6 Overcrowded.
static func population(roll: int) -> int:
	assert(roll >= 1 and roll <= 6, "population: d6 out of range: %d" % roll)
	if roll <= 3:
		return Population.BARREN
	if roll <= 5:
		return Population.MIDDLING
	return Population.OVERCROWDED


## Scarcity from 1d6 (table order: 1 Desperate .. 6 Bountiful).
static func scarcity(roll: int) -> int:
	assert(roll >= 1 and roll <= 6, "scarcity: d6 out of range: %d" % roll)
	return roll - 1


## Atmosphere from 1d6 (table order: 1 Hidden .. 6 Primal).
static func atmosphere(roll: int) -> int:
	assert(roll >= 1 and roll <= 6, "atmosphere: d6 out of range: %d" % roll)
	return roll - 1


## Number of Locations for a Population: Barren 1d3, Middling 1d6, Overcrowded 2d6.
static func location_count(pop: int, rng: RandomNumberGenerator) -> int:
	match pop:
		Population.BARREN: return rng.randi_range(1, 3)
		Population.MIDDLING: return rng.randi_range(1, 6)
		Population.OVERCROWDED: return rng.randi_range(1, 6) + rng.randi_range(1, 6)
	assert(false, "location_count: unknown population %d" % pop)
	return 0


## Number of Factions for a Population: Barren 1, Middling 1d3, Overcrowded 1d6.
static func faction_count(pop: int, rng: RandomNumberGenerator) -> int:
	match pop:
		Population.BARREN: return 1
		Population.MIDDLING: return rng.randi_range(1, 3)
		Population.OVERCROWDED: return rng.randi_range(1, 6)
	assert(false, "faction_count: unknown population %d" % pop)
	return 0


## Roll a whole settlement: population/scarcity/atmosphere + its location and
## faction counts. (Reservoir/Paddock locations add +1 to Scarcity — applied by
## the caller once locations are known.)
static func generate(rng: RandomNumberGenerator) -> Dictionary:
	var pop := population(rng.randi_range(1, 6))
	return {
		"population": pop,
		"scarcity": scarcity(rng.randi_range(1, 6)),
		"atmosphere": atmosphere(rng.randi_range(1, 6)),
		"locations": location_count(pop, rng),
		"factions": faction_count(pop, rng),
	}
