class_name HexMap
## A single hex grid (one scale). Tiles are stored by axial coord.
## Used for both Regional (rectangular) and Local (hexagonal) maps.

enum Scale { REGIONAL, LOCAL }
enum Orientation { POINTY, FLAT }

# Local map: clean flat-top hexagon-of-hexes; 6 sub-hexes span it angle-to-angle.
const LOCAL_RADIUS := 3

var scale: Scale = Scale.REGIONAL
var orientation: int = Orientation.POINTY  # Orientation enum; typed int for cross-class checks
var tiles: Dictionary = {}  # Vector2i(q, r) -> HexTile


func has(coord: Vector2i) -> bool:
	return tiles.has(coord)


func get_tile(coord: Vector2i) -> HexTile:
	# No silent fallback: a missing tile is a bug, surface it.
	assert(tiles.has(coord), "HexMap.get_tile: no tile at %s" % coord)
	return tiles[coord]


## Rectangular block (odd-r offset internally, stored as axial).
## cols × rows hexes — e.g. the 10×8 Regional map.
static func make_rectangular(cols: int, rows: int) -> HexMap:
	assert(cols > 0 and rows > 0, "make_rectangular needs positive dimensions")
	var m := HexMap.new()
	m.scale = Scale.REGIONAL
	for row in range(rows):
		for col in range(cols):
			var q := col - (row - (row & 1)) / 2  # odd-r offset -> axial
			var coord := Vector2i(q, row)
			m.tiles[coord] = HexTile.new(coord)
	return m


## Local map: clean hexagon-of-hexes (no clipping). Point-up 1-mile sub-hexes
## forming a flat-side-up regional hex: 7 across the straight axes, 6 along the
## angle-to-angle diagonal. 1 hex = 1 mile.
static func make_local() -> HexMap:
	var m := HexMap.new()
	m.scale = Scale.LOCAL
	m.orientation = Orientation.POINTY
	for q in range(-LOCAL_RADIUS, LOCAL_RADIUS + 1):
		var r_lo: int = max(-LOCAL_RADIUS, -q - LOCAL_RADIUS)
		var r_hi: int = min(LOCAL_RADIUS, -q + LOCAL_RADIUS)
		for r in range(r_lo, r_hi + 1):
			var coord := Vector2i(q, r)
			m.tiles[coord] = HexTile.new(coord)
	assert(not m.tiles.is_empty(), "make_local_flat produced no tiles")
	return m


## Centroid of all tile centres, for framing the camera.
func pixel_center(hex_size: float) -> Vector2:
	assert(not tiles.is_empty(), "pixel_center on empty map")
	var flat := orientation == Orientation.FLAT
	var sum := Vector2.ZERO
	for coord in tiles:
		sum += HexGrid.axial_to_pixel(coord, hex_size, flat)
	return sum / tiles.size()
