## Verisimilitude tests for Abilities. Score/modifier math is DCC-style (project
## decision): 3d6, modifier = floor((score-10)/2), range -4..+4.

func run() -> Array:
	var f: Array = []

	# Full modifier table for floor((score-10)/2).
	var expected := {
		3: -4, 4: -3, 5: -3, 6: -2, 7: -2, 8: -1, 9: -1,
		10: 0, 11: 0, 12: 1, 13: 1, 14: 2, 15: 2, 16: 3, 17: 3, 18: 4,
	}
	for score in expected:
		TestKit.eq(f, Abilities.modifier(score), expected[score], "mod(%d)" % score)

	# Endpoints / symmetry called out by the decision (+/- 4).
	TestKit.eq(f, Abilities.modifier(3), -4, "min mod = -4 at 3")
	TestKit.eq(f, Abilities.modifier(18), 4, "max mod = +4 at 18")
	TestKit.eq(f, Abilities.modifier(10), 0, "mod 0 at 10")

	# 3d6 generation stays in 3..18; all extremes reachable.
	var rng := TestKit.rng(11)
	var lo := 99
	var hi := 0
	for i in range(5000):
		var s := Abilities.roll_score(rng)
		lo = mini(lo, s)
		hi = maxi(hi, s)
	TestKit.eq(f, lo, 3, "3d6 minimum is 3")
	TestKit.eq(f, hi, 18, "3d6 maximum is 18")

	# roll_set yields all six abilities, each a valid 3-18 score.
	var set := Abilities.roll_set(rng)
	TestKit.eq(f, set.size(), 6, "roll_set has 6 abilities")
	for a in Abilities.Ability.values():
		TestKit.ok(f, set.has(a), "roll_set has ability %d" % a)
		TestKit.between(f, set[a], 3, 18, "score for ability %d in 3..18" % a)

	# highest_modifier picks the best.
	var scores := {Abilities.Ability.STR: 8, Abilities.Ability.DEX: 16, Abilities.Ability.CON: 12,
		Abilities.Ability.INT: 10, Abilities.Ability.WIS: 7, Abilities.Ability.CHA: 9}
	TestKit.eq(f, Abilities.highest_modifier(scores), 3, "highest mod = +3 (DEX 16)")

	return f
