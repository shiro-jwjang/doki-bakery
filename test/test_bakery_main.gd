extends GutTest

var BakeryMain: Control

func before_each():
	# Load BakeryMain scene
	var scene = load("res://scenes/bakery/bakery_main.tscn")
	BakeryMain = scene.instantiate()
	add_child_autofree(BakeryMain)
	BakeryMain._ready()

func test_bakery_main_has_background():
	var color_rect = BakeryMain.get_node_or_null("ColorRect")
	assert_not_null(color_rect, "Should have ColorRect background")
	assert_eq(color_rect.color, Color(0.95, 0.92, 0.88, 1), "Background color should be warm bakery color")

func test_bakery_main_has_two_oven_slots():
	var oven_slot_0 = BakeryMain.get_node("GameArea/LeftPanel/OvenSlots/OvenSlot0")
	var oven_slot_1 = BakeryMain.get_node("GameArea/LeftPanel/OvenSlots/OvenSlot1")

	assert_not_null(oven_slot_0, "Should have OvenSlot0")
	assert_not_null(oven_slot_1, "Should have OvenSlot1")

func test_bakery_main_has_two_display_slots():
	var display_slot_0 = BakeryMain.get_node("GameArea/RightPanel/DisplaySlots/DisplaySlot0")
	var display_slot_1 = BakeryMain.get_node("GameArea/RightPanel/DisplaySlots/DisplaySlot1")

	assert_not_null(display_slot_0, "Should have DisplaySlot0")
	assert_not_null(display_slot_1, "Should have DisplaySlot1")

func test_bakery_main_has_hud():
	var hud = BakeryMain.get_node_or_null("HUD")
	assert_not_null(hud, "Should have HUD")

func test_bakery_main_has_bottom_bar_with_buttons():
	var bread_button = BakeryMain.get_node_or_null("BottomBar/BreadSelectButton")
	var shop_button = BakeryMain.get_node_or_null("BottomBar/ShopButton")
	var fairy_button = BakeryMain.get_node_or_null("BottomBar/FairyButton")

	assert_not_null(bread_button, "Should have BreadSelectButton")
	assert_not_null(shop_button, "Should have ShopButton")
	assert_not_null(fairy_button, "Should have FairyButton")

func test_oven_slots_have_correct_indices():
	var oven_slot_0 = BakeryMain.get_node("GameArea/LeftPanel/OvenSlots/OvenSlot0")
	var oven_slot_1 = BakeryMain.get_node("GameArea/LeftPanel/OvenSlots/OvenSlot1")

	assert_eq(oven_slot_0.slot_index, 0, "OvenSlot0 should have index 0")
	assert_eq(oven_slot_1.slot_index, 1, "OvenSlot1 should have index 1")

func test_display_slots_have_correct_indices():
	var display_slot_0 = BakeryMain.get_node("GameArea/RightPanel/DisplaySlots/DisplaySlot0")
	var display_slot_1 = BakeryMain.get_node("GameArea/RightPanel/DisplaySlots/DisplaySlot1")

	assert_eq(display_slot_0.slot_index, 0, "DisplaySlot0 should have index 0")
	assert_eq(display_slot_1.slot_index, 1, "DisplaySlot1 should have index 1")

func test_bakery_main_has_menu_containers():
	var bread_menu = BakeryMain.get_node_or_null("MenuContainer/BreadMenu")
	var upgrade_menu = BakeryMain.get_node_or_null("MenuContainer/UpgradeMenu")
	var fairy_menu = BakeryMain.get_node_or_null("MenuContainer/FairyMenu")

	assert_not_null(bread_menu, "Should have BreadMenu container")
	assert_not_null(upgrade_menu, "Should have UpgradeMenu container")
	assert_not_null(fairy_menu, "Should have FairyMenu container")

func test_baking_finished_adds_to_display_slot():
	# This test verifies that when baking finishes, bread is added to display
	var display_slot_0 = BakeryMain.get_node("GameArea/RightPanel/DisplaySlots/DisplaySlot0")

	# Initially empty
	assert_eq(display_slot_0.state, "empty", "DisplaySlot should start empty")

	# Simulate baking finished (would normally be triggered by OvenSlot)
	BakeryMain._add_to_display_slot("white_bread")

	# Should now have white_bread
	assert_eq(display_slot_0.state, "displayed", "DisplaySlot should now have bread")
	assert_eq(display_slot_0.current_bread_id, "white_bread", "Should have white_bread")

func test_add_to_same_display_slot_increases_quantity():
	var display_slot_0 = BakeryMain.get_node("GameArea/RightPanel/DisplaySlots/DisplaySlot0")

	# Add first bread
	BakeryMain._add_to_display_slot("white_bread")
	assert_eq(display_slot_0.quantity, 1, "Should have 1 bread")

	# Add same bread again
	BakeryMain._add_to_display_slot("white_bread")
	assert_eq(display_slot_0.quantity, 2, "Should have 2 breads")

func test_add_different_bread_uses_new_slot():
	var display_slot_0 = BakeryMain.get_node("GameArea/RightPanel/DisplaySlots/DisplaySlot0")
	var display_slot_1 = BakeryMain.get_node("GameArea/RightPanel/DisplaySlots/DisplaySlot1")

	# Add first bread to slot 0
	BakeryMain._add_to_display_slot("white_bread")
	assert_eq(display_slot_0.current_bread_id, "white_bread", "Slot 0 should have white_bread")

	# Add different bread, should go to slot 1
	BakeryMain._add_to_display_slot("croissant")
	assert_eq(display_slot_1.current_bread_id, "croissant", "Slot 1 should have croissant")
