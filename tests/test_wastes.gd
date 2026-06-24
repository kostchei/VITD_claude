## Verisimilitude tests for the Wastes day-cycle (rules p10), back-filling the
## tables that predate the harness: 2d6 weather, 1d12+1d6 encounters + mood,
## 1d20 curiosities, and the 18mi/forced-march/ration movement rules.

func run() -> Array:
	var f: Array = []
	var W := Wastes.Weather
	var E := Wastes.Encounter
	var M := Wastes.Mood

	# Movement constants.
	TestKit.eq(f, Wastes.BASE_MILES_PER_DAY, 18, "18 mi/day base")
	TestKit.eq(f, Wastes.FORCED_MARCH_MILES, 6, "+6 mi per forced march")

	# 2d6 Weather table: 2-6 Calm, then 7..12.
	for roll in range(2, 7):
		TestKit.eq(f, Wastes.weather(roll), W.CALM, "weather %d = Calm" % roll)
	TestKit.eq(f, Wastes.weather(7), W.DUST_STORM, "7 Dust Storm")
	TestKit.eq(f, Wastes.weather(8), W.WIND_BLAST, "8 Wind Blast")
	TestKit.eq(f, Wastes.weather(9), W.STONE_HAIL, "9 Stone Hail")
	TestKit.eq(f, Wastes.weather(10), W.PILLAR_FOG, "10 Pillar Fog")
	TestKit.eq(f, Wastes.weather(11), W.GRIT_SLIDE, "11 Grit Slide")
	TestKit.eq(f, Wastes.weather(12), W.DUNE_WAVE, "12 Dune Wave")

	# Encounter table read on 1d12+1d6 (+mods): 2-5 Nothing (roll 1 is unreachable
	# by the dice) .. 18+ Griffon.
	for roll in range(2, 6):
		TestKit.eq(f, Wastes.encounter(roll), E.NOTHING, "enc %d = Nothing" % roll)
	var enc_rows := {
		6: E.LOST_TRAVELERS, 7: E.NOMADS, 8: E.MERCHANTS, 9: E.BANDITS,
		10: E.PILGRIMS, 11: E.LODESTONE_PROSPECTORS, 12: E.CARAVAN,
		13: E.CUTTHROATS, 14: E.CYCLOPS, 15: E.HARPIES, 16: E.MEDUSA,
		17: E.SHADE, 18: E.GRIFFON,
	}
	for roll in enc_rows:
		TestKit.eq(f, Wastes.encounter(roll), enc_rows[roll], "enc row %d" % roll)
	TestKit.eq(f, Wastes.encounter(24), E.GRIFFON, "past 18 still Griffon (Pillar Fog +6)")

	# Mood: only Nomads/Bandits/Cutthroats roll one (the same d6).
	TestKit.ok(f, Wastes.has_mood(E.NOMADS), "Nomads have mood")
	TestKit.ok(f, Wastes.has_mood(E.BANDITS), "Bandits have mood")
	TestKit.ok(f, Wastes.has_mood(E.CUTTHROATS), "Cutthroats have mood")
	TestKit.ok(f, not Wastes.has_mood(E.SHADE), "Shade has no mood")
	TestKit.ok(f, not Wastes.has_mood(E.MERCHANTS), "Merchants have no mood")

	TestKit.eq(f, Wastes.mood(E.NOMADS, 1), M.CAUTIOUS, "Nomad 1 Cautious")
	TestKit.eq(f, Wastes.mood(E.NOMADS, 3), M.CURIOUS, "Nomad 2-4 Curious")
	TestKit.eq(f, Wastes.mood(E.NOMADS, 6), M.FRIENDLY, "Nomad 5-6 Friendly")
	TestKit.eq(f, Wastes.mood(E.BANDITS, 2), M.CRAZED, "Bandit 1-2 Crazed")
	TestKit.eq(f, Wastes.mood(E.BANDITS, 5), M.TRIBUTE, "Bandit 3-5 Tribute")
	TestKit.eq(f, Wastes.mood(E.BANDITS, 6), M.CURIOUS, "Bandit 6 Curious")
	TestKit.eq(f, Wastes.mood(E.CUTTHROATS, 3), M.CRAZED, "Cutthroat 1-3 Crazed")
	TestKit.eq(f, Wastes.mood(E.CUTTHROATS, 5), M.TRIBUTE, "Cutthroat 4-5 Tribute")
	TestKit.eq(f, Wastes.mood(E.CUTTHROATS, 6), M.RECRUIT, "Cutthroat 6 Recruit")

	# 1d20 Curiosities: 20 named rows; shelter on 1 (Ruin outcropping),
	# 8 (Collapsed tower), 16 (Secret tunnel).
	for roll in range(1, 21):
		TestKit.ok(f, Wastes.curiosity(roll) != "", "curiosity %d named" % roll)
	TestKit.eq(f, Wastes.curiosity(1), "Ruin outcropping", "1 = Ruin outcropping")
	TestKit.eq(f, Wastes.curiosity(20), "Forgotten treasure", "20 = Forgotten treasure")
	for roll in [1, 8, 16]:
		TestKit.ok(f, Wastes.curiosity_provides_shelter(roll), "curiosity %d shelters" % roll)
	TestKit.ok(f, not Wastes.curiosity_provides_shelter(2), "curiosity 2 no shelter")

	# Group sizes: Nothing 0, lone monsters 1, others rolled > 0.
	var rng := TestKit.rng(13)
	TestKit.eq(f, Wastes.group_size(E.NOTHING, rng), 0, "Nothing = 0")
	TestKit.eq(f, Wastes.group_size(E.SHADE, rng), 1, "Shade = 1")
	TestKit.eq(f, Wastes.group_size(E.GRIFFON, rng), 1, "Griffon = 1")
	TestKit.between(f, Wastes.group_size(E.NOMADS, rng), 1, 6, "Nomads 1d6")
	TestKit.between(f, Wastes.group_size(E.PILGRIMS, rng), 2, 12, "Pilgrims 2d6")
	TestKit.between(f, Wastes.group_size(E.MERCHANTS, rng), 1, 3, "Merchants 1d3")

	# Upkeep: spend a ration, else gain exhaustion (on the canonical Traveler).
	var A := Abilities.Ability
	var scores := {A.STR: 10, A.DEX: 10, A.CON: 10, A.INT: 10, A.WIS: 10, A.CHA: 10}
	var t := Traveler.create("A", 1, scores, rng)
	t.rations = 1
	Wastes.upkeep([t])
	TestKit.eq(f, t.rations, 0, "ration consumed")
	TestKit.eq(f, t.exhaustion, 0, "no exhaustion while fed")
	Wastes.upkeep([t])
	TestKit.eq(f, t.exhaustion, 1, "starved => exhaustion")

	# spend_day: a forced march adds +6 mi; report fields are well-formed.
	rng.seed = 99
	var report := Wastes.spend_day([], VastGen.WASTES, 1, rng)
	TestKit.ok(f, report.travel_miles >= 0, "travel_miles non-negative")
	TestKit.ok(f, report.weather in W.values(), "weather valid")
	TestKit.ok(f, report.encounter in E.values(), "encounter valid")
	TestKit.ok(f, report.encounter_roll >= 2, "encounter roll >= 2 (1d12+1d6)")

	return f
