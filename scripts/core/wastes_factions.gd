class_name WastesFactions
## The four Factions of the Wastes (rules p13). Each grants a learnable boon once
## a Traveler earns its trust. This is the faction data + boon identifiers + the
## one dice mechanic (Dust Anglers' hunt); the conditional boon effects wire into
## exhaustion / inventory / trade as those systems are built.
## No silent fallbacks: unknown faction ids raise (assert).

enum Faction { LODESTONE_BROKERS, CANDLEKEEPERS, DUST_ANGLERS, PILLAR_WORMS }

const DUST_ANGLER_HUNT_DICE := 6   # a day's hunt yields 1d6 rations of small game

const FACTIONS := {
	Faction.LODESTONE_BROKERS: {
		"name": "Lodestone Brokers",
		"boon": "What's Fair is Fair",
		"boon_desc": "When trading, barter common items for common items and magic for magic at no cost, regardless of value difference.",
		"learn": "Assist one of their caravans on a full trade route.",
	},
	Faction.CANDLEKEEPERS: {
		"name": "Candlekeepers",
		"boon": "A Burden Shared",
		"boon_desc": "When an ally within arm's reach would gain a level of exhaustion or lose a memory, you may instead take a level of exhaustion.",
		"learn": "Join them on a call to action.",
	},
	Faction.DUST_ANGLERS: {
		"name": "Dust Anglers",
		"boon": "Plenty From Nothing",
		"boon_desc": "While travelling the wastes with appropriate tools, spend a day to hunt and trap 1d6 rations of small game.",
		"learn": "Hunt and survive a week with them.",
	},
	Faction.PILLAR_WORMS: {
		"name": "Pillar Worms",
		"boon": "Grit and Bear It",
		"boon_desc": "Gain a level of exhaustion to perform a task as if you had a required/useful tool equipped.",
		"learn": "Delve three separate Pillars.",
	},
}


static func faction(id: int) -> Dictionary:
	assert(FACTIONS.has(id), "faction: unknown id %d" % id)
	return FACTIONS[id]


static func name_of(id: int) -> String:
	return faction(id)["name"]


static func boon_of(id: int) -> String:
	return faction(id)["boon"]


## Dust Anglers' "Plenty From Nothing": a day's hunt yields 1d6 rations.
static func dust_angler_hunt(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(1, DUST_ANGLER_HUNT_DICE)
