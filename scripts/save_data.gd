extends Resource
class_name SaveData

## 세이브 데이터 Resource

@export var version: int = 1
@export var timestamp: int  # Unix timestamp

@export var gold: int = 0
@export var level: int = 1
@export var experience: int = 0

@export var unlocked_breads: Array[String] = []
@export var owned_fairies: Array[String] = []

@export var upgrade_levels: Dictionary = {}  # {upgrade_id: level}

@export var inventory: Dictionary = {}  # {ingredient_id: amount}
@export var active_baking: Dictionary = {}  # {slot_index: { "id": bread_id, "start_time": unix_timestamp }}

@export var total_breads_crafted: int = 0
@export var total_gold_earned: int = 0

@export var offline_start_time: int = 0  # 방치 시간 계산용

@export var tutorial_completed: bool = false


func _init() -> void:
	timestamp = Time.get_unix_time_from_system()
