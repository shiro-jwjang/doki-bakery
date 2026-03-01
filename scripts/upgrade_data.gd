extends Resource
class_name UpgradeData

## 업그레이드 데이터 Resource

@export var id: String
@export var name: String
@export var name_en: String
@export var description: String

@export var type: String  # craft_speed, sell_slots, critical_chance, profit_bonus
@export var bonus: float
@export var max_level: int

@export var base_cost: int
@export var cost_multiplier: float = 1.5


func get_cost(current_level: int) -> int:
	return int(base_cost * pow(cost_multiplier, current_level))


func is_maxed(current_level: int) -> bool:
	return current_level >= max_level
