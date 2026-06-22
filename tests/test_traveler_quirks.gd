## Verisimilitude tests for Traveler Quirks (rules p6): a 1d20 table where only
## Ruin Plucker repeats, and selection respects uniqueness.

func run() -> Array:
	var f: Array = []

	# Exactly 20 quirks, ids 1..20 unique, names non-empty.
	TestKit.eq(f, TravelerQuirks.QUIRKS.size(), 20, "20 quirks")
	var seen := {}
	for q in TravelerQuirks.QUIRKS:
		TestKit.ok(f, q["id"] >= 1 and q["id"] <= 20, "id in 1..20")
		TestKit.ok(f, not seen.has(q["id"]), "id %s unique" % q["id"])
		seen[q["id"]] = true
		TestKit.ok(f, str(q["name"]) != "", "quirk %s has a name" % q["id"])

	# Only #1 Ruin Plucker is repeatable.
	TestKit.eq(f, TravelerQuirks.quirk(1)["name"], "Ruin Plucker", "id1 = Ruin Plucker")
	TestKit.ok(f, TravelerQuirks.quirk(1)["repeatable"], "Ruin Plucker repeatable")
	var repeatable_count := 0
	for q in TravelerQuirks.QUIRKS:
		if q["repeatable"]:
			repeatable_count += 1
	TestKit.eq(f, repeatable_count, 1, "exactly one repeatable quirk")

	# can_take: repeatable always; non-repeatable only if unheld.
	TestKit.ok(f, TravelerQuirks.can_take(1, [1, 1]), "can re-take Ruin Plucker")
	TestKit.ok(f, not TravelerQuirks.can_take(2, [2]), "cannot re-take a unique quirk")
	TestKit.ok(f, TravelerQuirks.can_take(2, [3, 4]), "can take an unheld quirk")

	# roll(): every id 1..20 is reachable.
	var rng := TestKit.rng(7)
	var hits := {}
	for i in range(4000):
		hits[TravelerQuirks.roll(rng)] = true
	TestKit.eq(f, hits.size(), 20, "all 20 quirks reachable by roll")

	# roll_takeable never returns an already-held unique quirk.
	var held := [2, 3, 4, 5, 6]
	var bad := false
	for i in range(500):
		var id := TravelerQuirks.roll_takeable(held, rng)
		if held.has(id) and not TravelerQuirks.quirk(id)["repeatable"]:
			bad = true
	TestKit.ok(f, not bad, "roll_takeable avoids held unique quirks")

	return f
