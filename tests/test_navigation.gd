## Verisimilitude tests for Navigation (rules p9). Anchored on the book's stated
## numbers and the worked example (4 assets => lost only on a 1 => "Late").

func run() -> Array:
	var f: Array = []

	# Threshold: 0 assets -> lost on 1-5; each asset -1; clamps at 0.
	TestKit.eq(f, Navigation.lost_threshold(0), 5, "threshold@0 assets")
	TestKit.eq(f, Navigation.lost_threshold(1), 4, "threshold@1 asset")
	TestKit.eq(f, Navigation.lost_threshold(4), 1, "threshold@4 assets (book example)")
	TestKit.eq(f, Navigation.lost_threshold(5), 0, "threshold@5 assets (0-in-6)")
	TestKit.eq(f, Navigation.lost_threshold(7), 0, "threshold clamps at 0")

	# With no assets, only a 6 succeeds.
	TestKit.ok(f, Navigation.is_lost(5, 5), "no-asset roll 5 is lost")
	TestKit.ok(f, not Navigation.is_lost(6, 5), "no-asset roll 6 succeeds")

	# Book example: 4 assets (threshold 1) -> lost only on a 1.
	TestKit.ok(f, Navigation.is_lost(1, 1), "4-asset roll 1 is lost")
	TestKit.ok(f, not Navigation.is_lost(2, 1), "4-asset roll 2 succeeds")

	# Lost-effect bands; anchor: threshold 1 -> Late (book example).
	TestKit.eq(f, Navigation.lost_effect(0), Navigation.LostEffect.NONE, "effect@0")
	TestKit.eq(f, Navigation.lost_effect(1), Navigation.LostEffect.LATE, "effect@1 = Late (anchor)")
	TestKit.eq(f, Navigation.lost_effect(2), Navigation.LostEffect.OFF_COURSE, "effect@2")
	TestKit.eq(f, Navigation.lost_effect(3), Navigation.LostEffect.DANGEROUSLY_OFF_COURSE, "effect@3")
	TestKit.eq(f, Navigation.lost_effect(4), Navigation.LostEffect.UTTERLY_LOST, "effect@4")
	TestKit.eq(f, Navigation.lost_effect(5), Navigation.LostEffect.UTTERLY_LOST, "effect@5")

	# Distances stated on the page.
	TestKit.eq(f, Navigation.LOST_EFFECT_MILES[Navigation.LostEffect.LATE], 6, "Late = 6mi")
	TestKit.eq(f, Navigation.LOST_EFFECT_MILES[Navigation.LostEffect.DANGEROUSLY_OFF_COURSE], 12, "Dangerous = 12mi")
	TestKit.eq(f, Navigation.LOST_EFFECT_MILES[Navigation.LostEffect.UTTERLY_LOST], -1, "Utterly = open-ended")

	# navigate(): a 6 is never lost; with 5 assets you are never lost at all.
	var rng := TestKit.rng(42)
	var safe_lost := 0
	for i in range(2000):
		if Navigation.navigate(5, rng)["lost"]:
			safe_lost += 1
	TestKit.eq(f, safe_lost, 0, "5 assets => never lost over 2000 rolls")

	# With no assets, lost frequency ~ 5/6; sanity bounds (not exact).
	var lost := 0
	for i in range(6000):
		if Navigation.navigate(0, rng)["lost"]:
			lost += 1
	TestKit.between(f, float(lost) / 6000.0, 0.79, 0.88, "no-asset lost rate ~5/6")

	# A lost result on a 4-asset day always reads "Late".
	var late_ok := true
	for i in range(500):
		var r := Navigation.navigate(4, rng)
		if r["lost"] and r["effect"] != Navigation.LostEffect.LATE:
			late_ok = false
	TestKit.ok(f, late_ok, "4-asset lost is always Late")

	return f
