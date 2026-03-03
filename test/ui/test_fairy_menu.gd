extends GutTest

var FairyMenu: Control
var DataManager: Node
var GameManager: Node


func before_each():
	# Setup DataManager
	DataManager = load("res://scripts/autoload/data_manager.gd").new()
	add_child_autofree(DataManager)
	DataManager.load_all_data()

	# Setup GameManager
	GameManager = load("res://scripts/autoload/game_manager.gd").new()
	add_child_autofree(GameManager)
	GameManager._ready()

	# Create FairyMenu
	var scene = load("res://scenes/ui/FairyMenu.tscn")
	if scene:
		FairyMenu = scene.instantiate()
	else:
		FairyMenu = load("res://scripts/ui/fairy_menu.gd").new()

	add_child_autofree(FairyMenu)
	FairyMenu._ready()


func test_fairy_menu_has_close_button():
	var close_button = FairyMenu.get_node_or_null("Panel/VBoxContainer/Header/CloseButton")
	assert_not_null(close_button, "Should have CloseButton")


func test_fairy_menu_has_fairy_list():
	var fairy_list = FairyMenu.get_node_or_null("Panel/VBoxContainer/ScrollContainer/FairyList")
	assert_not_null(fairy_list, "Should have FairyList")


func test_fairy_menu_displays_unlocked_fairies():
	var fairies = DataManager.get_unlocked_fairies(3)
	assert_gt(fairies.size(), 0, "Should have fairies available at level 3")


func test_fairy_menu_shows_fairy_cost():
	var fairy = DataManager.get_fairy("strawberry_fairy")
	assert_not_null(fairy, "Should have strawberry_fairy")
	assert_gt(fairy.cost, 0, "Fairy should have a cost")


func test_fairy_menu_emits_hired_signal():
	watch_signals(FairyMenu)
	FairyMenu.hire_fairy("strawberry_fairy")

	assert_signal_emitted(FairyMenu, "fairy_hired", "Should emit fairy_hired signal")


func test_fairy_menu_checks_gold_before_hiring():
	GameManager.player_gold = 300

	# Strawberry fairy costs 500, should fail
	var result = FairyMenu.hire_fairy("strawberry_fairy")
	assert_false(result, "Should not afford fairy with insufficient gold")


func test_fairy_menu_checks_level_requirement():
	# Set level to 2
	GameManager.player_level = 2

	# Strawberry fairy requires level 3, should fail
	var result = FairyMenu.hire_fairy("strawberry_fairy")
	assert_false(result, "Should not hire fairy without meeting level requirement")
