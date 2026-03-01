extends CanvasLayer
class_name HUD

## HUD - 게임 내 상단 UI

@onready var gold_label: Label = $MarginContainer/HBoxContainer/GoldLabel
@onready var level_label: Label = $MarginContainer/HBoxContainer/LevelLabel
@onready var time_label: Label = $MarginContainer/HBoxContainer/TimeLabel


func _ready() -> void:
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.level_changed.connect(_on_level_changed)

	_update_gold(GameManager.gold)
	_update_level(GameManager.level)


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
