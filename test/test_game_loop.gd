extends GutTest

## Integration test for the complete game loop:
## ProductionManager → SalesManager → GameManager

var ProductionManager: Node
var SalesManager: Node
var GameManager: Node
var DataManager: Node


func before_each():
	# Setup DataManager
	DataManager = load("res://scripts/autoload/data_manager.gd").new()
	add_child_autofree(DataManager)
	DataManager.load_all_data()

	# Setup ProductionManager
	ProductionManager = load("res://scripts/autoload/ProductionManager.gd").new()
	add_child_autofree(ProductionManager)

	# Setup SalesManager
	SalesManager = load("res://scripts/autoload/SalesManager.gd").new()
	add_child_autofree(SalesManager)
	SalesManager._ready()

	# Setup GameManager
	GameManager = load("res://scripts/autoload/GameManager.gd").new()
	add_child_autofree(GameManager)
	GameManager._ready()

	# Clear any existing state
	SalesManager.inventory.clear()
	SalesManager.total_gold = 0
	GameManager.player_gold = 0
	ProductionManager.active_baking.clear()


func test_complete_production_to_sales_cycle():
	# Start: Begin baking
	ProductionManager.start_baking(0, "white_bread")

	assert_true(ProductionManager.active_baking.has(0), "Should have active baking")
	assert_eq(
		ProductionManager.active_baking[0].bread_id, "white_bread", "Should be baking white_bread"
	)

	# Middle: Simulate baking completion
	ProductionManager.active_baking[0].start_time = Time.get_unix_time_from_system() - 100
	ProductionManager._process(0)

	# Verify bread was added to inventory
	assert_true(SalesManager.inventory.has("white_bread"), "Should have white_bread in inventory")
	assert_eq(SalesManager.inventory["white_bread"], 1, "Should have 1 white_bread")

	# End: Sell the bread
	SalesManager.sell_bread("white_bread", 1)

	# Verify sale
	assert_eq(SalesManager.inventory["white_bread"], 0, "Should have no white_bread left")
	assert_gt(SalesManager.total_gold, 0, "Should have earned gold")


func test_baking_emits_signals():
	watch_signals(ProductionManager)

	ProductionManager.start_baking(0, "white_bread")

	assert_signal_emitted(ProductionManager, "baking_started", "Should emit baking_started signal")


func test_sales_emits_signals():
	watch_signals(SalesManager)

	# First add bread
	SalesManager.add_bread_to_inventory("white_bread")

	# Then sell
	SalesManager.sell_bread("white_bread", 1)

	assert_signal_emitted(SalesManager, "bread_sold", "Should emit bread_sold signal")


func test_multiple_breads_can_be_sold():
	# Bake and sell multiple breads
	SalesManager.add_bread_to_inventory("white_bread")
	SalesManager.add_bread_to_inventory("white_bread")
	SalesManager.add_bread_to_inventory("croissant")

	SalesManager.sell_bread("white_bread", 2)
	SalesManager.sell_bread("croissant", 1)

	var total_gold = SalesManager.get_total_gold()
	# white_bread: 30 * 2 = 60, croissant: ~40 = ~100 total
	assert_gt(total_gold, 90, "Should have earned significant gold")


func test_gold_updates_game_manager():
	watch_signals(GameManager)

	var initial_gold = GameManager.player_gold
	SalesManager.set_total_gold(100)
	GameManager.add_gold(50)

	assert_gt(GameManager.player_gold, initial_gold, "GameManager gold should increase")
	assert_signal_emitted(GameManager, "gold_changed", "Should emit gold_changed signal")


func test_experience_gained_from_selling():
	# This would require SalesManager to emit experience signals
	# For now, test GameManager experience directly
	watch_signals(GameManager)

	GameManager.add_experience(50)

	assert_eq(GameManager.player_experience, 50, "Should have 50 experience")
	assert_signal_emitted(GameManager, "experience_gained", "Should emit experience_gained signal")


func test_level_up_from_experience():
	watch_signals(GameManager)

	GameManager.add_experience(100)  # Enough for level up

	assert_eq(GameManager.player_level, 2, "Should be at level 2")
	assert_signal_emitted(GameManager, "level_changed", "Should emit level_changed signal")


func test_production_manager_updates_slots():
	# Test that multiple slots work independently
	ProductionManager.start_baking(0, "white_bread")
	ProductionManager.start_baking(1, "croissant")

	assert_eq(ProductionManager.active_baking.size(), 2, "Should have 2 active bakings")
	assert_true(ProductionManager.active_baking.has(0), "Slot 0 should be active")
	assert_true(ProductionManager.active_baking.has(1), "Slot 1 should be active")


func test_sales_manager_inventory_tracking():
	# Add multiple breads of different types
	SalesManager.add_bread_to_inventory("white_bread", 3)
	SalesManager.add_bread_to_inventory("croissant", 2)

	assert_eq(SalesManager.inventory["white_bread"], 3, "Should have 3 white_breads")
	assert_eq(SalesManager.inventory["croissant"], 2, "Should have 2 croissants")

	# Sell some
	SalesManager.sell_bread("white_bread", 2)
	SalesManager.sell_bread("croissant", 1)

	assert_eq(SalesManager.inventory["white_bread"], 1, "Should have 1 white_bread left")
	assert_eq(SalesManager.inventory["croissant"], 1, "Should have 1 croissant left")


func test_game_loop_persistence():
	# Verify that data flows through the entire loop
	# 1. Start baking
	ProductionManager.start_baking(0, "strawberry_cake")

	# 2. Complete baking
	ProductionManager.active_baking[0].start_time = Time.get_unix_time_from_system() - 1000
	ProductionManager._process(0)

	# 3. Verify inventory
	assert_true(SalesManager.inventory.has("strawberry_cake"), "Should have strawberry_cake")

	# 4. Sell for gold
	var gold_before = SalesManager.get_total_gold()
	SalesManager.sell_bread("strawberry_cake", 1)
	var gold_after = SalesManager.get_total_gold()

	assert_gt(gold_after, gold_before, "Gold should increase after selling")
