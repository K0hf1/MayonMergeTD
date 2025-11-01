extends Node2D

@export var tower_randomizer: NodePath
@export var tower_slots_parent_path: NodePath
@export var buy_tower_button_path: NodePath
@export var base_tower_cost := 5
@export var cost_growth_rate := 1.25

var current_tower_cost := base_tower_cost
var tower_slots: Array[MarkerSlot] = []
var coin_manager: Node = null
var buy_tower_button: Button = null
var current_wave: int = 0

func _ready():
	# Gather tower slots
	_gather_slots()
	
	# Find coin manager
	_find_coin_manager()
	
	# Assign buy tower button from exported path
	buy_tower_button = get_node_or_null(buy_tower_button_path)
	if not buy_tower_button:
		push_warning("Buy Tower button not assigned!")
	
	# Initialize tower cost and button text
	_update_tower_cost(0)
	
	print("✅ TowerManager ready with", tower_slots.size(), "slots")


# --- COIN MANAGER ---
func _find_coin_manager():
	coin_manager = get_node_or_null("/root/Main/CoinManager")
	if not coin_manager:
		coin_manager = get_tree().root.find_child("CoinManager", true, false)
	if not coin_manager:
		push_warning("CoinManager not found!")


# --- BUTTON INPUT ---
func _on_buy_tower_button_pressed() -> void:
	buy_tower()


# --- TOWER SLOTS ---
func _gather_slots():
	var parent = get_node_or_null(tower_slots_parent_path)
	if not parent:
		push_warning("Tower slots parent not found!")
		return
	for child in parent.get_children():
		if child is MarkerSlot:
			tower_slots.append(child)


# --- TOWER COST & BUTTON TEXT ---
func _update_tower_cost(wave_number: int):
	current_tower_cost = int(base_tower_cost * pow(cost_growth_rate, wave_number))
	_update_buy_button_text()

func _update_buy_button_text():
	if buy_tower_button:
		buy_tower_button.text = "Buy Tower\n(%d Gold)" % current_tower_cost


# --- BUY TOWER ---
func buy_tower():
	if not coin_manager or not coin_manager.try_deduct(current_tower_cost):
		print("❌ Not enough gold!")
		return false
	_spawn_tower()
	return true


# --- SPAWN TOWER ---
func _spawn_tower():
	var empty_slots = tower_slots.filter(func(s): return not s.is_occupied)
	if empty_slots.is_empty():
		print("🚫 No available slots!")
		return

	var chosen_slot = empty_slots[randi() % empty_slots.size()]
	var tier = get_node(tower_randomizer).get_random_tower_tier()
	var scene_path = "res://Defender%dAssets/defender%d.tscn" % [tier, tier]
	if not ResourceLoader.exists(scene_path):
		push_warning("Tower scene not found: %s" % scene_path)
		return

	var tower = load(scene_path).instantiate()
	get_parent().add_child(tower)
	tower.global_position = chosen_slot.global_position
	print("🎯 Spawned tower tier", tier)

	# Mark slot as occupied
	chosen_slot.is_occupied = true
	chosen_slot.current_tower = tower
	tower.set_meta("current_slot", chosen_slot)

	# Initialize drag module if present
	var drag_module = tower.get_node_or_null("DragModule")
	if drag_module and not drag_module.slots_parent:
		var tm_slots = get_node_or_null("TowerSlots")
		if tm_slots:
			drag_module.slots_parent = tm_slots
		drag_module.call_deferred("on_spawn")


# --- MERGE HANDLER ---
func request_merge(def1: Node2D, def2: Node2D) -> void:
	var merge_handler = get_node_or_null("MergeHandler")
	if merge_handler:
		merge_handler.request_merge(def1, def2)
	else:
		push_warning("MergeHandler not found!")


# --- WAVE HANDLING ---
func set_current_wave(wave_number: int):
	"""
	Call this from GameManager whenever the wave changes.
	Updates the tower cost and button text automatically.
	"""
	current_wave = wave_number
	_update_tower_cost(current_wave)
	
	# ✅ Print tower cost for this wave
	print("🌊 Wave %d ended — Tower cost is now: %d" % [current_wave, current_tower_cost])
