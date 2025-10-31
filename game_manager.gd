extends Node2D

@export var tower_prefab: PackedScene
@export var tower_slots_parent_path: NodePath
@onready var spawner = $"../Path2D"
@onready var start_wave_button = get_node("../UI/StartWaveButton")
@onready var record_label: Label = get_node("../UI/Canvas Layer/WaveRecord/RecordLabel") as Label
@onready var buy_button: Button = get_node("../UI/BuyTowerButton") as Button
@onready var tower_randomizer = $TowerRandomizer

@export var defender_base_path: String = "res://DefenderXAssets/defender"

# ===== SIGNALS =====
signal coin_collected(amount: int)
signal wave_started(wave_number: int)
signal wave_ended(wave_number: int)

# ===== WAVE CONFIGURATION =====
@export var max_waves: int = 999999
@export var wave_delay: float = 2.0
@export var auto_start_next_wave: bool = false

# ===== VARIABLES =====
var coins_collected: int = 20
var current_wave: int = 0
var active_enemies: int = 0
var wave_in_progress: bool = false

var tower_slots: Array[MarkerSlot] = []
var tower_slots_parent: Node2D = null

# ✅ Manager References
var button_sfx_manager: Node = null
var music_manager: Node = null

# ===== TOWER COST SETTINGS =====
var base_tower_cost: int = 5
var cost_growth_rate: float = 1.25
var current_tower_cost: int = base_tower_cost



# ===== READY / INITIALIZATION =====
func _ready() -> void:
	#--- Button Path Checking ---
	if not record_label:
		print("⚠️ RecordLabel not found! Check your UI path.")
	else:
		print("✓ RecordLabel found: ", record_label.name)

	# --- Load player record ---
	PlayerRecord.load()
	print("✓ PlayerRecord loaded: Highest Wave =", PlayerRecord.highest_wave)
	print("✓ PlayerRecord loaded: Highest Tier =", PlayerRecord.highest_tier)
	
	if record_label:
		record_label.text = "Best Wave: %d" % PlayerRecord.highest_wave
	
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

	# ✅ Find Managers
	_find_button_sfx_manager()
	_find_music_manager()

	# Verify start_wave_button is found and connect signal safely
	if start_wave_button:
		print("✓ Start Wave button found: ", start_wave_button.name)
		var cb: Callable = Callable(self, "_on_start_wave_button_pressed")
		if not start_wave_button.is_connected("pressed", cb):
			start_wave_button.pressed.connect(cb)
	else:
		print("❌ Start Wave button NOT found!")
		
	update_buy_button_label()
	
	# Initialize tower cost
	current_tower_cost = calculate_tower_cost(current_wave)
	update_buy_button_label()


func _gather_slots_recursive(node: Node) -> void:
	"""Recursively search for MarkerSlot nodes"""
	for child in node.get_children():
		if child is MarkerSlot:
			tower_slots.append(child)
			print("Found MarkerSlot at: %s (name: %s)" % [child.global_position, child.name])
		else:
			_gather_slots_recursive(child)

## Find Button SFX Manager
func _find_button_sfx_manager() -> void:
	button_sfx_manager = get_node_or_null("/root/Main/ButtonSFXManager")
	
	if not button_sfx_manager:
		button_sfx_manager = get_tree().root.find_child("ButtonSFXManager", true, false)
	
	if button_sfx_manager:
		print("✓ GameManager found ButtonSFXManager")
	else:
		print("⚠️  GameManager WARNING: ButtonSFXManager NOT found!")

## Find Music Manager
func _find_music_manager() -> void:
	print("🔍 DEBUG: Searching for MusicManager...")
	
	# Try lowercase path first (correct path)
	music_manager = get_node_or_null("/root/main/MusicManager")
	if music_manager:
		print("✓ Found at /root/main/MusicManager")
	else:
		# Try tree search
		music_manager = get_tree().root.find_child("MusicManager", true, false)
		if music_manager:
			print("✓ Found via tree search at: ", music_manager.get_path())
	
	if music_manager:
		print("✓ GameManager found MusicManager")
	else:
		print("⚠️  GameManager WARNING: MusicManager NOT found!")
		
# ===== TOWER / DEFENDER MANAGEMENT =====

func calculate_tower_cost(wave_number: int) -> int:
	# Nonlinear increase: cost grows faster with higher wave
	var new_cost = int(base_tower_cost * pow(cost_growth_rate, wave_number))
	return new_cost

func update_buy_button_label() -> void:
	# ✅ FIXED: Use the member variable buy_button, don't create a local one
	if buy_button:
		buy_button.text = "Buy Tower\n(%d Gold)" % current_tower_cost


func _on_buy_tower_button_pressed() -> void:
	# ✅ Play button click sound
	if button_sfx_manager and button_sfx_manager.has_method("play_button_click"):
		button_sfx_manager.play_button_click()
	
	# --- Check if player has enough coins ---
	if not try_deduct_coins(current_tower_cost):
		print("❌ Tower purchase failed. Not enough gold.")
		return

	print("💰 Tower purchased successfully! Spawning tower...")

	# --- Check available slots ---
	var available_slots = []
	for slot in tower_slots:
		if not slot.is_occupied:
			available_slots.append(slot)
	
	if available_slots.is_empty():
		print("🚫 No available tower slots left!")
		return

	# --- Randomly choose an empty slot ---
	var chosen_slot: MarkerSlot = available_slots[randi() % available_slots.size()]

	# ✅ FIXED: Use the member variable tower_randomizer, don't create a local one
	if not tower_randomizer:
		push_warning("⚠️ TowerRandomizer node not found — spawning Tier 1 by default.")
		return

	# --- Get randomized tower tier ---
	var rolled_tier = tower_randomizer.get_random_tower_tier()
	tower_randomizer.debug_print_probabilities()

	# --- Construct the scene path based on the rolled tier ---
	var folder_name = "Defender%dAssets" % rolled_tier
	var scene_name = "defender%d.tscn" % rolled_tier
	var scene_path = "res://%s/%s" % [folder_name, scene_name]

	# --- Validate that the tower exists ---
	if not ResourceLoader.exists(scene_path):
		push_warning("❌ Tower scene not found for Tier %d at: %s" % [rolled_tier, scene_path])
		return

	# --- Spawn the new tower ---
	var tower_scene = load(scene_path)
	var new_tower: Node2D = tower_scene.instantiate()
	get_parent().add_child(new_tower)
	new_tower.global_position = chosen_slot.global_position

	# --- Configure the tower's drag module ---
	var drag_module = new_tower.get_node("DragModule")
	if drag_module:
		drag_module.slots_parent = tower_slots_parent
		drag_module.call_deferred("on_spawn")

	print("🎯 Spawned Tier %d Tower at slot: %s" % [rolled_tier, str(chosen_slot.name)])



func request_merge(defender1: Node2D, defender2: Node2D) -> void:
	var new_tier: int = defender1.tier + 1
	
	if new_tier > 14:
		print("⚠️ Maximum tier reached:", new_tier)
		return
	
	var folder_name = "Defender%dAssets" % new_tier
	var scene_name = "defender%d.tscn" % new_tier
	var scene_path = "res://%s/%s" % [folder_name, scene_name]
	
	if not ResourceLoader.exists(scene_path):
		print("❌ No scene found for tier", new_tier, "at path:", scene_path)
		return
	
	var merged_scene: PackedScene = load(scene_path)
	var merged_defender: Node2D = merged_scene.instantiate()
	
	# Spawn new merged tower
	merged_defender.global_position = (defender1.global_position + defender2.global_position) / 2
	get_parent().add_child(merged_defender)
	
	if "tier" in merged_defender:
		merged_defender.tier = new_tier
		print("✅ Set merged defender tier to:", new_tier)
	
	var drag_module = merged_defender.get_node("DragModule")
	if drag_module:
		drag_module.slots_parent = tower_slots_parent
		if drag_module.has_method("on_spawn"):
			drag_module.on_spawn()
	
	print("💠 Merged defender created at tier", new_tier)
	print("Available slots after merge: %d" % _count_available_slots())
	
	# Track the new highest merged tier (lifetime)
	var player_record = PlayerRecord
	
	if player_record:
		player_record.update_highest_tier(new_tier)
	else:
		push_warning("⚠️ PlayerRecord node not found — highest_tier not updated.")


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
	

func try_deduct_coins(amount: int) -> bool:
	"""
	Try to deduct coins. Returns true if successful, false if insufficient funds.
	Automatically updates UI and emits coin_collected signal.
	"""
	if coins_collected >= amount:
		coins_collected -= amount
		print("💸 Deducted %d gold. Remaining: %d" % [amount, coins_collected])
		
		# Emit signal for UI update
		coin_collected.emit(-amount)
		_update_coin_ui()
		return true
	else:
		print("❌ Not enough gold! Needed %d, have %d" % [amount, coins_collected])
		return false


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
	# ✅ Play button click sound
	if button_sfx_manager and button_sfx_manager.has_method("play_button_click"):
		button_sfx_manager.play_button_click()
	
	if wave_in_progress:
		print("⚠️  Wave already in progress!")
		return
	
	print("\n▶️  START WAVE BUTTON PRESSED!")
	if start_wave_button:
		start_wave_button.disabled = true
	
	wave_in_progress = true
	
	# ✅ Play gameplay music at 30% volume
	if music_manager and music_manager.has_method("play_gameplay_music"):
		print("🎵 Playing gameplay music at 30% volume...")
		music_manager.play_gameplay_music()
		if music_manager.has_method("set_music_volume"):
			music_manager.set_music_volume(0.3)
	
	if spawner:
		spawner.start_wave(current_wave + 1)

## Calculate enemy count based on wave number
func _calculate_wave_enemy_count(wave_number: int) -> int:
	"""
	Enemy count scaling logic:
	- Wave 1: 5 Warrior
	- Wave 2: 5 Archers
	- Wave 3: 5 Lancers
	- Wave 4: 5 Monks
	- Wave 5: 10 enemies (randomized mix)
	- Wave 6+: +3 per wave (13, 16, 19, 22...)
	"""
	
	if wave_number <= 4:
		return 5
	elif wave_number == 5:
		return 10
	else:
		return 10 + 3 + (wave_number - 6) * 3

## Generate enemy composition for a wave
func _generate_wave_enemies(wave_number: int) -> Array:
	"""
	Wave progression:
	- Wave 1: All Warrior (1)
	- Wave 2: All Archer (5)
	- Wave 3: All Lancer (5)
	- Wave 4: All Monk (5)
	- Wave 5+: Randomized mix of all enemy types
	"""
	
	var total_enemies = _calculate_wave_enemy_count(wave_number)
	var enemy_composition = []
	
	if wave_number == 1:
		enemy_composition.append({"type": "Warrior", "count": total_enemies})
		print("🎯 Wave 1: All Warrior (%d enemy)" % total_enemies)
	
	elif wave_number == 2:
		enemy_composition.append({"type": "Archer", "count": total_enemies})
		print("🎯 Wave 2: All Archer (%d enemies)" % total_enemies)
	
	elif wave_number == 3:
		enemy_composition.append({"type": "Lancer", "count": total_enemies})
		print("🎯 Wave 3: All Lancer (%d enemies)" % total_enemies)
	
	elif wave_number == 4:
		enemy_composition.append({"type": "Monk", "count": total_enemies})
		print("🎯 Wave 4: All Monk (%d enemies)" % total_enemies)
	
	else:
		# Wave 5+: Randomized mix of all enemy types
		var warriors = randi_range(int(total_enemies * 0.2), int(total_enemies * 0.4))
		var archers = randi_range(int(total_enemies * 0.2), int(total_enemies * 0.35))
		var lancers = randi_range(int(total_enemies * 0.15), int(total_enemies * 0.3))
		var monks = total_enemies - warriors - archers - lancers
		
		if monks < 0:
			monks = 0
		
		enemy_composition.append({"type": "Warrior", "count": warriors})
		enemy_composition.append({"type": "Archer", "count": archers})
		enemy_composition.append({"type": "Lancer", "count": lancers})
		enemy_composition.append({"type": "Monk", "count": monks})
		
		print("🎯 Wave %d: Randomized mix - Warriors: %d, Archers: %d, Lancers: %d, Monks: %d (Total: %d)" % [wave_number, warriors, archers, lancers, monks, total_enemies])
	
	return enemy_composition

func get_wave_enemy_config(wave_number: int) -> Dictionary:
	"""Get enemy configuration for any wave (infinite support)"""
	var enemies = _generate_wave_enemies(wave_number)
	return {"enemies": enemies}

func get_enemies_for_wave(wave_number: int) -> int:
	var config = get_wave_enemy_config(wave_number)
	var total = 0
	for enemy_data in config["enemies"]:
		total += enemy_data["count"]
	print("📊 Wave %d breakdown: Total: %d" % [wave_number, total])
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
	
	# ✅ Restore music volume after wave
	if music_manager and music_manager.has_method("set_music_volume"):
		print("🎵 Restoring music volume to 100%...")
		music_manager.set_music_volume(1.0)
	
	# ✅ Play wave complete music
	if music_manager and music_manager.has_method("play_wave_complete_music"):
		music_manager.play_wave_complete_music()
	
	_reset_start_wave_button()
	
	# ✅ Update player record
	PlayerRecord.update_wave_record(current_wave)
	_update_record_label()
	
	print("⏳ Ready for next wave!")
	var next_wave = current_wave + 1
	print("🔘 START WAVE button is now ACTIVE - Click to start wave ", next_wave)
	
	# ✅ ONLY auto-start if enabled
	if auto_start_next_wave:
		print("   (Auto-starting in ", int(wave_delay), " seconds)")
		await get_tree().create_timer(wave_delay).timeout
		_start_next_wave_auto()
	else:
		print("   (Click button to start next wave)")
	
	# Increase tower cost nonlinearly based on current wave
	current_tower_cost = calculate_tower_cost(current_wave)
	update_buy_button_label()

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
			
			# ✅ Reduce music volume for wave
			if music_manager and music_manager.has_method("set_music_volume"):
				music_manager.set_music_volume(0.3)
			
			# ✅ Play gameplay music
			if music_manager and music_manager.has_method("play_gameplay_music"):
				music_manager.play_gameplay_music()
			
			spawner.start_wave(next_wave)
			if start_wave_button:
				start_wave_button.disabled = true

func _enable_restart_button() -> void:
	# ✅ ADDED: Clean up unpicked coins before enabling restart
	print("\n🧹 Cleaning up unpicked coins...")
	_cleanup_dropped_coins()
	
	if start_wave_button:
		start_wave_button.text = "Restart Level"
		start_wave_button.button_pressed = false
		start_wave_button.disabled = false
		start_wave_button.modulate = Color.WHITE
		print("✓ Restart button enabled")

# ===== LEVEL RESET & CLEANUP =====
func restart_level() -> void:
	print("\n========== RESTARTING LEVEL ==========")
	
	# ✅ ADDED: Clean up unpicked coins FIRST
	print("🧹 Cleaning up unpicked coins before restart...")
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
	
	# ✅ Stop music on restart
	if music_manager and music_manager.has_method("stop_music"):
		music_manager.stop_music()
	
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

# ===== Update the highest wave UI label =====
func _update_record_label() -> void:
	if record_label:
		record_label.text = "Highest Wave: %d" % PlayerRecord.highest_wave
