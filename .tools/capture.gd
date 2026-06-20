extends Node
## Test harness (not part of the game): loads Main, drives it through every
## scale, and screenshots each so the UI/render can be verified. Safe to delete.

const SHOT_DIR := "res://.tools/shots"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await _settle()
	await _shoot("1_regional")

	main.call("_enter_local", Vector2i(0, 0))
	await _settle()
	await _shoot("2_local")

	# Enter a Ruins regional hex so the local map can show Settlements (flags).
	var ruins_coord = _find_terrain(main, &"ruins")
	if ruins_coord != null:
		main.call("_show_regional")
		main.call("_enter_local", ruins_coord)
		await _settle()
		await _shoot("2b_local_from_ruins")

	main.call("_enter_dungeon", Vector2i(0, 0))
	await _settle()
	await _shoot("3_dungeon_level1")

	main.call("_set_level", 3)
	await _settle()
	await _shoot("4_dungeon_level4")

	# Back up to regional with a selected hex showing.
	main.call("_show_regional")
	main.call("_on_hex_clicked", Vector2i(4, 4))
	await _settle()
	await _shoot("5_regional_selected")

	print("CAPTURE_DONE")
	get_tree().quit()


func _find_terrain(main: Node, terrain: StringName):
	var rmap = main.get("regional_map")
	for coord in rmap.tiles:
		if rmap.tiles[coord].terrain == terrain:
			return coord
	return null


func _settle() -> void:
	for _i in range(8):
		await get_tree().process_frame


func _shoot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [SHOT_DIR, shot_name]
	var err := img.save_png(path)
	print("SHOT %s err=%d size=%s" % [path, err, img.get_size()])
