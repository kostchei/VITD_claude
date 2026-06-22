## Verisimilitude tests for The Harrowing (rules p8): 5 memories, a hardship may
## cost one, and losing the 5th Harrows the Traveler (slain/NPC/wander).

func run() -> Array:
	var f: Array = []
	var A := Abilities.Ability
	var rng := TestKit.rng(9)
	var scores := {A.STR: 10, A.DEX: 10, A.CON: 10, A.INT: 10, A.WIS: 10, A.CHA: 10}
	var t := Traveler.create("Test", 1, scores, rng)

	t.set_memories(["books", "first kiss", "knowledge", "escape", "my name"])
	TestKit.eq(f, t.memories.size(), 5, "5 memories chosen")
	TestKit.ok(f, not t.is_harrowed(), "not harrowed with memories left")

	# chance_in_6 = 0 never costs a memory; = 6 always does.
	var r := t.resolve_hardship(Traveler.HarrowingHardship.GREAT_TRAGEDY, 0, rng)
	TestKit.ok(f, not r["lost"], "chance 0 never loses")
	TestKit.eq(f, t.memories.size(), 5, "still 5 memories")

	# Force losses with chance 6; the 5th loss Harrows.
	var harrowed_reported := false
	for i in range(5):
		var res := t.resolve_hardship(Traveler.HarrowingHardship.DROPPED_TO_ZERO, 6, rng)
		TestKit.ok(f, res["lost"], "chance 6 always loses (step %d)" % i)
		if res["harrowed"]:
			harrowed_reported = true
			TestKit.eq(f, i, 4, "harrowed reported exactly on the 5th loss")
	TestKit.ok(f, harrowed_reported, "harrowed reported")
	TestKit.ok(f, t.is_harrowed(), "harrowed once all memories gone")
	TestKit.eq(f, t.memories.size(), 0, "no memories remain")

	# Harrowed fate is one of the three outcomes.
	var fate := t.harrowed_fate(rng)
	TestKit.ok(f, fate in Traveler.HarrowedFate.values(), "fate is slain/NPC/wander")

	# The 0-Flesh and 7th-exhaustion hardships exist as triggers on the Traveler.
	var t2 := Traveler.create("T2", 1, scores, rng)
	t2.flesh = 0
	TestKit.ok(f, t2.is_down(), "0 Flesh is a hardship trigger")
	t2.exhaustion = 7
	TestKit.ok(f, t2.is_overexhausted(), "7th exhaustion is a hardship trigger")

	return f
