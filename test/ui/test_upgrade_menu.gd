extends GutTest

var UpgradeMenu: Control
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

	# Create UpgradeMenu
	var scene = load("res://scenes/ui/UpgradeMenu.tscn")
	if scene:
		UpgradeMenu = scene.instantiate()
	else:
		UpgradeMenu = load("res://scripts/ui/upgrade_menu.gd").new()

	add_child_autofree(UpgradeMenu)
	UpgradeMenu._ready()


func test_upgrade_menu_has_close_button():
	var close_button = UpgradeMenu.get_node_or_null("Panel/VBoxContainer/Header/CloseButton")
	assert_not_null(close_button, "Should have CloseButton")


func test_upgrade_menu_has_upgrade_list():
	var upgrade_list = UpgradeMenu.get_node_or_null(
		"Panel/VBoxContainer/ScrollContainer/UpgradeList"
	)
	assert_not_null(upgrade_list, "Should have UpgradeList")


func test_upgrade_menu_displays_available_upgrades():
	var upgrades = DataManager.upgrades
	assert_gt(upgrades.size(), 0, "Should have upgrades available")


func test_upgrade_menu_calculates_cost():
	var upgrade = DataManager.get_upgrade("oven_speed")
	assert_not_null(upgrade, "Should have oven_speed upgrade")

	# Level 1 cost
	var cost = upgrade.base_cost
	assert_gt(cost, 0, "Upgrade should have a cost")


func test_upgrade_menu_emits_purchased_signal():
	watch_signals(UpgradeMenu)
	UpgradeMenu.purchase_upgrade("oven_speed")

	assert_signal_emitted(UpgradeMenu, "upgrade_purchased", "Should emit upgrade_purchased signal")


func test_upgrade_menu_checks_gold_before_purchase():
	# Clean state - reset upgrade levels to ensure clean test
	UpgradeMenu.upgrade_levels = {}
	for upgrade_id in DataManager.upgrades.keys():
		UpgradeMenu.upgrade_levels[upgrade_id] = 0

	# UpgradeMenu는 autoload GameManager.gold를 참조하므로 autoload에 설정
	var autoload_gm = get_node_or_null("/root/GameManager")
	if autoload_gm:
		# autoload가 있으면 거기에 설정
		autoload_gm.gold = 50
	else:
		# autoload가 없으면 로컬 GameManager 사용
		GameManager.gold = 50

	# Oven speed upgrade costs 100 at level 0, should fail
	var result = UpgradeMenu.purchase_upgrade("oven_speed")
	assert_false(result, "Should not afford upgrade with insufficient gold (have 50, need 100)")
