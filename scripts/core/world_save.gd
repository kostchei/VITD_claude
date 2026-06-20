class_name WorldSave
## Persists the generated world (regional map + explored local maps) to a JSON
## file under user://. Maps are rebuilt generically from the saved tiles, so this
## does not depend on grid dimensions. No silent fallbacks: any I/O or format
## problem raises (assert) per project conventions.

const PATH := "user://vast_world.json"
const VERSION := 1


static func has_save() -> bool:
	return FileAccess.file_exists(PATH)


static func save_world(regional: HexMap, locals: Dictionary) -> void:
	var locals_out := {}
	for reg_coord in locals:
		locals_out[_key(reg_coord)] = _map_to_dict(locals[reg_coord])
	var data := {
		"version": VERSION,
		"regional": _map_to_dict(regional),
		"locals": locals_out,
	}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	assert(f != null, "WorldSave.save_world: cannot write %s (err %d)" % [PATH, FileAccess.get_open_error()])
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


## Returns { "regional": HexMap, "locals": Dictionary(Vector2i -> HexMap) }.
static func load_world() -> Dictionary:
	assert(has_save(), "WorldSave.load_world: no save at %s" % PATH)
	var f := FileAccess.open(PATH, FileAccess.READ)
	assert(f != null, "WorldSave.load_world: cannot read %s (err %d)" % [PATH, FileAccess.get_open_error()])
	var text := f.get_as_text()
	f.close()

	var data: Variant = JSON.parse_string(text)
	assert(data is Dictionary, "WorldSave.load_world: malformed JSON in %s" % PATH)
	assert(int(data.get("version", -1)) == VERSION,
		"WorldSave.load_world: version mismatch (file %s, expected %d)" % [str(data.get("version")), VERSION])

	var locals := {}
	for key in data["locals"]:
		locals[_parse_key(key)] = _dict_to_map(data["locals"][key])
	return {
		"regional": _dict_to_map(data["regional"]),
		"locals": locals,
	}


static func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(PATH)


# --- (de)serialisation ---

static func _map_to_dict(m: HexMap) -> Dictionary:
	var tiles := {}
	for coord in m.tiles:
		tiles[_key(coord)] = String(m.tiles[coord].terrain)
	return {
		"scale": int(m.scale),
		"orientation": int(m.orientation),
		"tiles": tiles,
	}


static func _dict_to_map(d: Dictionary) -> HexMap:
	var m := HexMap.new()
	m.scale = int(d["scale"])
	m.orientation = int(d["orientation"])
	var tiles: Dictionary = d["tiles"]
	for key in tiles:
		var coord := _parse_key(key)
		var t := HexTile.new(coord)
		t.terrain = StringName(tiles[key])
		m.tiles[coord] = t
	assert(not m.tiles.is_empty(), "WorldSave._dict_to_map: rebuilt an empty map")
	return m


static func _key(c: Vector2i) -> String:
	return "%d,%d" % [c.x, c.y]


static func _parse_key(s: String) -> Vector2i:
	var parts := s.split(",")
	assert(parts.size() == 2, "WorldSave: bad coord key '%s'" % s)
	return Vector2i(int(parts[0]), int(parts[1]))
