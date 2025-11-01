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


# --- Merge two defenders into next tier ---
func request_merge(defender1: Node2D, defender2: Node2D) -> void:
	# Defensive checks
	if not is_instance_valid(defender1) or not is_instance_valid(defender2):
		print("❌ request_merge: invalid defender(s)")
		return

	# Attempt to read tiers (support property or method if present)
	var tier_a: int = -1
	var tier_b: int = -1
	if "tier" in defender1:
		tier_a = int(defender1.tier)
	elif defender1.has_method("get"):
		tier_a = int(defender1.get("tier") if defender1.get("tier") != null else -1)

	if "tier" in defender2:
		tier_b = int(defender2.tier)
	elif defender2.has_method("get"):
		tier_b = int(defender2.get("tier") if defender2.get("tier") != null else -1)

	if tier_a < 0 or tier_b < 0:
		push_warning("request_merge: could not determine defender tiers")
		return

	if tier_a != tier_b:
		push_warning("request_merge: tiers do not match (%d vs %d)" % [tier_a, tier_b])
		return

	var new_tier: int = tier_a + 1

	# Cap new tier
	const MAX_TIER := 14
	if new_tier > MAX_TIER:
		print("⚠️ request_merge: maximum tier reached:", new_tier)
		return

	# Build scene path
	var folder_name = "Defender%dAssets" % new_tier
	var scene_name = "defender%d.tscn" % new_tier
	var scene_path = "res://%s/%s" % [folder_name, scene_name]

	if not ResourceLoader.exists(scene_path):
		print("❌ request_merge: no scene for tier %d at %s" % [new_tier, scene_path])
		return

	var merged_scene: PackedScene = load(scene_path)
	if not merged_scene:
		push_warning("❌ request_merge: failed to load merged scene: %s" % scene_path)
		return

	# Decide spawn parent and position (midpoint)
	var spawn_parent: Node = defender1.get_parent() if defender1.get_parent() else get_parent()
	var spawn_pos: Vector2 = (defender1.global_position + defender2.global_position) * 0.5

	# Free and capture previous slot references BEFORE deleting nodes
	var slot1: MarkerSlot = null
	var slot2: MarkerSlot = null
	if defender1.has_meta("current_slot"):
		slot1 = defender1.get_meta("current_slot")
	if defender2.has_meta("current_slot"):
		slot2 = defender2.get_meta("current_slot")

	# Free those slots now (we will reassign one of them to merged)
	if slot1:
		slot1.is_occupied = false
		slot1.current_tower = null
	if slot2:
		slot2.is_occupied = false
		slot2.current_tower = null

	# Instantiate merged defender and configure
	var merged_defender: Node2D = merged_scene.instantiate()
	merged_defender.global_position = spawn_pos
	spawn_parent.add_child(merged_defender)

	# Ensure merged defender is in defender groups used by other systems
	if not merged_defender.is_in_group("Defender"):
		merged_defender.add_to_group("Defender")
	if not merged_defender.is_in_group("defender"):
		merged_defender.add_to_group("defender")

	# Assign tier property if supported
	if "tier" in merged_defender:
		merged_defender.tier = new_tier
	elif merged_defender.has_method("set"):
		# best-effort try
		merged_defender.set("tier", new_tier)

	# Try to attach to one of the freed slots (prefer slot2 then slot1)
	var assigned_slot: MarkerSlot = null
	if slot2 and is_instance_valid(slot2):
		assigned_slot = slot2
	elif slot1 and is_instance_valid(slot1):
		assigned_slot = slot1


	if assigned_slot:
		merged_defender.global_position = assigned_slot.global_position
		assigned_slot.is_occupied = true
		assigned_slot.current_tower = merged_defender
		merged_defender.set_meta("current_slot", assigned_slot)
		print("✅ Merged defender snapped to freed slot at", assigned_slot.global_position)
	else:
		print("⚠️ No freed slot available — merged defender placed at midpoint:", spawn_pos)

	# Configure DragModule on merged defender (so it can snap/swap later)
	var drag_module = merged_defender.get_node_or_null("DragModule")
	if drag_module:
		# Prefer TowerManager's known slots_parent if available
		if has_node("TowerSlots"):
			# if TowerSlots is a child of TowerManager
			var tm_slots = get_node_or_null("TowerSlots")
			if tm_slots:
				drag_module.slots_parent = tm_slots
		elif "slots_parent" in self and self.slots_parent != null:
			drag_module.slots_parent = self.slots_parent
		else:
			# fallback: try to find TowerManager->TowerSlots in the tree
			var tower_mgr = get_tree().root.find_child("TowerManager", true, false)
			if tower_mgr:
				drag_module.slots_parent = tower_mgr.find_child("TowerSlots", true, false)

		# Call spawn hook if any
		if drag_module.has_method("on_spawn"):
			drag_module.on_spawn()
		else:
			drag_module.call_deferred("on_spawn")

	# Play merge sound if available
	var sfx_mgr = get_tree().root.find_child("ButtonSFXManager", true, false)
	if sfx_mgr and sfx_mgr.has_method("play_merge"):
		sfx_mgr.play_merge()

	# Update PlayerRecord highest tier
	if PlayerRecord and PlayerRecord.has_method("update_highest_tier"):
		PlayerRecord.update_highest_tier(new_tier)

	print("💠 Merged defender created at tier", new_tier)

	# Finally, remove the original defenders (deferred to avoid tree issues)
	# Remove them from groups and free
	if is_instance_valid(defender1):
		defender1.remove_from_group("Defender")
		defender1.remove_from_group("defender")
		defender1.queue_free()
	if is_instance_valid(defender2):
		defender2.remove_from_group("Defender")
		defender2.remove_from_group("defender")
		defender2.queue_free()
