class_name HexMapView
extends Node2D
## Renders any HexMap (Regional or Local) with custom drawing.
## Handles hover + click/double-click picking. No art assets required.

signal tile_hovered(coord: Vector2i)
signal tile_clicked(coord: Vector2i)
signal tile_entered(coord: Vector2i)  # double-click = descend a scale

var map: HexMap = null
var hex_size: float = 48.0

# Line-art terrain markers (parchment book style). Loaded at runtime.
var _tex_ruin: Texture2D = null
var _tex_settlement: Texture2D = null

var _has_hover := false
var _hovered := Vector2i.ZERO
var _has_selected := false
var _selected := Vector2i.ZERO


func _ready() -> void:
	# No silent fallback: missing marker art is a build error.
	_tex_ruin = load("res://assets/markers/ruin.svg")
	_tex_settlement = load("res://assets/markers/settlement.svg")
	assert(_tex_ruin != null, "missing res://assets/markers/ruin.svg")
	assert(_tex_settlement != null, "missing res://assets/markers/settlement.svg")


func set_map(m: HexMap, size: float) -> void:
	map = m
	hex_size = size
	_has_hover = false
	_has_selected = false
	queue_redraw()


func set_selected(coord: Vector2i) -> void:
	_selected = coord
	_has_selected = true
	queue_redraw()


func _process(_dt: float) -> void:
	if map == null or not visible:
		return
	var local := to_local(get_global_mouse_position())
	var c := HexGrid.pixel_to_axial(local, hex_size, _flat())
	var now := map.has(c)
	if now != _has_hover or (now and c != _hovered):
		_has_hover = now
		_hovered = c
		queue_redraw()
		if now:
			tile_hovered.emit(c)


func _unhandled_input(event: InputEvent) -> void:
	if map == null or not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var c := HexGrid.pixel_to_axial(to_local(get_global_mouse_position()), hex_size, _flat())
		if not map.has(c):
			return
		if event.double_click:
			tile_entered.emit(c)
		else:
			set_selected(c)
			tile_clicked.emit(c)


func _flat() -> bool:
	return map != null and map.orientation == HexMap.Orientation.FLAT


func _draw() -> void:
	if map == null:
		return
	var flat := _flat()
	var font := ThemeDB.fallback_font
	for coord in map.tiles:
		var center: Vector2 = HexGrid.axial_to_pixel(coord, hex_size, flat)
		var pts := HexGrid.hex_corners(center, hex_size, flat)
		var col := _tile_color(coord)
		if _has_selected and coord == _selected:
			col = col.lightened(0.45)
		elif _has_hover and coord == _hovered:
			col = col.lightened(0.22)
		draw_colored_polygon(pts, col)

		var outline := PackedVector2Array(pts)
		outline.append(pts[0])
		draw_polyline(outline, Color(0.55, 0.66, 0.84), 2.0)  # light steel-blue grid
		if _has_selected and coord == _selected:
			draw_polyline(outline, Color(0.95, 0.74, 0.15), 3.0)

		_draw_marker(center, map.get_tile(coord).terrain)

		var label := "%d,%d" % [coord.x, coord.y]
		draw_string(font, center + Vector2(-hex_size * 0.5, hex_size * 0.62), label,
			HORIZONTAL_ALIGNMENT_CENTER, hex_size, 11, Color(0.35, 0.30, 0.22, 0.6))


## Draw the line-art terrain glyph (ruin / settlement) centred in the hex.
func _draw_marker(center: Vector2, terrain: StringName) -> void:
	var tex: Texture2D = null
	match terrain:
		VastGen.RUINS: tex = _tex_ruin
		VastGen.SETTLEMENTS: tex = _tex_settlement
		_: return  # wastes/pillars have no marker
	var w := hex_size * 1.15
	var size := Vector2(w, w)
	# Nudge up slightly so the flag/battlements sit above the coord label.
	draw_texture_rect(tex, Rect2(center - size * 0.5 - Vector2(0, hex_size * 0.08), size), false)


func _tile_color(coord: Vector2i) -> Color:
	var base := _terrain_color(map.get_tile(coord).terrain, coord)
	# Deterministic, non-negative variety so neighbouring tiles read apart.
	var n := absi(coord.x) * 7 + absi(coord.y) * 13
	return base.lightened((n % 7) / 7.0 * 0.10)


func _terrain_color(terrain: StringName, coord: Vector2i) -> Color:
	# Parchment palette to match the book: pale paper fills, glyphs carry meaning.
	match terrain:
		VastGen.WASTES: return Color(0.93, 0.91, 0.83)        # bare paper / dust
		VastGen.RUINS: return Color(0.89, 0.86, 0.77)         # faint warm parchment
		VastGen.SETTLEMENTS: return Color(0.91, 0.87, 0.72)   # warmer, inhabited
		VastGen.PILLARS: return Color(0.74, 0.75, 0.81)       # cool stone grey
	# No silent fallback: an un-stocked tile is a generation bug.
	assert(false, "_terrain_color: unknown terrain %s at %s" % [terrain, coord])
	return Color.MAGENTA
