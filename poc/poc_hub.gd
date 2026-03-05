extends Node

## PoC Hub — 검증 씬 선택 메뉴


func _on_btn_window_pressed() -> void:
	get_tree().change_scene_to_file("res://poc/poc_window.tscn")


func _on_btn_ysort_pressed() -> void:
	get_tree().change_scene_to_file("res://poc/poc_ysort.tscn")


func _on_btn_offline_pressed() -> void:
	get_tree().change_scene_to_file("res://poc/poc_offline.tscn")
