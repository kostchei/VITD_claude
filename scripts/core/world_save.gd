class_name WorldSave
## Persists the generated world (regional map + explored local maps) to a JSON
## file under user://. Maps are rebuilt generically from the saved tiles, so this
## does not depend on grid dimensions. No silent fallbacks: any I/O or format
## problem raises (assert) per project conventions.

const PATH := "user://vast_world.json"
const VERSION := 2  # v2 adds the roaming-hazards overlay per local map


static func has_save() -> bool:
	return FileAccess.file_exists(PATH)


## `hazards` maps a regional coord -> HazardSet for each explored local map.
static func save_world(regional: HexMap, locals: Dictionary, hazards: Dictionary = {}) -> void:
	var locals_out := {}
	for reg_coord in locals:
		locals_out[_key(reg_coord)] = _map_to_dict(locals[reg_coord])
	var hazards_out := {}
	for reg_coord in hazards:
		hazards_out[_key(reg_coord)] = _hazards_to_dict(hazards[reg_coord])
	var data := {
		"version": VERSION,
		"regional": _map_to_dict(regional),
		"locals": locals_out,
		"hazards": hazards_out,
	}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	assert(f != null, "WorldSave.save_world: cannot write %s (err %d)" % [PATH, FileAccess.get_open_error()])
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


## Returns { "regional": HexMap, "locals": {Vector2i->HexMap},
##           "hazards": {Vector2i->HazardSet} }.
static func load_world() -> Dictionary:
	assert(has_save(), "WorldSave.load_world: no save at %s" % PATH)
	var f := FileAccess.open(PATH, FileAccess.READ)
	assert(f != null, "WorldSave.load_world: cannot read %s (err %d)" % [PATH, FileAccess.get_open_error()])
	var text := f.get_as_text()
	f.close()

	var data: Variant = JSON.parse_string(text)
	assert(data is Dictionary, "WorldSave.load_world: malformed JSON in %s" % PATH)
	var ver := int(data.get("version", -1))
	assert(ver >= 1 and ver <= VERSION,
		"WorldSave.load_world: unsupported version %s (expected 1..%d)" % [str(data.get("version")), VERSION])

	var locals := {}
	for key in data["locals"]:
		locals[_parse_key(key)] = _dict_to_map(data["locals"][key])
	# v1 saves have no hazards block; those local maps re-seed hazards on entry.
	var hazards := {}
	if data.has("hazards"):
		for key in data["hazards"]:
			hazards[_parse_key(key)] = _dict_to_hazards(data["hazards"][key])
	return {
		"regional": _dict_to_map(data["regional"]),
		"locals": locals,
		"hazards": hazards,
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


static func _hazards_to_dict(hs: HazardSet) -> Dictionary:
	var list := []
	for h in hs.hazards:
		list.append({"hex": _key(h.hex), "kind": int(h.kind)})
	return {"day": int(hs.day), "hazards": list}


static func _dict_to_hazards(d: Dictionary) -> HazardSet:
	var hs := HazardSet.new()
	hs.day = int(d["day"])
	for entry in d["hazards"]:
		var kind := int(entry["kind"])
		assert(kind >= 0 and kind < HazardSet.Kind.size(),
			"WorldSave._dict_to_hazards: bad kind %d" % kind)
		hs.hazards.append(HazardSet.Hazard.new(_parse_key(entry["hex"]), kind))
	return hs


static func _key(c: Vector2i) -> String:
	return "%d,%d" % [c.x, c.y]


static func _parse_key(s: String) -> Vector2i:
	var parts := s.split(",")
	assert(parts.size() == 2, "WorldSave: bad coord key '%s'" % s)
	return Vector2i(int(parts[0]), int(parts[1]))
