extends Control
class_name BreadMenu

## BreadMenu - 빵을 선택하고 제작을 시작하는 UI

signal bread_selected(bread_id: String, oven_slot_index: int)

@onready var panel: Panel = $Panel
@onready var bread_list_container: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/BreadList
@onready var close_button: Button = $Panel/VBoxContainer/Header/CloseButton
@onready var level_label: Label = $Panel/VBoxContainer/Header/LevelLabel

var target_oven_slot: int = -1


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	_populate_bread_list()


func show_for_slot(slot_index: int) -> void:
	target_oven_slot = slot_index
	show()
	_populate_bread_list()


func select_bread(bread_id: String, oven_slot_index: int) -> void:
	if not ProductionManager:
		push_error("BreadMenu: ProductionManager not found")
		return

	var slot = oven_slot_index
	if not ProductionManager.is_slot_free(slot):
		print("BreadMenu: Slot %d is busy" % slot)
		return

	# Start baking
	ProductionManager.start_baking(slot, bread_id)
	bread_selected.emit(bread_id, slot)

	print("BreadMenu: Selected %s for slot %d" % [bread_id, slot])
	hide()


func _populate_bread_list() -> void:
	if not bread_list_container:
		return

	# Clear existing items
	for child in bread_list_container.get_children():
		child.queue_free()

	# Get current level
	var current_level = 1
	if GameManager:
		current_level = GameManager.player_level

	if level_label:
		level_label.text = "Lv.%d" % current_level

	# Get unlocked breads
	var unlocked_breads = DataManager.get_unlocked_breads(current_level)

	for bread in unlocked_breads:
		var bread_item = _create_bread_item(bread)
		bread_list_container.add_child(bread_item)


func _create_bread_item(bread_data: BreadData) -> Control:
	var container = HBoxContainer.new()

	# Icon
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	container.add_child(icon)

	# Info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label = Label.new()
	name_label.text = bread_data.name
	info_vbox.add_child(name_label)

	var details_label = Label.new()
	var time = (
		ProductionManager.calculate_production_time(bread_data.id, "")
		if ProductionManager
		else 10.0
	)
	var price = bread_data.base_price
	details_label.text = "%d초 | %d골드" % [int(time), price]
	details_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info_vbox.add_child(details_label)

	container.add_child(info_vbox)

	# Bake button
	var bake_button = Button.new()
	bake_button.text = "제작"
	bake_button.pressed.connect(_on_bake_button_pressed.bind(bread_data.id))
	container.add_child(bake_button)

	return container


func _on_bake_button_pressed(bread_id: String) -> void:
	select_bread(bread_id, target_oven_slot if target_oven_slot >= 0 else 0)


func _on_close_pressed() -> void:
	hide()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()
