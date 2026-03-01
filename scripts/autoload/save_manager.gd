extends Node

## 세이브 매니저 - 저장/로드/백업 관리

signal game_saved
signal game_loaded(save_data: SaveData)

const SAVE_PATH := "user://save.json"
const BACKUP_PATH := "user://save_backup.json"
const AUTO_SAVE_INTERVAL := 60.0  # 60초

var current_save: SaveData = null
var _auto_save_timer: float = 0.0

# 의존성 주입 (테스트용)
var _game_manager = null


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
	current_save = SaveData.new()


func _process(delta: float) -> void:
	_auto_save_timer += delta
	if _auto_save_timer >= AUTO_SAVE_INTERVAL:
		_auto_save_timer = 0.0
		save_game()


func save_game() -> bool:
	if current_save == null:
		current_save = SaveData.new()

	# GameManager 데이터 동기화
	var gm = _get_game_manager()
	if gm:
		current_save.gold = gm.gold
		current_save.level = gm.level
		current_save.experience = gm.experience

	current_save.timestamp = Time.get_unix_time_from_system()

	var json_string = JSON.stringify(_save_to_dict(current_save))
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to save game: %s" % FileAccess.get_open_error())
		return false

	file.store_string(json_string)
	file.close()

	# 백업 생성
	_create_backup()

	game_saved.emit()
	print("💾 Game saved successfully")
	return true


func load_game() -> SaveData:
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		print("No save file found, creating new save")
		current_save = SaveData.new()
		return current_save

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("Save file corrupted, trying backup")
		return _load_backup()

	current_save = _dict_to_save(json.data)

	# GameManager 데이터 복원
	var gm = _get_game_manager()
	if gm:
		gm.gold = current_save.gold
		gm.level = current_save.level
		gm.experience = current_save.experience

	game_loaded.emit(current_save)
	print("📂 Game loaded successfully")
	return current_save


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> bool:
	var err = DirAccess.remove_absolute(SAVE_PATH)
	if err != OK:
		push_error("Failed to delete save: %d" % err)
		return false

	# 백업도 삭제
	DirAccess.remove_absolute(BACKUP_PATH)

	current_save = SaveData.new()
	print("🗑️ Save deleted")
	return true


func _create_backup() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var source = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if source == null:
		return

	var content = source.get_as_text()
	source.close()

	var backup = FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
	if backup == null:
		return

	backup.store_string(content)
	backup.close()


func _load_backup() -> SaveData:
	var file = FileAccess.open(BACKUP_PATH, FileAccess.READ)
	if file == null:
		push_error("No backup found, creating new save")
		return SaveData.new()

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("Backup also corrupted")
		return SaveData.new()

	return _dict_to_save(json.data)


func _save_to_dict(save: SaveData) -> Dictionary:
	return {
		"version": save.version,
		"timestamp": save.timestamp,
		"gold": save.gold,
		"level": save.level,
		"experience": save.experience,
		"unlocked_breads": save.unlocked_breads,
		"owned_fairies": save.owned_fairies,
		"upgrade_levels": save.upgrade_levels,
		"inventory": save.inventory,
		"total_breads_crafted": save.total_breads_crafted,
		"total_gold_earned": save.total_gold_earned,
		"offline_start_time": save.offline_start_time,
		"tutorial_completed": save.tutorial_completed
	}


func _dict_to_save(dict: Dictionary) -> SaveData:
	var save = SaveData.new()
	save.version = dict.get("version", 1)
	save.timestamp = dict.get("timestamp", 0)
	save.gold = dict.get("gold", 0)
	save.level = dict.get("level", 1)
	save.experience = dict.get("experience", 0)
	# Convert Array to Array[String] properly
	var breads_data = dict.get("unlocked_breads", [])
	for bread in breads_data:
		if bread is String:
			save.unlocked_breads.append(bread)
	var fairies_data = dict.get("owned_fairies", [])
	for fairy in fairies_data:
		if fairy is String:
			save.owned_fairies.append(fairy)
	save.upgrade_levels = dict.get("upgrade_levels", {})
	save.inventory = dict.get("inventory", {})
	save.total_breads_crafted = dict.get("total_breads_crafted", 0)
	save.total_gold_earned = dict.get("total_gold_earned", 0)
	save.offline_start_time = dict.get("offline_start_time", 0)
	save.tutorial_completed = dict.get("tutorial_completed", false)
	return save


func get_offline_duration() -> float:
	if current_save.offline_start_time == 0:
		return 0.0

	var current_time = Time.get_unix_time_from_system()
	return current_time - current_save.offline_start_time


func set_offline_start() -> void:
	current_save.offline_start_time = Time.get_unix_time_from_system()
	save_game()
