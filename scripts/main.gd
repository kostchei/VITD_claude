extends Node2D
## Top-level controller: owns world state, the three scale views, the camera,
## and the UI. Drives transitions Regional -> Local -> Dungeon and back.

# --- design dimensions ---
const REGIONAL_COLS := 10
const REGIONAL_ROWS := 8
const LOCAL_ACROSS := 6        # sub-hexes spanning the local hex angle-to-angle; 1 hex = 1 mile
const DUNGEON_LEVELS := 6
const DUNGEON_W := 16
const DUNGEON_H := 12
const HEX_SIZE := 48.0
const DUNGEON_CELL := 44.0

enum Scale { REGIONAL, LOCAL, DUNGEON }

# --- world state ---
var rng := RandomNumberGenerator.new()
var current_scale: Scale = Scale.REGIONAL
var regional_map: HexMap
var local_maps := {}     # Vector2i -> HexMap
var local_hazards := {}  # Vector2i -> HazardSet (roaming overlay per local map)
var dungeons := {}       # String -> Dungeon
var current_hazards: HazardSet = null  # hazards of the local map on screen

var has_regional := false
var selected_regional := Vector2i.ZERO
var has_local := false
var selected_local := Vector2i.ZERO
var current_dungeon: Dungeon
var current_level := 0

# --- travel (Local scale): 1 hex = 1 mile; a day's 18 miles triggers a roll ---
var party_local := Vector2i.ZERO
var miles_today := 0
var last_day_text := ""

# --- nodes ---
var world: Node2D
var camera: WorldCamera
var hex_view: HexMapView
var dungeon_view: DungeonView

# --- ui ---
var breadcrumb: Label
var info: Label
var hint: Label
var journal: Label
var back_btn: Button
var new_btn: Button
var next_day_btn: Button
var new_dialog: ConfirmationDialog
var scale_btns := {}   # Scale -> Button
var level_panel: VBoxContainer
var level_btns: Array[Button] = []


func _ready() -> void:
	rng.randomize()
	if WorldSave.has_save():
		_load_world()
	else:
		_new_world()

	world = Node2D.new()
	add_child(world)

	hex_view = HexMapView.new()
	hex_view.tile_hovered.connect(_on_hex_hovered)
	hex_view.tile_clicked.connect(_on_hex_clicked)
	hex_view.tile_entered.connect(_on_hex_entered)
	world.add_child(hex_view)

	dungeon_view = DungeonView.new()
	dungeon_view.cell_hovered.connect(_on_cell_hovered)
	world.add_child(dungeon_view)

	camera = WorldCamera.new()
	add_child(camera)

	_build_ui()
	_show_regional()


# --- world creation / persistence ---

## Generate a fresh regional map (rolling dice), reset state, and save.
func _new_world() -> void:
	regional_map = HexMap.make_rectangular(REGIONAL_COLS, REGIONAL_ROWS)
	VastGen.generate_regional(regional_map, rng)
	local_maps.clear()
	local_hazards.clear()
	dungeons.clear()
	has_regional = false
	has_local = false
	WorldSave.save_world(regional_map, local_maps, local_hazards)


func _load_world() -> void:
	var w := WorldSave.load_world()
	regional_map = w["regional"]
	local_maps = w["locals"]
	local_hazards = w["hazards"]
	dungeons.clear()  # dungeons are placeholder; regenerated lazily


func _on_new_map_pressed() -> void:
	new_dialog.popup_centered()


func _on_new_map_confirmed() -> void:
	_new_world()
	_show_regional()


# --- scale transitions ---

func _show_regional() -> void:
	current_scale = Scale.REGIONAL
	current_hazards = null
	dungeon_view.visible = false
	hex_view.visible = true
	hex_view.set_map(regional_map, HEX_SIZE)
	hex_view.clear_party()  # the party token lives on the Local map only
	if has_regional:
		hex_view.set_selected(selected_regional)
	camera.position = regional_map.pixel_center(HEX_SIZE)
	camera.set_zoom_level(0.8)
	_refresh_ui()


func _enter_local(reg: Vector2i) -> void:
	selected_regional = reg
	has_regional = true
	var m: HexMap = _get_local_map(reg)
	current_hazards = _get_local_hazards(reg, m)
	current_scale = Scale.LOCAL
	dungeon_view.visible = false
	hex_view.visible = true
	hex_view.set_map(m, HEX_SIZE)
	hex_view.set_hazards(current_hazards)
	if has_local:
		hex_view.set_selected(selected_local)
	# Party starts at the centre of the local hex; the day's mile count resets.
	party_local = Vector2i.ZERO
	miles_today = 0
	last_day_text = ""
	hex_view.set_party(party_local)
	camera.position = m.pixel_center(HEX_SIZE)
	camera.set_zoom_level(1.0)
	_refresh_ui()


func _enter_dungeon(loc: Vector2i) -> void:
	selected_local = loc
	has_local = true
	current_dungeon = _get_dungeon(selected_regional, loc)
	current_level = 0
	current_hazards = null
	current_scale = Scale.DUNGEON
	hex_view.visible = false
	hex_view.clear_party()
	dungeon_view.visible = true
	dungeon_view.set_level(current_dungeon.levels[current_level], DUNGEON_CELL)
	camera.position = Vector2(DUNGEON_W * DUNGEON_CELL * 0.5, DUNGEON_H * DUNGEON_CELL * 0.5)
	camera.set_zoom_level(0.9)
	_refresh_ui()


func _go_back() -> void:
	match current_scale:
		Scale.LOCAL:
			_show_regional()
		Scale.DUNGEON:
			_enter_local(selected_regional)


func _set_level(i: int) -> void:
	current_level = clampi(i, 0, current_dungeon.level_count() - 1)
	dungeon_view.set_level(current_dungeon.levels[current_level], DUNGEON_CELL)
	_refresh_ui()


# --- caches (lazy generation; procgen plugs in here later) ---

func _get_local_map(reg: Vector2i) -> HexMap:
	if not local_maps.has(reg):
		var m := HexMap.make_local()
		# Local terrain is keyed by the parent regional hex's type.
		var parent: StringName = regional_map.get_tile(reg).terrain
		VastGen.generate_local(m, parent, rng)
		local_maps[reg] = m
		WorldSave.save_world(regional_map, local_maps, local_hazards)  # persist newly explored map
	return local_maps[reg]


## Roaming hazards for a local map: seeded once on first visit, then persisted
## (so re-entering shows the same dice on the same day).
func _get_local_hazards(reg: Vector2i, m: HexMap) -> HazardSet:
	if not local_hazards.has(reg):
		local_hazards[reg] = HazardSet.generate(m, rng)
		WorldSave.save_world(regional_map, local_maps, local_hazards)
	return local_hazards[reg]


## One day in the wastes — the single daily beat. Triggered by completing 18
## miles of travel OR by resting in place (the Rest button). It rolls weather +
## an encounter, then drifts every roaming hazard one hex (re-dropping on
## collision/edge). Ration upkeep and rest also belong here: Wastes.spend_day
## already models them, it just needs a real party instead of today's empty one
## (wired up once we have stats & inventory).
func _pass_day(rested: bool = false) -> void:
	if current_scale != Scale.LOCAL:
		return
	_roll_day_tables(rested)
	if current_hazards != null:
		current_hazards.advance_day(local_maps[selected_regional], rng)
		hex_view.set_hazards(current_hazards)
	miles_today = 0  # a closed day (marched or rested) starts a fresh 18-mile stint
	WorldSave.save_world(regional_map, local_maps, local_hazards)
	_refresh_ui()


func _get_dungeon(reg: Vector2i, loc: Vector2i) -> Dungeon:
	var key := "%d,%d|%d,%d" % [reg.x, reg.y, loc.x, loc.y]
	if not dungeons.has(key):
		dungeons[key] = Dungeon.make_empty(DUNGEON_LEVELS, DUNGEON_W, DUNGEON_H)
	return dungeons[key]


# --- input from views ---

func _on_hex_hovered(c: Vector2i) -> void:
	info.text = "%s  hex %d, %d" % [_scale_label(current_scale), c.x, c.y]
	if current_scale == Scale.LOCAL and current_hazards != null and current_hazards.has_hazard_at(c):
		info.text += "   ⚠ %s" % current_hazards.name_of(current_hazards.at(c).kind)


func _on_hex_clicked(c: Vector2i) -> void:
	if current_scale == Scale.REGIONAL:
		selected_regional = c
		has_regional = true
	elif current_scale == Scale.LOCAL:
		# Clicking an adjacent hex steps the party there (1 mile); other clicks
		# just select. Double-click still descends a scale (tile_entered).
		if HexGrid.distance(party_local, c) == 1:
			_travel_step(c)
			return
		selected_local = c
		has_local = true
	hex_view.set_selected(c)  # keep the view's highlight in sync with state
	_refresh_ui()


# --- travel ---

## Move the party one hex (= 1 mile). Each completed 18 miles is a day, which
## rolls weather + an encounter on the current hex's terrain table.
func _travel_step(dest: Vector2i) -> void:
	party_local = dest
	hex_view.set_party(party_local)
	miles_today += 1
	if miles_today >= Wastes.BASE_MILES_PER_DAY:
		_pass_day(false)  # a full day's march closes the day and starts a new stint
	_refresh_ui()


## Roll the day's tables for the hex the party stands on, building the journal
## line. `rested` distinguishes a day spent resting in place from a full march.
## Only the Wastes table exists today; other terrains report "no table yet"
## (parked). The caller (_pass_day) owns hazard drift, the stint reset, and save.
func _roll_day_tables(rested: bool) -> void:
	var how := "Rested" if rested else "Marched %d mi" % Wastes.BASE_MILES_PER_DAY
	var terrain: StringName = local_maps[selected_regional].get_tile(party_local).terrain
	if terrain != VastGen.WASTES:
		last_day_text = "%s · a day passes on %s — no encounter table for that terrain yet." % [how, terrain]
	else:
		# Empty party for now: weather + encounter roll without ration/exhaustion.
		var report := Wastes.spend_day([], terrain, 0, rng)
		var weather: String = Wastes.WEATHER_NAMES[report.weather]
		if report.encounter == Wastes.Encounter.NOTHING:
			last_day_text = "%s · Weather: %s · Nothing (roll %d)" % [how, weather, report.encounter_roll]
		else:
			var enc: String = Wastes.ENCOUNTER_NAMES[report.encounter]
			var mood: String = Wastes.MOOD_NAMES[report.mood]
			var mood_str := "  [%s]" % mood if mood != "" else ""
			last_day_text = "%s · Weather: %s · %d %s%s (roll %d)" % [how, weather, report.group_size, enc, mood_str, report.encounter_roll]
		if report.landmarks_obscured:
			last_day_text += "  · landmarks obscured"
	# Rations & rest are checked here too — flagged until stats/inventory exist.
	last_day_text += "   · upkeep: rations/rest TBD"


func _on_hex_entered(c: Vector2i) -> void:
	if current_scale == Scale.REGIONAL:
		_enter_local(c)
	elif current_scale == Scale.LOCAL:
		_enter_dungeon(c)


func _on_cell_hovered(c: Vector2i) -> void:
	info.text = "Dungeon L%d  cell %d, %d" % [current_level + 1, c.x, c.y]


# --- keyboard ---

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_BACKSPACE:
			_go_back()
		elif current_scale == Scale.DUNGEON:
			if event.keycode == KEY_E or event.keycode == KEY_PAGEDOWN:
				_set_level(current_level + 1)  # deeper
			elif event.keycode == KEY_Q or event.keycode == KEY_PAGEUP:
				_set_level(current_level - 1)  # up


# --- UI construction ---

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	# Row 1: navigation controls (Back + scale switcher) on their own line.
	var controls := HBoxContainer.new()
	controls.position = Vector2(16, 12)
	controls.add_theme_constant_override("separation", 6)
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(controls)

	back_btn = Button.new()
	back_btn.text = "◂ Back"
	back_btn.pressed.connect(_go_back)
	controls.add_child(back_btn)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(16, 0)
	controls.add_child(spacer)

	for s in [Scale.REGIONAL, Scale.LOCAL, Scale.DUNGEON]:
		var b := Button.new()
		b.text = _scale_label(s)
		b.toggle_mode = true
		b.pressed.connect(_on_scale_button.bind(s))
		controls.add_child(b)
		scale_btns[s] = b

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(16, 0)
	controls.add_child(spacer2)

	new_btn = Button.new()
	new_btn.text = "⟳ New Map"
	new_btn.pressed.connect(_on_new_map_pressed)
	controls.add_child(new_btn)

	# Rest: pass a day in place (Local scale only) — same daily beat as travel:
	# rolls weather + encounter and drifts the roaming hazards one hex.
	next_day_btn = Button.new()
	next_day_btn.text = "Rest a day ▸"
	next_day_btn.pressed.connect(_pass_day.bind(true))
	controls.add_child(next_day_btn)

	new_dialog = ConfirmationDialog.new()
	new_dialog.title = "New Regional Map"
	new_dialog.dialog_text = "Roll a new regional map?\nThe current world and all explored local maps will be replaced."
	new_dialog.ok_button_text = "Generate"
	new_dialog.confirmed.connect(_on_new_map_confirmed)
	layer.add_child(new_dialog)

	# Rows 2-4: breadcrumb / hovered-tile info / hint, stacked below the controls.
	breadcrumb = _make_label(layer, Vector2(16, 52), 20)
	info = _make_label(layer, Vector2(16, 86), 14)
	hint = _make_label(layer, Vector2(16, 108), 14)
	journal = _make_label(layer, Vector2(16, 130), 14)
	journal.add_theme_color_override("font_color", Color(0.95, 0.74, 0.15))

	level_panel = VBoxContainer.new()
	level_panel.position = Vector2(1140, 100)
	level_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(level_panel)
	var title := Label.new()
	title.text = "Levels (Q/E)"
	level_panel.add_child(title)
	for i in range(DUNGEON_LEVELS):
		var lb := Button.new()
		lb.text = "L%d%s" % [i + 1, "  entrance" if i == 0 else ""]
		lb.toggle_mode = true
		lb.pressed.connect(_set_level.bind(i))
		level_panel.add_child(lb)
		level_btns.append(lb)


func _make_label(layer: CanvasLayer, pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	layer.add_child(l)
	return l


func _on_scale_button(s: Scale) -> void:
	match s:
		Scale.REGIONAL:
			_show_regional()
		Scale.LOCAL:
			if has_regional:
				_enter_local(selected_regional)
			else:
				_refresh_ui()  # nothing selected yet; revert toggle
		Scale.DUNGEON:
			if has_regional and has_local:
				_enter_dungeon(selected_local)
			else:
				_refresh_ui()


func _refresh_ui() -> void:
	breadcrumb.text = _breadcrumb_text()
	hint.text = _hint_text()
	journal.text = last_day_text if current_scale == Scale.LOCAL else ""
	back_btn.disabled = current_scale == Scale.REGIONAL
	next_day_btn.visible = current_scale == Scale.LOCAL

	scale_btns[Scale.REGIONAL].button_pressed = current_scale == Scale.REGIONAL
	scale_btns[Scale.LOCAL].button_pressed = current_scale == Scale.LOCAL
	scale_btns[Scale.DUNGEON].button_pressed = current_scale == Scale.DUNGEON
	scale_btns[Scale.LOCAL].disabled = not has_regional
	scale_btns[Scale.DUNGEON].disabled = not (has_regional and has_local)

	level_panel.visible = current_scale == Scale.DUNGEON
	if current_scale == Scale.DUNGEON:
		for i in range(level_btns.size()):
			level_btns[i].button_pressed = (i == current_level)


# --- text helpers ---

func _scale_label(s: Scale) -> String:
	match s:
		Scale.REGIONAL: return "Regional"
		Scale.LOCAL: return "Local"
		Scale.DUNGEON: return "Dungeon"
	return "?"


func _breadcrumb_text() -> String:
	var s := "Region %d×%d" % [REGIONAL_COLS, REGIONAL_ROWS]
	if current_scale == Scale.REGIONAL:
		if has_regional:
			s += "   ›   hex %d,%d (selected)" % [selected_regional.x, selected_regional.y]
		return s
	s += "   ›   Local %d,%d (%d mi across)" % [selected_regional.x, selected_regional.y, LOCAL_ACROSS]
	if current_scale == Scale.LOCAL:
		if current_hazards != null:
			s += "   ›   Day %d · %d hazards" % [current_hazards.day, current_hazards.hazards.size()]
		s += "   ›   %d/%d mi today" % [miles_today, Wastes.BASE_MILES_PER_DAY]
		return s
	s += "   ›   Dungeon %d,%d   ›   Level %d/%d" % [selected_local.x, selected_local.y, current_level + 1, DUNGEON_LEVELS]
	return s


func _hint_text() -> String:
	match current_scale:
		Scale.REGIONAL:
			return "Double-click a hex to enter Local.   Right-drag = pan, wheel = zoom, WASD = move."
		Scale.LOCAL:
			return "Click an adjacent hex to travel (1 mile). A full day — 18 miles marched, or Rest in place — rolls weather + an encounter, drifts the hazards, and starts a fresh 18-mile stint.   Double-click to descend.   Backspace = up."
		Scale.DUNGEON:
			return "Q/E (or PageUp/Down) change level.   Backspace = surface.   Rooms come with procgen."
	return ""
