extends Node2D

@export var tower_prefab: PackedScene
@export var tower_slots_parent_path: NodePath
@onready var spawner = $"../Path2D"
@onready var start_wave_button = get_node("../UI/StartWaveButton")
@export var defender_base_path: String = "res://DefenderXAssets/defender"

# ===== SIGNALS =====
signal coin_collected(amount: int)
signal wave_started(wave_number: int)
signal wave_ended(wave_number: int)
signal all_waves_complete

# ===== WAVE CONFIGURATION =====
@export var max_waves: int = 10
@export var enemies_per_wave: int = 10
@export var wave_delay: float = 2.0

# ===== RANDOMIZATION FOR WAVES 5+ =====
@export var min_enemies_wave_5_plus: int = 8
@export var max_enemies_wave_5_plus: int = 15

# ===== WAVE ENEMY CONFIGURATION =====
@export var wave_enemy_config: Dictionary = {
	1: {"enemies": [{"type": "Warrior", "count": 1}]},
	2: {"enemies": [{"type": "Archer", "count": 1}]},
	3: {"enemies": [{"type": "Lancer", "count": 1}]},
	4: {"enemies": [{"type": "Monk", "count": 1}]},
}

# ===== VARIABLES =====
var coins_collected: int = 0
var current_wave: int = 0
var active_enemies: int = 0
var wave_in_progress: bool = false

var tower_slots: Array[MarkerSlot] = []
var tower_slots_parent: Node2D = null

# ===== READY / INITIALIZATION =====
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

	# Verify start_wave_button is found and connect signal safely
	if start_wave_button:
		print("✓ Start Wave button found: ", start_wave_button.name)
		var cb: Callable = Callable(self, "_on_start_wave_button_pressed")
		if not start_wave_button.is_connected("pressed", cb):
			start_wave_button.pressed.connect(cb)
	else:
		print("❌ Start Wave button NOT found!")



func _gather_slots_recursive(node: Node) -> void:
	"""Recursively search for MarkerSlot nodes"""
	for child in node.get_children():
		if child is MarkerSlot:
			tower_slots.append(child)
			print("Found MarkerSlot at: %s (name: %s)" % [child.global_position, child.name])
		else:
			_gather_slots_recursive(child)

# ===== TOWER / DEFENDER MANAGEMENT =====
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

func _count_available_slots() -> int:
	var count = 0
	for slot in tower_slots:
		if not slot.is_occupied:
			count += 1
	return count

# ===== COIN MANAGEMENT =====
func on_coin_collected(coin_amount: int = 1) -> void:
	coins_collected += coin_amount
	print("=== COIN COLLECTED ===")
	print("Amount: +%d | Total coins: %d" % [coin_amount, coins_collected])
	
	coin_collected.emit(coin_amount)
	_update_coin_ui()

func _update_coin_ui() -> void:
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
	coins_collected = 0
	_cleanup_dropped_coins()
	_update_coin_ui()
	print("✓ Coins reset to 0")

func _cleanup_dropped_coins() -> void:
	print("🧹 Cleaning up dropped coins...")
	var coins = get_tree().get_nodes_in_group("Coin")
	for coin in coins:
		if is_instance_valid(coin):
			coin.queue_free()
	print("✓ Cleaned up %d coins from map" % coins.size())

# ===== WAVE & ENEMY MANAGEMENT =====
func _on_start_wave_button_pressed():
	if wave_in_progress:
		print("⚠️  Wave already in progress!")
		return
	
	print("\n▶️  START WAVE BUTTON PRESSED!")
	if start_wave_button:
		start_wave_button.disabled = true
	
	wave_in_progress = true
	if spawner:
		spawner.start_wave(current_wave + 1)

func get_wave_enemy_config(wave_number: int) -> Dictionary:
	if wave_number in wave_enemy_config:
		return wave_enemy_config[wave_number]
	else:
		var random_warriors = randi_range(3, 6)
		var random_archers = randi_range(4, 8)
		var random_mages = randi_range(2, 5)
		return {"enemies": [
			{"type": "Warrior", "count": random_warriors},
			{"type": "Archer", "count": random_archers},
			{"type": "Mage", "count": random_mages}
		]}

func get_enemies_for_wave(wave_number: int) -> int:
	var config = get_wave_enemy_config(wave_number)
	var total = 0
	for enemy_data in config["enemies"]:
		total += enemy_data["count"]
	print("📊 Wave %d breakdown: %s | Total: %d" % [wave_number, config["enemies"], total])
	return total

func set_current_wave(wave_number: int) -> void:
	current_wave = wave_number
	var enemy_count = get_enemies_for_wave(wave_number)
	print("📊 Current wave set to: ", current_wave)
	print("👹 Enemies for this wave: ", enemy_count)
	wave_started.emit(wave_number)

func enemy_spawned() -> void:
	active_enemies += 1
	print("👹 Enemy spawned! Active enemies: ", active_enemies)

func enemy_died(enemy: Node) -> void:
	active_enemies -= 1
	print("💀 Enemy died! Active enemies: ", active_enemies)

func check_all_waves_complete() -> void:
	print("✅ WAVE %d COMPLETE! All enemies defeated!" % current_wave)
	wave_ended.emit(current_wave)
	wave_in_progress = false
	
	_reset_start_wave_button()
	
	if current_wave >= max_waves:
		print("🎉 ALL WAVES COMPLETE!")
		all_waves_complete.emit()
		_enable_restart_button()
		return
	
	print("⏳ Ready for next wave!")
	var next_wave = current_wave + 1
	print("🔘 START WAVE button is now ACTIVE - Click to start wave ", next_wave)
	print("   (Or wave will auto-start in ", int(wave_delay), " seconds)")
	
	await get_tree().create_timer(wave_delay).timeout
	_start_next_wave_auto()

func _reset_start_wave_button() -> void:
	if not is_instance_valid(start_wave_button):
		print("❌ Button is invalid!")
		return
	
	print("\n🔘 RESETTING BUTTON:")
	print("   Before: pressed=%s | disabled=%s" % [start_wave_button.button_pressed, start_wave_button.disabled])
	start_wave_button.release_focus()
	await get_tree().process_frame
	start_wave_button.button_pressed = false
	start_wave_button.disabled = false
	start_wave_button.modulate = Color.WHITE
	print("   After:  pressed=%s | disabled=%s" % [start_wave_button.button_pressed, start_wave_button.disabled])
	print("   ✅ Button ready!\n")

func _start_next_wave_auto() -> void:
	var all_enemies = get_tree().get_nodes_in_group("Enemy")
	if all_enemies.size() == 0 and not wave_in_progress:
		if spawner and spawner.has_method("start_wave"):
			var next_wave = current_wave + 1
			print("🌊 AUTO-STARTING wave %d..." % next_wave)
			wave_in_progress = true
			spawner.start_wave(next_wave)
			if start_wave_button:
				start_wave_button.disabled = true

func _enable_restart_button() -> void:
	if start_wave_button:
		start_wave_button.text = "Restart Level"
		start_wave_button.button_pressed = false
		start_wave_button.disabled = false
		start_wave_button.modulate = Color.WHITE
		print("✓ Restart button enabled")

# ===== LEVEL RESET & CLEANUP =====
func restart_level() -> void:
	print("\n========== RESTARTING LEVEL ==========")
	
	_cleanup_dropped_coins()
	reset_coins()
	_cleanup_enemies()
	_cleanup_towers()
	
	for slot in tower_slots:
		slot.is_occupied = false
		slot.current_tower = null
	
	if spawner and spawner.has_method("stop_wave"):
		spawner.stop_wave()
	
	if spawner and spawner.has_method("reset_waves"):
		spawner.reset_waves()
	
	if start_wave_button:
		start_wave_button.disabled = false
		start_wave_button.button_pressed = false
		start_wave_button.text = "Start Wave"
		start_wave_button.modulate = Color.WHITE
	
	current_wave = 0
	active_enemies = 0
	wave_in_progress = false
	
	wave_ended.emit(0)
	print("✓ Level restarted successfully\n")

func _cleanup_towers() -> void:
	print("🧹 Cleaning up towers...")
	var towers = get_tree().get_nodes_in_group("Defender")
	for tower in towers:
		if is_instance_valid(tower):
			tower.queue_free()
	print("✓ Cleaned up %d towers" % towers.size())

func _cleanup_enemies() -> void:
	print("🧹 Cleaning up enemies...")
	var enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	print("✓ Cleaned up %d enemies" % enemies.size())
