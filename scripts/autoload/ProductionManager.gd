extends Node

signal baking_started(slot_index, bread_id, duration)
signal baking_progressed(slot_index, progress_percent)
signal baking_finished(slot_index, bread_id)

var active_baking = {}  # slot_index: { bread_id, start_time, duration, fairy_id }
var max_slots = 2  # Starting slots


func _process(delta):
	var current_time = Time.get_unix_time_from_system()
	var finished_slots = []

	for slot_index in active_baking.keys():
		var data = active_baking[slot_index]
		var elapsed = current_time - data.start_time
		var progress = clamp(elapsed / data.duration, 0.0, 1.0)

		emit_signal("baking_progressed", slot_index, progress)

		if progress >= 1.0:
			finished_slots.append(slot_index)

	for slot_index in finished_slots:
		finish_baking(slot_index)


func start_baking(slot_index: int, bread_id: String, fairy_id: String = ""):
	if active_baking.has(slot_index):
		printerr("ProductionManager: Slot ", slot_index, " is already busy.")
		return

	var duration = calculate_production_time(bread_id, fairy_id)

	active_baking[slot_index] = {
		"bread_id": bread_id,
		"start_time": Time.get_unix_time_from_system(),
		"duration": duration,
		"fairy_id": fairy_id
	}

	emit_signal("baking_started", slot_index, bread_id, duration)
	print("ProductionManager: Started baking ", bread_id, " in slot ", slot_index)


func finish_baking(slot_index: int):
	var data = active_baking[slot_index]
	var bread_id = data.bread_id

	active_baking.erase(slot_index)
	emit_signal("baking_finished", slot_index, bread_id)

	# Add to inventory (via SalesManager later)
	if SalesManager:
		SalesManager.add_bread_to_inventory(bread_id)

	print("ProductionManager: Finished baking ", bread_id, " in slot ", slot_index)


func calculate_production_time(bread_id: String, fairy_id: String) -> float:
	if not DataManager or not DataManager.balance or not DataManager.balance.production:
		push_error("ProductionManager: DataManager.balance not loaded")
		return 10.0  # Default fallback time

	if not DataManager.balance.production.breads.has(bread_id):
		push_error("ProductionManager: Unknown bread_id: " + bread_id)
		return 10.0

	var base_data = DataManager.balance.production.breads[bread_id]
	var base_time = base_data.baseTime

	# TODO: Apply fairy and upgrade bonuses
	# Production time = Base * (1 - FairyBonus) * (1 - UpgradeBonus)

	return base_time


func is_slot_free(slot_index: int) -> bool:
	return not active_baking.has(slot_index)
