extends CanvasLayer
class_name ProductionPanel

## 빵 생산 패널 스크립트

@onready var slot1: Button = $Control/MarginContainer/VBoxContainer/HBoxContainer/Slot1
@onready var slot2: Button = $Control/MarginContainer/VBoxContainer/HBoxContainer/Slot2
@onready var slot3: Button = $Control/MarginContainer/VBoxContainer/HBoxContainer/Slot3
@onready var slot4: Button = $Control/MarginContainer/VBoxContainer/HBoxContainer/Slot4
@onready var slot5: Button = $Control/MarginContainer/VBoxContainer/HBoxContainer/Slot5

var _slots: Array[Button] = []
var _production_manager: Node = null

const BREADS := ["white_bread", "croissant", "cake", "cookie", "madeleine"]
const BREAD_NAMES := {
	"white_bread": "식빵", "croissant": "크로와상", "cake": "케이크", "cookie": "쿠키", "madeleine": "마들렌"
}


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

	if not pm or not gm:
		return

	for i in range(_slots.size()):
		var bread_id = BREADS[i]
		var bread_name = BREAD_NAMES.get(bread_id, bread_id)

		# 라벨 노드 찾기
		var label = _slots[i].get_node_or_null("VBox/Label")

		# 데이터 매니저에서 잠금 레벨 확인
		var unlock_level = 1
		if dm and dm.has_method("get_bread_data"):
			var bread_data = dm.get_bread_data(bread_id)
			if bread_data:
				unlock_level = bread_data.get("unlock_level", 1)

		var current_level = gm.level

		if current_level < unlock_level:
			if label:
				label.text = "%s\n🔒 Lv.%d" % [bread_name, unlock_level]
			_slots[i].disabled = true
		elif pm.has_method("is_producing") and pm.is_producing(bread_id):
			var remaining = (
				pm.get_remaining_time(bread_id) if pm.has_method("get_remaining_time") else 0.0
			)
			if label:
				label.text = "%s\n%.1f초" % [bread_name, remaining]
			_slots[i].disabled = true
		else:
			if label:
				label.text = bread_name
			_slots[i].disabled = false


func _on_slot_pressed(slot_index: int) -> void:
	var pm = _get_production_manager()
	if pm and pm.has_method("start_production"):
		pm.start_production(BREADS[slot_index])


# 매니저 접근 도우미
func _get_production_manager() -> Node:
	if _production_manager:
		return _production_manager
	return get_node_or_null("/root/ProductionManager")


func _get_game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


func _get_data_manager() -> Node:
	return get_node_or_null("/root/DataManager")
