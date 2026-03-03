extends Control
class_name OvenSlot

## OvenSlot - 빵을 굽는 오븐 슬롯 컴포넌트

signal baking_started(bread_id, duration)
signal baking_progressed(progress_percent, time_remaining)
signal baking_finished(bread_id)
signal bread_collected(bread_id)
signal bread_selection_requested(slot_index)

@export var slot_index: int = 0

var state: String = "idle"  # idle, baking, completed
var current_bread_id: String = ""
var baking_start_time: float = 0.0
var baking_duration: float = 0.0

# 의존성 주입 (테스트용)
var _production_manager = null


func set_production_manager(production_manager: Node):
	_production_manager = production_manager


func _get_production_manager() -> Node:
	if _production_manager:
		return _production_manager
	return get_node_or_null("/root/ProductionManager")


@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var bread_icon: TextureRect = $VBoxContainer/BreadIcon
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var collect_button: Button = $VBoxContainer/CollectButton


func _ready() -> void:
	if start_button and not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
	if collect_button:
		if not collect_button.pressed.is_connected(_on_collect_pressed):
			collect_button.pressed.connect(_on_collect_pressed)
		collect_button.hide()

	_update_ui()


func _process(_delta: float) -> void:
	if state == "baking":
		var current_time = Time.get_unix_time_from_system()
		var elapsed = current_time - baking_start_time
		var progress = clamp(elapsed / baking_duration, 0.0, 1.0)

		baking_progressed.emit(progress, baking_duration - elapsed)

		if progress >= 1.0:
			_finish_baking()

		_update_ui()


func start_baking(bread_id: String) -> bool:
	if state != "idle":
		return false

	var pm = _get_production_manager()
	if not pm:
		push_error("OvenSlot: ProductionManager not found")
		return false

	if not pm.is_slot_free(slot_index):
		return false

	current_bread_id = bread_id
	baking_start_time = Time.get_unix_time_from_system()
	baking_duration = pm.calculate_production_time(bread_id, "")
	state = "baking"

	# Load bread icon
	var dm = get_node_or_null("/root/DataManager")
	if dm and bread_icon:
		var bread_data = dm.get_bread(bread_id)
		if bread_data and bread_data.icon and ResourceLoader.exists(bread_data.icon):
			bread_icon.texture = load(bread_data.icon)

	# Start baking in ProductionManager
	pm.start_baking(slot_index, bread_id)

	baking_started.emit(bread_id, baking_duration)
	print("OvenSlot %d: Started baking %s" % [slot_index, bread_id])

	_update_ui()
	return true


func _finish_baking() -> void:
	state = "completed"
	baking_finished.emit(current_bread_id)
	print("OvenSlot %d: Finished baking %s" % [slot_index, current_bread_id])

	_update_ui()


func collect_bread() -> void:
	if state != "completed":
		return

	var bread_id = current_bread_id
	current_bread_id = ""
	state = "idle"

	bread_collected.emit(bread_id)
	print("OvenSlot %d: Collected %s" % [slot_index, bread_id])

	_update_ui()


func get_progress() -> float:
	if state != "baking":
		return 1.0 if state == "completed" else 0.0

	var current_time = Time.get_unix_time_from_system()
	var elapsed = current_time - baking_start_time
	return clamp(elapsed / baking_duration, 0.0, 1.0)


func get_time_remaining() -> float:
	if state != "baking":
		return 0.0

	var current_time = Time.get_unix_time_from_system()
	var elapsed = current_time - baking_start_time
	return max(0.0, baking_duration - elapsed)


func set_baking_start_time(time: float) -> void:
	baking_start_time = time


func _on_start_pressed() -> void:
	# This will be connected to BreadMenu to select bread
	# For now, emit a signal to request bread selection
	emit_signal("bread_selection_requested", slot_index)


func _on_collect_pressed() -> void:
	collect_bread()


func _update_ui() -> void:
	if not status_label:
		return

	match state:
		"idle":
			if status_label:
				status_label.text = "비어있음"
			if progress_bar:
				progress_bar.value = 0
			if start_button:
				start_button.show()
				start_button.text = "시작"
			if collect_button:
				collect_button.hide()
			if bread_icon:
				bread_icon.hide()

		"baking":
			var progress = get_progress() * 100
			if status_label:
				status_label.text = "굽는 중... %.0f%%" % progress
			if progress_bar:
				progress_bar.value = progress
			if start_button:
				start_button.hide()
			if collect_button:
				collect_button.hide()
			if bread_icon:
				bread_icon.show()

		"completed":
			if status_label:
				status_label.text = "완성!"
			if progress_bar:
				progress_bar.value = 100
			if start_button:
				start_button.hide()
			if collect_button:
				collect_button.show()
				collect_button.text = "수집"
			if bread_icon:
				bread_icon.show()
