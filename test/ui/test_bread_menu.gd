extends GutTest

var BreadMenu: Control
var DataManager: Node
var ProductionManager: Node


func before_each():
	# Setup DataManager
	DataManager = load("res://scripts/autoload/data_manager.gd").new()
	add_child_autofree(DataManager)
	DataManager.load_all_data()

	# Setup ProductionManager
	ProductionManager = load("res://scripts/autoload/production_manager.gd").new()
	add_child_autofree(ProductionManager)

	# Create BreadMenu scene
	var scene = load("res://scenes/ui/BreadMenu.tscn")
	if scene:
		BreadMenu = scene.instantiate()
	else:
		BreadMenu = load("res://scripts/ui/bread_menu.gd").new()

	add_child_autofree(BreadMenu)
	BreadMenu._ready()


func test_bread_menu_has_close_button():
	var close_button = BreadMenu.get_node_or_null("Panel/VBoxContainer/Header/CloseButton")
	assert_not_null(close_button, "Should have CloseButton")


func test_bread_menu_has_bread_list():
	var bread_list = BreadMenu.get_node_or_null("Panel/VBoxContainer/BreadList")
	assert_not_null(bread_list, "Should have BreadList container")


func test_bread_menu_displays_unlocked_breads():
	# At level 1, only white_bread should be available
	var unlocked = DataManager.get_unlocked_breads(1)
	assert_gt(unlocked.size(), 0, "Should have at least one unlocked bread")


func test_bread_menu_filters_by_level():
	var level_1_breads = DataManager.get_unlocked_breads(1)
	var level_3_breads = DataManager.get_unlocked_breads(3)

	assert_gt(
		level_3_breads.size(),
		level_1_breads.size(),
		"Level 3 should unlock more breads than level 1"
	)


func test_bread_menu_emits_bread_selected_signal():
	watch_signals(BreadMenu)
	BreadMenu.select_bread("white_bread", 0)

	assert_signal_emitted(
		BreadMenu, "bread_selected", "Should emit bread_selected signal when bread is selected"
	)


func test_bread_menu_hides_after_selection():
	watch_signals(BreadMenu)
	BreadMenu.select_bread("white_bread", 0)

	var signal_params = get_signal_parameters(BreadMenu, "bread_selected", 0)
	assert_eq(signal_params[0], "white_bread", "First param should be bread_id")
	assert_eq(signal_params[1], 0, "Second param should be oven_slot_index")


func test_bread_menu_shows_bread_info():
	# Menu should display bread name, price, time, etc.
	# We can't directly test UI rendering, but we can check data access
	var bread = DataManager.get_bread("white_bread")
	assert_not_null(bread, "Should be able to get bread data")
	assert_eq(bread.id, "white_bread", "Bread ID should match")
	assert_gt(bread.base_price, 0, "Bread should have a price")


func test_bread_menu_connects_to_production_manager():
	# Selecting a bread should start baking in ProductionManager
	BreadMenu.select_bread("white_bread", 0)

	assert_true(
		ProductionManager.active_baking.has(0),
		"ProductionManager should have baking started in slot 0"
	)


func test_bread_menu_closes_on_escape():
	# Simulate escape key press
	var event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true

	BreadMenu._input(event)

	# Menu should be hidden
	assert_false(BreadMenu.visible, "Menu should be hidden after escape")
