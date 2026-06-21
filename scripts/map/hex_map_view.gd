class_name HexMapView
extends Node2D
## Renders any HexMap (Regional or Local) with custom drawing.
## Handles hover + click/double-click picking. No art assets required.

signal tile_hovered(coord: Vector2i)
signal tile_clicked(coord: Vector2i)
signal tile_entered(coord: Vector2i)  # double-click = descend a scale

var map: HexMap = null
var hex_size: float = 48.0
var hazards: HazardSet = null  # roaming-hazards overlay (Local scale only)

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
	hazards = null  # cleared until the owner sets the matching overlay
	queue_redraw()


## Set (or clear, with null) the roaming-hazards overlay drawn on this map.
func set_hazards(hs: HazardSet) -> void:
	hazards = hs
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

	# Roaming-hazard dice draw on top of the terrain so they never hide the map.
	if hazards != null:
		for h in hazards.hazards:
			_draw_hazard(HexGrid.axial_to_pixel(h.hex, hex_size, flat), h.kind, font)


## Draw a hazard as a d6 die: a coloured rounded face showing the pips of the
## rolled value (kind + 1) plus the hazard's name beneath it.
func _draw_hazard(center: Vector2, kind: int, font: Font) -> void:
	var side := hex_size * 0.72
	var rect := Rect2(center - Vector2(side, side) * 0.5, Vector2(side, side))
	draw_rect(rect, Color(0.13, 0.12, 0.15, 0.92), true)            # die body
	draw_rect(rect, _hazard_color(kind), false, 3.0)               # coloured rim
	_draw_die_pips(center, side, kind + 1)
	var nm: String = HazardSet.KIND_NAMES[kind]
	var tw := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_string(font, center + Vector2(-tw * 0.5, side * 0.5 + 16), nm,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, _hazard_color(kind))


## Pip layout for a d6 face (1-6), drawn as small light dots inside the die.
func _draw_die_pips(center: Vector2, side: float, value: int) -> void:
	var u := side * 0.26  # pip offset from centre
	var rad := side * 0.085
	var col := Color(0.93, 0.93, 0.88)
	var L := center + Vector2(-u, 0)
	var R := center + Vector2(u, 0)
	var slots: Array[Vector2] = []
	match value:
		1: slots = [center]
		2: slots = [center + Vector2(-u, -u), center + Vector2(u, u)]
		3: slots = [center + Vector2(-u, -u), center, center + Vector2(u, u)]
		4: slots = [center + Vector2(-u, -u), center + Vector2(u, -u),
				center + Vector2(-u, u), center + Vector2(u, u)]
		5: slots = [center + Vector2(-u, -u), center + Vector2(u, -u), center,
				center + Vector2(-u, u), center + Vector2(u, u)]
		6: slots = [center + Vector2(-u, -u), L, center + Vector2(-u, u),
				center + Vector2(u, -u), R, center + Vector2(u, u)]
		_: assert(false, "_draw_die_pips: value %d out of range" % value)
	for p in slots:
		draw_circle(p, rad, col)


## Distinct accent per hazard kind (rim + label colour).
func _hazard_color(kind: int) -> Color:
	match kind:
		HazardSet.Kind.WARBAND: return Color(0.85, 0.24, 0.20)        # blood red
		HazardSet.Kind.MAELSTROM: return Color(0.40, 0.66, 0.86)      # storm blue
		HazardSet.Kind.CRAWLHERD: return Color(0.55, 0.74, 0.30)      # sickly green
		HazardSet.Kind.COLLAPSE: return Color(0.70, 0.55, 0.35)       # rubble brown
		HazardSet.Kind.VOID_LIGHTNING: return Color(0.66, 0.42, 0.90) # violet
		HazardSet.Kind.SINGING_SAND: return Color(0.90, 0.78, 0.38)   # sand gold
	assert(false, "_hazard_color: unknown kind %d" % kind)
	return Color.MAGENTA


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
