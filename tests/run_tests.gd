extends SceneTree
## Headless test runner. Loads every tests/test_*.gd, calls its `run() -> Array`
## (a list of failure strings; empty = pass), prints a summary, and exits with a
## code equal to the number of failures.
##   <godot_console.exe> --headless --script tests/run_tests.gd --path .


func _init() -> void:
	var files := _test_files()
	var total_failures := 0
	var total_tests := files.size()
	print("\n=== Running %d test file(s) ===" % total_tests)
	for path in files:
		var fname: String = path.get_file()
		var script: GDScript = load(path)
		if script == null:
			print("  FAIL  %s — failed to load/compile" % fname)
			total_failures += 1
			continue
		var inst: Object = script.new()
		if inst == null or not inst.has_method("run"):
			print("  FAIL  %s — no run() method" % fname)
			total_failures += 1
			continue
		var result: Variant = inst.run()
		if not (result is Array):
			print("  FAIL  %s — run() did not return an Array" % fname)
			total_failures += 1
			continue
		var failures: Array = result
		if failures.is_empty():
			print("  PASS  %s" % fname)
		else:
			for msg in failures:
				print("  FAIL  %s — %s" % [fname, msg])
			total_failures += failures.size()
	print("=== %d test file(s), %d failure(s) ===\n" % [total_tests, total_failures])
	quit(total_failures)


func _test_files() -> Array:
	var out: Array = []
	var dir := DirAccess.open("res://tests")
	assert(dir != null, "run_tests: cannot open res://tests")
	dir.list_dir_begin()
	var fn := dir.get_next()
	while fn != "":
		if not dir.current_is_dir() and fn.begins_with("test_") and fn.ends_with(".gd"):
			out.append("res://tests/" + fn)
		fn = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out
