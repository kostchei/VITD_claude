## Verisimilitude tests for the Travelers & Denizens catalog (rules p18).

func run() -> Array:
	var f: Array = []
	var D := Denizens.Denizen

	TestKit.eq(f, Denizens.DENIZENS.size(), 8, "eight named denizens")
	TestKit.eq(f, Denizens.name_of(D.NOD), "Nod", "Nod present")
	TestKit.eq(f, Denizens.name_of(D.DIVE), "Dive", "Dive present")

	# Every denizen has a name, role, and service hook.
	for id in Denizens.DENIZENS:
		var d: Dictionary = Denizens.data(id)
		TestKit.ok(f, str(d["name"]) != "", "denizen %d named" % id)
		TestKit.ok(f, str(d["role"]) != "", "denizen %d has a role" % id)
		TestKit.ok(f, str(d["service"]) != "", "denizen %d has a service" % id)

	return f
