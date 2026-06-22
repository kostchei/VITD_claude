## Verisimilitude tests for Grit & Flesh (rules p7).

func run() -> Array:
	var f: Array = []
	var A := Abilities.Ability
	var rng := TestKit.rng(3)

	# Scores with a known CON (14 -> +2) and a known highest (16 -> +3).
	var scores := {A.STR: 16, A.DEX: 10, A.CON: 14, A.INT: 9, A.WIS: 8, A.CHA: 7}
	var t := Traveler.create("Test", 3, scores, rng)

	# Flesh max = level + highest mod = 3 + 3 = 6 (deterministic).
	TestKit.eq(f, t.flesh_max, 6, "flesh_max = level + highest mod")
	TestKit.eq(f, t.flesh, t.flesh_max, "flesh starts full")

	# Grit max = sum(3d8) + CON mod(+2): range [3*1+2, 3*8+2] = [5, 26], >=1.
	TestKit.between(f, t.grit_max, 5, 26, "grit_max within 3d8 + CON band")
	TestKit.eq(f, t.grit, t.grit_max, "grit starts full")

	# Damage absorbed by Grit alone leaves Flesh and injuries untouched.
	t.grit = 5
	t.flesh = 6
	t.injuries = []
	var lost := t.take_damage(3, rng)
	TestKit.eq(f, t.grit, 2, "grit absorbs damage")
	TestKit.eq(f, t.flesh, 6, "flesh untouched while grit remains")
	TestKit.eq(f, lost, 0, "no flesh lost")
	TestKit.eq(f, t.injuries.size(), 0, "no injuries while grit absorbs")

	# Overflow past Grit cuts Flesh and records one injury per Flesh point lost.
	t.grit = 3
	t.flesh = 6
	t.injuries = []
	lost = t.take_damage(5, rng)  # 3 to grit, 2 to flesh
	TestKit.eq(f, t.grit, 0, "grit emptied")
	TestKit.eq(f, t.flesh, 4, "flesh took the overflow")
	TestKit.eq(f, lost, 2, "2 flesh lost")
	TestKit.eq(f, t.injuries.size(), 2, "one injury per flesh point lost")
	TestKit.ok(f, t.injuries[0]["ability"] in A.values(), "injury on a real stat")

	# Flesh can't drop below 0; is_down() at 0.
	t.grit = 0
	t.flesh = 1
	t.take_damage(10, rng)
	TestKit.eq(f, t.flesh, 0, "flesh floors at 0")
	TestKit.ok(f, t.is_down(), "is_down at 0 flesh")

	# Grit healing: 1d6 normal, 2d6 on full rest; capped at max; never exceeds.
	t.grit_max = 20
	t.grit = 10
	var healed := t.heal_grit(false, rng)
	TestKit.between(f, healed, 1, 6, "normal heal in 1..6")
	t.grit = 10
	healed = t.heal_grit(true, rng)
	TestKit.between(f, healed, 2, 12, "full-rest heal in 2..12")
	t.grit = 19
	t.heal_grit(true, rng)
	TestKit.ok(f, t.grit <= t.grit_max, "grit never exceeds max")

	# Flesh heals 1/day only (settlement), capped.
	t.flesh_max = 6
	t.flesh = 4
	TestKit.eq(f, t.heal_flesh_in_settlement(), 1, "flesh heals 1")
	TestKit.eq(f, t.flesh, 5, "flesh now 5")
	t.flesh = 6
	TestKit.eq(f, t.heal_flesh_in_settlement(), 0, "flesh capped at max")

	return f
