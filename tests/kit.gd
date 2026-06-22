class_name TestKit
## Tiny assertion helpers for the headless test suite. Each appends a failure
## string to `f` instead of aborting, so one test can report many failures and
## the runner can report many tests. See tests/run_tests.gd and the process doc.


static func eq(f: Array, got: Variant, want: Variant, label: String) -> void:
	if got != want:
		f.append("%s: expected %s, got %s" % [label, str(want), str(got)])


static func ok(f: Array, cond: bool, label: String) -> void:
	if not cond:
		f.append(label)


static func between(f: Array, v: float, lo: float, hi: float, label: String) -> void:
	if v < lo or v > hi:
		f.append("%s: %s not in [%s, %s]" % [label, str(v), str(lo), str(hi)])


## A seeded RNG so random-rule tests are reproducible.
static func rng(seed_value: int = 1) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r
