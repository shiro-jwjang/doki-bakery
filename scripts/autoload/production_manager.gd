extends Node

signal baking_started(slot_index, bread_id, duration)
signal baking_progressed(slot_index, progress_percent)
signal baking_finished(slot_index, bread_id)

var active_baking = {}  # slot_index: { bread_id, start_time, duration, fairy_id }
var max_slots = 2  # Starting slots

# 의존성 주입 (테스트용)
var _sales_manager = null
var _save_manager = null
var _data_manager = null


func set_sales_manager(sales_manager: Node):
	_sales_manager = sales_manager


func set_save_manager(save_manager: Node):
	_save_manager = save_manager


func set_data_manager(data_manager: Node):
	_data_manager = data_manager


func _get_sales_manager() -> Node:
	if _sales_manager:
		return _sales_manager
	return get_node_or_null("/root/SalesManager")


func _get_save_manager() -> Node:
	if _save_manager:
		return _save_manager
	return get_node_or_null("/root/SaveManager")


func _get_data_manager() -> Node:
	if _data_manager:
		return _data_manager
	return get_node_or_null("/root/DataManager")


func _ready():
	if "--check-only" in OS.get_cmdline_args() or "--script-check" in OS.get_cmdline_args():
		return

	# Wait for SaveManager to be ready and load data
	call_deferred("_check_offline_progress")


func _check_offline_progress():
	var save_mgr = _get_save_manager()
	if not save_mgr or not save_mgr.current_save:
		return

	var current_time = Time.get_unix_time_from_system()
	var offline_baking = save_mgr.current_save.active_baking.duplicate()

	if offline_baking.is_empty():
		return

	print("ProductionManager: Checking offline progress for ", offline_baking.size(), " slots")

	for slot_key in offline_baking.keys():
		var slot_index = int(slot_key)
		var data = offline_baking[slot_key]

		# We need duration to check if it finished
		# If duration is not in save, we recalculate it
		var bread_id = data.get("bread_id", data.get("id"))  # handle both old and new keys
		var start_time = data.get("start_time", 0.0)
		var fairy_id = data.get("fairy_id", "")
		var duration = data.get("duration", calculate_production_time(bread_id, fairy_id))

		var elapsed = current_time - start_time
		if elapsed >= duration:
			# Finished offline
			print(
				"ProductionManager: Offline baking finished for ", bread_id, " in slot ", slot_index
			)
			# Add to inventory
			var sales = _get_sales_manager()
			if sales:
				sales.add_bread_to_inventory(bread_id)

			# Experience
			if GameManager:
				GameManager.add_experience(int(duration * 5))

			# Remove from save
			save_mgr.current_save.active_baking.erase(slot_key)
		else:
			# Still baking, resume in memory
			active_baking[slot_index] = {
				"bread_id": bread_id,
				"start_time": start_time,
				"duration": duration,
				"fairy_id": fairy_id
			}
			print("ProductionManager: Resuming baking for ", bread_id, " in slot ", slot_index)

	save_mgr.save_game()


func _process(_delta):
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
	var start_time = Time.get_unix_time_from_system()

	active_baking[slot_index] = {
		"bread_id": bread_id, "start_time": start_time, "duration": duration, "fairy_id": fairy_id
	}

	# Save state for offline progress
	var save_mgr = _get_save_manager()
	if save_mgr and save_mgr.current_save:
		save_mgr.current_save.active_baking[str(slot_index)] = {
			"id": bread_id, "start_time": start_time, "duration": duration, "fairy_id": fairy_id
		}
		save_mgr.save_game()

	emit_signal("baking_started", slot_index, bread_id, duration)
	print("ProductionManager: Started baking ", bread_id, " in slot ", slot_index)


func finish_baking(slot_index: int):
	var data = active_baking[slot_index]
	var bread_id = data.bread_id

	active_baking.erase(slot_index)

	# Remove from save state
	var save_mgr = _get_save_manager()
	if save_mgr and save_mgr.current_save:
		save_mgr.current_save.active_baking.erase(str(slot_index))
		save_mgr.save_game()

	emit_signal("baking_finished", slot_index, bread_id)

	# Add to inventory (via SalesManager)
	var sales = _get_sales_manager()
	if sales:
		sales.add_bread_to_inventory(bread_id)

	# 경험치 추가 (생산 완료 시)
	if GameManager:
		GameManager.add_experience(int(data.duration * 5))  # 생산 시간당 5 XP

	print("ProductionManager: Finished baking ", bread_id, " in slot ", slot_index)


func calculate_production_time(bread_id: String, fairy_id: String) -> float:
	var data_mgr = _get_data_manager()
	if not data_mgr or not data_mgr.balance or not data_mgr.balance.production:
		push_error("ProductionManager: DataManager.balance not loaded")
		return 10.0  # Default fallback time

	if not data_mgr.balance.production.breads.has(bread_id):
		push_error("ProductionManager: Unknown bread_id: " + bread_id)
		return 10.0

	var base_data = data_mgr.balance.production.breads[bread_id]
	var base_time = base_data.baseTime

	# 업그레이드 보너스 적용 (오븐 속도)
	var upgrade_bonus = 0.0
	var save_mgr = _get_save_manager()
	if save_mgr and save_mgr.current_save.upgrade_levels.has("oven_speed"):
		var oven_speed_level = save_mgr.current_save.upgrade_levels["oven_speed"]
		upgrade_bonus = oven_speed_level * 0.1  # 레벨당 10% 감소

	# 요정 보너스 적용 (분유 요정: 생산 속도 +5%)
	var fairy_bonus = 0.0
	if fairy_id != "" and save_mgr and save_mgr.current_save.owned_fairies.has(fairy_id):
		if fairy_id == "fairy_flour":
			fairy_bonus = 0.05

	# 최종 시간 = 기본 시간 * (1 - 업그레이드 보너스) * (1 - 요정 보너스)
	var final_time = base_time * (1.0 - upgrade_bonus) * (1.0 - fairy_bonus)
	return max(final_time, 1.0)  # 최소 1초


func is_slot_free(slot_index: int) -> bool:
	return not active_baking.has(slot_index)


## 빵 ID로 현재 생산 중인지 확인 (ProductionPanel용)
func is_producing(bread_id: String) -> bool:
	for slot_index in active_baking.keys():
		if active_baking[slot_index].bread_id == bread_id:
			return true
	return false


## 빵 ID로 남은 시간 반환 (ProductionPanel용)
func get_remaining_time(bread_id: String) -> float:
	for slot_index in active_baking.keys():
		if active_baking[slot_index].bread_id == bread_id:
			var data = active_baking[slot_index]
			var current_time = Time.get_unix_time_from_system()
			var elapsed = current_time - data.start_time
			return max(0.0, data.duration - elapsed)
	return 0.0


## 빵 ID로 생산 시작 - 빈 슬롯 자동 할당 (ProductionPanel용)
func start_production(bread_id: String, fairy_id: String = "") -> bool:
	# 이미 생산 중인지 확인
	if is_producing(bread_id):
		printerr("ProductionManager: ", bread_id, " is already being produced.")
		return false

	# 빈 슬롯 찾기
	for i in range(max_slots):
		if is_slot_free(i):
			start_baking(i, bread_id, fairy_id)
			return true

	printerr("ProductionManager: No free slots available")
	return false
