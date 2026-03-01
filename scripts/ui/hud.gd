extends CanvasLayer
class_name HUD

## HUD - 게임 내 상단 UI

@onready
var gold_label: Label = $Control/PanelContainer/MarginContainer/HBoxContainer/GoldBox/GoldLabel
@onready
var level_label: Label = $Control/PanelContainer/MarginContainer/HBoxContainer/LevelBox/LevelLabel
@onready
var exp_bar: ProgressBar = $Control/PanelContainer/MarginContainer/HBoxContainer/ExpBox/ExpBar
@onready var exp_label: Label = $Control/PanelContainer/MarginContainer/HBoxContainer/ExpBox/ExpLabel

# 의존성 주입 (테스트용)
var _game_manager: Node = null


func set_game_manager(game_manager: Node):
	_game_manager = game_manager


func _get_game_manager() -> Node:
	if _game_manager:
		return _game_manager
	if has_node("/root/GameManager"):
		return get_node("/root/GameManager")
	return null


func _ready() -> void:
	var gm = _get_game_manager()
	if gm:
		gm.gold_changed.connect(_on_gold_changed)
		gm.level_changed.connect(_on_level_changed)
		gm.experience_changed.connect(_on_experience_changed)

		_update_gold(gm.gold)
		_update_level(gm.level)
		_update_experience(gm.experience, gm.level)


func _on_gold_changed(new_gold: int) -> void:
	_update_gold(new_gold)


func _on_level_changed(new_level: int) -> void:
	_update_level(new_level)
	# 레벨업 시 경험치 바도 업데이트
	var gm = _get_game_manager()
	if gm:
		_update_experience(gm.experience, new_level)


func _on_experience_changed(new_exp: int) -> void:
	var gm = _get_game_manager()
	if gm:
		_update_experience(new_exp, gm.level)


func _update_gold(gold: int) -> void:
	gold_label.text = "%d G" % gold


func _update_level(level: int) -> void:
	level_label.text = "Lv.%d" % level


func _update_experience(exp: int, level: int) -> void:
	# 필요 경험치 계산 (GameManager의 공식과 동일)
	var exp_needed = int(100 * pow(1.5, level - 1))

	exp_bar.max_value = exp_needed
	exp_bar.value = exp

	exp_label.text = "EXP: %d / %d" % [exp, exp_needed]
