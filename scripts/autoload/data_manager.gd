extends Node


## 데이터 매니저 - JSON 데이터를 Resource로 로드

signal data_loaded

var breads: Dictionary = {}  # id -> BreadData
var ingredients: Dictionary = {}  # id -> IngredientData
var fairies: Dictionary = {}  # id -> FairyData
var upgrades: Dictionary = {}  # id -> UpgradeData

var _data_path: String = "res://data"


func _ready() -> void:
	load_all_data()


func load_all_data() -> void:
	_load_breads()
	_load_ingredients()
	_load_fairies()
	_load_upgrades()
	data_loaded.emit()
	print("✅ All game data loaded: %d breads, %d ingredients, %d fairies, %d upgrades" % [
		breads.size(), ingredients.size(), fairies.size(), upgrades.size()
	])


func _load_breads() -> void:
	var file_path = _data_path + "/breads.json"
	var json_data = _load_json(file_path)
	if json_data == null:
		return
	
	for bread_dict in json_data.get("breads", []):
		var bread = BreadData.new()
		bread.id = bread_dict.get("id", "")
		bread.name = bread_dict.get("name", "")
		bread.name_en = bread_dict.get("name_en", "")
		bread.category = bread_dict.get("category", "")
		bread.tier = bread_dict.get("tier", 1)
		bread.base_price = bread_dict.get("base_price", 0)
		bread.base_craft_time = bread_dict.get("base_craft_time", 0.0)
		bread.experience = bread_dict.get("experience", 0)
		bread.ingredients = bread_dict.get("ingredients", [])
		bread.unlock_level = bread_dict.get("unlock_level", 1)
		bread.icon = bread_dict.get("icon", "")
		
		breads[bread.id] = bread


func _load_ingredients() -> void:
	var file_path = _data_path + "/ingredients.json"
	var json_data = _load_json(file_path)
	if json_data == null:
		return
	
	for ing_dict in json_data.get("ingredients", []):
		var ingredient = IngredientData.new()
		ingredient.id = ing_dict.get("id", "")
		ingredient.name = ing_dict.get("name", "")
		ingredient.name_en = ing_dict.get("name_en", "")
		ingredient.base_price = ing_dict.get("base_price", 0)
		ingredient.max_stack = ing_dict.get("max_stack", 999)
		
		ingredients[ingredient.id] = ingredient


func _load_fairies() -> void:
	var file_path = _data_path + "/fairies.json"
	var json_data = _load_json(file_path)
	if json_data == null:
		return
	
	for fairy_dict in json_data.get("fairies", []):
		var fairy = FairyData.new()
		fairy.id = fairy_dict.get("id", "")
		fairy.name = fairy_dict.get("name", "")
		fairy.name_en = fairy_dict.get("name_en", "")
		fairy.description = fairy_dict.get("description", "")
		fairy.ability = fairy_dict.get("ability", {})
		fairy.unlock_condition = fairy_dict.get("unlock_condition", {})
		fairy.cost = fairy_dict.get("cost", 0)
		fairy.icon = fairy_dict.get("icon", "")
		
		fairies[fairy.id] = fairy


func _load_upgrades() -> void:
	var file_path = _data_path + "/upgrades.json"
	var json_data = _load_json(file_path)
	if json_data == null:
		return
	
	for upgrade_dict in json_data.get("upgrades", []):
		var upgrade = UpgradeData.new()
		upgrade.id = upgrade_dict.get("id", "")
		upgrade.name = upgrade_dict.get("name", "")
		upgrade.name_en = upgrade_dict.get("name_en", "")
		upgrade.description = upgrade_dict.get("description", "")
		upgrade.type = upgrade_dict.get("type", "")
		upgrade.bonus = upgrade_dict.get("bonus", 0.0)
		upgrade.max_level = upgrade_dict.get("max_level", 1)
		upgrade.base_cost = upgrade_dict.get("base_cost", 0)
		upgrade.cost_multiplier = upgrade_dict.get("cost_multiplier", 1.5)
		
		upgrades[upgrade.id] = upgrade


func _load_json(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to load JSON file: %s" % file_path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return {}
	
	return json.data


func get_bread(id: String) -> BreadData:
	return breads.get(id)


func get_ingredient(id: String) -> IngredientData:
	return ingredients.get(id)


func get_fairy(id: String) -> FairyData:
	return fairies.get(id)


func get_upgrade(id: String) -> UpgradeData:
	return upgrades.get(id)


func get_unlocked_breads(current_level: int) -> Array[BreadData]:
	var result: Array[BreadData] = []
	for bread in breads.values():
		if bread.is_unlocked(current_level):
			result.append(bread)
	return result


func get_unlocked_fairies(current_level: int) -> Array[FairyData]:
	var result: Array[FairyData] = []
	for fairy in fairies.values():
		if fairy.is_unlocked(current_level):
			result.append(fairy)
	return result
