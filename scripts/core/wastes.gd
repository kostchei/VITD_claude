class_name Wastes
## Day-cycle for crossing the open Wastes — implements wastes-weather-encounters.md:
##   - 2d6 Weather table.
##   - Encounters read on 1d12 + 1d6 (the d6 doubles as the Mood die); Pillar Fog
##     adds +6 on top, so the roll can reach the monster rows.
##   - 1d20 Curiosities table.
##   - Movement & survival: 18 mi/day base, +6 mi per level of exhaustion
##     (forced march), 1 ration/Traveler/day or a level of exhaustion.
## Tables are terrain-keyed; only the Wastes set lives here (Ruins / Settlements /
## Pillars supply their own elsewhere). Like HazardSet, this implements the
## deterministic mechanics (rolls, travel, upkeep) and *reports* the save/damage
## weather effects for a combat layer to adjudicate, rather than faking stats.
## No silent fallbacks: out-of-range rolls or non-Wastes terrain raise (assert).

const BASE_MILES_PER_DAY := 18  # on foot, per 24h, before needing rest
const FORCED_MARCH_MILES := 6   # extra distance bought per level of exhaustion

enum Weather { CALM, DUST_STORM, WIND_BLAST, STONE_HAIL, PILLAR_FOG, GRIT_SLIDE, DUNE_WAVE }

# 1d12+1d6 encounter table, in row order (Nothing covers the low rows).
enum Encounter {
	NOTHING, LOST_TRAVELERS, NOMADS, MERCHANTS, BANDITS, PILGRIMS,
	LODESTONE_PROSPECTORS, CARAVAN, CUTTHROATS, CYCLOPS, HARPIES, MEDUSA,
	SHADE, GRIFFON,
}

enum Mood { NONE, CAUTIOUS, CURIOUS, FRIENDLY, CRAZED, TRIBUTE, RECRUIT }

const WEATHER_NAMES := {
	Weather.CALM: "Calm",
	Weather.DUST_STORM: "Dust Storm",
	Weather.WIND_BLAST: "Wind Blast",
	Weather.STONE_HAIL: "Stone Hail",
	Weather.PILLAR_FOG: "Pillar Fog",
	Weather.GRIT_SLIDE: "Grit Slide",
	Weather.DUNE_WAVE: "Dune Wave",
}

const ENCOUNTER_NAMES := {
	Encounter.NOTHING: "Nothing",
	Encounter.LOST_TRAVELERS: "Lost Travelers",
	Encounter.NOMADS: "Nomads",
	Encounter.MERCHANTS: "Merchants",
	Encounter.BANDITS: "Bandits",
	Encounter.PILGRIMS: "Pilgrims",
	Encounter.LODESTONE_PROSPECTORS: "Lodestone Prospectors",
	Encounter.CARAVAN: "Caravan",
	Encounter.CUTTHROATS: "Cutthroats",
	Encounter.CYCLOPS: "Cyclops",
	Encounter.HARPIES: "Harpies",
	Encounter.MEDUSA: "Medusa",
	Encounter.SHADE: "Shade",
	Encounter.GRIFFON: "Griffon",
}

const MOOD_NAMES := {
	Mood.NONE: "",
	Mood.CAUTIOUS: "Cautious",
	Mood.CURIOUS: "Curious",
	Mood.FRIENDLY: "Friendly",
	Mood.CRAZED: "Crazed",
	Mood.TRIBUTE: "Tribute",
	Mood.RECRUIT: "Recruit",
}

# 1d20 Curiosities, in roll order (index 0 = roll 1).
const CURIOSITY_NAMES := [
	"Ruin outcropping", "Abandoned camp", "Stone totem", "Desiccated corpses",
	"Burial cairn", "Cache of lodestone", "Nomad in black", "Collapsed tower",
	"Lodestone obelisk", "Traveler tied to a pillar", "Unearthed road", "Swarm",
	"Lonely graves", "Nest", "Plague-ridden corpse", "Secret tunnel",
	"Message", "Lost caravan", "Bereft Swordsman", "Forgotten treasure",
]
# Rolls whose Curiosity provides shelter (the counter to harmful weather).
const CURIOSITY_SHELTER_ROLLS := [1, 8, 16]


## Outcome of one day: what was rolled, how far the party got, and any weather
## effects that still need adjudication (saves/damage) by a combat layer.
class DayReport:
	var weather: int = Weather.CALM
	var travel_miles: int = 0
	var landmarks_obscured: bool = false
	var encounter: int = Encounter.NOTHING
	var encounter_roll: int = 0  # the 1d12 + 1d6 (+ mods) total
	var mood: int = Mood.NONE
	var group_size: int = 0      # headcount of the encountered group
	var pending_effects: Array[String] = []  # save/damage prompts to resolve


## 2d6 Weather table.  2-6 Calm, then 7..12 ascending.
static func weather(roll: int) -> int:
	assert(roll >= 2 and roll <= 12, "weather: 2d6 roll out of range: %d" % roll)
	if roll <= 6:
		return Weather.CALM
	match roll:
		7: return Weather.DUST_STORM
		8: return Weather.WIND_BLAST
		9: return Weather.STONE_HAIL
		10: return Weather.PILLAR_FOG
		11: return Weather.GRIT_SLIDE
		12: return Weather.DUNE_WAVE
	assert(false, "weather: unreachable for roll %d" % roll)
	return Weather.CALM


## Encounter table read on 1d12 + 1d6 (+ mods).  Min 2; Pillar Fog can push it
## past 18, which still reads as Griffon.
static func encounter(roll: int) -> int:
	assert(roll >= 2, "encounter: roll below the 1d12+1d6 minimum: %d" % roll)
	if roll <= 5:
		return Encounter.NOTHING
	match roll:
		6: return Encounter.LOST_TRAVELERS
		7: return Encounter.NOMADS
		8: return Encounter.MERCHANTS
		9: return Encounter.BANDITS
		10: return Encounter.PILGRIMS
		11: return Encounter.LODESTONE_PROSPECTORS
		12: return Encounter.CARAVAN
		13: return Encounter.CUTTHROATS
		14: return Encounter.CYCLOPS
		15: return Encounter.HARPIES
		16: return Encounter.MEDUSA
		17: return Encounter.SHADE
	return Encounter.GRIFFON  # 18 and anything pushed higher


## Whether an encounter rolls a 1d6 Mood (the same d6 used for the encounter row).
static func has_mood(enc: int) -> bool:
	return enc == Encounter.NOMADS or enc == Encounter.BANDITS or enc == Encounter.CUTTHROATS


## 1d6 Mood for an encounter that has one. Caller must check has_mood() first.
static func mood(enc: int, roll: int) -> int:
	assert(roll >= 1 and roll <= 6, "mood: 1d6 out of range: %d" % roll)
	match enc:
		Encounter.NOMADS:
			if roll == 1:
				return Mood.CAUTIOUS
			if roll <= 4:
				return Mood.CURIOUS
			return Mood.FRIENDLY
		Encounter.BANDITS:
			if roll <= 2:
				return Mood.CRAZED
			if roll <= 5:
				return Mood.TRIBUTE
			return Mood.CURIOUS
		Encounter.CUTTHROATS:
			if roll <= 3:
				return Mood.CRAZED
			if roll <= 5:
				return Mood.TRIBUTE
			return Mood.RECRUIT
	assert(false, "mood: encounter %d has no Mood; check has_mood() first" % enc)
	return Mood.NONE


## Headcount of an encountered group (its own dice). 0 for Nothing; 1 for the
## lone monsters; the Caravan is 1d6 Merchants + 2d6 Nomads.
static func group_size(enc: int, rng: RandomNumberGenerator) -> int:
	match enc:
		Encounter.NOTHING: return 0
		Encounter.LOST_TRAVELERS: return _roll(rng, 1, 6)
		Encounter.NOMADS: return _roll(rng, 1, 6)
		Encounter.MERCHANTS: return _roll(rng, 1, 3)
		Encounter.BANDITS: return _roll(rng, 1, 6)
		Encounter.PILGRIMS: return _roll(rng, 2, 6)
		Encounter.LODESTONE_PROSPECTORS: return _roll(rng, 1, 6)
		Encounter.CARAVAN: return _roll(rng, 1, 6) + _roll(rng, 2, 6)
		Encounter.CUTTHROATS: return _roll(rng, 1, 6)
		Encounter.CYCLOPS: return _roll(rng, 1, 6)
		Encounter.HARPIES: return _roll(rng, 1, 3)
		Encounter.MEDUSA: return _roll(rng, 1, 3)
		Encounter.SHADE: return 1
		Encounter.GRIFFON: return 1
	assert(false, "group_size: unknown encounter %d" % enc)
	return 0


## 1d20 Curiosities table -> the curiosity's name.
static func curiosity(roll: int) -> String:
	assert(roll >= 1 and roll <= 20, "curiosity: 1d20 out of range: %d" % roll)
	return CURIOSITY_NAMES[roll - 1]


## Does the rolled Curiosity provide shelter?
static func curiosity_provides_shelter(roll: int) -> bool:
	assert(roll >= 1 and roll <= 20, "curiosity_provides_shelter: 1d20 out of range: %d" % roll)
	return CURIOSITY_SHELTER_ROLLS.has(roll)


## Spend one day on the map: charge upkeep, roll weather (which can cut travel and
## raise the encounter roll), then roll the encounter. `push_extra_marches` is how
## many extra 6-mile marches the party chooses to force, each costing the whole
## party a level of exhaustion. Returns a DayReport.
static func spend_day(party: Array, terrain: StringName, push_extra_marches: int, rng: RandomNumberGenerator) -> DayReport:
	assert(terrain == VastGen.WASTES,
		"spend_day: only the Wastes tables exist here; got terrain %s" % terrain)
	assert(push_extra_marches >= 0, "spend_day: push_extra_marches must be >= 0")
	var report := DayReport.new()
	var travel := BASE_MILES_PER_DAY
	var encounter_mod := 0

	# Forced march: buy extra distance with party-wide exhaustion.
	for i in range(push_extra_marches):
		travel += FORCED_MARCH_MILES
		for t in party:
			t.exhaustion += 1

	# Weather (resolve first: it feeds travel and the encounter roll).
	var w := weather(rng.randi_range(1, 6) + rng.randi_range(1, 6))
	report.weather = w
	match w:
		Weather.CALM:
			pass
		Weather.DUST_STORM:
			travel -= 6
			report.landmarks_obscured = true
		Weather.WIND_BLAST:
			report.pending_effects.append(
				"Wind Blast: unprotected lights/fires blown out; Travelers in the open risk being blown away for %d damage" % _roll(rng, 3, 6))
		Weather.STONE_HAIL:
			report.pending_effects.append(
				"Stone Hail: unprotected Travelers Save v. Breath or take %d damage" % _roll(rng, 3, 6))
		Weather.PILLAR_FOG:
			encounter_mod += 6
			report.landmarks_obscured = true
		Weather.GRIT_SLIDE:
			travel -= 6
			report.pending_effects.append(
				"Grit Slide: Save v. Breath or take %d damage" % _roll(rng, 3, 6))
		Weather.DUNE_WAVE:
			# Running from the wave is the survivable choice — take the exhaustion.
			for t in party:
				t.exhaustion += 1
			report.pending_effects.append(
				"Dune Wave: each Traveler gained a level of exhaustion (running) or would be buried")

	# Encounter: one pair of dice — d12 sets the row, d6 bumps it AND is the mood.
	var d12 := rng.randi_range(1, 12)
	var d6 := rng.randi_range(1, 6)
	var roll := d12 + d6 + encounter_mod
	var enc := encounter(roll)
	report.encounter = enc
	report.encounter_roll = roll
	if enc != Encounter.NOTHING:
		report.group_size = group_size(enc, rng)
		report.mood = mood(enc, d6) if has_mood(enc) else Mood.NONE

	# Upkeep: eat or tire (once per day, regardless of weather/encounter).
	upkeep(party)

	report.travel_miles = maxi(travel, 0)
	return report


## Daily upkeep: each Traveler spends 1 ration, or gains a level of exhaustion.
static func upkeep(party: Array) -> void:
	for t in party:
		if t.rations > 0:
			t.rations -= 1
		else:
			t.exhaustion += 1


# --- internal ---

## Roll `n` dice of `sides` faces (NdS) and sum them.
static func _roll(rng: RandomNumberGenerator, n: int, sides: int) -> int:
	var total := 0
	for i in range(n):
		total += rng.randi_range(1, sides)
	return total
