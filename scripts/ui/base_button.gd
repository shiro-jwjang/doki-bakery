extends Button
class_name BaseButton

## 기본 버튼 컴포넌트

@export var button_text: String = "Button":
	set(value):
		button_text = value
		_update_label()

@export var button_size: String = "medium":  # small, medium, large
	set(value):
		button_size = value
		_update_size()

@export var button_style: String = "primary":  # primary, secondary, danger
	set(value):
		button_style = value
		_update_style()

var _label: Label


func _ready() -> void:
	_label = $Label
	_update_label()
	_update_size()
	_update_style()


func _update_label() -> void:
	if _label:
		_label.text = button_text


func _update_size() -> void:
	match button_size:
		"small":
			custom_minimum_size = Vector2(64, 24)
		"medium":
			custom_minimum_size = Vector2(128, 32)
		"large":
			custom_minimum_size = Vector2(192, 48)


func _update_style() -> void:
	# TODO: 테마 적용
	pass
