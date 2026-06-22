class_name Inventory
## Slot-based inventory (rules p7). Capacity = CON modifier + extra slots from
## Packs and Cargo Transports. Items cost 1-4 slots. In a settlement you may
## dedicate slots to a purpose at 10 coin/slot and draw a relevant item later.
## (The book's 10-slot example sheet is a CON-0 Traveler carrying a Backpack.)
## No silent fallbacks: unknown items / over-capacity adds raise (assert).

const SETTLEMENT_SLOT_COIN := 10  # coin per dedicated slot, paid in a settlement

# Item slot costs from the page's example list (♦ = 1 .. ♦♦♦♦ = 4).
const ITEM_SLOTS := {
	"Spiked Boots": 1, "Water Jug": 1, "Net": 1, "Chisel": 1, "Spyglass": 1,
	"Soapstone": 1, "50ft Rope": 1, "Torch": 1,
	"Shield": 1, "Gambeson": 1, "Brass Knuckles": 1, "Club": 1, "Knife": 1, "Ammunition": 1,
	"10ft Ladder": 2, "Lock-box": 2, "Tent": 2, "Portable Stove": 2,
	"Piecemeal Armor": 2, "Axe": 2, "Mace": 2, "Spear": 2, "Sword": 2, "Bow": 2,
	"Chainmail": 3, "Claymore": 3, "Great Axe": 3, "Maul": 3, "Crossbow": 3,
	"Splintmail": 4, "Arquebus": 4,
}

# Packs: extra slots, purchased from a settlement (slots, coin).
const PACKS := {
	"Bindle": {"slots": 2, "coin": 20},
	"Sack": {"slots": 6, "coin": 80},
	"Backpack": {"slots": 10, "coin": 120},
}

# Cargo transports: big slot gains, but cap overland speed to 12 mi/day when
# under-crewed (Pulk pulled alone; Sleigh pulled by two or fewer).
const CARGO := {
	"Pulk": {"slots": 10, "speed_cap": 12, "min_crew": 2},
	"Sleigh": {"slots": 20, "speed_cap": 12, "min_crew": 3},
}

var con_mod: int = 0
var packs: Array = []          # pack names carried
var cargo: Array = []          # cargo transport names
var items: Array = []          # carried item names (each costs ITEM_SLOTS)
var reserved: int = 0          # settlement-dedicated slots not yet drawn


## Total slots available: CON modifier + pack + cargo bonuses, floored at 0.
func capacity() -> int:
	var total := con_mod
	for p in packs:
		total += pack_slots(p)
	for c in cargo:
		total += cargo_slots(c)
	return maxi(0, total)


## Slots currently used: carried items + dedicated-but-undrawn slots.
func used() -> int:
	var total := reserved
	for it in items:
		total += item_slots(it)
	return total


func free_slots() -> int:
	return capacity() - used()


## Add an item if it fits. Returns false (no fallback partial add) if it doesn't.
func add_item(name: String) -> bool:
	var cost := item_slots(name)
	if cost > free_slots():
		return false
	items.append(name)
	return true


func remove_item(name: String) -> bool:
	var i := items.find(name)
	if i == -1:
		return false
	items.remove_at(i)
	return true


## Dedicate `slots` to a purpose in a settlement; returns the coin cost. The
## purpose label is the player's; mechanically it just reserves capacity.
func dedicate(slots: int) -> int:
	assert(slots >= 1, "dedicate: need >= 1 slot")
	assert(slots <= free_slots(), "dedicate: not enough free slots")
	reserved += slots
	return slots * SETTLEMENT_SLOT_COIN


## Draw a concrete item from dedicated slots: frees its cost from `reserved` and
## records the item. The item must cost no more than the slots still reserved.
func draw(name: String) -> bool:
	var cost := item_slots(name)
	if cost > reserved:
		return false
	reserved -= cost
	items.append(name)
	return true


# --- static table lookups (no silent fallback on unknown keys) ---

static func item_slots(name: String) -> int:
	assert(ITEM_SLOTS.has(name), "item_slots: unknown item '%s'" % name)
	return ITEM_SLOTS[name]


static func pack_slots(name: String) -> int:
	assert(PACKS.has(name), "pack_slots: unknown pack '%s'" % name)
	return PACKS[name]["slots"]


static func pack_coin(name: String) -> int:
	assert(PACKS.has(name), "pack_coin: unknown pack '%s'" % name)
	return PACKS[name]["coin"]


static func cargo_slots(name: String) -> int:
	assert(CARGO.has(name), "cargo_slots: unknown cargo '%s'" % name)
	return CARGO[name]["slots"]
