extends CanvasLayer

## 게임 상단 HUD (골드, 레벨, 인벤토리 표시)

@onready
var gold_label: Label = $Control/PanelContainer/MarginContainer/HBoxContainer/GoldBox/GoldLabel
@onready
var level_label: Label = $Control/PanelContainer/MarginContainer/HBoxContainer/LevelBox/LevelLabel
@onready
var inv_label: Label = $Control/PanelContainer/MarginContainer/HBoxContainer/InventoryBox/InvLabel
@onready
var exp_bar: ProgressBar = $Control/PanelContainer/MarginContainer/HBoxContainer/LevelBox/ExpBar

# 의존성 주입 (테스트용)
var _game_manager = null
var _sales_manager = null


func set_game_manager(gm: Node):
	_game_manager = gm


func set_sales_manager(sm: Node):
	_sales_manager = sm


func _ready() -> void:
	print("HUD: _ready called")
	_connect_signals()
	_update_display()


func _connect_signals() -> void:
	var gm = _get_game_manager()
	if gm:
		if not gm.gold_changed.is_connected(_on_gold_changed):
			gm.gold_changed.connect(_on_gold_changed)
		if not gm.level_changed.is_connected(_on_level_changed):
			gm.level_changed.connect(_on_level_changed)
		print("HUD: Connected to GameManager signals")
	else:
		print("HUD: GameManager not found!")

	var sm = _get_sales_manager()
	if sm:
		if not sm.inventory_updated.is_connected(_on_inventory_updated):
			sm.inventory_updated.connect(_on_inventory_updated)
		print("HUD: Connected to SalesManager signals")


func _process(_delta: float) -> void:
	# 주기적으로 강제 동기화 (fallback)
	var gm = _get_game_manager()
	if gm and gold_label:
		var expected = "%d G" % gm.gold
		if gold_label.text != expected:
			gold_label.text = expected

	if gm and level_label:
		var expected = "Lv.%d" % gm.level
		if level_label.text != expected:
			level_label.text = expected


func _update_display() -> void:
	var gm = _get_game_manager()
	if gm:
		_update_gold(gm.gold)
		_update_level(gm.level)

	var sm = _get_sales_manager()
	if sm:
		_update_inventory(sm.inventory)


func _on_gold_changed(new_gold: int) -> void:
	_update_gold(new_gold)


func _on_level_changed(new_level: int, _new_experience: int) -> void:
	_update_level(new_level)


func _on_inventory_updated(_bread_id: String, _count: int) -> void:
	var sm = _get_sales_manager()
	if sm:
		_update_inventory(sm.inventory)


func _update_gold(gold: int) -> void:
	if gold_label:
		gold_label.text = "%d G" % gold
		print("HUD: Updated gold to %d" % gold)


func _update_level(level: int) -> void:
	if level_label:
		level_label.text = "Lv.%d" % level
		print("HUD: Updated level to %d" % level)


func _update_inventory(inventory: Dictionary) -> void:
	if inv_label:
		var total = 0
		for count in inventory.values():
			total += count
		inv_label.text = str(total)


func _get_game_manager() -> Node:
	if _game_manager:
		return _game_manager
	return get_node_or_null("/root/GameManager")


func _get_sales_manager() -> Node:
	if _sales_manager:
		return _sales_manager
	return get_node_or_null("/root/SalesManager")
