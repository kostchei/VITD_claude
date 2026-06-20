class_name VastGen
## Procedural terrain for The Vast. Implements generating-the-vast.md:
##   Regional: drop 8 dice on the map, read d6 -> terrain, empties = Wastes.
##   Local:    roll 1d6 for density (6/12/32 dice), read d6 keyed by the parent
##             regional hex's type, empties = Wastes. Pillars are not stocked.
## No silent fallbacks: bad input raises (assert) per project conventions.

const WASTES := &"wastes"
const RUINS := &"ruins"
const PILLARS := &"pillars"
const SETTLEMENTS := &"settlements"

const REGIONAL_DICE := 8


## Regional terrain table (d6).  1 = Wastes, 2-4 = Ruins, 5-6 = Pillars.
static func regional_terrain(roll: int) -> StringName:
	assert(roll >= 1 and roll <= 6, "regional_terrain: roll out of range: %d" % roll)
	if roll == 1:
		return WASTES
	if roll <= 4:
		return RUINS
	return PILLARS


## Local terrain table (d6), keyed by the parent regional hex's terrain.
##   parent Ruins:  1 = Wastes, 2-4 = Ruins,  5-6 = Settlements
##   parent Wastes: 1-4 = Wastes, 5-6 = Ruins
static func local_terrain(roll: int, parent: StringName) -> StringName:
	assert(roll >= 1 and roll <= 6, "local_terrain: roll out of range: %d" % roll)
	match parent:
		RUINS:
			if roll == 1:
				return WASTES
			if roll <= 4:
				return RUINS
			return SETTLEMENTS
		WASTES:
			if roll <= 4:
				return WASTES
			return RUINS
	# Pillars (or anything else) has no local table — caller must handle it.
	assert(false, "local_terrain: parent must be ruins or wastes, got %s" % parent)
	return WASTES


## Number of dice for one local map: roll 1d6 once.
##   1-3 = Barren (6), 4-5 = Sparse (12), 6 = Plentiful (32).
static func local_dice_count(rng: RandomNumberGenerator) -> int:
	var roll := rng.randi_range(1, 6)
	if roll <= 3:
		return 6
	if roll <= 5:
		return 12
	return 32


## Step 1 — stock a regional map: 8 dice, one die per hex (max 1), empties = Wastes.
static func generate_regional(map: HexMap, rng: RandomNumberGenerator) -> void:
	assert(map.scale == HexMap.Scale.REGIONAL, "generate_regional: not a regional map")
	_fill_wastes(map)
	for coord in _scatter(map.tiles.keys(), REGIONAL_DICE, rng):
		map.get_tile(coord).terrain = regional_terrain(rng.randi_range(1, 6))


## Step 2 — stock a local map for the given parent regional terrain.
## Pillars are filled solid and not stocked (impassable, not subdivided).
static func generate_local(map: HexMap, parent: StringName, rng: RandomNumberGenerator) -> void:
	assert(map.scale == HexMap.Scale.LOCAL, "generate_local: not a local map")
	if parent == PILLARS:
		for coord in map.tiles:
			map.get_tile(coord).terrain = PILLARS
		return
	assert(parent == RUINS or parent == WASTES,
		"generate_local: parent must be ruins/wastes/pillars, got %s" % parent)
	_fill_wastes(map)
	var dice := local_dice_count(rng)
	for coord in _scatter(map.tiles.keys(), dice, rng):
		map.get_tile(coord).terrain = local_terrain(rng.randi_range(1, 6), parent)


# --- helpers ---

static func _fill_wastes(map: HexMap) -> void:
	for coord in map.tiles:
		map.get_tile(coord).terrain = WASTES


## Pick `count` distinct coords at random (Fisher-Yates partial shuffle).
static func _scatter(coords: Array, count: int, rng: RandomNumberGenerator) -> Array:
	assert(count <= coords.size(),
		"_scatter: %d dice but only %d hexes" % [count, coords.size()])
	var pool := coords.duplicate()
	var picked: Array = []
	for i in range(count):
		var j := rng.randi_range(i, pool.size() - 1)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
		picked.append(pool[i])
	return picked
