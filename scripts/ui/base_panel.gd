extends PanelContainer
class_name BasePanel

## 기본 패널 컴포넌트

@export var panel_title: String = "":
	set(value):
		panel_title = value
		_update_title()

@export var show_shadow: bool = true:
	set(value):
		show_shadow = value
		_update_shadow()


func _ready() -> void:
	_update_shadow()


func _update_title() -> void:
	# TODO: 타이틀 라벨 추가
	pass


func _update_shadow() -> void:
	# TODO: 그림자 효과
	pass
