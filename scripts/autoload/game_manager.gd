extends Node


## 게임 매니저 - 두근두근 베이커리의 핵심 싱글톤

signal gold_changed(new_amount: int)
signal level_changed(new_level: int)
signal experience_changed(new_amount: int)

var gold: int = 0:
	set(value):
		gold = value
		gold_changed.emit(gold)

var level: int = 1:
	set(value):
		level = value
		level_changed.emit(level)

var experience: int = 0:
	set(value):
		experience = value
		experience_changed.emit(experience)

var total_breads_crafted: int = 0
var total_gold_earned: int = 0


func _ready() -> void:
	print("🎮 Doki-Doki Bakery initialized!")
	_load_game()


func add_gold(amount: int) -> void:
	gold += amount
	total_gold_earned += amount
	_save_game()


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	_save_game()
	return true


func add_experience(amount: int) -> void:
	experience += amount
	_check_level_up()
	_save_game()


func _check_level_up() -> void:
	# 레벨당 필요 경험치: level * 100
	var required_exp = level * 100
	while experience >= required_exp:
		experience -= required_exp
		level += 1
		print("🎉 Level up! Now level %d" % level)
		required_exp = level * 100


func add_bread_crafted(count: int = 1) -> void:
	total_breads_crafted += count
	_save_game()


func _load_game() -> void:
	var save = SaveManager.load_game()
	
	gold = save.gold
	level = save.level
	experience = save.experience
	total_breads_crafted = save.total_breads_crafted
	total_gold_earned = save.total_gold_earned
	
	# 방치 보상 계산
	var offline_duration = SaveManager.get_offline_duration()
	if offline_duration > 0:
		_calculate_offline_rewards(offline_duration)


func _save_game() -> void:
	SaveManager.current_save.gold = gold
	SaveManager.current_save.level = level
	SaveManager.current_save.experience = experience
	SaveManager.current_save.total_breads_crafted = total_breads_crafted
	SaveManager.current_save.total_gold_earned = total_gold_earned


func _calculate_offline_duration(duration_seconds: float) -> void:
	# 24시간 캡
	var capped_duration = min(duration_seconds, 24 * 60 * 60)
	
	# 8시간까지 100%, 그 이후 50% 효율
	var effective_duration = capped_duration
	if capped_duration > 8 * 60 * 60:
		var full_hours = 8 * 60 * 60
		var reduced_hours = capped_duration - full_hours
		effective_duration = full_hours + (reduced_hours * 0.5)
	
	# 초당 기본 골드 (레벨 기반)
	var gold_per_second = level * 0.1
	var offline_gold = int(effective_duration * gold_per_second)
	
	add_gold(offline_gold)
	print("💰 Offline rewards: %d gold (%.1f hours)" % [offline_gold, duration_seconds / 3600.0])
