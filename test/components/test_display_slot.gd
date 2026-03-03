extends GutTest

var DisplaySlot: Node
var SalesManager: Node
var DataManager: Node


func before_each():
	# Setup DataManager
	DataManager = load("res://scripts/autoload/data_manager.gd").new()
	add_child_autofree(DataManager)
	DataManager.load_all_data()

	# Setup SalesManager
	SalesManager = load("res://scripts/autoload/sales_manager.gd").new()
	add_child_autofree(SalesManager)
	# Inject DataManager dependency into SalesManager
	if SalesManager.has_method("set_data_manager"):
		SalesManager.set_data_manager(DataManager)

	# Create DisplaySlot scene
	var scene = load("res://scenes/components/DisplaySlot.tscn")
	if scene:
		DisplaySlot = scene.instantiate()
	else:
		# Fallback: create script directly if scene doesn't exist yet
		DisplaySlot = load("res://scripts/components/display_slot.gd").new()

	# Inject dependencies for testing
	if DisplaySlot.has_method("set_sales_manager"):
		DisplaySlot.set_sales_manager(SalesManager)
	if DisplaySlot.has_method("set_data_manager"):
		DisplaySlot.set_data_manager(DataManager)

	add_child_autofree(DisplaySlot)


func test_display_slot_has_slot_index():
	assert_not_null(DisplaySlot.slot_index, "DisplaySlot should have slot_index property")


func test_display_slot_has_default_state():
	assert_eq(DisplaySlot.state, "empty", "DisplaySlot should start in empty state")


func test_display_slot_has_no_bread_initially():
	assert_eq(DisplaySlot.current_bread_id, "", "DisplaySlot should have no bread initially")


func test_display_slot_can_display_bread():
	watch_signals(DisplaySlot)
	DisplaySlot.display_bread("white_bread", 5)

	assert_eq(DisplaySlot.state, "displayed", "DisplaySlot should be in displayed state")
	assert_eq(DisplaySlot.current_bread_id, "white_bread", "DisplaySlot should have white_bread")
	assert_eq(DisplaySlot.quantity, 5, "DisplaySlot should have quantity 5")
	assert_signal_emitted(DisplaySlot, "bread_displayed", "Should emit bread_displayed signal")


func test_display_slot_can_sell_bread():
	watch_signals(DisplaySlot)
	# Add bread to SalesManager inventory first
	SalesManager.add_bread_to_inventory("white_bread", 10)
	DisplaySlot.display_bread("white_bread", 5)
	DisplaySlot.sell_bread()

	assert_eq(DisplaySlot.quantity, 4, "Quantity should decrease by 1")
	assert_signal_emitted(DisplaySlot, "bread_sold", "Should emit bread_sold signal")


func test_display_slot_cannot_sell_when_empty():
	var result = DisplaySlot.sell_bread()

	assert_false(result, "Should not be able to sell when empty")
	assert_eq(DisplaySlot.state, "empty", "State should remain empty")


func test_display_slot_becomes_empty_when_quantity_zero():
	# Add bread to SalesManager inventory first
	SalesManager.add_bread_to_inventory("white_bread", 10)
	DisplaySlot.display_bread("white_bread", 1)
	DisplaySlot.sell_bread()

	assert_eq(DisplaySlot.state, "empty", "DisplaySlot should be empty after selling last bread")
	assert_eq(DisplaySlot.current_bread_id, "", "Bread ID should be cleared")


func test_display_slot_updates_inventory_on_sell():
	# Add bread to SalesManager inventory first
	SalesManager.add_bread_to_inventory("white_bread", 10)
	DisplaySlot.display_bread("white_bread", 3)
	DisplaySlot.sell_bread()

	assert_true(SalesManager.inventory.has("white_bread"), "SalesManager should have white_bread")
	assert_eq(SalesManager.inventory["white_bread"], 9, "Should have 9 white_bread left (10 - 1)")


func test_display_slot_calculates_total_price():
	DisplaySlot.display_bread("white_bread", 5)
	var price = DisplaySlot.get_sell_price()

	# white_bread price is 30 from balance.json
	assert_eq(price, 150.0, "Total price should be 30 * 5 = 150")


func test_display_slot_updates_ui():
	DisplaySlot.display_bread("white_bread", 5)

	# UI should be updated (we can't directly test UI, but we can check properties)
	assert_eq(DisplaySlot.current_bread_id, "white_bread", "Bread ID should be set")
	assert_eq(DisplaySlot.quantity, 5, "Quantity should be set")


func test_display_slot_can_clear_display():
	DisplaySlot.display_bread("white_bread", 5)
	DisplaySlot.clear_display()

	assert_eq(DisplaySlot.state, "empty", "State should be empty after clearing")
	assert_eq(DisplaySlot.current_bread_id, "", "Bread ID should be cleared")
	assert_eq(DisplaySlot.quantity, 0, "Quantity should be 0")


func test_display_slot_connects_to_sales_manager():
	# Add bread to SalesManager inventory first
	SalesManager.add_bread_to_inventory("white_bread", 10)
	DisplaySlot.display_bread("white_bread", 3)
	DisplaySlot.sell_bread()

	# SalesManager should be updated
	assert_true(
		SalesManager.inventory.has("white_bread"), "SalesManager inventory should be updated"
	)
	assert_eq(SalesManager.inventory["white_bread"], 9, "Should have 9 white_bread left")
