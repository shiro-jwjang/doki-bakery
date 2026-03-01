extends GutTest

var SalesManager: Node
var DataManager: Node


func before_each():
	# Create DataManager mock with necessary data
	DataManager = load("res://scripts/autoload/data_manager.gd").new()
	add_child_autofree(DataManager)
	DataManager.load_all_data()

	SalesManager = load("res://scripts/autoload/sales_manager.gd").new()
	add_child_autofree(SalesManager)
	SalesManager._ready()


func test_sales_manager_has_inventory():
	assert_not_null(SalesManager.inventory, "Should have inventory dictionary")


func test_sales_manager_starts_with_zero_gold():
	assert_eq(SalesManager.get_total_gold(), 0, "Should start with 0 gold")


func test_add_bread_to_inventory_adds_new_bread():
	SalesManager.add_bread_to_inventory("white_bread")

	assert_true(SalesManager.inventory.has("white_bread"), "Inventory should contain white_bread")
	assert_eq(SalesManager.inventory["white_bread"], 1, "Should have 1 white_bread")


func test_add_bread_to_inventory_increases_quantity():
	SalesManager.add_bread_to_inventory("white_bread")
	SalesManager.add_bread_to_inventory("white_bread")

	assert_eq(SalesManager.inventory["white_bread"], 2, "Should have 2 white_breads")


func test_add_bread_to_inventory_emits_signal():
	watch_signals(SalesManager)
	SalesManager.add_bread_to_inventory("white_bread")

	assert_signal_emitted(SalesManager, "inventory_updated", "Should emit inventory_updated signal")


func test_calculate_sell_price_for_white_bread():
	var price = SalesManager.calculate_sell_price("white_bread")
	# From balance.json: ingredientCost=10, basePrice=5, ingredientMultiplier=2.5
	# Formula: 10 * 2.5 + 5 = 25 + 5 = 30
	assert_eq(price, 30.0, "white_bread sell price should be 30")


func test_calculate_sell_price_for_strawberry_cake():
	var price = SalesManager.calculate_sell_price("strawberry_cake")
	# From balance.json: ingredientCost=100, basePrice=50, ingredientMultiplier=2.5
	# Formula: 100 * 2.5 + 50 = 250 + 50 = 300
	assert_eq(price, 300.0, "strawberry_cake sell price should be 300")


func test_sell_bread_removes_from_inventory():
	SalesManager.add_bread_to_inventory("white_bread")
	SalesManager.sell_bread("white_bread", 1)

	assert_eq(SalesManager.inventory["white_bread"], 0, "Should have 0 white_breads after selling")


func test_sell_bread_adds_gold():
	watch_signals(SalesManager)
	SalesManager.add_bread_to_inventory("white_bread")
	SalesManager.sell_bread("white_bread", 1)

	assert_eq(SalesManager.get_total_gold(), 30, "Should have 30 gold after selling white_bread")
	assert_signal_emitted(SalesManager, "bread_sold", "Should emit bread_sold signal")


func test_sell_bread_emits_inventory_updated():
	watch_signals(SalesManager)
	SalesManager.add_bread_to_inventory("white_bread")
	SalesManager.sell_bread("white_bread", 1)

	assert_signal_emitted(SalesManager, "inventory_updated", "Should emit inventory_updated signal")


func test_sell_multiple_breads():
	SalesManager.add_bread_to_inventory("white_bread")
	SalesManager.add_bread_to_inventory("white_bread")
	SalesManager.sell_bread("white_bread", 2)

	assert_eq(SalesManager.get_total_gold(), 60, "Should have 60 gold for 2 white_breads")
	assert_eq(SalesManager.inventory["white_bread"], 0, "Should have 0 white_breads left")


func test_sell_bread_without_inventory_fails_gracefully():
	# Should not crash, just print error
	SalesManager.sell_bread("white_bread", 1)

	assert_eq(SalesManager.get_total_gold(), 0, "Gold should remain 0")


func test_sell_more_than_available_fails():
	SalesManager.add_bread_to_inventory("white_bread")
	SalesManager.sell_bread("white_bread", 5)

	assert_eq(SalesManager.inventory["white_bread"], 1, "Should still have 1 white_bread")
	assert_eq(SalesManager.get_total_gold(), 0, "Gold should remain 0")


func test_different_breads_have_different_prices():
	var white_bread_price = SalesManager.calculate_sell_price("white_bread")
	var croissant_price = SalesManager.calculate_sell_price("croissant")
	var strawberry_cake_price = SalesManager.calculate_sell_price("strawberry_cake")

	assert_gt(strawberry_cake_price, croissant_price, "Cake should cost more than croissant")
	assert_gt(croissant_price, white_bread_price, "Croissant should cost more than white_bread")


func test_set_total_gold():
	SalesManager.set_total_gold(100)
	assert_eq(SalesManager.get_total_gold(), 100, "Total gold should be 100")
