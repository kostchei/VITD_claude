# Rules → Code Process

How we turn *The Vast in the Dark* rules into tested GDScript. The full rules
text is extracted at `D:/Code/VastDark/Codex/the-vast-in-the-dark.md` (44 pages).
We work through it **page by page, in order**, and never hand-wave a number —
every mechanical rule is decomposed, pseudocoded, coded, and tested for
verisimilitude before it is committed.

## The loop (per page)

1. **Read the page** from the rules md.
2. **Decompose** it into distinct mechanical rules. Skip pure flavour/setting
   prose — only rules with dice, numbers, tables, thresholds, or state changes.
3. **One todo per rule** (TaskCreate), so progress is trackable.
4. For each rule todo:
   1. **Pseudocode** — add a summary + pseudocode to a per-chapter rules doc
      (the style of [generating-the-vast.md](generating-the-vast.md),
      [wastes-weather-encounters.md](wastes-weather-encounters.md),
      [roaming-hazards.md](roaming-hazards.md)). Cite the page.
   2. **Code** — implement in a `scripts/core/*.gd` module. Project conventions:
      `class_name`, static where pure, `assert` on bad input — **no silent
      fallbacks** (a missing/illegal value throws).
   3. **Test** — write `tests/test_<rule>.gd` that encodes the rule's *specified*
      behaviour: exact table values, thresholds, ranges, odds, and any worked
      example from the book (these are the verisimilitude anchors). For random
      rules, assert outcome ranges, that every outcome is reachable, and that
      deterministic edge cases hold.
   4. **Run** `tests/run_tests.gd` headless. **Green → commit** that rule alone.
      **Red → rework** code (or test) until green.
5. Mark the todo done; move to the next rule, then the next page.

## Verisimilitude = the test mirrors the book

A test passes "for verisimilitude" when it reproduces what the rules page
actually says — not what seems reasonable. Anchor every test to a quoted number
or worked example. Where the book is genuinely ambiguous or system-agnostic
(e.g. it defers ability scores to the host RPG), make the interpretation
explicit in the chapter doc, encode *that* decision in the test, and flag it for
review rather than burying a guess.

## Running the tests

```
# real Godot mono console exe (see memory: godot-real-exe-path)
<godot_console.exe> --headless --import --path .          # once, after adding a class_name
<godot_console.exe> --headless --script tests/run_tests.gd --path .
```

The runner loads every `tests/test_*.gd`, calls its `run() -> Array` (returns a
list of failure strings), prints a summary, and exits non-zero if any failed.

## Layout

```
rules-implementation-process.md   # this file
<chapter>.md                      # per-chapter rules summary + pseudocode
scripts/core/<rule>.gd            # implementation
tests/
  run_tests.gd                    # headless runner (SceneTree)
  kit.gd                          # TestKit assertion helpers
  test_<rule>.gd                  # one per rule
```

## Status

Implemented before this process existed (already in the repo): regional/local
terrain generation, the continuous 1-mile travel grid + persistence, the Wastes
weather/encounter/curiosity tables, roaming-hazard placement & drift. Those are
back-filled with tests as we pass their pages. New rules follow the loop above.
The live todo list is the source of truth for what's done vs pending.
