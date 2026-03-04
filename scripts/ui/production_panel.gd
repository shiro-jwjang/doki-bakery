extends CanvasLayer
class_name ProductionPanel

## 빵 생산 패널 - 슬롯 클릭 시 빵 메뉴를 열고 제작 상태를 표시합니다.

@onready var slot1: Button = $Control/MarginContainer/VBoxContainer/HBoxContainer/Slot1
@onready var slot2: Button = $Control/MarginContainer/VBoxContainer/HBoxContainer/Slot2
@onready var slot3: Button = $Control/MarginContainer/VBoxContainer/HBoxContainer/Slot3
@onready var slot4: Button = $Control/MarginContainer/VBoxContainer/HBoxContainer/Slot4
@onready var slot5: Button = $Control/MarginContainer/VBoxContainer/HBoxContainer/Slot5

var _slots: Array[Button] = []
var _production_manager: Node = null

# 기본 아이콘 (비어있을 때)
const EMPTY_ICON = preload("res://icon.svg")

func _ready() -> void:
	_slots = [slot1, slot2, slot3, slot4, slot5]

	# 버튼 신호 연결
	for i in range(_slots.size()):
		if not _slots[i].pressed.is_connected(_on_slot_pressed):
			_slots[i].pressed.connect(_on_slot_pressed.bind(i))

	_update_slots()


func _process(_delta: float) -> void:
	# 매 프레임 업데이트 (남은 시간 표시용)
	_update_slots()


func _update_slots() -> void:
	var pm = _get_production_manager()
	var gm = _get_game_manager()
	var dm = _get_data_manager()

	# pm이나 gm이 없으면 업데이트를 중단하지 않고, 에러 로그를 남기거나 최소한의 표시만 합니다.
	if not pm: return

	# ProductionManager에서 현재 상태 가져오기
	var active_baking = pm.active_baking # {slot_index: {bread_id, start_time, duration, fairy_id}}
	var max_slots = pm.max_slots

	for i in range(_slots.size()):
		var label = _slots[i].get_node_or_null("VBox/Label")
		var icon_rect = _slots[i].get_node_or_null("VBox/Icon")

		if not label or not icon_rect: continue

		# 1. 슬롯 잠금 여부 (pm.max_slots 기준)
		if i >= max_slots:
			label.text = "잠김\n(업그레이드)"
			icon_rect.texture = null # 잠긴 슬롯은 아이콘 제거
			icon_rect.modulate = Color(0.2, 0.2, 0.2, 0.5)
			_slots[i].disabled = true
			continue

		_slots[i].disabled = false
		icon_rect.modulate = Color.WHITE

		# 2. 제작 상태 확인
		if active_baking.has(i):
			# 제작 중 또는 완료
			var data = active_baking[i]
			var bread_id = data.bread_id
			var elapsed = Time.get_unix_time_from_system() - data.start_time
			var remaining = max(0.0, data.duration - elapsed)

			# 빵 이름 및 아이콘 가져오기
			var bread_name = bread_id
			if dm and dm.has_method("get_bread"):
				var b_data = dm.get_bread(bread_id)
				if b_data:
					bread_name = b_data.name
					if b_data.icon and ResourceLoader.exists(b_data.icon):
						icon_rect.texture = Load(b_data.icon)

			if remaining > 0:
				label.text = "%s\n🔥 %.1f초" % [bread_name, remaining]
				# 생산 중 indicator: 주황색 틴트
				_slots[i].modulate = Color(1.0, 0.7, 0.3, 1.0)
			else:
				label.text = "%s\n완료!" % bread_name
				_slots[i].modulate = Color.WHITE
		else:
			# 3. 비어있는 상태 (확실히 초기화)
			label.text = "슬롯 %d\n(비어있음)" % (i + 1)
			icon_rect.texture = null # 아이콘 제거하여 빵이 계속 보이는 현상 방지
			_slots[i].modulate = Color.WHITE


func _on_slot_pressed(slot_index: int) -> void:
	var pm = _get_production_manager()
	if not pm: return

	# 이미 제작 중이면 무시 (추후 '완료' 클릭 시 수령 로직 추가 가능)
	if not pm.is_slot_free(slot_index):
		print("ProductionPanel: Slot %d is already busy" % slot_index)
		return

	# BreadMenu 찾아서 열기
	var bread_menu = _find_bread_menu()
	if bread_menu:
		bread_menu.show_for_slot(slot_index)
	else:
		push_error("ProductionPanel: BreadMenu not found in scene tree")


func _find_bread_menu() -> BreadMenu:
	# 씬 트리를 검색하여 BreadMenu 인스턴스 찾기
	return get_tree().root.find_child("BreadMenu", true, false) as BreadMenu


# 매니저 접근 도우미
func _get_production_manager() -> Node:
	if _production_manager:
		return _production_manager
	return get_node_or_null("/root/ProductionManager")


func _get_game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


func _get_data_manager() -> Node:
	return get_node_or_null("/root/DataManager")
