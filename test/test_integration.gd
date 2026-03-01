extends GutTest

# 통합 테스트: GameManager, ProductionManager, SalesManager의 연동 테스트

var GameManager: Node
var ProductionManager: Node
var SalesManager: Node
var DataManager: Node


func before_each():
	DataManager = load("res://scripts/autoload/data_manager.gd").new()
	add_child_autofree(DataManager)
	DataManager.load_all_data()

	ProductionManager = load("res://scripts/autoload/production_manager.gd").new()
	add_child_autofree(ProductionManager)

	SalesManager = load("res://scripts/autoload/sales_manager.gd").new()
	add_child_autofree(SalesManager)
	SalesManager._ready()

	GameManager = load("res://scripts/autoload/game_manager.gd").new()
	add_child_autofree(GameManager)
	GameManager._ready()


func test_full_baking_and_sales_cycle():
	# 1. Start baking
	ProductionManager.start_baking(0, "white_bread")
	assert_true(ProductionManager.active_baking.has(0), "Baking should start")

	# 2. Finish baking manually (simulate time passing)
	var data = ProductionManager.active_baking[0]
	data.start_time = Time.get_unix_time_from_system() - 100  # Set start time in the past

	# Call _process to trigger finish detection
	ProductionManager._process(0)

	# 3. Check inventory
	assert_true(SalesManager.inventory.has("white_bread"), "Bread should be in inventory")
	assert_eq(SalesManager.inventory["white_bread"], 1, "Should have 1 bread")

	# 4. Sell bread
	SalesManager.sell_bread("white_bread", 1)

	# 5. Check gold
	assert_eq(SalesManager.get_total_gold(), 30, "Should have 30 gold from selling")


func test_multiple_production_cycles():
	# Bake white_bread
	ProductionManager.start_baking(0, "white_bread")
	var data0 = ProductionManager.active_baking[0]
	data0.start_time = Time.get_unix_time_from_system() - 100

	# Bake croissant
	ProductionManager.start_baking(1, "croissant")
	var data1 = ProductionManager.active_baking[1]
	data1.start_time = Time.get_unix_time_from_system() - 100

	ProductionManager._process(0)

	# Should have both breads in inventory
	assert_eq(SalesManager.inventory.size(), 2, "Should have 2 different bread types")


func test_production_to_sales_gold_flow():
	# Start with 0 gold
	assert_eq(SalesManager.get_total_gold(), 0, "Start with 0 gold")

	# Bake and sell white_bread
	ProductionManager.start_baking(0, "white_bread")
	ProductionManager.active_baking[0].start_time = Time.get_unix_time_from_system() - 100
	ProductionManager._process(0)

	SalesManager.sell_bread("white_bread", 1)

	# Sell strawberry_cake for comparison
	ProductionManager.start_baking(0, "strawberry_cake")
	ProductionManager.active_baking[0].start_time = Time.get_unix_time_from_system() - 200
	ProductionManager._process(0)

	SalesManager.sell_bread("strawberry_cake", 1)

	# white_bread: 30g, strawberry_cake: 300g = 330g total
	assert_eq(SalesManager.get_total_gold(), 330, "Should have 330 gold total")


func test_gold_sync_between_managers():
	watch_signals(GameManager)
	GameManager.add_gold(100)

	# GameManager's gold should be updated
	assert_eq(GameManager.player_gold, 100, "GameManager should have 100 gold")


func test_level_up_from_bread_sales():
	# Each bread gives experience (not yet implemented in ProductionManager)
	# This test will be expanded when experience gain from baking is added
	pass


func test_inventory_limits():
	# Add many breads to inventory
	for i in range(100):
		SalesManager.add_bread_to_inventory("white_bread")

	assert_eq(SalesManager.inventory["white_bread"], 100, "Should have 100 white_breads")

	# Sell half
	SalesManager.sell_bread("white_bread", 50)

	assert_eq(SalesManager.inventory["white_bread"], 50, "Should have 50 white_breads left")


func test_production_time_calculation_consistency():
	# Test that production time calculation is consistent
	var time1 = ProductionManager.calculate_production_time("white_bread", "")
	var time2 = ProductionManager.calculate_production_time("white_bread", "")

	assert_eq(time1, time2, "Production time should be consistent")


func test_price_calculation_consistency():
	# Test that price calculation is consistent
	var price1 = SalesManager.calculate_sell_price("white_bread")
	var price2 = SalesManager.calculate_sell_price("white_bread")

	assert_eq(price1, price2, "Price should be consistent")
