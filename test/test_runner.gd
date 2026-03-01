extends Node

## Simple test runner for TDD without GUT dependency

var test_results = {"passed": 0, "failed": 0, "errors": []}


func _ready():
	print("=== Running Doki Bakery Tests ===")
	run_all_tests()
	print_tests_summary()
	get_tree().quit()


func run_all_tests():
	# Test DataManager
	test_data_manager()
	# Test ProductionManager
	test_production_manager()
	# Test SalesManager
	test_sales_manager()
	# Test GameManager
	test_game_manager()
	# Integration tests
	test_integration()


func assert_true(condition, message):
	if condition:
		test_results.passed += 1
		print("  ✓ " + message)
	else:
		test_results.failed += 1
		test_results.errors.append("✗ FAILED: " + message)
		print("  ✗ FAILED: " + message)


func assert_false(condition, message):
	if not condition:
		test_results.passed += 1
		print("  ✓ " + message)
	else:
		test_results.failed += 1
		test_results.errors.append("✗ FAILED: " + message)
		print("  ✗ FAILED: " + message)


func assert_eq(a, b, message):
	if a == b:
		test_results.passed += 1
		print("  ✓ " + message)
	else:
		test_results.failed += 1
		test_results.errors.append(
			"✗ FAILED: " + message + " (expected: " + str(b) + ", got: " + str(a) + ")"
		)
		print("  ✗ FAILED: " + message + " (expected: " + str(b) + ", got: " + str(a) + ")")


func assert_not_null(value, message):
	if value != null:
		test_results.passed += 1
		print("  ✓ " + message)
	else:
		test_results.failed += 1
		test_results.errors.append("✗ FAILED: " + message)
		print("  ✗ FAILED: " + message)


func print_tests_summary():
	print("\n=== Test Summary ===")
	print("Passed: " + str(test_results.passed))
	print("Failed: " + str(test_results.failed))
	if test_results.failed > 0:
		print("\nErrors:")
		for error in test_results.errors:
			print("  " + error)
		print("\n❌ Tests FAILED")
	else:
		print("\n✅ All tests PASSED")


func test_data_manager():
	print("\n--- DataManager Tests ---")
	var dm = DataManager  # Use autoload instance

	assert_not_null(dm.balance, "Balance data loaded")
	assert_not_null(dm.balance.production, "Production config exists")
	assert_not_null(dm.balance.pricing, "Pricing config exists")
	assert_eq(dm.balance.production.baseTimeMultiplier, 0.2, "Base time multiplier is 0.2")
	assert_true(dm.balance.production.breads.has("white_bread"), "Has white_bread config")
	assert_eq(
		dm.balance.production.breads.white_bread.baseTime, 5.0, "white_bread base time is 5.0"
	)


func test_production_manager():
	print("\n--- ProductionManager Tests ---")
	var pm = ProductionManager  # Use autoload instance

	assert_eq(pm.max_slots, 2, "Has 2 slots")
	assert_true(pm.is_slot_free(0), "Slot 0 is initially free")

	pm.start_baking(0, "white_bread")
	assert_false(pm.is_slot_free(0), "Slot 0 is busy after baking")
	assert_eq(pm.active_baking[0].bread_id, "white_bread", "Correct bread ID")

	var duration = pm.calculate_production_time("white_bread", "")
	assert_eq(duration, 5.0, "white_bread takes 5 seconds")

	var cake_duration = pm.calculate_production_time("strawberry_cake", "")
	assert_eq(cake_duration, 60.0, "strawberry_cake takes 60 seconds")


func test_sales_manager():
	print("\n--- SalesManager Tests ---")
	var sm = SalesManager  # Use autoload instance

	assert_eq(sm.get_total_gold(), 0, "Starts with 0 gold")

	sm.add_bread_to_inventory("white_bread")
	assert_true(sm.inventory.has("white_bread"), "Inventory has white_bread")
	assert_eq(sm.inventory["white_bread"], 1, "Has 1 white_bread")

	var price = sm.calculate_sell_price("white_bread")
	assert_eq(price, 30.0, "white_bread price is 30")

	sm.sell_bread("white_bread", 1)
	assert_eq(sm.get_total_gold(), 30, "Has 30 gold after selling")
	assert_eq(sm.inventory["white_bread"], 0, "No white_bread left")


func test_game_manager():
	print("\n--- GameManager Tests ---")
	var gm = GameManager  # Use autoload instance

	assert_eq(gm.player_gold, 0, "Starts with 0 gold")
	assert_eq(gm.player_level, 1, "Starts at level 1")

	gm.add_gold(100)
	assert_eq(gm.player_gold, 100, "Has 100 gold")

	assert_true(gm.remove_gold(50), "Can remove gold with sufficient amount")
	assert_eq(gm.player_gold, 50, "Has 50 gold left")

	assert_false(gm.remove_gold(100), "Cannot remove more than available")
	assert_eq(gm.player_gold, 50, "Gold unchanged after failed removal")

	gm.add_experience(100)
	assert_eq(gm.player_level, 2, "Leveled up to 2")


func test_integration():
	print("\n--- Integration Tests ---")
	var pm = ProductionManager  # Use autoload instance
	var sm = SalesManager  # Use autoload instance

	# Clear any existing state
	sm.inventory.clear()
	sm.total_gold = 0
	pm.active_baking.clear()

	pm.start_baking(0, "white_bread")
	# Simulate time passing
	pm.active_baking[0].start_time = Time.get_unix_time_from_system() - 100
	pm._process(0)

	assert_true(sm.inventory.has("white_bread"), "Bread added to inventory after baking")

	sm.sell_bread("white_bread", 1)
	assert_eq(sm.get_total_gold(), 30, "Gold earned from selling")
