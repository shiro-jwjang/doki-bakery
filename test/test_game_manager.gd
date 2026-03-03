extends GutTest

var GameManager: Node


func before_each():
	# Delete save file to prevent state pollution between tests
	var save_path = "user://save.json"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	var backup_path = "user://save_backup.json"
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)

	GameManager = load("res://scripts/autoload/game_manager.gd").new()
	add_child_autofree(GameManager)

	# Skip _ready() which loads save data - we want fresh state for each test
	# Reset all state to default values BEFORE any _ready() call
	GameManager.gold = 0
	GameManager.level = 1
	GameManager.experience = 0
	GameManager.total_breads_crafted = 0
	GameManager.total_gold_earned = 0


func test_game_manager_starts_with_zero_gold():
	assert_eq(GameManager.player_gold, 0, "Should start with 0 gold")


func test_game_manager_starts_at_level_1():
	assert_eq(GameManager.player_level, 1, "Should start at level 1")


func test_game_manager_starts_with_zero_experience():
	assert_eq(GameManager.player_experience, 0, "Should start with 0 experience")


func test_add_gold_increases_player_gold():
	watch_signals(GameManager)
	GameManager.add_gold(100)

	assert_eq(GameManager.player_gold, 100, "Should have 100 gold")
	assert_signal_emitted(GameManager, "gold_changed", "Should emit gold_changed signal")


func test_add_gold_multiple_times():
	GameManager.add_gold(50)
	GameManager.add_gold(30)

	assert_eq(GameManager.player_gold, 80, "Should have 80 gold")


func test_remove_gold_with_sufficient_gold():
	watch_signals(GameManager)
	GameManager.add_gold(100)
	var result = GameManager.remove_gold(40)

	assert_true(result, "Should successfully remove gold")
	assert_eq(GameManager.player_gold, 60, "Should have 60 gold left")
	assert_signal_emitted(GameManager, "gold_changed", "Should emit gold_changed signal")


func test_remove_gold_with_insufficient_fails():
	GameManager.add_gold(20)
	var result = GameManager.remove_gold(40)

	assert_false(result, "Should fail to remove gold")
	assert_eq(GameManager.player_gold, 20, "Should still have 20 gold")


func test_add_experience_increases_experience():
	watch_signals(GameManager)
	GameManager.add_experience(50)

	assert_eq(GameManager.player_experience, 50, "Should have 50 experience")
	assert_signal_emitted(GameManager, "experience_gained", "Should emit experience_gained signal")


func test_add_experience_triggers_level_up():
	watch_signals(GameManager)
	GameManager.add_experience(100)  # Enough for level 1 -> 2

	assert_eq(GameManager.player_level, 2, "Should be at level 2")
	assert_eq(GameManager.player_experience, 0, "Experience should reset to 0")
	assert_signal_emitted(GameManager, "level_changed", "Should emit level_changed signal")


func test_calculate_experience_needed_for_level_1():
	var needed = GameManager.calculate_experience_needed(1)
	assert_eq(needed, 100, "Level 1 should need 100 experience")


func test_calculate_experience_needed_for_level_2():
	var needed = GameManager.calculate_experience_needed(2)
	# Formula: 100 * (1.5 ^ 1) = 150
	assert_eq(needed, 150, "Level 2 should need 150 experience")


func test_calculate_experience_needed_for_level_3():
	var needed = GameManager.calculate_experience_needed(3)
	# Formula: 100 * (1.5 ^ 2) = 225
	assert_eq(needed, 225, "Level 3 should need 225 experience")


func test_level_up_emits_signal_with_correct_values():
	watch_signals(GameManager)
	GameManager.add_experience(100)

	var signal_params = get_signal_parameters(GameManager, "level_changed", 0)
	assert_eq(signal_params[0], 2, "First param should be new level (2)")
	assert_eq(signal_params[1], 0, "Second param should be new experience (0)")


func test_multiple_level_ups():
	GameManager.add_experience(300)  # Enough for 2 level ups

	assert_eq(GameManager.player_level, 3, "Should be at level 3")


func test_gold_changed_signal_emits_correct_value():
	watch_signals(GameManager)
	GameManager.add_gold(42)

	var signal_params = get_signal_parameters(GameManager, "gold_changed", 0)
	assert_eq(signal_params[0], 42, "Should emit new gold amount (42)")
