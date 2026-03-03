extends Control
class_name UpgradeMenu

## UpgradeMenu - 업그레이드를 구매하는 UI

signal upgrade_purchased(upgrade_id: String)

@onready var close_button: Button = $Panel/VBoxContainer/Header/CloseButton
@onready var upgrade_list_container: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/UpgradeList

var upgrade_levels: Dictionary = {}  # upgrade_id -> current_level


func _ready() -> void:
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	_load_upgrade_levels()
	_populate_upgrade_list()


func _load_upgrade_levels() -> void:
	# Load from SaveManager
	if SaveManager and SaveManager.current_save:
		upgrade_levels = SaveManager.current_save.upgrade_levels.duplicate()
	else:
		# Initialize with level 0
		for upgrade_id in DataManager.upgrades.keys():
			upgrade_levels[upgrade_id] = 0


func purchase_upgrade(upgrade_id: String) -> bool:
	if not GameManager:
		push_error("UpgradeMenu: GameManager not found")
		return false

	var upgrade = DataManager.get_upgrade(upgrade_id)
	if not upgrade:
		push_error("UpgradeMenu: Unknown upgrade %s" % upgrade_id)
		return false

	var current_level = upgrade_levels.get(upgrade_id, 0)
	if current_level >= upgrade.max_level:
		print("UpgradeMenu: Upgrade %s is at max level" % upgrade_id)
		return false

	var cost = _calculate_cost(upgrade, current_level)
	if GameManager.gold < cost:
		print(
			(
				"UpgradeMenu: Not enough gold for %s (need %d, have %d)"
				% [upgrade_id, cost, GameManager.gold]
			)
		)
		return false

	# Purchase
	GameManager.spend_gold(cost)
	upgrade_levels[upgrade_id] = current_level + 1

	# SaveManager에도 저장
	if SaveManager and SaveManager.current_save:
		SaveManager.current_save.upgrade_levels[upgrade_id] = upgrade_levels[upgrade_id]
		SaveManager.save_game()

	upgrade_purchased.emit(upgrade_id)

	print("UpgradeMenu: Purchased %s to level %d" % [upgrade_id, upgrade_levels[upgrade_id]])

	# Refresh UI
	_populate_upgrade_list()
	return true


func _calculate_cost(upgrade: UpgradeData, level: int) -> int:
	return int(upgrade.base_cost * pow(upgrade.cost_multiplier, level))


func _populate_upgrade_list() -> void:
	if not upgrade_list_container:
		return

	# Clear existing items
	for child in upgrade_list_container.get_children():
		child.queue_free()

	for upgrade_id in DataManager.upgrades.keys():
		var upgrade = DataManager.get_upgrade(upgrade_id)
		var upgrade_item = _create_upgrade_item(upgrade)
		upgrade_list_container.add_child(upgrade_item)


func _create_upgrade_item(upgrade_data: UpgradeData) -> Control:
	var container = VBoxContainer.new()

	# Header
	var header = HBoxContainer.new()
	container.add_child(header)

	var name_label = Label.new()
	name_label.text = upgrade_data.name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	var level_label = Label.new()
	var current_level = upgrade_levels.get(upgrade_data.id, 0)
	level_label.text = "Lv.%d/%d" % [current_level, upgrade_data.max_level]
	header.add_child(level_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = upgrade_data.description
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	container.add_child(desc_label)

	# Cost and Purchase button
	var footer = HBoxContainer.new()
	container.add_child(footer)

	var cost_label = Label.new()
	var cost = _calculate_cost(upgrade_data, current_level)
	cost_label.text = "%d골드" % cost
	footer.add_child(cost_label)

	var buy_button = Button.new()
	if current_level >= upgrade_data.max_level:
		buy_button.text = "MAX"
		buy_button.disabled = true
	else:
		buy_button.text = "구매"
		buy_button.pressed.connect(_on_buy_button_pressed.bind(upgrade_data.id))
	footer.add_child(buy_button)

	return container


func _on_buy_button_pressed(upgrade_id: String) -> void:
	purchase_upgrade(upgrade_id)


func _on_close_pressed() -> void:
	hide()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()
