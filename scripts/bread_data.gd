extends Resource
class_name BreadData

## 빵 데이터 Resource

@export var id: String
@export var name: String
@export var name_en: String
@export var category: String  # basic, pastry, cake, seasonal, special
@export var tier: int
@export var base_price: int
@export var base_craft_time: float  # 초 단위
@export var experience: int

var ingredients: Array[Dictionary] = []  # [{id: "flour", amount: 2}, ...]
@export var unlock_level: int
@export var icon: String


func get_ingredient_amount(ingredient_id: String) -> int:
	for ingredient in ingredients:
		if ingredient.id == ingredient_id:
			return ingredient.amount
	return 0


func is_unlocked(current_level: int) -> bool:
	return current_level >= unlock_level
