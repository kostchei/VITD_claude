class_name Navigation
## Navigation Roll for crossing the Vast (rules p9, "Exploring the Vast").
## Each day of travel the party rolls 1d6: a 6 navigates successfully, 1-5 means
## Lost. Navigational assets each cut the lost chance by 1 (down to 0-in-6). The
## severity of being Lost scales with that remaining lost chance.
## No silent fallbacks: out-of-range input raises (assert).

# Assets that each lessen the chance of becoming lost by 1 (p9).
enum Asset { LANDMARK, DIRECTIONS, TOOL, LIGHT, DEAD_RECKONING }

enum LostEffect { NONE, LATE, OFF_COURSE, DANGEROUSLY_OFF_COURSE, UTTERLY_LOST }

# With no assets you are lost on a d6 of 1-5 (only a 6 succeeds).
const BASE_LOST_THRESHOLD := 5

const LOST_EFFECT_NAMES := {
	LostEffect.NONE: "Arrived",
	LostEffect.LATE: "Late",
	LostEffect.OFF_COURSE: "Off course",
	LostEffect.DANGEROUSLY_OFF_COURSE: "Dangerously off course",
	LostEffect.UTTERLY_LOST: "Utterly lost",
}

# Distance penalty in miles. UTTERLY_LOST is open-ended (roll until success), -1.
const LOST_EFFECT_MILES := {
	LostEffect.NONE: 0,
	LostEffect.LATE: 6,                    # 6 mi short of destination
	LostEffect.OFF_COURSE: 6,              # 6 mi away, random direction
	LostEffect.DANGEROUSLY_OFF_COURSE: 12, # 12 mi away
	LostEffect.UTTERLY_LOST: -1,           # roll until success = days lost
}


## The d6 value at or below which the party is Lost, given how many assets they
## prepared. 0 assets -> 5, each asset -1, clamped to 0 ("down to 0-in-6").
static func lost_threshold(asset_count: int) -> int:
	assert(asset_count >= 0, "lost_threshold: asset_count must be >= 0")
	return clampi(BASE_LOST_THRESHOLD - asset_count, 0, BASE_LOST_THRESHOLD)


## True if a navigation roll (1-6) means the party is Lost for that threshold.
static func is_lost(roll: int, threshold: int) -> bool:
	assert(roll >= 1 and roll <= 6, "is_lost: roll out of range: %d" % roll)
	return roll <= threshold


## How badly Lost, by the day's remaining lost chance (threshold). Anchored on
## the book's worked example: 4 assets -> threshold 1 -> only ever "Late".
## The middle bands (2,3) and the worst (4-5) are our documented reading of
## "determined by their original chances of becoming lost".
static func lost_effect(threshold: int) -> LostEffect:
	assert(threshold >= 0 and threshold <= BASE_LOST_THRESHOLD, "lost_effect: bad threshold %d" % threshold)
	if threshold <= 0:
		return LostEffect.NONE
	if threshold == 1:
		return LostEffect.LATE
	if threshold == 2:
		return LostEffect.OFF_COURSE
	if threshold == 3:
		return LostEffect.DANGEROUSLY_OFF_COURSE
	return LostEffect.UTTERLY_LOST  # 4-5


## Resolve one day's navigation. Returns:
##   { roll:int, threshold:int, lost:bool, effect:LostEffect, miles_penalty:int }
static func navigate(asset_count: int, rng: RandomNumberGenerator) -> Dictionary:
	var threshold := lost_threshold(asset_count)
	var roll := rng.randi_range(1, 6)
	var lost := is_lost(roll, threshold)
	var effect: int = lost_effect(threshold) if lost else LostEffect.NONE
	return {
		"roll": roll,
		"threshold": threshold,
		"lost": lost,
		"effect": effect,
		"miles_penalty": LOST_EFFECT_MILES[effect],
	}
