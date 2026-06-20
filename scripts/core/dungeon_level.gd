class_name DungeonLevel
## One level of a Dungeon: a square grid. Room layout is added by procgen later.

var width: int
var height: int
var cells: Dictionary = {}  # Vector2i -> cell data (populated by procgen)


func _init(w: int, h: int) -> void:
	assert(w > 0 and h > 0, "DungeonLevel needs positive dimensions")
	width = w
	height = h


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height
