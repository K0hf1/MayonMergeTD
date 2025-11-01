extends Node2D

# Drag state
var dragging: bool = false
var offset: Vector2 = Vector2.ZERO
var original_position: Vector2
var is_snapping: bool = false

# Reference to the defender root node
var tower_root: Node2D

# Automatically find the TowerSlots node under TowerManager
var slots_parent: Node = null


# Current slot reference
var current_slot: MarkerSlot = null

# Tier tracking label
var tier_label: Label = null

# GameManager and SFX Manager references
var game_manager: Node = null
var button_sfx_manager: Node = null

func _ready() -> void:
	tower_root = get_parent() as Node2D
	original_position = tower_root.global_position

	# ✅ Auto-locate GameManager
	game_manager = get_tree().root.find_child("GameManager", true, false)
	if not game_manager:
		game_manager = get_node_or_null("/root/Main/GameManager")
	if game_manager:
		print("✓ DragModule: GameManager found")
	else:
		print("❌ DragModule: GameManager NOT found!")

	# ✅ Auto-locate ButtonSFXManager
	button_sfx_manager = get_tree().root.find_child("ButtonSFXManager", true, false)
	if not button_sfx_manager:
		button_sfx_manager = get_node_or_null("/root/Main/ButtonSFXManager")
	if button_sfx_manager:
		print("✓ DragModule: ButtonSFXManager found")
	else:
		print("⚠️ DragModule: ButtonSFXManager NOT found!")

	# ✅ Auto-locate TowerSlots (under TowerManager)
	if not slots_parent:
		var tower_manager = get_tree().root.find_child("TowerManager", true, false)
		if tower_manager:
			slots_parent = tower_manager.find_child("TowerSlots", true, false)
			if slots_parent:
				print("✓ DragModule: TowerSlots found under TowerManager")
			else:
				print("❌ DragModule: TowerSlots NOT found under TowerManager!")
		else:
			print("❌ DragModule: TowerManager not found!")

	# Connect drag button
	var drag_button = $Dragging
	if drag_button:
		drag_button.connect("button_down", Callable(self, "_on_drag_button_down"))
		drag_button.connect("button_up", Callable(self, "_on_drag_button_up"))
	else:
		print("⚠️ DragModule: No Dragging button found!")

func _process(delta: float) -> void:
	if dragging:
		tower_root.global_position = get_global_mouse_position() + offset

func _on_drag_button_down() -> void:
	dragging = true
	original_position = tower_root.global_position
	offset = tower_root.global_position - get_global_mouse_position()
	print("Dragging defender - Tier: %s" % tower_root.tier)

func _on_drag_button_up() -> void:
	dragging = false

	# Check for defender collision
	var collided_defender = _get_collided_defender()
	if collided_defender:
		var my_tier = tower_root.tier
		var other_tier = collided_defender.tier

		print("Collision detected - My tier: %s, Other tier: %s" % [my_tier, other_tier])

		if my_tier == other_tier:
			print("✅ Merging defenders of tier %s" % my_tier)
			_merge_defenders(collided_defender)
			return
		else:
			print("Swapping defenders - Tier %s <-> Tier %s" % [my_tier, other_tier])
			_swap_with_defender(collided_defender)
			return

	# No collision → snap to nearest slot
	_snap_to_nearest_slot()

# --- Helper Methods ---

func _get_collided_defender() -> Node2D:
	for defender in get_tree().get_nodes_in_group("defender"):
		if defender == tower_root:
			continue
		var distance = tower_root.global_position.distance_to(defender.global_position)
		if distance < 32:
			return defender
	return null

func _merge_defenders(other_defender: Node2D) -> void:
	if button_sfx_manager and button_sfx_manager.has_method("play_merge"):
		button_sfx_manager.play_merge()

	# Clear slots
	if tower_root.has_meta("current_slot"):
		var my_slot: MarkerSlot = tower_root.get_meta("current_slot")
		my_slot.is_occupied = false
		my_slot.current_tower = null
	if other_defender.has_meta("current_slot"):
		var other_slot: MarkerSlot = other_defender.get_meta("current_slot")
		other_slot.is_occupied = false
		other_slot.current_tower = null

	var tower_manager = get_tree().root.find_child("TowerManager", true, false)
	if tower_manager and tower_manager.has_method("request_merge"):
		tower_manager.request_merge(tower_root, other_defender)
	else:
		print("⚠️ Merge failed: TowerManager not found or missing request_merge()")


	tower_root.queue_free()
	other_defender.queue_free()

func _swap_with_defender(other_defender: Node2D) -> void:
	if not tower_root.has_meta("current_slot") or not other_defender.has_meta("current_slot"):
		print("Swap aborted: slot data not ready")
		_snap_to_nearest_slot()
		return

	var my_slot: MarkerSlot = tower_root.get_meta("current_slot")
	var other_slot: MarkerSlot = other_defender.get_meta("current_slot")
	if not my_slot or not other_slot:
		print("Swap aborted: invalid slot refs")
		_snap_to_nearest_slot()
		return

	my_slot.is_occupied = false
	other_slot.is_occupied = false
	my_slot.current_tower = null
	other_slot.current_tower = null

	tower_root.global_position = other_slot.global_position
	other_defender.global_position = my_slot.global_position

	my_slot.current_tower = other_defender
	my_slot.is_occupied = true
	other_defender.set_meta("current_slot", my_slot)

	other_slot.current_tower = tower_root
	other_slot.is_occupied = true
	tower_root.set_meta("current_slot", other_slot)
	current_slot = other_slot

	print("Swap completed successfully")

func _snap_to_nearest_slot() -> void:
	if not slots_parent:
		print("❌ _snap_to_nearest_slot: slots_parent is NULL. Attempting recovery...")
		var tower_manager = get_tree().root.find_child("TowerManager", true, false)
		if tower_manager:
			slots_parent = tower_manager.find_child("TowerSlots", true, false)
			if not slots_parent:
				print("❌ Still cannot find TowerSlots.")
				return
		else:
			print("❌ TowerManager not found either!")
			return

	var slots = slots_parent.get_children()
	var closest_slot: MarkerSlot = null
	var min_dist = INF

	var current_occupied_slot: MarkerSlot = null
	if tower_root.has_meta("current_slot"):
		current_occupied_slot = tower_root.get_meta("current_slot")

	for slot in slots:
		if slot is MarkerSlot:
			var is_available = not slot.is_occupied or slot == current_occupied_slot
			if is_available:
				var dist = tower_root.global_position.distance_to(slot.global_position)
				if dist < min_dist and dist <= slot.snap_radius:
					min_dist = dist
					closest_slot = slot

	if closest_slot:
		if current_occupied_slot and current_occupied_slot != closest_slot:
			current_occupied_slot.is_occupied = false
			current_occupied_slot.current_tower = null

		tower_root.global_position = closest_slot.global_position
		closest_slot.is_occupied = true
		closest_slot.current_tower = tower_root
		tower_root.set_meta("current_slot", closest_slot)
		current_slot = closest_slot
		print("Snapped to slot at:", closest_slot.global_position)
	else:
		if current_occupied_slot:
			tower_root.global_position = current_occupied_slot.global_position
			print("Returned to current slot")
		else:
			tower_root.global_position = original_position
			print("WARNING: Tower has no valid slot!")

func on_spawn() -> void:
	call_deferred("_snap_to_nearest_slot")
	call_deferred("_update_tier_label")

func _update_tier_label() -> void:
	if not tier_label:
		tier_label = tower_root.get_node_or_null("TierLabel")
	if tier_label:
		tier_label.text = "Tier %d" % tower_root.tier
