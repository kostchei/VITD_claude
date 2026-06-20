class_name Dungeon
## A stack of dungeon levels (index 0 = entrance, higher = deeper).
## Up to 6 levels. Links between levels (stairs/shafts) come with procgen.

var levels: Array[DungeonLevel] = []


static func make_empty(level_count: int, width: int, height: int) -> Dungeon:
	assert(level_count > 0, "Dungeon needs at least one level")
	var d := Dungeon.new()
	for i in range(level_count):
		d.levels.append(DungeonLevel.new(width, height))
	return d


func level_count() -> int:
	return levels.size()
