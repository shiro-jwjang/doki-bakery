extends GutTest

var DataManager: Node

func before_each():
	DataManager = load("res://scripts/autoload/data_manager.gd").new()
	add_child_autofree(DataManager)
	DataManager.load_all_data()

func test_balance_data_is_loaded():
	assert_not_null(DataManager.balance, "Balance data should be loaded")
	assert_not_null(DataManager.balance.production, "Production config should exist")
	assert_not_null(DataManager.balance.pricing, "Pricing config should exist")

func test_balance_base_values():
	assert_eq(DataManager.balance.production.baseTimeMultiplier, 0.2, "Base time multiplier should be 0.2")
	assert_eq(DataManager.balance.production.fairyLevelBonus, 0.05, "Fairy level bonus should be 0.05")
	assert_eq(DataManager.balance.pricing.ingredientMultiplier, 2.5, "Ingredient multiplier should be 2.5")

func test_balance_bread_configs():
	assert_not_null(DataManager.balance.production.breads, "Bread configs should exist")
	assert_true(DataManager.balance.production.breads.has("croissant"), "Should have croissant config")
	assert_true(DataManager.balance.production.breads.has("cake"), "Should have cake config")

func test_balance_croissant_config():
	var croissant = DataManager.balance.production.breads.croissant
	assert_eq(croissant.baseTime, 5, "Croissant base time should be 5")
	assert_eq(croissant.ingredientCost, 10, "Croissant ingredient cost should be 10")
	assert_eq(croissant.basePrice, 5, "Croissant base price should be 5")

func test_balance_upgrade_configs():
	assert_not_null(DataManager.balance.upgrades, "Upgrade configs should exist")
	assert_eq(DataManager.balance.upgrades.costMultiplier, 1.5, "Upgrade cost multiplier should be 1.5")
	assert_eq(DataManager.balance.upgrades.baseCosts.oven, 100, "Oven base cost should be 100")

func test_balance_offline_configs():
	assert_not_null(DataManager.balance.offline, "Offline config should exist")
	assert_eq(DataManager.balance.offline.rewardMultiplier, 0.5, "Offline reward multiplier should be 0.5")
	assert_eq(DataManager.balance.offline.maxOfflineHours, 24, "Max offline hours should be 24")

func test_balance_milestones():
	assert_not_null(DataManager.balance.milestones, "Milestones should exist")
	assert_true(DataManager.balance.milestones.has("5min"), "Should have 5min milestone")
	assert_eq(DataManager.balance.milestones["5min"].target, 100, "5min milestone target should be 100")
