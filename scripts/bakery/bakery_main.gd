extends Control
class_name BakeryMain

## 메인 베이커리 화면

@onready var bread_select_button: Button = $BottomBar/BreadSelectButton
@onready var shop_button: Button = $BottomBar/ShopButton
@onready var fairy_button: Button = $BottomBar/FairyButton

@onready var oven_slot_0: OvenSlot = $GameArea/LeftPanel/OvenSlots/OvenSlot0
@onready var oven_slot_1: OvenSlot = $GameArea/LeftPanel/OvenSlots/OvenSlot1
@onready var display_slot_0: DisplaySlot = $GameArea/RightPanel/DisplaySlots/DisplaySlot0
@onready var display_slot_1: DisplaySlot = $GameArea/RightPanel/DisplaySlots/DisplaySlot1

@onready var bread_menu: Control = $MenuContainer/BreadMenu
@onready var upgrade_menu: Control = $MenuContainer/UpgradeMenu
@onready var fairy_menu: Control = $MenuContainer/FairyMenu

var selected_oven_slot: int = -1

# 의존성 주입 (테스트용)
var _game_manager = null


func set_game_manager(game_manager: Node):
	_game_manager = game_manager


func _get_game_manager() -> Node:
	if _game_manager:
		return _game_manager
	return get_node_or_null("/root/GameManager")


func _ready() -> void:
	bread_select_button.pressed.connect(_on_bread_select_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	fairy_button.pressed.connect(_on_fairy_pressed)

	# Connect OvenSlot signals
	oven_slot_0.baking_started.connect(_on_baking_started)
	oven_slot_0.baking_finished.connect(_on_baking_finished)
	oven_slot_0.bread_collected.connect(_on_bread_collected)

	oven_slot_1.baking_started.connect(_on_baking_started)
	oven_slot_1.baking_finished.connect(_on_baking_finished)
	oven_slot_1.bread_collected.connect(_on_bread_collected)

	# Connect DisplaySlot signals
	display_slot_0.bread_sold.connect(_on_bread_sold)
	display_slot_1.bread_sold.connect(_on_bread_sold)


func _on_bread_select_pressed() -> void:
	print("🍞 빵 선택 메뉴 열기")
	bread_menu.show()
	# TODO: Open BreadMenu with bread selection


func _on_shop_pressed() -> void:
	print("🛒 상점 메뉴 열기")
	upgrade_menu.show()
	# TODO: Open UpgradeMenu


func _on_fairy_pressed() -> void:
	print("🧚 요정 메뉴 열기")
	fairy_menu.show()
	# TODO: Open FairyMenu


func _on_baking_started(bread_id: String, _duration: float) -> void:
	print("BakeryMain: Baking started for %s" % bread_id)


func _on_baking_finished(bread_id: String) -> void:
	print("BakeryMain: Baking finished for %s" % bread_id)
	# Auto-collect to first available display slot
	_add_to_display_slot(bread_id)


func _on_bread_collected(bread_id: String) -> void:
	print("BakeryMain: Bread collected %s" % bread_id)


func _on_bread_sold(bread_id: String, gold_earned: float) -> void:
	print("BakeryMain: Bread sold %s for %d gold" % [bread_id, gold_earned])
	var gm = _get_game_manager()
	if gm:
		gm.add_gold(int(gold_earned))


func _add_to_display_slot(bread_id: String) -> void:
	# Try to add to existing slot with same bread, or first empty slot
	var display_slots = [display_slot_0, display_slot_1]

	for slot in display_slots:
		if slot.current_bread_id == bread_id and slot.state == "displayed":
			slot.quantity += 1
			slot._update_ui()
			print("BakeryMain: Added %s to existing display slot" % bread_id)
			return

	# Find first empty slot
	for slot in display_slots:
		if slot.state == "empty":
			slot.display_bread(bread_id, 1)
			print("BakeryMain: Added %s to new display slot" % bread_id)
			return

	print("BakeryMain: No available display slots for %s" % bread_id)


func start_baking_in_slot(slot_index: int, bread_id: String) -> void:
	match slot_index:
		0:
			oven_slot_0.start_baking(bread_id)
		1:
			oven_slot_1.start_baking(bread_id)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Close all menus
		bread_menu.hide()
		upgrade_menu.hide()
		fairy_menu.hide()
