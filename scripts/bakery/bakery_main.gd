extends Control
class_name BakeryMain

## 메인 베이커리 화면

@onready var bread_select_button: Button = $BottomBar/BreadSelectButton
@onready var shop_button: Button = $BottomBar/ShopButton
@onready var fairy_button: Button = $BottomBar/FairyButton


func _ready() -> void:
	bread_select_button.pressed.connect(_on_bread_select_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	fairy_button.pressed.connect(_on_fairy_pressed)


func _on_bread_select_pressed() -> void:
	print("🍞 빵 선택 버튼 클릭")
	# TODO: 빵 선택 UI 표시


func _on_shop_pressed() -> void:
	print("🛒 상점 버튼 클릭")
	# TODO: 상점 UI 표시


func _on_fairy_pressed() -> void:
	print("🧚 요정 버튼 클릭")
	# TODO: 요정 UI 표시


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
