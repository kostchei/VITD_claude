## Verisimilitude tests for Settlement Factions (rules p19): four factions with
## their named boons and the dice helpers (1d3 craft, 1d6 Grit, 1d6->1 Flesh).

func run() -> Array:
	var f: Array = []
	var F := SettlementFactions.Faction

	TestKit.eq(f, SettlementFactions.FACTIONS.size(), 4, "four settlement factions")

	TestKit.eq(f, SettlementFactions.name_of(F.PARTISANS_OF_FLAME), "Partisans of Flame", "Partisans name")
	TestKit.eq(f, SettlementFactions.boon_of(F.PARTISANS_OF_FLAME), "Novice of the Fire", "Partisans boon")
	TestKit.eq(f, SettlementFactions.name_of(F.SEEKER_KEEPERS), "Seeker Keepers", "Seekers name")
	TestKit.eq(f, SettlementFactions.boon_of(F.SEEKER_KEEPERS), "Inscrutable Pockets", "Seekers boon")
	TestKit.eq(f, SettlementFactions.name_of(F.BLACK_HELMS), "Black Helms", "Black Helms name")
	TestKit.eq(f, SettlementFactions.boon_of(F.BLACK_HELMS), "There is Only Darkness", "Black Helms boon")
	TestKit.eq(f, SettlementFactions.name_of(F.GRAFTERS), "Grafters", "Grafters name")
	TestKit.eq(f, SettlementFactions.boon_of(F.GRAFTERS), "One Body", "Grafters boon")

	for id in SettlementFactions.FACTIONS:
		var d: Dictionary = SettlementFactions.faction(id)
		TestKit.ok(f, str(d["boon_desc"]) != "", "faction %d boon_desc" % id)
		TestKit.ok(f, str(d["learn"]) != "", "faction %d learn condition" % id)

	# Dice helpers: bounds + reachability.
	var rng := TestKit.rng(37)
	var jf_lo := 9; var jf_hi := 0
	var bh_lo := 9; var bh_hi := 0
	var gr_lo := 9; var gr_hi := 0
	for i in range(3000):
		var jf := SettlementFactions.jarred_fire_hours(rng)
		jf_lo = mini(jf_lo, jf); jf_hi = maxi(jf_hi, jf)
		var bh := SettlementFactions.black_helm_grit(rng)
		bh_lo = mini(bh_lo, bh); bh_hi = maxi(bh_hi, bh)
		var g := SettlementFactions.graft(rng)
		gr_lo = mini(gr_lo, g["grit_cost"]); gr_hi = maxi(gr_hi, g["grit_cost"])
	TestKit.eq(f, SettlementFactions.graft(rng)["flesh_healed"], 1, "graft heals 1 Flesh")
	TestKit.eq(f, jf_lo, 1, "Jarred Fire min 1h"); TestKit.eq(f, jf_hi, 3, "Jarred Fire max 3h (1d3)")
	TestKit.eq(f, bh_lo, 1, "Black Helm Grit min 1"); TestKit.eq(f, bh_hi, 6, "Black Helm Grit max 6 (1d6)")
	TestKit.eq(f, gr_lo, 1, "graft Grit min 1"); TestKit.eq(f, gr_hi, 6, "graft Grit max 6 (1d6)")

	return f
