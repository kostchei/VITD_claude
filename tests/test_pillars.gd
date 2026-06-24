## Verisimilitude tests for being at a Pillar (rules p14): mining/gathering yields
## and encounter modifiers, lodestone refine value, and the pillar encounter table.

func run() -> Array:
	var f: Array = []
	var E := Pillars.Encounter
	var M := Pillars.Mood
	var rng := TestKit.rng(17)

	TestKit.eq(f, Pillars.RAW_LODESTONE_SLOTS, 1, "Raw Lodestone = 1 slot")

	# Gathering: 1d2 lodestone + 1d6 encounter mod. Mining: 1d6 + 2d6.
	var g_lo := 99; var g_hi := 0; var gm_lo := 99; var gm_hi := 0
	var m_lo := 99; var m_hi := 0; var mm_lo := 99; var mm_hi := 0
	for i in range(4000):
		var g := Pillars.gather(rng)
		g_lo = mini(g_lo, g["lodestone"]); g_hi = maxi(g_hi, g["lodestone"])
		gm_lo = mini(gm_lo, g["encounter_mod"]); gm_hi = maxi(gm_hi, g["encounter_mod"])
		var m := Pillars.mine(rng)
		m_lo = mini(m_lo, m["lodestone"]); m_hi = maxi(m_hi, m["lodestone"])
		mm_lo = mini(mm_lo, m["encounter_mod"]); mm_hi = maxi(mm_hi, m["encounter_mod"])
	TestKit.eq(f, g_lo, 1, "gather lodestone min 1"); TestKit.eq(f, g_hi, 2, "gather lodestone max 2 (1d2)")
	TestKit.eq(f, gm_lo, 1, "gather mod min 1"); TestKit.eq(f, gm_hi, 6, "gather mod max 6 (1d6)")
	TestKit.eq(f, m_lo, 1, "mine lodestone min 1"); TestKit.eq(f, m_hi, 6, "mine lodestone max 6 (1d6)")
	TestKit.eq(f, mm_lo, 2, "mine mod min 2"); TestKit.eq(f, mm_hi, 12, "mine mod max 12 (2d6)")

	# Refine value: 1d10 x 10 -> {10..100}, multiples of 10, all reachable.
	var seen := {}
	var all_mult10 := true
	for i in range(3000):
		var v := Pillars.refine_value(rng)
		if v % 10 != 0:
			all_mult10 = false
		seen[v] = true
	TestKit.ok(f, all_mult10, "refine value always a multiple of 10")
	TestKit.eq(f, seen.size(), 10, "refine yields 10 distinct values")
	TestKit.ok(f, seen.has(10) and seen.has(100), "refine spans 10..100")

	# Encounter table by roll (1d6 + mining mod).
	TestKit.eq(f, Pillars.encounter(1), E.NOTHING, "1 Nothing")
	TestKit.eq(f, Pillars.encounter(2), E.NOTHING, "2 Nothing")
	var rows := {
		3: E.LOST_TRAVELERS, 4: E.LODESTONE_MINERS, 5: E.MERCHANTS, 6: E.CYCLOPS,
		7: E.BANDITS, 8: E.HARPIES, 9: E.CUTTHROATS, 10: E.MEDUSA,
		11: E.CYCLOPS_2D6, 12: E.OGRE, 13: E.HARPIES_2D6, 14: E.SHADE,
	}
	for roll in rows:
		TestKit.eq(f, Pillars.encounter(roll), rows[roll], "enc row %d" % roll)
	TestKit.eq(f, Pillars.encounter(15), E.GRIFFON, "15 Griffon")
	TestKit.eq(f, Pillars.encounter(20), E.GRIFFON, "past 15 still Griffon")

	# Moods: Miners/Bandits/Cutthroats only.
	TestKit.ok(f, Pillars.has_mood(E.LODESTONE_MINERS), "Miners have mood")
	TestKit.ok(f, Pillars.has_mood(E.BANDITS), "Bandits have mood")
	TestKit.ok(f, Pillars.has_mood(E.CUTTHROATS), "Cutthroats have mood")
	TestKit.ok(f, not Pillars.has_mood(E.OGRE), "Ogre has no mood")
	TestKit.eq(f, Pillars.mood(E.LODESTONE_MINERS, 1), M.TERRITORIAL, "Miner 1-2 Territorial")
	TestKit.eq(f, Pillars.mood(E.LODESTONE_MINERS, 3), M.CURIOUS, "Miner 3-4 Curious")
	TestKit.eq(f, Pillars.mood(E.LODESTONE_MINERS, 6), M.FRIENDLY, "Miner 5-6 Friendly")
	TestKit.eq(f, Pillars.mood(E.BANDITS, 6), M.CURIOUS, "Bandit 6 Curious")
	TestKit.eq(f, Pillars.mood(E.CUTTHROATS, 6), M.RECRUIT, "Cutthroat 6 Recruit")

	# Group sizes.
	TestKit.eq(f, Pillars.group_size(E.NOTHING, rng), 0, "Nothing 0")
	TestKit.eq(f, Pillars.group_size(E.OGRE, rng), 1, "Ogre 1")
	TestKit.eq(f, Pillars.group_size(E.SHADE, rng), 1, "Shade 1")
	TestKit.eq(f, Pillars.group_size(E.GRIFFON, rng), 1, "Griffon 1")
	TestKit.between(f, Pillars.group_size(E.CYCLOPS_2D6, rng), 2, 12, "Cyclops swarm 2d6")
	TestKit.between(f, Pillars.group_size(E.MERCHANTS, rng), 1, 3, "Merchants 1d3")

	return f
