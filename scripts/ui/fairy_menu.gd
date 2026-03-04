extends Control
class_name FairyMenu

## FairyMenu - 요정을 고용하는 UI

signal fairy_hired(fairy_id: String)

@onready var close_button: Button = $Panel/VBoxContainer/Header/CloseButton
@onready var fairy_list_container: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/FairyList

var hired_fairies: Array[String] = []


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	_load_hired_fairies()
	_populate_fairy_list()


func _load_hired_fairies() -> void:
	# Load from SaveManager
	if SaveManager and SaveManager.current_save:
		hired_fairies.clear()
		for fairy_id in SaveManager.current_save.owned_fairies:
			hired_fairies.append(fairy_id)


func hire_fairy(fairy_id: String) -> bool:
	if not GameManager:
		push_error("FairyMenu: GameManager not found")
		return false

	var fairy = DataManager.get_fairy(fairy_id)
	if not fairy:
		push_error("FairyMenu: Unknown fairy %s" % fairy_id)
		return false

	# Check if already hired
	if fairy_id in hired_fairies:
		print("FairyMenu: Fairy %s already hired" % fairy_id)
		return false

	# Check level requirement
	var current_level = GameManager.level
	var required_level = fairy.unlock_condition.get("value", 1)
	if current_level < required_level:
		print("FairyMenu: Need level %d to hire %s" % [required_level, fairy_id])
		return false

	# Check gold
	if GameManager.gold < fairy.cost:
		print(
			(
				"FairyMenu: Not enough gold for %s (need %d, have %d)"
				% [fairy_id, fairy.cost, GameManager.gold]
			)
		)
		return false

	# Hire
	GameManager.spend_gold(fairy.cost)
	hired_fairies.append(fairy_id)

	# SaveManager에도 저장
	if SaveManager and SaveManager.current_save:
		if fairy_id not in SaveManager.current_save.owned_fairies:
			SaveManager.current_save.owned_fairies.append(fairy_id)
		SaveManager.save_game()

	fairy_hired.emit(fairy_id)

	print("FairyMenu: Hired %s" % fairy_id)

	# Refresh UI
	_populate_fairy_list()
	return true


func _populate_fairy_list() -> void:
	if not fairy_list_container:
		return

	# Clear existing items
	for child in fairy_list_container.get_children():
		child.queue_free()

	for fairy_id in DataManager.fairies.keys():
		var fairy = DataManager.get_fairy(fairy_id)
		var fairy_item = _create_fairy_item(fairy)
		fairy_list_container.add_child(fairy_item)


func _create_fairy_item(fairy_data: FairyData) -> Control:
	var container = VBoxContainer.new()

	# Header with icon
	var header = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(header)

	# Fairy icon - Display full image (64x64) and ensure it's pixel-perfect
	var icon_rect = TextureRect.new()
	if fairy_data.icon and ResourceLoader.exists(fairy_data.icon):
		var tex = load(fairy_data.icon)
		if tex:
			icon_rect.texture = tex
			# Ensure pixel art looks sharp
			icon_rect.texture_filter = TEXTURE_FILTER_NEAREST
			print("FairyMenu: Loaded icon for ", fairy_data.name)
		else:
			print("FairyMenu: Failed to load texture: ", fairy_data.icon)
	else:
		print("FairyMenu: Icon not found: ", fairy_data.icon)

	icon_rect.custom_minimum_size = Vector2(80, 80)  # Larger icon display
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	header.add_child(icon_rect)

	var name_label = Label.new()
	name_label.text = fairy_data.name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", Color(0.29, 0.22, 0.16))  # GDD Dark Brown
	name_label.add_theme_font_size_override("font_size", 18)
	header.add_child(name_label)

	var status_label = Label.new()
	if fairy_data.id in hired_fairies:
		status_label.text = "고용됨"
		status_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	else:
		var required_level = fairy_data.unlock_condition.get("value", 1)
		var current_level = GameManager.level if GameManager else 1
		if current_level < required_level:
			status_label.text = "Lv.%d 필요" % required_level
			status_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
		else:
			status_label.text = "%d골드" % fairy_data.cost
	header.add_child(status_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = fairy_data.description
	desc_label.add_theme_color_override("font_color", Color(0.29, 0.22, 0.16, 0.8))  # GDD Dark Brown with alpha
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(desc_label)

	# Hire button
	var hire_button = Button.new()
	if fairy_data.id in hired_fairies:
		hire_button.text = "이미 고용됨"
		hire_button.disabled = true
	else:
		var required_level = fairy_data.unlock_condition.get("value", 1)
		var current_level = GameManager.level if GameManager else 1
		if current_level < required_level:
			hire_button.text = "잠김"
			hire_button.disabled = true
		else:
			hire_button.text = "고용"
			hire_button.pressed.connect(_on_hire_button_pressed.bind(fairy_data.id))

	container.add_child(hire_button)

	return container


func _on_hire_button_pressed(fairy_id: String) -> void:
	hire_fairy(fairy_id)


func _on_close_pressed() -> void:
	hide()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()
