class_name DungeonView
extends Node2D
## Renders one DungeonLevel as a square grid. Rooms are drawn once procgen
## fills `level.cells`; for now it's an empty grid with hover highlighting.

signal cell_hovered(cell: Vector2i)

var level: DungeonLevel = null
var cell_size: float = 44.0

var _has_hover := false
var _hovered := Vector2i.ZERO


func set_level(l: DungeonLevel, size: float) -> void:
	level = l
	cell_size = size
	_has_hover = false
	queue_redraw()


func _process(_dt: float) -> void:
	if level == null or not visible:
		return
	var local := to_local(get_global_mouse_position())
	var c := Vector2i(floori(local.x / cell_size), floori(local.y / cell_size))
	var inside := level.in_bounds(c)
	if inside != _has_hover or (inside and c != _hovered):
		_has_hover = inside
		_hovered = c
		queue_redraw()
		if inside:
			cell_hovered.emit(c)


func _draw() -> void:
	if level == null:
		return
	for y in range(level.height):
		for x in range(level.width):
			var rect := Rect2(x * cell_size, y * cell_size, cell_size, cell_size)
			var col := Color(0.20, 0.20, 0.25) if (x + y) % 2 == 0 else Color(0.16, 0.16, 0.21)
			if _has_hover and Vector2i(x, y) == _hovered:
				col = col.lightened(0.30)
			draw_rect(rect, col, true)
			draw_rect(rect, Color(0, 0, 0, 0.35), false, 1.0)
