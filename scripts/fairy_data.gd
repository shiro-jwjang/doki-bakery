extends Resource
class_name FairyData

## 요정 데이터 Resource

@export var id: String
@export var name: String
@export var name_en: String
@export var description: String

@export var ability: Dictionary  # {type: "craft_speed", category: "cake", bonus: 0.2}
@export var unlock_condition: Dictionary  # {type: "level", value: 3}
@export var cost: int
@export var icon: String


func is_unlocked(current_level: int, _stats: Dictionary = {}) -> bool:
	match unlock_condition.type:
		"level":
			return current_level >= unlock_condition.value
		_:
			return false
