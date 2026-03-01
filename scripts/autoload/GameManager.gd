extends Node

signal gold_changed(new_amount)
signal level_changed(new_level, new_experience)
signal experience_gained(amount)

var player_gold: int = 0
var player_level: int = 1
var player_experience: int = 0

func _ready():
	# Connect to SaveManager and wait for data load
	# In a real game, this might happen later
	load_game_state()

func load_game_state():
	# Interaction with SaveManager should go here
	pass

func _process(delta):
	# Update loop if needed
	pass

func add_gold(amount: int):
	player_gold += amount
	emit_signal("gold_changed", player_gold)
	
	# Update SalesManager total gold for consistency
	if SalesManager:
		SalesManager.set_total_gold(player_gold)
	
	print("GameManager: Added ", amount, " gold. Total: ", player_gold)

func remove_gold(amount: int):
	if player_gold >= amount:
		player_gold -= amount
		emit_signal("gold_changed", player_gold)
		
		# Update SalesManager total gold for consistency
		if SalesManager:
			SalesManager.set_total_gold(player_gold)
		
		print("GameManager: Spent ", amount, " gold. Total: ", player_gold)
		return true
	
	return false

func add_experience(amount: int):
	player_experience += amount
	emit_signal("experience_gained", amount)
	
	# Check for level up
	var experience_needed = calculate_experience_needed(player_level)
	if player_experience >= experience_needed:
		level_up()
	
	print("GameManager: Gained ", amount, " experience. Total: ", player_experience)

func level_up():
	player_level += 1
	player_experience = 0 # Or carry over extra experience
	emit_signal("level_changed", player_level, player_experience)
	print("GameManager: Leveled up! New Level: ", player_level)

func calculate_experience_needed(level: int) -> int:
	# Formula: ExperienceNeeded = 100 * (1.5 ^ (Level - 1))
	return int(100 * pow(1.5, level - 1))

func save_game():
	# Interaction with SaveManager should go here
	pass
