class_name HazardSet
## A population of mobile dangers roaming one Local hex map (roaming-hazards.md).
## Each hazard is a die sitting on a hex; every day they drift one hex, and are
## re-dropped on collision or when they would leave the map, so the count stays
## constant. Hazards layer *on top of* the generated terrain — they reference the
## same Local HexMap and never replace its tiles.
## No silent fallbacks: bad input or an impossible re-drop raises (assert).

enum Kind { WARBAND, MAELSTROM, CRAWLHERD, COLLAPSE, VOID_LIGHTNING, SINGING_SAND }

# d6 Roaming Hazards table order: face 1 = Warband ... face 6 = Singing Sand.
const KIND_NAMES := {
	Kind.WARBAND: "Warband",
	Kind.MAELSTROM: "Maelstrom",
	Kind.CRAWLHERD: "Crawlherd",
	Kind.COLLAPSE: "Collapse",
	Kind.VOID_LIGHTNING: "Void Lightning",
	Kind.SINGING_SAND: "Singing Sand",
}


## One die on the map: its hex and which hazard (Kind) its face shows.
class Hazard:
	var hex: Vector2i
	var kind: int  # Kind enum

	func _init(h: Vector2i, k: int) -> void:
		hex = h
		kind = k


var day: int = 1
var hazards: Array[Hazard] = []


## d6 face (1-6) -> Kind. The enum is declared in table order.
static func kind_from_roll(roll: int) -> int:
	assert(roll >= 1 and roll <= 6, "kind_from_roll: %d out of range" % roll)
	return roll - 1


func name_of(kind: int) -> String:
	assert(KIND_NAMES.has(kind), "name_of: unknown kind %d" % kind)
	return KIND_NAMES[kind]


func at(hex: Vector2i) -> Hazard:
	# No silent fallback: callers check has_hazard_at first.
	for h in hazards:
		if h.hex == hex:
			return h
	assert(false, "HazardSet.at: no hazard at %s" % hex)
	return null


func has_hazard_at(hex: Vector2i) -> bool:
	for h in hazards:
		if h.hex == hex:
			return true
	return false


## Place a fresh population on a Local map: roll 1d6 for the count, drop that many
## dice on distinct hexes, each reading its face on the d6 hazard table.
static func generate(map: HexMap, rng: RandomNumberGenerator) -> HazardSet:
	assert(map.scale == HexMap.Scale.LOCAL, "HazardSet.generate: not a local map")
	var set := HazardSet.new()
	var count := rng.randi_range(1, 6)
	var pool: Array = map.tiles.keys()
	assert(count <= pool.size(), "HazardSet.generate: %d dice but %d hexes" % [count, pool.size()])
	# Partial Fisher-Yates: pick `count` distinct hexes.
	for i in range(count):
		var j := rng.randi_range(i, pool.size() - 1)
		var tmp: Variant = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
		var kind := kind_from_roll(rng.randi_range(1, 6))
		set.hazards.append(Hazard.new(pool[i], kind))
	return set


## Advance one day: move every die one hex in a random direction; if it would
## collide with another die or leave the map, re-drop it onto a free hex.
func advance_day(map: HexMap, rng: RandomNumberGenerator) -> void:
	day += 1
	# Track currently-claimed hexes so dice neither stack nor swap onto each other.
	var occupied := {}
	for h in hazards:
		occupied[h.hex] = true
	for h in hazards:
		occupied.erase(h.hex)  # this die is vacating its hex
		var dir: Vector2i = HexGrid.DIRECTIONS[rng.randi_range(1, 6) - 1]
		var dest: Vector2i = h.hex + dir
		if not map.has(dest) or occupied.has(dest):
			dest = _random_free_hex(map, occupied, rng)
		h.hex = dest
		occupied[dest] = true


# --- internal ---

## A random map hex not currently claimed in `occupied`. With <= 6 dice on 37
## hexes there is always room; an empty pool is a bug, so assert rather than loop.
static func _random_free_hex(map: HexMap, occupied: Dictionary, rng: RandomNumberGenerator) -> Vector2i:
	var free: Array[Vector2i] = []
	for coord in map.tiles:
		if not occupied.has(coord):
			free.append(coord)
	assert(not free.is_empty(), "HazardSet._random_free_hex: no free hex to re-drop onto")
	return free[rng.randi_range(0, free.size() - 1)]
