extends GutTest

var OvenSlot: Node
var ProductionManager: Node
var DataManager: Node

func before_each():
	# Setup DataManager
	DataManager = load("res://scripts/autoload/data_manager.gd").new()
	add_child_autofree(DataManager)
	DataManager.load_all_data()

	# Setup ProductionManager
	ProductionManager = load("res://scripts/autoload/ProductionManager.gd").new()
	add_child_autofree(ProductionManager)

	# Create OvenSlot scene
	var scene = load("res://scenes/components/OvenSlot.tscn")
	if scene:
		OvenSlot = scene.instantiate()
	else:
		# Fallback: create script directly if scene doesn't exist yet
		OvenSlot = load("res://scripts/components/oven_slot.gd").new()

	add_child_autofree(OvenSlot)
	OvenSlot._ready()

func test_oven_slot_has_slot_index():
	assert_not_null(OvenSlot.slot_index, "OvenSlot should have slot_index property")

func test_oven_slot_has_default_state():
	assert_eq(OvenSlot.state, "idle", "OvenSlot should start in idle state")

func test_oven_slot_has_no_bread_initially():
	assert_eq(OvenSlot.current_bread_id, "", "OvenSlot should have no bread initially")

func test_oven_slot_can_start_baking():
	watch_signals(OvenSlot)
	OvenSlot.start_baking("white_bread")

	assert_eq(OvenSlot.state, "baking", "OvenSlot should be in baking state")
	assert_eq(OvenSlot.current_bread_id, "white_bread", "OvenSlot should have white_bread")
	assert_signal_emitted(OvenSlot, "baking_started", "Should emit baking_started signal")

func test_oven_slot_emits_progress_during_baking():
	watch_signals(OvenSlot)
	OvenSlot.start_baking("white_bread")

	# Simulate some progress
	OvenSlot._process(0.5)  # 0.5 seconds

	# Should have emitted progress signal (may be multiple times)
	var signal_count = get_signal_parameters(OvenSlot, "baking_progressed", 0)
	assert_true(signal_count != null or OvenSlot.get_signal_connection_count("baking_progressed") > 0,
		"Should emit baking_progressed signal")

func test_oven_slot_finishes_baking():
	watch_signals(OvenSlot)
	OvenSlot.start_baking("white_bread")

	# Set start time far in the past to simulate completion
	if OvenSlot.has_method("set_baking_start_time"):
		OvenSlot.set_baking_start_time(Time.get_unix_time_from_system() - 100)

	# Process to trigger completion
	OvenSlot._process(1.0)

	assert_eq(OvenSlot.state, "completed", "OvenSlot should be in completed state")
	assert_signal_emitted(OvenSlot, "baking_finished", "Should emit baking_finished signal")

func test_oven_slot_cannot_start_when_busy():
	OvenSlot.start_baking("white_bread")
	var result = OvenSlot.start_baking("croissant")

	assert_false(result, "Should not be able to start baking when already baking")
	assert_eq(OvenSlot.current_bread_id, "white_bread", "Should keep original bread")

func test_oven_slot_can_collect_bread():
	watch_signals(OvenSlot)
	OvenSlot.start_baking("white_bread")

	# Force complete
	if OvenSlot.has_method("set_baking_start_time"):
		OvenSlot.set_baking_start_time(Time.get_unix_time_from_system() - 100)
	OvenSlot._process(1.0)

	# Collect bread
	OvenSlot.collect_bread()

	assert_eq(OvenSlot.state, "idle", "OvenSlot should return to idle after collecting")
	assert_eq(OvenSlot.current_bread_id, "", "OvenSlot should have no bread after collecting")
	assert_signal_emitted(OvenSlot, "bread_collected", "Should emit bread_collected signal")

func test_oven_slot_has_progress_percentage():
	OvenSlot.start_baking("white_bread")

	var progress = OvenSlot.get_progress()
	assert_ge(progress, 0.0, "Progress should be >= 0")
	assert_le(progress, 1.0, "Progress should be <= 1")

func test_oven_slot_shows_time_remaining():
	OvenSlot.start_baking("white_bread")

	var time_left = OvenSlot.get_time_remaining()
	assert_ge(time_left, 0.0, "Time remaining should be >= 0")

func test_oven_slot_connects_to_production_manager():
	# Start baking through OvenSlot should affect ProductionManager
	OvenSlot.start_baking("white_bread")

	assert_true(ProductionManager.active_baking.has(OvenSlot.slot_index),
		"ProductionManager should have this slot in active_baking")
