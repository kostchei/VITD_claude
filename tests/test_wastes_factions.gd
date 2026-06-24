## Verisimilitude tests for Factions of the Wastes (rules p13): four factions,
## each with its named boon, plus the Dust Anglers' 1d6-ration hunt.

func run() -> Array:
	var f: Array = []
	var F := WastesFactions.Faction

	TestKit.eq(f, WastesFactions.FACTIONS.size(), 4, "four wasteland factions")

	# Each faction's name + boon, straight from the page.
	TestKit.eq(f, WastesFactions.name_of(F.LODESTONE_BROKERS), "Lodestone Brokers", "Brokers name")
	TestKit.eq(f, WastesFactions.boon_of(F.LODESTONE_BROKERS), "What's Fair is Fair", "Brokers boon")
	TestKit.eq(f, WastesFactions.name_of(F.CANDLEKEEPERS), "Candlekeepers", "Candlekeepers name")
	TestKit.eq(f, WastesFactions.boon_of(F.CANDLEKEEPERS), "A Burden Shared", "Candlekeepers boon")
	TestKit.eq(f, WastesFactions.name_of(F.DUST_ANGLERS), "Dust Anglers", "Dust Anglers name")
	TestKit.eq(f, WastesFactions.boon_of(F.DUST_ANGLERS), "Plenty From Nothing", "Dust Anglers boon")
	TestKit.eq(f, WastesFactions.name_of(F.PILLAR_WORMS), "Pillar Worms", "Pillar Worms name")
	TestKit.eq(f, WastesFactions.boon_of(F.PILLAR_WORMS), "Grit and Bear It", "Pillar Worms boon")

	# Every faction has a non-empty description and learn condition.
	for id in WastesFactions.FACTIONS:
		var data: Dictionary = WastesFactions.faction(id)
		TestKit.ok(f, str(data["boon_desc"]) != "", "faction %d has boon_desc" % id)
		TestKit.ok(f, str(data["learn"]) != "", "faction %d has learn condition" % id)

	# Dust Anglers' hunt yields 1d6 rations; bounds + every value reachable.
	var rng := TestKit.rng(21)
	var lo := 99
	var hi := 0
	var seen := {}
	for i in range(3000):
		var r := WastesFactions.dust_angler_hunt(rng)
		lo = mini(lo, r)
		hi = maxi(hi, r)
		seen[r] = true
	TestKit.eq(f, lo, 1, "hunt min 1")
	TestKit.eq(f, hi, 6, "hunt max 6")
	TestKit.eq(f, seen.size(), 6, "all 1..6 reachable")

	return f
