## Verisimilitude tests for Pillar delving tables (rules p15): tunnel shape (1d6),
## events (1d6 + previous rolls), loot (1d6 + depth), and the delve timings.

func run() -> Array:
	var f: Array = []
	var T := PillarDelve.Tunnel
	var E := PillarDelve.Event
	var L := PillarDelve.Loot

	# Timings.
	TestKit.eq(f, PillarDelve.TUNNEL_TRAVEL_MINUTES, 10, "tunnel->tunnel 10 min")
	TestKit.eq(f, PillarDelve.TUNNEL_SEARCH_MINUTES, 30, "search 30 min")

	# Tunnel Shape & Size (1d6), in table order.
	var tunnels := {
		1: T.CONSTRICTING_SQUEEZE, 2: T.SHEER_DROP, 3: T.TIGHT_HALLS,
		4: T.WINDING_TUNNEL, 5: T.JAGGED_ASCENT, 6: T.CAVERNOUS,
	}
	for roll in tunnels:
		TestKit.eq(f, PillarDelve.tunnel(roll), tunnels[roll], "tunnel %d" % roll)

	# Pillar Events: 1-3 Chill Fog, then 4..14, 15+ Call of the Dark.
	for roll in [1, 2, 3]:
		TestKit.eq(f, PillarDelve.event(roll), E.CHILL_FOG, "event %d = Chill Fog" % roll)
	var events := {
		4: E.WIND_BLAST, 5: E.CYCLOPS, 6: E.DECAY, 7: E.MEDUSA, 8: E.HARPIES,
		9: E.COLLAPSE, 10: E.HALLUCINATION, 11: E.HARMONICS, 12: E.OGRE,
		13: E.EGO_SINK, 14: E.SHADE,
	}
	for roll in events:
		TestKit.eq(f, PillarDelve.event(roll), events[roll], "event row %d" % roll)
	TestKit.eq(f, PillarDelve.event(15), E.CALL_OF_THE_DARK, "15 = Call of the Dark")
	TestKit.eq(f, PillarDelve.event(40), E.CALL_OF_THE_DARK, "past 15 still Call of the Dark")

	# Pillar Loot: 1-3 Forgotten Corpse, 4-6 Raw 1d10, 7..13, 14+ Hoard.
	for roll in [1, 2, 3]:
		TestKit.eq(f, PillarDelve.loot(roll), L.FORGOTTEN_CORPSE, "loot %d = Forgotten Corpse" % roll)
	for roll in [4, 5, 6]:
		TestKit.eq(f, PillarDelve.loot(roll), L.RAW_LODESTONE_1D10, "loot %d = Raw 1d10" % roll)
	var loots := {
		7: L.LODESTONE_IDOLS, 8: L.ABANDONED_SUPPLIES, 9: L.RAW_LODESTONE_2D10,
		10: L.LONE_SURVIVOR, 11: L.LODESTONE_MURAL, 12: L.CORPSE_PILE, 13: L.ARTIFACT,
	}
	for roll in loots:
		TestKit.eq(f, PillarDelve.loot(roll), loots[roll], "loot row %d" % roll)
	TestKit.eq(f, PillarDelve.loot(14), L.HOARD, "14 = Hoard")
	TestKit.eq(f, PillarDelve.loot(99), L.HOARD, "deep loot still Hoard")

	# Roll helpers apply the modifiers and stay valid over many rolls.
	var rng := TestKit.rng(31)
	var all_valid := true
	for i in range(500):
		if not (PillarDelve.roll_tunnel(rng) in T.values()):
			all_valid = false
		if not (PillarDelve.roll_event(3, rng) in E.values()):
			all_valid = false
		if not (PillarDelve.roll_loot(2, rng) in L.values()):
			all_valid = false
	TestKit.ok(f, all_valid, "roll helpers always return valid table entries")

	# Depth pushes the loot roll up: depth 12 -> 1d6+12 = 13..18 -> Artifact/Hoard only.
	var deep_ok := true
	for i in range(400):
		var lt := PillarDelve.roll_loot(12, rng)
		if lt != L.ARTIFACT and lt != L.HOARD:
			deep_ok = false
	TestKit.ok(f, deep_ok, "depth 12 only yields Artifact or Hoard (roll >= 13)")

	return f
