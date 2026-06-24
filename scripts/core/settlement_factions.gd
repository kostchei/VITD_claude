class_name SettlementFactions
## The four Settlement Factions (rules p19), each granting a learnable boon once
## a Traveler earns their trust. Data + boon identifiers + the dice helpers; the
## conditional boon effects wire into crafting / inventory / combat / Grit-Flesh
## as those systems mature. No silent fallbacks: unknown ids raise (assert).

enum Faction { PARTISANS_OF_FLAME, SEEKER_KEEPERS, BLACK_HELMS, GRAFTERS }

const JARRED_FIRE_CRAFT_DICE := 3   # Partisans craft Jarred Fire in 1d3 hours
const BLACK_HELM_GRIT_DICE := 6     # Black Helms gain 1d6 Grit per memory lost
const GRAFTER_GRIT_DICE := 6        # Grafters move 1d6 Grit from host to heal 1 Flesh
const GRAFTER_FLESH_HEALED := 1

const FACTIONS := {
	Faction.PARTISANS_OF_FLAME: {
		"name": "Partisans of Flame",
		"boon": "Novice of the Fire",
		"boon_desc": "Craft Jarred Fire (pg.15) in 1d3 hours so long as you have the materials.",
		"learn": "Gift an artifact to a pyromancer.",
	},
	Faction.SEEKER_KEEPERS: {
		"name": "Seeker Keepers",
		"boon": "Inscrutable Pockets",
		"boon_desc": "Once per day, produce a single common tool/item from your person; it is poor quality and breaks after one use.",
		"learn": "Gift them something important from before you arrived.",
	},
	Faction.BLACK_HELMS: {
		"name": "Black Helms",
		"boon": "There is Only Darkness",
		"boon_desc": "For every memory lost, gain 1d6 Grit and an additional attack in combat.",
		"learn": "Defeat a Black Helm in ritual combat.",
	},
	Faction.GRAFTERS: {
		"name": "Grafters",
		"boon": "One Body",
		"boon_desc": "Sacrifice or take 1d6 Grit from a willing host to heal 1 Flesh on yourself or another.",
		"learn": "Assist the Grafters with their arts on three occasions.",
	},
}


static func faction(id: int) -> Dictionary:
	assert(FACTIONS.has(id), "faction: unknown id %d" % id)
	return FACTIONS[id]


static func name_of(id: int) -> String:
	return faction(id)["name"]


static func boon_of(id: int) -> String:
	return faction(id)["boon"]


## Partisans of Flame: hours to craft Jarred Fire (1d3).
static func jarred_fire_hours(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(1, JARRED_FIRE_CRAFT_DICE)


## Black Helms: Grit gained per memory lost (1d6). Also grants +1 attack (caller).
static func black_helm_grit(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(1, BLACK_HELM_GRIT_DICE)


## Grafters' One Body: 1d6 Grit taken from a willing host heals 1 Flesh.
static func graft(rng: RandomNumberGenerator) -> Dictionary:
	return {"grit_cost": rng.randi_range(1, GRAFTER_GRIT_DICE), "flesh_healed": GRAFTER_FLESH_HEALED}
