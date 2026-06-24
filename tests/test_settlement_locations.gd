## Verisimilitude tests for the 1d12 Settlement Locations (rules p17).

func run() -> Array:
	var f: Array = []
	var L := SettlementLocations.Location

	TestKit.eq(f, SettlementLocations.LOCATIONS.size(), 12, "12 locations")

	# Table order anchors.
	TestKit.eq(f, SettlementLocations.location(1), L.STORYTELLER, "1 Storyteller")
	TestKit.eq(f, SettlementLocations.location(2), L.SCRAP_SMITHY, "2 Scrap Smithy")
	TestKit.eq(f, SettlementLocations.location(9), L.LODESTONE_CARVER, "9 Lodestone Carver")
	TestKit.eq(f, SettlementLocations.location(12), L.NOMAD_HOLD, "12 Nomad Hold")

	# Every location has a name, boon, and description.
	for id in SettlementLocations.LOCATIONS:
		var d: Dictionary = SettlementLocations.data(id)
		TestKit.ok(f, str(d["name"]) != "", "location %d named" % id)
		TestKit.ok(f, str(d["boon"]) != "", "location %d has a boon" % id)
		TestKit.ok(f, str(d["desc"]) != "", "location %d described" % id)

	# Only Reservoir and Paddock raise Scarcity (+1).
	TestKit.eq(f, SettlementLocations.scarcity_mod(L.RESERVOIR), 1, "Reservoir +1 scarcity")
	TestKit.eq(f, SettlementLocations.scarcity_mod(L.PADDOCK), 1, "Paddock +1 scarcity")
	TestKit.eq(f, SettlementLocations.scarcity_mod(L.BAZAAR), 0, "Bazaar no scarcity mod")
	var raisers := 0
	for id in SettlementLocations.LOCATIONS:
		if SettlementLocations.scarcity_mod(id) == 1:
			raisers += 1
	TestKit.eq(f, raisers, 2, "exactly two Scarcity-raising locations")

	# total_scarcity_mod sums them.
	TestKit.eq(f, SettlementLocations.total_scarcity_mod([L.RESERVOIR, L.PADDOCK, L.BAZAAR]), 2, "two raisers = +2")

	# Concrete numbers.
	TestKit.eq(f, SettlementLocations.LODESTONE_CARVER_COIN, 100, "Lodestone Carver 100 coin")
	TestKit.eq(f, SettlementLocations.STORYTELLER_REST_CHANCE_IN_6, 1, "Storyteller 1-in-6")

	# roll_locations returns `count` valid ids, all reachable across many rolls.
	var rng := TestKit.rng(29)
	var rolled: Array = SettlementLocations.roll_locations(8, rng)
	TestKit.eq(f, rolled.size(), 8, "rolled 8 locations")
	var seen := {}
	for i in range(4000):
		seen[SettlementLocations.location(rng.randi_range(1, 12))] = true
	TestKit.eq(f, seen.size(), 12, "all 12 locations reachable")

	return f
