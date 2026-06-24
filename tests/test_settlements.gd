## Verisimilitude tests for Settlement generation (rules p16): the 1d6
## Population/Scarcity/Atmosphere tables and the population-driven counts.

func run() -> Array:
	var f: Array = []
	var P := Settlements.Population
	var S := Settlements.Scarcity
	var A := Settlements.Atmosphere
	var rng := TestKit.rng(23)

	# Population: 1-3 Barren, 4-5 Middling, 6 Overcrowded.
	for roll in [1, 2, 3]:
		TestKit.eq(f, Settlements.population(roll), P.BARREN, "pop %d Barren" % roll)
	for roll in [4, 5]:
		TestKit.eq(f, Settlements.population(roll), P.MIDDLING, "pop %d Middling" % roll)
	TestKit.eq(f, Settlements.population(6), P.OVERCROWDED, "pop 6 Overcrowded")

	# Scarcity table order (1 Desperate .. 6 Bountiful).
	TestKit.eq(f, Settlements.scarcity(1), S.DESPERATE, "scarcity 1 Desperate")
	TestKit.eq(f, Settlements.scarcity(2), S.LIMITED_INVENTORY, "scarcity 2 Limited")
	TestKit.eq(f, Settlements.scarcity(3), S.STEEP_PRICES, "scarcity 3 Steep")
	TestKit.eq(f, Settlements.scarcity(4), S.DIFFICULT_BARGAINS, "scarcity 4 Difficult")
	TestKit.eq(f, Settlements.scarcity(5), S.MIDDLING, "scarcity 5 Middling")
	TestKit.eq(f, Settlements.scarcity(6), S.BOUNTIFUL, "scarcity 6 Bountiful")

	# Atmosphere table order (1 Hidden .. 6 Primal).
	TestKit.eq(f, Settlements.atmosphere(1), A.HIDDEN, "atmo 1 Hidden")
	TestKit.eq(f, Settlements.atmosphere(6), A.PRIMAL, "atmo 6 Primal")

	# Counts by population: Barren 1d3 loc / 1 fac; Middling 1d6 / 1d3;
	# Overcrowded 2d6 / 1d6.
	var b_loc_lo := 99; var b_loc_hi := 0
	var o_loc_lo := 99; var o_loc_hi := 0
	var m_fac_lo := 99; var m_fac_hi := 0
	for i in range(3000):
		var bl := Settlements.location_count(P.BARREN, rng)
		b_loc_lo = mini(b_loc_lo, bl); b_loc_hi = maxi(b_loc_hi, bl)
		var ol := Settlements.location_count(P.OVERCROWDED, rng)
		o_loc_lo = mini(o_loc_lo, ol); o_loc_hi = maxi(o_loc_hi, ol)
		var mf := Settlements.faction_count(P.MIDDLING, rng)
		m_fac_lo = mini(m_fac_lo, mf); m_fac_hi = maxi(m_fac_hi, mf)
	TestKit.eq(f, b_loc_lo, 1, "Barren loc min 1"); TestKit.eq(f, b_loc_hi, 3, "Barren loc max 3 (1d3)")
	TestKit.eq(f, o_loc_lo, 2, "Overcrowded loc min 2"); TestKit.eq(f, o_loc_hi, 12, "Overcrowded loc max 12 (2d6)")
	TestKit.eq(f, m_fac_lo, 1, "Middling fac min 1"); TestKit.eq(f, m_fac_hi, 3, "Middling fac max 3 (1d3)")
	TestKit.eq(f, Settlements.faction_count(P.BARREN, rng), 1, "Barren always 1 faction")

	# generate() returns a coherent settlement.
	var s := Settlements.generate(rng)
	TestKit.ok(f, s["population"] in P.values(), "generate population valid")
	TestKit.ok(f, s["scarcity"] in S.values(), "generate scarcity valid")
	TestKit.ok(f, s["atmosphere"] in A.values(), "generate atmosphere valid")
	TestKit.ok(f, s["locations"] >= 1, "generate has >=1 location")
	TestKit.ok(f, s["factions"] >= 1, "generate has >=1 faction")

	return f
