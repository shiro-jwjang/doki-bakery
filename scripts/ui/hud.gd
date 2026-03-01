extends CanvasLayer
class_name HUD

## HUD - 게임 내 상단 UI

@onready var gold_label: Label = $MarginContainer/HBoxContainer/GoldLabel
@onready var level_label: Label = $MarginContainer/HBoxContainer/LevelLabel
@onready var time_label: Label = $MarginContainer/HBoxContainer/TimeLabel

# 의존성 주입 (테스트용)
var _game_manager: Node = null


func set_game_manager(game_manager: Node):
	_game_manager = game_manager


func _get_game_manager() -> Node:
	if _game_manager:
		return _game_manager
	# Check if GameManager exists in tree (autoload)
	if has_node("/root/GameManager"):
		return get_node("/root/GameManager")
	return null


func _ready() -> void:
	var gm = _get_game_manager()
	if gm:
		gm.gold_changed.connect(_on_gold_changed)
		gm.level_changed.connect(_on_level_changed)

		_update_gold(gm.gold)
		_update_level(gm.level)


func _process(_delta: float) -> void:
	_update_time()


func _on_gold_changed(new_gold: int) -> void:
	_update_gold(new_gold)


func _on_level_changed(new_level: int) -> void:
	_update_level(new_level)


func _update_gold(gold: int) -> void:
	gold_label.text = "💰 %d" % gold


func _update_level(level: int) -> void:
	level_label.text = "⭐ Lv.%d" % level


func _update_time() -> void:
	var time_dict = Time.get_time_dict_from_system()
	time_label.text = "🕐 %02d:%02d" % [time_dict.hour, time_dict.minute]
