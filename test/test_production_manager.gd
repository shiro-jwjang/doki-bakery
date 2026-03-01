extends GutTest

var ProductionManager: Node
var DataManager: Node


func before_each():
	# Create DataManager mock with necessary data
	DataManager = load("res://scripts/autoload/data_manager.gd").new()
	add_child_autofree(DataManager)
	DataManager.load_all_data()

	ProductionManager = load("res://scripts/autoload/production_manager.gd").new()
	add_child_autofree(ProductionManager)
	ProductionManager._ready()


func test_production_manager_has_active_baking():
	assert_not_null(ProductionManager.active_baking, "Should have active_baking dictionary")


func test_production_manager_has_max_slots():
	assert_eq(ProductionManager.max_slots, 2, "Should start with 2 slots")


func test_start_baking_creates_active_baking_entry():
	ProductionManager.start_baking(0, "white_bread")

	assert_true(ProductionManager.active_baking.has(0), "Slot 0 should be in active_baking")
	assert_eq(
		ProductionManager.active_baking[0].bread_id, "white_bread", "Bread ID should be white_bread"
	)


func test_start_baking_emits_signal():
	watch_signals(ProductionManager)
	ProductionManager.start_baking(0, "white_bread")

	assert_signal_emitted(ProductionManager, "baking_started", "Should emit baking_started signal")


func test_start_baking_calculates_duration():
	# white_bread base time is 5 seconds from balance.json
	var duration = ProductionManager.calculate_production_time("white_bread", "")
	assert_eq(duration, 5.0, "white_bread should take 5 seconds without bonuses")


func test_start_baking_same_slot_twice_fails():
	ProductionManager.start_baking(0, "white_bread")
	ProductionManager.start_baking(0, "croissant")

	# Second start should be ignored (slot already busy)
	assert_eq(ProductionManager.active_baking.size(), 1, "Should only have one active baking")


func test_is_slot_free_returns_true_for_empty_slot():
	assert_true(ProductionManager.is_slot_free(0), "Empty slot should be free")


func test_is_slot_free_returns_false_for_busy_slot():
	ProductionManager.start_baking(0, "white_bread")
	assert_false(ProductionManager.is_slot_free(0), "Busy slot should not be free")


func test_strawberry_cake_has_longer_production_time():
	var white_bread_time = ProductionManager.calculate_production_time("white_bread", "")
	var strawberry_cake_time = ProductionManager.calculate_production_time("strawberry_cake", "")

	assert_gt(strawberry_cake_time, white_bread_time, "Cake should take longer than white_bread")
	assert_eq(strawberry_cake_time, 60.0, "Cake base time should be 60 seconds")


func test_multiple_slots_can_bake_simultaneously():
	ProductionManager.start_baking(0, "white_bread")
	ProductionManager.start_baking(1, "strawberry_cake")

	assert_eq(ProductionManager.active_baking.size(), 2, "Should have 2 active bakings")
	assert_true(ProductionManager.active_baking.has(0), "Slot 0 should be active")
	assert_true(ProductionManager.active_baking.has(1), "Slot 1 should be active")


func test_bread_production_time_from_balance():
	var croissant_time = ProductionManager.calculate_production_time("croissant", "")
	assert_eq(croissant_time, 10.0, "Croissant base time should be 10 seconds")

	var chocolate_muffin_time = ProductionManager.calculate_production_time("chocolate_muffin", "")
	assert_eq(chocolate_muffin_time, 20.0, "Chocolate muffin base time should be 20 seconds")

	var macaron_time = ProductionManager.calculate_production_time("macaron", "")
	assert_eq(macaron_time, 30.0, "Macaron base time should be 30 seconds")
