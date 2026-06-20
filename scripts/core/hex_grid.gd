class_name HexGrid
## Pure hex math for axial-coordinate grids — pointy-top (default) or flat-top.
## All functions are static; this class holds no state.
## Reference: Red Blob Games "Hexagonal Grids".

const SQRT3 := 1.7320508075688772

# Axial directions (q, r) for the 6 neighbours.
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]


## Centre pixel of an axial hex, given the corner radius `size`.
## `flat` selects flat-top layout; default is pointy-top.
static func axial_to_pixel(coord: Vector2i, size: float, flat: bool = false) -> Vector2:
	var q := float(coord.x)
	var r := float(coord.y)
	if flat:
		return Vector2(size * 1.5 * q, size * (SQRT3 * 0.5 * q + SQRT3 * r))
	var x := size * (SQRT3 * q + SQRT3 * 0.5 * r)
	var y := size * (1.5 * r)
	return Vector2(x, y)


## Nearest axial hex to a pixel position (already in the grid's local space).
static func pixel_to_axial(p: Vector2, size: float, flat: bool = false) -> Vector2i:
	if flat:
		var qf := (2.0 / 3.0 * p.x) / size
		var rf := (-1.0 / 3.0 * p.x + SQRT3 / 3.0 * p.y) / size
		return _axial_round(qf, rf)
	var q := (SQRT3 / 3.0 * p.x - 1.0 / 3.0 * p.y) / size
	var r := (2.0 / 3.0 * p.y) / size
	return _axial_round(q, r)


## The 6 corner points of a hex, for drawing. `flat` selects flat-top.
static func hex_corners(center: Vector2, size: float, flat: bool = false) -> PackedVector2Array:
	var start := 0.0 if flat else -30.0
	var pts := PackedVector2Array()
	for i in range(6):
		var angle := deg_to_rad(60.0 * i + start)
		pts.append(center + Vector2(cos(angle), sin(angle)) * size)
	return pts


## Hex distance between two axial coords.
static func distance(a: Vector2i, b: Vector2i) -> int:
	return int((abs(a.x - b.x) + abs(a.x + a.y - b.x - b.y) + abs(a.y - b.y)) / 2)


static func neighbors(coord: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in DIRECTIONS:
		out.append(coord + d)
	return out


# --- internal ---

static func _axial_round(qf: float, rf: float) -> Vector2i:
	# Round in cube space, then fix the largest-error component.
	var xf := qf
	var zf := rf
	var yf := -xf - zf
	var rx := roundf(xf)
	var ry := roundf(yf)
	var rz := roundf(zf)
	var dx := absf(rx - xf)
	var dy := absf(ry - yf)
	var dz := absf(rz - zf)
	if dx > dy and dx > dz:
		rx = -ry - rz
	elif dy > dz:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return Vector2i(int(rx), int(rz))
