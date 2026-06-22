class_name TravelerQuirks
## 1d20 Traveler Quirks (rules p6, "You are a Traveler"). At character creation or
## advancement a Traveler may randomly select one quirk. Ruin Plucker (#1) may be
## taken multiple times; every other quirk is unique to a Traveler.
## This is the table + selection rule; each quirk's mechanical effect is wired
## into the relevant system as that system is built.
## No silent fallbacks: out-of-range rolls / unknown ids raise (assert).

# id, name, description (faithful to the page). Only Ruin Plucker is repeatable.
const QUIRKS := [
	{"id": 1, "name": "Ruin Plucker", "repeatable": true,
		"desc": "Gain an extra inventory slot; always loathe to leave things behind. Can be taken multiple times."},
	{"id": 2, "name": "Enigmatic Paranoia", "repeatable": false,
		"desc": "You sense when you are followed or tracked, whispering it aloud without realizing."},
	{"id": 3, "name": "Hollow Fortitude", "repeatable": false,
		"desc": "3-in-6 chance you do not suffer exhaustion when you normally would."},
	{"id": 4, "name": "Labrinthiosis", "repeatable": false,
		"desc": "In a structure, meditate 10 minutes to predict what the next 1d6 rooms contain."},
	{"id": 5, "name": "Magnetoception", "repeatable": false,
		"desc": "Meditate 1 hour in a place to relocate it later at any distance; replaces the old location."},
	{"id": 6, "name": "Vacant Amygdala", "repeatable": false,
		"desc": "Incapable of feeling fear, supernatural or otherwise."},
	{"id": 7, "name": "Distant Appetite", "repeatable": false,
		"desc": "May go without food for up to 1d6 days; food offers little pleasure."},
	{"id": 8, "name": "Vampyr", "repeatable": false,
		"desc": "May drink 1d6 HP of fresh blood in place of a meal."},
	{"id": 9, "name": "Vicious Abandon", "repeatable": false,
		"desc": "Sacrifice a weapon to automatically hit and deal maximum damage to an assailant."},
	{"id": 10, "name": "Wind Seer", "repeatable": false,
		"desc": "Predict weather in the Vast perfectly."},
	{"id": 11, "name": "Dreamless", "repeatable": false,
		"desc": "Only need sleep every 1d6 days."},
	{"id": 12, "name": "Unreadable", "repeatable": false,
		"desc": "People cannot read your motives or emotions."},
	{"id": 13, "name": "Psychitabolism", "repeatable": false,
		"desc": "Eat brains to acquire simple memories (names/secrets from people, shelter/food from animals)."},
	{"id": 14, "name": "Psionherd", "repeatable": false,
		"desc": "Hypnotize small non-hostile creatures of the Vast to hold, follow, or leave."},
	{"id": 15, "name": "Long-walker", "repeatable": false,
		"desc": "Travel 6 extra miles each day with no ill effect."},
	{"id": 16, "name": "Gentle Presence", "repeatable": false,
		"desc": "Non-hostile Travelers are friendly or helpful toward you."},
	{"id": 17, "name": "Candles in the Dark", "repeatable": false,
		"desc": "See in the dark up to 1d6 hours after light is gone."},
	{"id": 18, "name": "Cold Blood", "repeatable": false,
		"desc": "No harm from cold weather; half damage from cold attacks."},
	{"id": 19, "name": "Dull Psyche", "repeatable": false,
		"desc": "Advantage on resisting charms or mental compulsion."},
	{"id": 20, "name": "Memetic", "repeatable": false,
		"desc": "Duplicate one ability or quirk of a traveler observed for more than a day."},
]


## The quirk for a 1d20 roll (1-20).
static func quirk(id: int) -> Dictionary:
	assert(id >= 1 and id <= QUIRKS.size(), "quirk: id out of range: %d" % id)
	return QUIRKS[id - 1]


## Roll 1d20 for a quirk; returns the rolled id (1-20).
static func roll(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(1, QUIRKS.size())


## Whether a Traveler who already has `current_ids` may take quirk `id`:
## always true for repeatable quirks, otherwise only if not already held.
static func can_take(id: int, current_ids: Array) -> bool:
	if quirk(id)["repeatable"]:
		return true
	return not current_ids.has(id)


## Roll a quirk the Traveler may legally take, re-rolling collisions. If every
## non-repeatable quirk is already held this would loop forever — assert instead.
static func roll_takeable(current_ids: Array, rng: RandomNumberGenerator) -> int:
	var taken_non_repeatable := 0
	for q in QUIRKS:
		if not q["repeatable"] and current_ids.has(q["id"]):
			taken_non_repeatable += 1
	assert(taken_non_repeatable < QUIRKS.size(), "roll_takeable: no quirk left to take")
	var id := roll(rng)
	while not can_take(id, current_ids):
		id = roll(rng)
	return id
