class_name Denizens
## Travelers and Denizens (rules p18): named NPCs found in the Vast, each with a
## service or quest hook. A reference catalog (mostly narrative); their quests
## hook into other systems as those exist. No silent fallbacks: unknown ids raise.

enum Denizen { NOD, MASQUE, FLAYED_DERVISH, SINDR, OLD_TUNE, HOOL, SKITTER, DIVE }

# id -> { name, role, service }
const DENIZENS := {
	Denizen.NOD: {"name": "Nod", "role": "Pale roguish knife-bearer",
		"service": "Finds and brings back anyone in the Vast — paid only in Raw Lodestone and the teeth of a Crawl."},
	Denizen.MASQUE: {"name": "Masque", "role": "Masked rumor-monger",
		"service": "Tell them a dangerous secret and they repay you with an equally potent one."},
	Denizen.FLAYED_DERVISH: {"name": "Flayed Dervish", "role": "Blade-cloaked warrior",
		"service": "Fights at your side if you help hunt the seven cutthroats who slew their companions."},
	Denizen.SINDR: {"name": "Sindr", "role": "Reckless pyromancer",
		"service": "Seeks the five Holds of Fire — hidden workshops whose knowledge may usurp the Vast."},
	Denizen.OLD_TUNE: {"name": "Old Tune", "role": "Blind aged flautist",
		"service": "Bring back a song from the deep (sung by the Crawl) and receive a flute of comforting memory."},
	Denizen.HOOL: {"name": "Hool", "role": "Waste-Crier herald",
		"service": "Protect them between settlements for lodging, food, and small gifts."},
	Denizen.SKITTER: {"name": "Skitter", "role": "Cryptic alchemist",
		"service": "Seeks an exit from the Vast — recover ancient lab formulas and reagents to begin the grand work."},
	Denizen.DIVE: {"name": "Dive", "role": "Haunted ex-delver",
		"service": "Pays for safe passage into the depths — a greater reward each depth, growing ever more obsessed."},
}


static func data(id: int) -> Dictionary:
	assert(DENIZENS.has(id), "data: unknown denizen %d" % id)
	return DENIZENS[id]


static func name_of(id: int) -> String:
	return data(id)["name"]
