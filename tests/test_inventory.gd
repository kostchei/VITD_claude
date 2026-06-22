## Verisimilitude tests for Inventory (rules p7): slots = CON mod + packs/cargo,
## item slot costs, pack/cargo numbers, and the 10 coin/slot settlement rule.

func run() -> Array:
	var f: Array = []

	# Item slot costs from the page's ♦ list.
	TestKit.eq(f, Inventory.item_slots("Torch"), 1, "Torch = 1 slot")
	TestKit.eq(f, Inventory.item_slots("Sword"), 2, "Sword = 2 slots")
	TestKit.eq(f, Inventory.item_slots("Crossbow"), 3, "Crossbow = 3 slots")
	TestKit.eq(f, Inventory.item_slots("Arquebus"), 4, "Arquebus = 4 slots")

	# Pack/cargo numbers straight from the page.
	TestKit.eq(f, Inventory.pack_slots("Bindle"), 2, "Bindle +2")
	TestKit.eq(f, Inventory.pack_coin("Bindle"), 20, "Bindle 20c")
	TestKit.eq(f, Inventory.pack_slots("Sack"), 6, "Sack +6")
	TestKit.eq(f, Inventory.pack_coin("Sack"), 80, "Sack 80c")
	TestKit.eq(f, Inventory.pack_slots("Backpack"), 10, "Backpack +10")
	TestKit.eq(f, Inventory.pack_coin("Backpack"), 120, "Backpack 120c")
	TestKit.eq(f, Inventory.cargo_slots("Pulk"), 10, "Pulk 10 slots")
	TestKit.eq(f, Inventory.cargo_slots("Sleigh"), 20, "Sleigh 20 slots")
	TestKit.eq(f, Inventory.CARGO["Pulk"]["speed_cap"], 12, "Pulk caps speed at 12")

	# Capacity = CON mod + packs + cargo; the book's 10-slot sheet = CON 0 + Backpack.
	var inv := Inventory.new()
	inv.con_mod = 0
	inv.packs = ["Backpack"]
	TestKit.eq(f, inv.capacity(), 10, "CON 0 + Backpack = 10 (book sheet)")

	inv = Inventory.new()
	inv.con_mod = 2
	inv.packs = ["Bindle"]
	TestKit.eq(f, inv.capacity(), 4, "CON +2 + Bindle(+2) = 4")

	# Negative CON eats into capacity but floors at 0.
	inv = Inventory.new()
	inv.con_mod = -4
	TestKit.eq(f, inv.capacity(), 0, "capacity floors at 0")
	inv.con_mod = -2
	inv.packs = ["Sack"]
	TestKit.eq(f, inv.capacity(), 4, "CON -2 + Sack(+6) = 4")

	# Adding items respects capacity; used()/free() track slots.
	inv = Inventory.new()
	inv.con_mod = 0
	inv.packs = ["Backpack"]  # 10 slots
	TestKit.ok(f, inv.add_item("Sword"), "add Sword (2)")
	TestKit.ok(f, inv.add_item("Crossbow"), "add Crossbow (3)")
	TestKit.eq(f, inv.used(), 5, "used = 5")
	TestKit.eq(f, inv.free_slots(), 5, "free = 5")
	TestKit.ok(f, inv.add_item("Splintmail"), "add Splintmail (4)")  # 9/10
	TestKit.ok(f, not inv.add_item("Sword"), "cannot add Sword (would be 11/10)")
	TestKit.eq(f, inv.used(), 9, "used still 9 after rejected add")

	# Settlement: dedicate slots at 10 coin/slot, then draw an item from them.
	inv = Inventory.new()
	inv.con_mod = 0
	inv.packs = ["Backpack"]
	TestKit.eq(f, inv.dedicate(3), 30, "dedicate 3 slots = 30 coin")
	TestKit.eq(f, inv.used(), 3, "reserved counts as used")
	TestKit.ok(f, inv.draw("Crossbow"), "draw a 3-slot item from the 3 reserved")
	TestKit.eq(f, inv.reserved, 0, "reservation consumed")
	TestKit.eq(f, inv.used(), 3, "item now occupies the slots")
	TestKit.ok(f, not inv.draw("Knife"), "nothing left reserved to draw")

	TestKit.eq(f, Inventory.SETTLEMENT_SLOT_COIN, 10, "10 coin per dedicated slot")

	return f
