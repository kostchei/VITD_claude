## Verisimilitude tests for Exhaustion (rules p7-9): gain a level from hardship,
## a full rest day removes one, and a 7th level is a Harrowing hardship.

func run() -> Array:
	var f: Array = []
	var A := Abilities.Ability
	var rng := TestKit.rng(5)
	var scores := {A.STR: 10, A.DEX: 10, A.CON: 10, A.INT: 10, A.WIS: 10, A.CHA: 10}
	var t := Traveler.create("Test", 1, scores, rng)

	TestKit.eq(f, t.exhaustion, 0, "starts at 0 exhaustion")

	# Each cause adds a level; full-day rest removes one.
	t.gain_exhaustion(Traveler.ExhaustionCause.NO_FOOD)
	TestKit.eq(f, t.exhaustion, 1, "no food -> 1 level")
	t.gain_exhaustion(Traveler.ExhaustionCause.PUSHED_TOO_HARD)
	TestKit.eq(f, t.exhaustion, 2, "forced march -> 2 levels")
	t.rest_full_day()
	TestKit.eq(f, t.exhaustion, 1, "rest removes one level")
	t.rest_full_day()
	t.rest_full_day()
	TestKit.eq(f, t.exhaustion, 0, "rest floors at 0")

	# 7th level is the Harrowing trigger; gain_exhaustion reports the crossing once.
	t.exhaustion = 0
	var crossed_count := 0
	for i in range(6):
		if t.gain_exhaustion(Traveler.ExhaustionCause.LOST_SLEEP):
			crossed_count += 1
	TestKit.eq(f, t.exhaustion, 6, "six levels, not yet harrowed")
	TestKit.ok(f, not t.is_overexhausted(), "6 levels is not over-exhausted")
	TestKit.eq(f, crossed_count, 0, "no crossing before the 7th")

	var crossed := t.gain_exhaustion(Traveler.ExhaustionCause.SEVERELY_WOUNDED)
	TestKit.eq(f, t.exhaustion, 7, "seventh level reached")
	TestKit.ok(f, t.is_overexhausted(), "7 levels is over-exhausted (Harrowing)")
	TestKit.ok(f, crossed, "gain reports crossing the 7th level")

	# Crossing is reported only once, not again past 7.
	TestKit.ok(f, not t.gain_exhaustion(Traveler.ExhaustionCause.LOST_SLEEP), "no re-trigger past 7")
	TestKit.eq(f, t.exhaustion, 8, "still climbs past 7")

	return f
