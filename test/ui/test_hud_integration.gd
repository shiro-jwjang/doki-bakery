extends GutTest

var HUD: CanvasLayer
var GameManager: Node


func before_each():
	# Clean up save files to prevent state pollution
	if FileAccess.file_exists("user://save.json"):
		DirAccess.remove_absolute("user://save.json")
	if FileAccess.file_exists("user://save_backup.json"):
		DirAccess.remove_absolute("user://save_backup.json")

	# Setup GameManager
	GameManager = load("res://scripts/autoload/game_manager.gd").new()
	add_child_autofree(GameManager)
	GameManager._ready()
	# Reset state to prevent test pollution
	GameManager.gold = 0
	GameManager.level = 1
	GameManager.experience = 0

	# Create HUD scene
	var scene = load("res://scenes/ui/hud.tscn")
	if scene:
		HUD = scene.instantiate()
	else:
		HUD = load("res://scripts/ui/hud.gd").new()

	add_child_autofree(HUD)

	# 의존성 주입
	HUD.set_game_manager(GameManager)

	# Wait for @onready to initialize
	await get_tree().process_frame
	HUD._ready()


func test_hud_displays_initial_gold():
	watch_signals(GameManager)
	var gold_label = HUD.get_node_or_null(
		"Control/PanelContainer/MarginContainer/HBoxContainer/GoldBox/GoldLabel"
	)

	assert_not_null(gold_label, "HUD should have GoldLabel")
	# Initial gold is 0
	assert_true(gold_label.text.contains("0"), "Gold label should show 0")


func test_hud_updates_when_gold_changes():
	watch_signals(GameManager)
	var gold_label = HUD.get_node_or_null(
		"Control/PanelContainer/MarginContainer/HBoxContainer/GoldBox/GoldLabel"
	)

	var initial_text = gold_label.text
	GameManager.add_gold(100)

	# Wait for signal to propagate
	await Engine.get_main_loop().process_frame
	assert_true(gold_label.text.contains("100"), "Gold label should update to 100")


func test_hud_displays_initial_level():
	var level_label = HUD.get_node_or_null(
		"Control/PanelContainer/MarginContainer/HBoxContainer/LevelBox/LevelLabel"
	)

	assert_not_null(level_label, "HUD should have LevelLabel")
	assert_true(level_label.text.contains("1"), "Level label should show 1")


func test_hud_updates_when_level_changes():
	watch_signals(GameManager)
	var level_label = HUD.get_node_or_null(
		"Control/PanelContainer/MarginContainer/HBoxContainer/LevelBox/LevelLabel"
	)

	GameManager.add_experience(100)  # Enough to level up

	assert_true(level_label.text.contains("2"), "Level label should update to 2")


func test_hud_connects_to_game_manager_signals():
	watch_signals(GameManager)

	GameManager.add_gold(50)
	assert_signal_emitted(
		GameManager, "gold_changed", "GameManager should emit gold_changed signal"
	)

	GameManager.add_experience(100)
	assert_signal_emitted(
		GameManager, "level_changed", "GameManager should emit level_changed signal"
	)


func test_hud_shows_time():
	var time_label = HUD.get_node_or_null(
		"Control/PanelContainer/MarginContainer/HBoxContainer/TimeBox/TimeLabel"
	)

	assert_not_null(time_label, "HUD should have TimeLabel")
	# Time format is "🕐 HH:MM"
	assert_true(time_label.text.contains("🕐"), "Time label should show clock icon")
