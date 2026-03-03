extends Node2D

## Main 게임 씬

const SLOT_SCENE := preload("res://scenes/components/DisplaySlot.tscn")

@onready var display_stand: GridContainer = $UILayer/DisplayStand
@onready var hud: CanvasLayer = $HUD
@onready var ui_layer: CanvasLayer = $UILayer
@onready var fairy_menu: Control = $UILayer/FairyMenu
@onready var upgrade_menu: Control = $UILayer/UpgradeMenu

var fairy_btn: Button = null
var upgrade_btn: Button = null
var _display_slots: Array[DisplaySlot] = []


func _ready() -> void:
	# Sidebar 버튼은 UILayer 아래에서 찾기
	var sidebar = ui_layer.get_node_or_null("Sidebar")
	if sidebar:
		fairy_btn = sidebar.get_node_or_null("FairyBtn")
		upgrade_btn = sidebar.get_node_or_null("UpgradeBtn")

		if fairy_btn:
			fairy_btn.pressed.connect(_on_fairy_btn_pressed)
		if upgrade_btn:
			upgrade_btn.pressed.connect(_on_upgrade_btn_pressed)

	# 진열대 슬롯 초기화
	if display_stand:
		for child in display_stand.get_children():
			if child is DisplaySlot:
				_display_slots.append(child)

	# 생산 완료 신호 연결
	var pm = get_node_or_null("/root/ProductionManager")
	if pm:
		if not pm.baking_finished.is_connected(_on_baking_finished):
			pm.baking_finished.connect(_on_baking_finished)

	# 메뉴 닫기 신호 연결 (Signal check removed for brevity, assume they exist or use has_signal)
	if fairy_menu and fairy_menu.has_signal("close_requested"):
		fairy_menu.close_requested.connect(_close_all_menus)
	if upgrade_menu and upgrade_menu.has_signal("close_requested"):
		upgrade_menu.close_requested.connect(_close_all_menus)

	# 업그레이드 신호 연결
	if upgrade_menu:
		if not upgrade_menu.upgrade_purchased.is_connected(_on_upgrade_purchased):
			upgrade_menu.upgrade_purchased.connect(_on_upgrade_purchased)

	# 초기 진열대 상태 설정
	_refresh_display_slots()

	# HUD 초기화
	call_deferred("_init_hud")


func _on_upgrade_purchased(upgrade_id: String) -> void:
	if upgrade_id == "display_capacity":
		_refresh_display_slots()


func _refresh_display_slots() -> void:
	if not display_stand:
		return

	# 현재 업그레이드 레벨 확인
	var level = 0
	if SaveManager and SaveManager.current_save:
		level = SaveManager.current_save.upgrade_levels.get("display_capacity", 0)

	# 기본 슬롯 수 (3) + 추가 슬롯 (level)
	var total_slots = 3 + level

	# 현재 자식들 정리 및 리스트 업데이트
	_display_slots.clear()
	var current_children = display_stand.get_children()

	# 기존 슬롯들 활성화/비활성화
	for i in range(current_children.size()):
		if current_children[i] is DisplaySlot:
			if i < total_slots:
				current_children[i].show()
				current_children[i].slot_index = i
				_display_slots.append(current_children[i])
			else:
				current_children[i].hide()

	# 부족한 슬롯 추가 생성 (필요할 경우)
	while _display_slots.size() < total_slots:
		var new_slot = SLOT_SCENE.instantiate()
		var new_index = _display_slots.size()
		new_slot.slot_index = new_index
		display_stand.add_child(new_slot)
		_display_slots.append(new_slot)
		print("Main: Expanded display with slot %d" % new_index)


func _on_baking_finished(slot_index: int, bread_id: String) -> void:
	print("Main: Baking finished in slot %d for %s" % [slot_index, bread_id])
	_add_to_display_slot(bread_id)


func _add_to_display_slot(bread_id: String) -> void:
	# 1. 같은 종류의 빵이 이미 진열된 슬롯 찾기
	for slot in _display_slots:
		if slot.state == "displayed" and slot.current_bread_id == bread_id:
			slot.quantity += 1
			slot._update_ui()
			print("Main: Added %s to existing display slot %d" % [bread_id, slot.slot_index])
			return

	# 2. 비어있는 슬롯 찾기
	for slot in _display_slots:
		if slot.state == "empty":
			slot.display_bread(bread_id, 1)
			print("Main: Added %s to new display slot %d" % [bread_id, slot.slot_index])
			return

	print("Main: No available display slots for %s" % bread_id)


func _init_hud() -> void:
	if hud and hud.has_method("_initialize_hud"):
		hud._initialize_hud()


func _on_fairy_btn_pressed() -> void:
	_close_all_menus()
	fairy_menu.show()


func _on_upgrade_btn_pressed() -> void:
	_close_all_menus()
	upgrade_menu.show()


func _close_all_menus() -> void:
	if fairy_menu:
		fairy_menu.hide()
	if upgrade_menu:
		upgrade_menu.hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close_all_menus()
