extends Node2D

@export var tower_prefab: PackedScene
@export var tower_slots_parent_path: NodePath
@onready var spawner = $"../Path2D"
@onready var start_wave_button = get_node("../UI/StartWaveButton")
@export var defender_base_path: String = "res://DefenderXAssets/defender"

# Coin tracking
var coins_collected: int = 0
@export var coin_value: int = 1

var tower_slots: Array[MarkerSlot] = []
var tower_slots_parent: Node2D = null

func _ready() -> void:
	# Get tower_slots_parent from the path
	if tower_slots_parent_path:
		tower_slots_parent = get_node(tower_slots_parent_path)
	
	# If still not set, try common locations
	if not tower_slots_parent:
		print("Searching for tower slots parent...")
		var parent = get_parent()
		for child in parent.get_children():
			if child.name.contains("Slot") or child.name.contains("slot"):
				tower_slots_parent = child
				print("Found potential slots parent: %s" % child.name)
				break
		
		if not tower_slots_parent:
			tower_slots_parent = parent
			print("Using parent as slots parent: %s" % parent.name)
	
	# Gather all MarkerSlot children
	print("=== Gathering tower slots from: %s ===" % tower_slots_parent.name)
	_gather_slots_recursive(tower_slots_parent)
	
	print("Total slots found: %d" % tower_slots.size())
	
	if tower_slots.is_empty():
		print("ERROR: No MarkerSlots found!")

func _gather_slots_recursive(node: Node) -> void:
	"""Recursively search for MarkerSlot nodes"""
	for child in node.get_children():
		if child is MarkerSlot:
			tower_slots.append(child)
			print("Found MarkerSlot at: %s (name: %s)" % [child.global_position, child.name])
		else:
			_gather_slots_recursive(child)

func _on_buy_tower_button_pressed() -> void:
	var available_slots = []
	print("=== Checking slot availability ===")
	for slot in tower_slots:
		print("Slot at %s - Occupied: %s" % [slot.global_position, slot.is_occupied])
		if not slot.is_occupied:
			available_slots.append(slot)
	
	print("Found %d available slots out of %d total" % [available_slots.size(), tower_slots.size()])
	
	if available_slots.is_empty():
		print("No available tower slots left!")
		return
	
	var chosen_slot: MarkerSlot = available_slots[randi() % available_slots.size()]
	
	var folder_name = "Defender1Assets"
	var scene_name = "defender1.tscn"
	var scene_path = "res://%s/%s" % [folder_name, scene_name]
	
	if not ResourceLoader.exists(scene_path):
		print("Tier 1 tower scene not found!")
		return
	
	var tower_scene = load(scene_path)
	var new_tower: Node2D = tower_scene.instantiate()
	get_parent().add_child(new_tower)
	
	new_tower.global_position = chosen_slot.global_position
	
	var drag_module = new_tower.get_node("DragModule")
	if drag_module:
		drag_module.slots_parent = tower_slots_parent
		drag_module.call_deferred("on_spawn")
	
	print("Tier 1 Tower spawned at:", chosen_slot.global_position)
	print("Available slots remaining: %d" % _count_available_slots())

func _count_available_slots() -> int:
	var count = 0
	for slot in tower_slots:
		if not slot.is_occupied:
			count += 1
	return count

func _on_start_wave_button_pressed():
	if start_wave_button:
		start_wave_button.disabled = true
	if spawner:
		spawner.start_wave(10)

func request_merge(defender1: Node2D, defender2: Node2D) -> void:
	var new_tier: int = defender1.tier + 1
	
	if new_tier > 14:
		print("Maximum tier reached: ", new_tier)
		return
	
	var folder_name = "Defender%dAssets" % new_tier
	var scene_name = "defender%d.tscn" % new_tier
	var scene_path = "res://%s/%s" % [folder_name, scene_name]
	
	if not ResourceLoader.exists(scene_path):
		print("No scene found for tier ", new_tier, " at path: ", scene_path)
		return
	
	var merged_scene: PackedScene = load(scene_path)
	var merged_defender: Node2D = merged_scene.instantiate()
	
	merged_defender.global_position = (defender1.global_position + defender2.global_position) / 2
	get_parent().add_child(merged_defender)
	
	if "tier" in merged_defender:
		merged_defender.tier = new_tier
		print("Set merged defender tier to: ", new_tier)
	
	var drag_module = merged_defender.get_node("DragModule")
	if drag_module:
		drag_module.slots_parent = tower_slots_parent
		if drag_module.has_method("on_spawn"):
			drag_module.on_spawn()
	
	print("Merged defender created at tier ", new_tier)
	print("Available slots after merge: %d" % _count_available_slots())

# ===== COIN MANAGEMENT =====

func coin_collected() -> void:
	coins_collected += coin_value
	print("=== COIN COLLECTED ===")
	print("Total coins: ", coins_collected)
	_update_coin_ui()

func _update_coin_ui() -> void:
	"""Update the coin counter UI"""
	var coin_counter = get_tree().root.find_child("CoinCounter", true, false)
	
	if not coin_counter:
		if has_node("/root/CanvasLayer/Control"):
			coin_counter = get_node("/root/CanvasLayer/Control")
	
	if coin_counter and coin_counter.has_method("update_coin_display"):
		coin_counter.update_coin_display(coins_collected)
		print("✓ CoinCounter UI updated to: ", coins_collected)

func get_coins_collected() -> int:
	return coins_collected

func reset_coins() -> void:
	"""Reset coins and clean up coin drops on map"""
	coins_collected = 0
	_cleanup_dropped_coins()
	_update_coin_ui()
	print("✓ Coins reset to 0")

func _cleanup_dropped_coins() -> void:
	"""Remove all dropped coin pickups from the map"""
	print("🧹 Cleaning up dropped coins...")
	
	# Find all nodes in the "Coin" group and remove them
	var coins = get_tree().get_nodes_in_group("Coin")
	print("Found %d coins to clean up" % coins.size())
	
	for coin in coins:
		if is_instance_valid(coin):
			print("  - Removing coin at: ", coin.global_position)
			coin.queue_free()
	
	if coins.size() > 0:
		print("✓ Cleaned up %d coins from map" % coins.size())

func restart_level() -> void:
	"""Restart the level completely"""
	print("\n========== RESTARTING LEVEL ==========")
	
	# 1. Clean up all coins FIRST (before anything else)
	_cleanup_dropped_coins()
	
	# 2. Reset coin counter
	reset_coins()
	
	# 3. Clean up all enemies
	_cleanup_enemies()
	
	# 4. Clean up all towers
	_cleanup_towers()
	
	# 5. Reset tower slots
	for slot in tower_slots:
		slot.is_occupied = false
		slot.current_tower = null
	
	# 6. Stop spawner
	if spawner and spawner.has_method("stop_wave"):
		spawner.stop_wave()
	
	# 7. Re-enable start button
	if start_wave_button:
		start_wave_button.disabled = false
	
	print("✓ Level restarted successfully\n")

func _cleanup_towers() -> void:
	"""Remove all towers from the map"""
	print("🧹 Cleaning up towers...")
	
	var towers = get_tree().get_nodes_in_group("Defender")
	for tower in towers:
		if is_instance_valid(tower):
			tower.queue_free()
	
	print("✓ Cleaned up %d towers" % towers.size())

func _cleanup_enemies() -> void:
	"""Remove all enemies from the map"""
	print("🧹 Cleaning up enemies...")
	
	var enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	print("✓ Cleaned up %d enemies" % enemies.size())
