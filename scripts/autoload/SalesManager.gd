extends Node

signal inventory_updated(bread_id, amount)
signal bread_sold(bread_id, quantity, gold_earned)

var inventory = {} # bread_id: quantity
var total_gold = 0

func _ready():
	# Initial gold from SaveData (if exists)
	total_gold = 0 # Default starting gold

func add_bread_to_inventory(bread_id: String, amount: int = 1):
	if inventory.has(bread_id):
		inventory[bread_id] += amount
	else:
		inventory[bread_id] = amount
	
	emit_signal("inventory_updated", bread_id, inventory[bread_id])
	print("SalesManager: Added ", amount, " ", bread_id, " to inventory. Total: ", inventory[bread_id])

func sell_bread(bread_id: String, quantity: int = 1):
	if not inventory.has(bread_id) or inventory[bread_id] < quantity:
		printerr("SalesManager: Not enough ", bread_id, " in inventory to sell.")
		return
	
	var price_info = DataManager.balance.production.breads[bread_id]
	var unit_price = calculate_sell_price(bread_id)
	var total_price = unit_price * quantity
	
	inventory[bread_id] -= quantity
	total_gold += total_price
	
	emit_signal("inventory_updated", bread_id, inventory[bread_id])
	emit_signal("bread_sold", bread_id, quantity, total_price)
	
	print("SalesManager: Sold ", quantity, " ", bread_id, " for ", total_price, "G. Total Gold: ", total_gold)

func calculate_sell_price(bread_id: String) -> float:
	if not DataManager or not DataManager.balance or not DataManager.balance.production:
		push_error("SalesManager: DataManager.balance not loaded")
		return 10.0 # Default fallback price

	if not DataManager.balance.production.breads.has(bread_id):
		push_error("SalesManager: Unknown bread_id: " + bread_id)
		return 10.0

	var base_data = DataManager.balance.production.breads[bread_id]
	var multiplier = DataManager.balance.pricing.ingredientMultiplier

	# Formula: SellPrice = IngredientCost * 2.5 + (BasePrice * (1 + LevelBonus))
	var price = base_data.ingredientCost * multiplier + base_data.basePrice

	return price

func get_total_gold() -> int:
	return total_gold

func set_total_gold(amount: int):
	total_gold = amount
