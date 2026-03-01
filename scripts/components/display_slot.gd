extends Control
class_name DisplaySlot

## DisplaySlot - 빵을 진열하고 판매하는 진열대 컴포넌트

signal bread_displayed(bread_id, quantity)
signal bread_sold(bread_id, gold_earned)

@export var slot_index: int = 0

var state: String = "empty"  # empty, displayed
var current_bread_id: String = ""
var quantity: int = 0

@onready var bread_icon: TextureRect = $VBoxContainer/BreadIcon
@onready var bread_name_label: Label = $VBoxContainer/BreadNameLabel
@onready var quantity_label: Label = $VBoxContainer/QuantityLabel
@onready var price_label: Label = $VBoxContainer/PriceLabel
@onready var sell_button: Button = $VBoxContainer/SellButton


func _ready() -> void:
	if sell_button:
		sell_button.pressed.connect(_on_sell_pressed)

	_update_ui()


func display_bread(bread_id: String, amount: int) -> void:
	current_bread_id = bread_id
	quantity = amount
	state = "displayed"

	bread_displayed.emit(bread_id, quantity)
	print("DisplaySlot %d: Displaying %d x %s" % [slot_index, quantity, bread_id])

	_update_ui()


func sell_bread() -> bool:
	if state != "displayed" or quantity <= 0:
		return false

	if not SalesManager:
		push_error("DisplaySlot: SalesManager not found")
		return false

	# Check if we have inventory to sell
	if not SalesManager.inventory.has(current_bread_id) or SalesManager.inventory[current_bread_id] <= 0:
		return false

	# Calculate price and sell
	var price = SalesManager.calculate_sell_price(current_bread_id)
	SalesManager.sell_bread(current_bread_id, 1)

	quantity -= 1
	bread_sold.emit(current_bread_id, price)

	print("DisplaySlot %d: Sold %s for %d gold" % [slot_index, current_bread_id, price])

	# Check if empty
	if quantity <= 0:
		state = "empty"
		current_bread_id = ""
		quantity = 0

	_update_ui()
	return true


func get_sell_price() -> float:
	if state != "displayed" or not SalesManager:
		return 0.0

	var unit_price = SalesManager.calculate_sell_price(current_bread_id)
	return unit_price * quantity


func clear_display() -> void:
	current_bread_id = ""
	quantity = 0
	state = "empty"

	_update_ui()


func _on_sell_pressed() -> void:
	sell_bread()


func _update_ui() -> void:
	if not bread_name_label:
		return

	match state:
		"empty":
			if bread_name_label:
				bread_name_label.text = "비어있음"
			if quantity_label:
				quantity_label.text = ""
			if price_label:
				price_label.text = ""
			if sell_button:
				sell_button.disabled = true
				sell_button.text = "판매"
			if bread_icon:
				bread_icon.hide()

		"displayed":
			var bread_data = DataManager.get_bread(current_bread_id)
			if bread_name_label:
				bread_name_label.text = bread_data.name if bread_data else current_bread_id
			if quantity_label:
				quantity_label.text = "x%d" % quantity
			if price_label:
				var total_price = get_sell_price()
				price_label.text = "%d골드" % int(total_price)
			if sell_button:
				sell_button.disabled = false
				sell_button.text = "판매"
			if bread_icon:
				bread_icon.show()
