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

# A regional hex is ~6 one-mile hexes across (linear), so it owns ~36 fine hexes.
const REGIONAL_SCALE := 6.0


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


# --- continuous 1-mile grid ---------------------------------------------------
# The Local scale is one continuous field of 1-mile (fine) hexes; the Regional
# map is a 6x zoom-out overlay. A fine hex belongs to whichever regional hex its
# centre rounds to (fine->coarse hex rounding) — a gapless partition. Both grids
# share the same (pointy) orientation, so the only difference is the 6x size.


## The regional (coarse) hex that owns this 1-mile (fine) hex.
static func coarse_of(fine: Vector2i) -> Vector2i:
	var p := HexGrid.axial_to_pixel(fine, 1.0, false)
	return HexGrid.pixel_to_axial(p, REGIONAL_SCALE, false)


## The fine hex nearest a regional hex's centre (the party's entry point).
static func region_center_fine(reg: Vector2i) -> Vector2i:
	var p := HexGrid.axial_to_pixel(reg, REGIONAL_SCALE, false)
	return HexGrid.pixel_to_axial(p, 1.0, false)


## Every fine hex belonging to regional hex `reg` (~36 of them).
static func region_fine_coords(reg: Vector2i) -> Array[Vector2i]:
	var center := region_center_fine(reg)
	var out: Array[Vector2i] = []
	var rad := int(REGIONAL_SCALE) + 1
	for dq in range(-rad, rad + 1):
		for dr in range(-rad, rad + 1):
			var fine := center + Vector2i(dq, dr)
			if coarse_of(fine) == reg:
				out.append(fine)
	return out


## Stock the fine hexes of regional hex `reg` into the continuous `field`, keyed
## by the regional hex's terrain (same table as generate_local). Pillars regions
## fill solid (impassable). A per-region seed makes the world stable across
## sessions without persisting every tile. No-op if `reg` is off the world.
static func generate_region(field: HexMap, regional_map: HexMap, reg: Vector2i, world_seed: int) -> void:
	assert(field.scale == HexMap.Scale.LOCAL, "generate_region: field must be a Local map")
	if not regional_map.has(reg):
		return  # off the edge of the regional map / world
	var coords := region_fine_coords(reg)
	var parent: StringName = regional_map.get_tile(reg).terrain
	var rng := RandomNumberGenerator.new()
	rng.seed = region_seed(world_seed, reg)
	if parent == PILLARS:
		for c in coords:
			_put(field, c, PILLARS)
		return
	for c in coords:
		_put(field, c, WASTES)
	var dice: int = min(local_dice_count(rng), coords.size())
	for c in _scatter(coords, dice, rng):
		field.get_tile(c).terrain = local_terrain(rng.randi_range(1, 6), parent)


## Deterministic per-region seed from the world seed and the regional coord.
static func region_seed(world_seed: int, reg: Vector2i) -> int:
	return world_seed ^ (reg.x * 73856093) ^ (reg.y * 19349663)


static func _put(field: HexMap, c: Vector2i, terrain: StringName) -> void:
	if not field.tiles.has(c):
		field.tiles[c] = HexTile.new(c)
	field.tiles[c].terrain = terrain


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
