class_name PillarDelve
## Delving the Pillars (rules p15): the tables rolled while exploring a Pillar's
## tunnels — Tunnel Shape & Size (1d6), Pillar Events (1d6 + previous rolls), and
## Pillar Loot (1d6 + depth) — plus the delve timings/structure.
## Tables are the deterministic core; event/loot effects (saves, monsters,
## rewards) are reported by name for the encounter/combat layer to adjudicate.
## No silent fallbacks: out-of-range rolls raise (assert).

const TUNNEL_TRAVEL_MINUTES := 10   # moving tunnel -> tunnel
const TUNNEL_SEARCH_MINUTES := 30   # searching a tunnel

# --- Tunnel Shape & Size (1d6) ---
enum Tunnel { CONSTRICTING_SQUEEZE, SHEER_DROP, TIGHT_HALLS, WINDING_TUNNEL, JAGGED_ASCENT, CAVERNOUS }
const TUNNEL_NAMES := {
	Tunnel.CONSTRICTING_SQUEEZE: "Constricting Squeeze",
	Tunnel.SHEER_DROP: "Sheer Drop",
	Tunnel.TIGHT_HALLS: "Tight Halls",
	Tunnel.WINDING_TUNNEL: "Winding Tunnel",
	Tunnel.JAGGED_ASCENT: "Jagged Ascent",
	Tunnel.CAVERNOUS: "Cavernous",
}

# --- Pillar Events (1d6 + number of previous rolls) ---
enum Event {
	CHILL_FOG, WIND_BLAST, CYCLOPS, DECAY, MEDUSA, HARPIES, COLLAPSE,
	HALLUCINATION, HARMONICS, OGRE, EGO_SINK, SHADE, CALL_OF_THE_DARK,
}
const EVENT_NAMES := {
	Event.CHILL_FOG: "Chill Fog",
	Event.WIND_BLAST: "Wind Blast",
	Event.CYCLOPS: "Cyclops",
	Event.DECAY: "Decay",
	Event.MEDUSA: "Medusa",
	Event.HARPIES: "Harpies",
	Event.COLLAPSE: "Collapse",
	Event.HALLUCINATION: "Hallucination",
	Event.HARMONICS: "Harmonics",
	Event.OGRE: "Ogre",
	Event.EGO_SINK: "Ego Sink",
	Event.SHADE: "Shade",
	Event.CALL_OF_THE_DARK: "Call of the Dark",
}

# --- Pillar Loot (1d6 + depth) ---
enum Loot {
	FORGOTTEN_CORPSE, RAW_LODESTONE_1D10, LODESTONE_IDOLS, ABANDONED_SUPPLIES,
	RAW_LODESTONE_2D10, LONE_SURVIVOR, LODESTONE_MURAL, CORPSE_PILE, ARTIFACT, HOARD,
}
const LOOT_NAMES := {
	Loot.FORGOTTEN_CORPSE: "Forgotten Corpse",
	Loot.RAW_LODESTONE_1D10: "Raw Lodestone (1d10)",
	Loot.LODESTONE_IDOLS: "Lodestone Idols",
	Loot.ABANDONED_SUPPLIES: "Abandoned Supplies",
	Loot.RAW_LODESTONE_2D10: "Raw Lodestone (2d10)",
	Loot.LONE_SURVIVOR: "Lone Survivor",
	Loot.LODESTONE_MURAL: "Lodestone Mural",
	Loot.CORPSE_PILE: "Corpse Pile",
	Loot.ARTIFACT: "Artifact",
	Loot.HOARD: "Hoard (2d20 Raw Lodestone)",
}


## Tunnel shape for a d6 (1-6).
static func tunnel(roll: int) -> int:
	assert(roll >= 1 and roll <= 6, "tunnel: d6 out of range: %d" % roll)
	return roll - 1  # enum declared in table order


## Pillar event for a roll = 1d6 + previous rolls (>= 1).
static func event(roll: int) -> int:
	assert(roll >= 1, "event: roll must be >= 1, got %d" % roll)
	if roll <= 3:
		return Event.CHILL_FOG
	match roll:
		4: return Event.WIND_BLAST
		5: return Event.CYCLOPS
		6: return Event.DECAY
		7: return Event.MEDUSA
		8: return Event.HARPIES
		9: return Event.COLLAPSE
		10: return Event.HALLUCINATION
		11: return Event.HARMONICS
		12: return Event.OGRE
		13: return Event.EGO_SINK
		14: return Event.SHADE
	return Event.CALL_OF_THE_DARK  # 15+


## Pillar loot for a roll = 1d6 + depth (>= 1).
static func loot(roll: int) -> int:
	assert(roll >= 1, "loot: roll must be >= 1, got %d" % roll)
	if roll <= 3:
		return Loot.FORGOTTEN_CORPSE
	if roll <= 6:
		return Loot.RAW_LODESTONE_1D10
	match roll:
		7: return Loot.LODESTONE_IDOLS
		8: return Loot.ABANDONED_SUPPLIES
		9: return Loot.RAW_LODESTONE_2D10
		10: return Loot.LONE_SURVIVOR
		11: return Loot.LODESTONE_MURAL
		12: return Loot.CORPSE_PILE
		13: return Loot.ARTIFACT
	return Loot.HOARD  # 14+


# --- roll helpers (apply the page's modifiers) ---

static func roll_tunnel(rng: RandomNumberGenerator) -> int:
	return tunnel(rng.randi_range(1, 6))


## Events add +1 per previous roll this delve.
static func roll_event(previous_rolls: int, rng: RandomNumberGenerator) -> int:
	assert(previous_rolls >= 0, "roll_event: previous_rolls must be >= 0")
	return event(rng.randi_range(1, 6) + previous_rolls)


## Loot adds the current depth.
static func roll_loot(depth: int, rng: RandomNumberGenerator) -> int:
	assert(depth >= 0, "roll_loot: depth must be >= 0")
	return loot(rng.randi_range(1, 6) + depth)
