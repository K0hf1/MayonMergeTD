extends Node

@export var max_tier: int = 14

# Reference back to TowerManager if needed
var tower_manager: Node = null

func request_merge(defender1: Node2D, defender2: Node2D) -> void:
	if not is_instance_valid(defender1) or not is_instance_valid(defender2):
		print("❌ request_merge: invalid defender(s)")
		return

	var tier_a = _get_defender_tier(defender1)
	var tier_b = _get_defender_tier(defender2)

	if tier_a < 0 or tier_b < 0:
		push_warning("request_merge: could not determine defender tiers")
		return
	if tier_a != tier_b:
		push_warning("request_merge: tiers do not match (%d vs %d)" % [tier_a, tier_b])
		return

	var new_tier = tier_a + 1
	if new_tier > max_tier:
		print("⚠️ request_merge: maximum tier reached:", new_tier)
		return

	var merged_scene_path = "res://Defender%dAssets/defender%d.tscn" % [new_tier, new_tier]
	if not ResourceLoader.exists(merged_scene_path):
		print("❌ request_merge: no scene for tier %d at %s" % [new_tier, merged_scene_path])
		return

	var merged_scene: PackedScene = load(merged_scene_path)
	if not merged_scene:
		push_warning("❌ request_merge: failed to load merged scene: %s" % merged_scene_path)
		return

	_spawn_merged(defender1, defender2, merged_scene, new_tier)


func _get_defender_tier(defender: Node2D) -> int:
	if "tier" in defender:
		return int(defender.tier)
	elif defender.has_method("get"):
		return int(defender.get("tier") if defender.get("tier") != null else -1)
	return -1


func _spawn_merged(def1: Node2D, def2: Node2D, merged_scene: PackedScene, new_tier: int) -> void:
	var spawn_parent: Node = def1.get_parent() if def1.get_parent() else get_parent()
	var spawn_pos: Vector2 = (def1.global_position + def2.global_position) * 0.5

	# Free previous slots
	var slot1 = def1.get_meta("current_slot") if def1.has_meta("current_slot") else null
	var slot2 = def2.get_meta("current_slot") if def2.has_meta("current_slot") else null

	if slot1:
		slot1.is_occupied = false
		slot1.current_tower = null
	if slot2:
		slot2.is_occupied = false
		slot2.current_tower = null

	# Instantiate merged defender
	var merged_defender: Node2D = merged_scene.instantiate()
	merged_defender.global_position = spawn_pos
	spawn_parent.add_child(merged_defender)
	merged_defender.add_to_group("Defender")
	merged_defender.add_to_group("defender")
	
	if "tier" in merged_defender:
		merged_defender.tier = new_tier
	elif merged_defender.has_method("set"):
		merged_defender.set("tier", new_tier)

	# Snap to freed slot if available
	var assigned_slot = slot2 if slot2 and is_instance_valid(slot2) else slot1
	if assigned_slot:
		merged_defender.global_position = assigned_slot.global_position
		assigned_slot.is_occupied = true
		assigned_slot.current_tower = merged_defender
		merged_defender.set_meta("current_slot", assigned_slot)
		print("✅ Merged defender snapped to freed slot at", assigned_slot.global_position)
	else:
		print("⚠️ No freed slot available — merged defender placed at midpoint:", spawn_pos)

	# Configure DragModule if present
	var drag_module = merged_defender.get_node_or_null("DragModule")
	if drag_module:
		if tower_manager and tower_manager.has_node("TowerSlots"):
			drag_module.slots_parent = tower_manager.get_node("TowerSlots")
		if drag_module.has_method("on_spawn"):
			drag_module.on_spawn()
		else:
			drag_module.call_deferred("on_spawn")

	# Play merge sound
	var sfx_mgr = get_tree().root.find_child("ButtonSFXManager", true, false)
	if sfx_mgr and sfx_mgr.has_method("play_merge"):
		sfx_mgr.play_merge()

	# Update PlayerRecord highest tier
	if PlayerRecord and PlayerRecord.has_method("update_highest_tier"):
		PlayerRecord.update_highest_tier(new_tier)

	# Remove originals
	if is_instance_valid(def1):
		def1.remove_from_group("Defender")
		def1.remove_from_group("defender")
		def1.queue_free()
	if is_instance_valid(def2):
		def2.remove_from_group("Defender")
		def2.remove_from_group("defender")
		def2.queue_free()

	print("💠 Merged defender created at tier", new_tier)
