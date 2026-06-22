class_name WorldSave
## Persists the world to a JSON file under user://. Stores the regional map plus
## a world seed; the continuous 1-mile Local field is regenerated deterministically
## from (world_seed, regional terrain), so per-tile local data need not be saved.
## No silent fallbacks: any I/O, format, or version problem raises (assert).

const PATH := "user://vast_world.json"
const VERSION := 3  # v3: continuous Local field is seed-derived (drops per-map locals/hazards)


static func has_save() -> bool:
	return FileAccess.file_exists(PATH)


## The version of the on-disk save, or -1 if there is none / it is unreadable.
## Lets the caller decide to roll a fresh world rather than load an old format.
static func save_version() -> int:
	if not has_save():
		return -1
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return -1
	var text := f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(text)
	if not (data is Dictionary):
		return -1
	return int(data.get("version", -1))


static func save_world(regional: HexMap, world_seed: int) -> void:
	var data := {
		"version": VERSION,
		"world_seed": world_seed,
		"regional": _map_to_dict(regional),
	}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	assert(f != null, "WorldSave.save_world: cannot write %s (err %d)" % [PATH, FileAccess.get_open_error()])
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


## Returns { "regional": HexMap, "world_seed": int }.
static func load_world() -> Dictionary:
	assert(has_save(), "WorldSave.load_world: no save at %s" % PATH)
	var f := FileAccess.open(PATH, FileAccess.READ)
	assert(f != null, "WorldSave.load_world: cannot read %s (err %d)" % [PATH, FileAccess.get_open_error()])
	var text := f.get_as_text()
	f.close()

	var data: Variant = JSON.parse_string(text)
	assert(data is Dictionary, "WorldSave.load_world: malformed JSON in %s" % PATH)
	var ver := int(data.get("version", -1))
	assert(ver == VERSION, "WorldSave.load_world: unsupported version %s (need %d)" % [str(data.get("version")), VERSION])
	assert(data.has("world_seed"), "WorldSave.load_world: missing world_seed")
	return {
		"regional": _dict_to_map(data["regional"]),
		"world_seed": int(data["world_seed"]),
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
