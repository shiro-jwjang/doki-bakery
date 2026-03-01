extends Node
class_name GameManager

## 게임 매니저 - 두근두근 베이커리의 핵심 싱글톤

signal gold_changed(new_amount: int)
signal level_changed(new_level: int)

var gold: int = 0
var level: int = 1
var experience: int = 0

func _ready() -> void:
	print("🎮 Doki-Doki Bakery initialized!")
	load_game()

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func add_experience(amount: int) -> void:
	experience += amount
	# TODO: 레벨업 로직

func save_game() -> void:
	# TODO: SaveManager로 이동
	pass

func load_game() -> void:
	# TODO: SaveManager로 이동
	pass
