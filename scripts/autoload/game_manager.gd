extends Node

## 게임 매니저 - 두근두근 베이커리의 핵심 싱글톤

signal gold_changed(new_amount: int)
signal level_changed(new_level: int, new_experience: int)
signal experience_changed(new_amount: int)
signal experience_gained(amount: int)

var gold: int = 0:
	set(value):
		gold = value
		gold_changed.emit(gold)

# API 호환성용 (테스트 및 일부 UI용)
var player_gold: int:
	get:
		return gold
	set(value):
		gold = value

var level: int = 1:
	set(value):
		level = value
		level_changed.emit(level, experience)

# API 호환성용 (테스트용)
var player_level: int:
	get:
		return level
	set(value):
		level = value

var experience: int = 0:
	set(value):
		experience = value
		experience_changed.emit(experience)

# API 호환성용 (테스트용)
var player_experience: int:
	get:
		return experience
	set(value):
		experience = value

var total_breads_crafted: int = 0
var total_gold_earned: int = 0


func _ready() -> void:
	if "--check-only" in OS.get_cmdline_args() or "--script-check" in OS.get_cmdline_args():
		return

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


# API 호환성용
func remove_gold(amount: int) -> bool:
	return spend_gold(amount)


func add_experience(amount: int) -> void:
	experience += amount
	experience_gained.emit(amount)
	_check_level_up()
	_save_game()


func calculate_experience_needed(for_level: int) -> int:
	# 레벨당 필요 경험치: 100 * 1.5^(level-1)
	return int(100 * pow(1.5, for_level - 1))


func _check_level_up() -> void:
	var required_exp = calculate_experience_needed(level)
	while experience >= required_exp:
		experience -= required_exp
		level += 1
		print("🎉 Level up! Now level %d" % level)
		level_changed.emit(level, experience)
		required_exp = calculate_experience_needed(level)


func add_bread_crafted(count: int = 1) -> void:
	total_breads_crafted += count
	_save_game()


func _load_game() -> void:
	var save = SaveManager.load_game()

	# Null check for save data
	if save == null:
		printerr("Failed to load save data")
		return

	gold = save.gold
	level = save.level
	experience = save.experience
	total_breads_crafted = save.total_breads_crafted
	total_gold_earned = save.total_gold_earned

	# 방치 보상 계산
	var offline_duration = SaveManager.get_offline_duration()
	if offline_duration > 0:
		_calculate_offline_duration(offline_duration)


func _save_game() -> void:
	# SaveManager.current_save 필드 채우기는 SaveManager.save_game() 내부에서 수행됨
	SaveManager.save_game()


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
