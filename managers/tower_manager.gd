extends Node2D

@export var tower_randomizer: NodePath
@export var tower_slots_parent_path: NodePath
@export var base_tower_cost := 5
@export var cost_growth_rate := 1.25

var current_tower_cost := base_tower_cost
var tower_slots: Array[MarkerSlot] = []
var coin_manager: Node = null

func _ready():
	_gather_slots()
	_update_tower_cost(0)
	print("✅ TowerManager ready with", tower_slots.size(), "slots")
	

func _on_buy_tower_button_pressed() -> void:
	buy_tower()

func _gather_slots():
	var parent = get_node(tower_slots_parent_path)
	for child in parent.get_children():
		if child is MarkerSlot:
			tower_slots.append(child)

func _update_tower_cost(wave_number: int):
	current_tower_cost = int(base_tower_cost * pow(cost_growth_rate, wave_number))

func buy_tower():
	if not coin_manager.try_deduct(current_tower_cost):
		print("❌ Not enough gold!")
		return false
	_spawn_tower()
	return true

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

	# ✅ NEW: Mark slot as occupied and link both ways
	chosen_slot.is_occupied = true
	chosen_slot.current_tower = tower
	tower.set_meta("current_slot", chosen_slot)

	# ✅ NEW: Initialize drag logic if present
	var drag_module = tower.get_node_or_null("DragModule")
	if drag_module:
		if not drag_module.slots_parent:
			var tm_slots = get_node_or_null("TowerSlots")
			if tm_slots:
				drag_module.slots_parent = tm_slots
		drag_module.call_deferred("on_spawn")

func request_merge(def1: Node2D, def2: Node2D) -> void:
	var merge_handler = get_node_or_null("MergeHandler")
	if merge_handler:
		merge_handler.request_merge(def1, def2)
	else:
		push_warning("MergeHandler not found!")
