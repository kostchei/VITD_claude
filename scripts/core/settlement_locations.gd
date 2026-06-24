class_name SettlementLocations
## The 1d12 Settlement Locations (rules p17). A settlement has a number of these
## (set by Population, see Settlements). Each offers a boon. Reservoir and Paddock
## raise the settlement's Scarcity roll by +1. This pass is the table + the
## concrete numeric bits; richer boon effects (crafting, recruiting, trade) wire
## into their systems later. No silent fallbacks: bad rolls raise (assert).

enum Location {
	STORYTELLER, SCRAP_SMITHY, APOTHECARY, PYROMANCER_FOUNDRY, MAGUS_SANCTUM,
	RESERVOIR, BAZAAR, CARTOGRAPHER_ROOST, LODESTONE_CARVER, MEMORIAL_SHRINE,
	PADDOCK, NOMAD_HOLD,
}

const LODESTONE_CARVER_COIN := 100        # Lodestone Carver: 1 Raw Lodestone -> 100 coins
const STORYTELLER_REST_CHANCE_IN_6 := 1   # Storyteller: 1-in-6/day extra exhaustion recovery

# id -> { name, boon, desc, scarcity_mod }
const LOCATIONS := {
	Location.STORYTELLER: {"name": "Storyteller", "boon": "Stories",
		"desc": "Each day, 1-in-6 chance to recover an extra level of Exhaustion while resting here.", "scarcity_mod": 0},
	Location.SCRAP_SMITHY: {"name": "Scrap Smithy", "boon": "Repair / Renew",
		"desc": "Trade two metal tools/arms/armor for one new item of equal weight; ingots trade for items of equal weight.", "scarcity_mod": 0},
	Location.APOTHECARY: {"name": "Apothecary", "boon": "Medicine",
		"desc": "Buy alchemical tools (Hellfire, Hearthfire, Remedy, Malady) with specific material components.", "scarcity_mod": 0},
	Location.PYROMANCER_FOUNDRY: {"name": "Pyromancer Foundry", "boon": "Jarred Fire",
		"desc": "Buy special fire tools with specific material components.", "scarcity_mod": 0},
	Location.MAGUS_SANCTUM: {"name": "Magus Sanctum", "boon": "Magic Scrolls",
		"desc": "Trade Raw Lodestone for a Magic Scroll (one spell; dissolves after use).", "scarcity_mod": 0},
	Location.RESERVOIR: {"name": "Reservoir", "boon": "Fishing pit",
		"desc": "Meager quarry dredged from the well. Adds +1 to the Scarcity roll.", "scarcity_mod": 1},
	Location.BAZAAR: {"name": "Bazaar", "boon": "Barter",
		"desc": "Trade common items in place of purchasing them with coin or lodestone.", "scarcity_mod": 0},
	Location.CARTOGRAPHER_ROOST: {"name": "Cartographer Roost", "boon": "Wayfinder",
		"desc": "Directions and maps may be purchased as an item.", "scarcity_mod": 0},
	Location.LODESTONE_CARVER: {"name": "Lodestone Carver", "boon": "Expertise",
		"desc": "Exchange Raw Lodestone here for 100 coins each.", "scarcity_mod": 0},
	Location.MEMORIAL_SHRINE: {"name": "Memorial Shrine", "boon": "Remember",
		"desc": "When a companion dies, write their name and replace a lost memory with the memory of them.", "scarcity_mod": 0},
	Location.PADDOCK: {"name": "Paddock", "boon": "Trapping pit",
		"desc": "Diminutive creatures hunted with bow and spear. Adds +1 to the Scarcity roll.", "scarcity_mod": 1},
	Location.NOMAD_HOLD: {"name": "Nomad Hold", "boon": "Companions",
		"desc": "Recruit or pay hirelings, travelers and companions to join your party.", "scarcity_mod": 0},
}


## Location for a 1d12 (1-12), table order.
static func location(roll: int) -> int:
	assert(roll >= 1 and roll <= 12, "location: d12 out of range: %d" % roll)
	return roll - 1


static func data(id: int) -> Dictionary:
	assert(LOCATIONS.has(id), "data: unknown location %d" % id)
	return LOCATIONS[id]


static func name_of(id: int) -> String:
	return data(id)["name"]


## +1 Scarcity for Reservoir / Paddock, else 0.
static func scarcity_mod(id: int) -> int:
	return data(id)["scarcity_mod"]


## Roll `count` locations (1d12 each; duplicates possible, as the table is rolled
## per slot). Returns the rolled location ids.
static func roll_locations(count: int, rng: RandomNumberGenerator) -> Array:
	assert(count >= 0, "roll_locations: count must be >= 0")
	var out: Array = []
	for i in range(count):
		out.append(location(rng.randi_range(1, 12)))
	return out


## Total Scarcity-roll modifier contributed by a set of location ids.
static func total_scarcity_mod(ids: Array) -> int:
	var total := 0
	for id in ids:
		total += scarcity_mod(id)
	return total
