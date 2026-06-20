class_name HexTile
## One tile of a HexMap. Terrain/content is filled in later by procgen.

var coord: Vector2i
var terrain: StringName = &"unknown"


func _init(c: Vector2i) -> void:
	coord = c
