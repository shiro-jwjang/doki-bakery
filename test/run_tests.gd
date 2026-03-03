extends SceneTree


func _init():
	# Create a parent node for GUT
	var test_parent = Node.new()
	root.add_child(test_parent)

	# Create GUT instance
	var Gut = load("res://addons/gut/gut.gd")
	var gut = Gut.new()

	# Configure GUT
	gut.add_children_to = test_parent
	gut.include_subdirectories = true  # Include test files in subdirectories
	test_parent.add_child(gut)

	# Add test directories
	gut.add_directory("res://test", "test_", ".gd")

	# Run tests and wait for completion
	gut.end_run.connect(_on_tests_finished.bind(gut))
	gut.test_scripts(false)


func _on_tests_finished(gut):
	# Print summary
	var passed = gut.get_pass_count()
	var failed = gut.get_fail_count()
	var pending = gut.get_pending_count()

	print("\n" + "=".repeat(50))
	print("Test Results:")
	print("  Passed:  ", passed)
	print("  Failed:  ", failed)
	print("  Pending: ", pending)
	print("=".repeat(50))

	# Exit with appropriate code
	var exit_code = 0 if failed == 0 else 1
	quit(exit_code)
