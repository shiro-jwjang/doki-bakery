extends Control
class_name TitleScreen

## 타이틀 화면

@onready var start_button: Button = $StartButton
@onready var continue_button: Button = $ContinueButton

signal start_new_game
signal continue_game


func _ready() -> void:
	# 세이브 파일 확인
	if _has_save():
		continue_button.visible = true
		start_button.text = "새로 시작"

	# 버튼 연결
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)


func _has_save() -> bool:
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager and save_manager.has_method("has_save"):
		return save_manager.has_save()
	return false


func _on_start_pressed() -> void:
	# 세이브 삭제 후 새 게임
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager and save_manager.has_method("delete_save"):
		save_manager.delete_save()

	start_new_game.emit()
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")


func _on_continue_pressed() -> void:
	continue_game.emit()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
