extends Node2D

# Drag state
var dragging: bool = false
var offset: Vector2 = Vector2.ZERO
var original_position: Vector2
var is_snapping: bool = false

# Reference to the defender root node
var tower_root: Node2D

# Reference to the parent node that holds tower slots
@export var slots_parent: Node

# Current slot reference
var current_slot: MarkerSlot = null

# Tier tracking label
var tier_label: Label = null

# ✅ NEW: GameManager reference
var game_manager: Node = null

func _ready() -> void:
	tower_root = get_parent() as Node2D
	original_position = tower_root.global_position

	# ✅ NEW: Find GameManager
	game_manager = get_tree().root.find_child("GameManager", true, false)
	if not game_manager:
		game_manager = get_node_or_null("/root/main/GameManager")
	
	if game_manager:
		print("✓ DragModule: GameManager found")
	else:
		print("❌ DragModule: GameManager NOT FOUND!")

	# Connect button signals (assumes button is named "Dragging")
	var drag_button = $Dragging
	drag_button.connect("button_down", Callable(self, "_on_drag_button_down"))
	drag_button.connect("button_up", Callable(self, "_on_drag_button_up"))

func _process(delta: float) -> void:
	if dragging:
		tower_root.global_position = get_global_mouse_position() + offset

func _on_drag_button_down() -> void:
	dragging = true
	original_position = tower_root.global_position
	offset = tower_root.global_position - get_global_mouse_position()
	
	# Print debug info
	print("Dragging defender - Tier: %s" % tower_root.tier)

func _on_drag_button_up() -> void:
	dragging = false

	# Check collision with other defenders
	var collided_defender = _get_collided_defender()
	if collided_defender:
		# Get both tiers
		var my_tier = tower_root.tier
		var other_tier = collided_defender.tier
		
		# Debug print
		print("Collision detected - My tier: %s, Other tier: %s" % [my_tier, other_tier])
		
		# ✅ UPDATED: Check wave-based merging
		if my_tier == other_tier:
			print("✅ Merging defenders of tier %s" % my_tier)
			_merge_defenders(collided_defender)
			return
		else:
			# Different tiers OR not mergeable → swap positions
			print("Swapping defenders - Tier %s <-> Tier %s" % [my_tier, other_tier])
			_swap_with_defender(collided_defender)
			return

	# No collision → snap to nearest slot
	_snap_to_nearest_slot()

# --- Helper Methods ---

func _get_collided_defender() -> Node2D:
	# Iterate all defenders in the "defender" group
	for defender in get_tree().get_nodes_in_group("defender"):
		if defender == tower_root:
			continue
		var distance = tower_root.global_position.distance_to(defender.global_position)
		if distance < 32: # collision radius (tweak for your sprite size)
			return defender
	return null


func _merge_defenders(other_defender: Node2D) -> void:
	# Clear slot occupancy for both defenders
	if tower_root.has_meta("current_slot"):
		var my_slot: MarkerSlot = tower_root.get_meta("current_slot")
		my_slot.is_occupied = false
		my_slot.current_tower = null
		print("Freed slot 1 at: %s" % my_slot.global_position)
		
	if other_defender.has_meta("current_slot"):
		var other_slot: MarkerSlot = other_defender.get_meta("current_slot")
		other_slot.is_occupied = false
		other_slot.current_tower = null
		print("Freed slot 2 at: %s" % other_slot.global_position)

	# Request merge from GameManager
	get_tree().root.get_node("main/GameManager").request_merge(tower_root, other_defender)
	
	print("About to delete defenders - slots should be free now")
	
	# Delete both defenders
	tower_root.queue_free()
	other_defender.queue_free()

func _swap_with_defender(other_defender: Node2D) -> void:
	# Ensure both defenders have current_slot metadata
	if not tower_root.has_meta("current_slot") or not other_defender.has_meta("current_slot"):
		print("Swap aborted: slot data not ready")
		tower_root.global_position = original_position
		_snap_to_nearest_slot()
		return

	var my_slot: MarkerSlot = tower_root.get_meta("current_slot")
	var other_slot: MarkerSlot = other_defender.get_meta("current_slot")

	if not my_slot or not other_slot:
		print("Swap aborted: invalid slot references")
		tower_root.global_position = original_position
		_snap_to_nearest_slot()
		return

	# Temporarily free the slots
	my_slot.is_occupied = false
	other_slot.is_occupied = false
	my_slot.current_tower = null
	other_slot.current_tower = null

	# Swap positions
	tower_root.global_position = other_slot.global_position
	other_defender.global_position = my_slot.global_position

	# Update slot occupancy
	my_slot.current_tower = other_defender
	my_slot.is_occupied = true
	other_defender.set_meta("current_slot", my_slot)

	other_slot.current_tower = tower_root
	other_slot.is_occupied = true
	tower_root.set_meta("current_slot", other_slot)

	# Update current_slot reference
	current_slot = other_slot
	
	print("Swap completed successfully")

func _snap_to_nearest_slot() -> void:
	var slots = slots_parent.get_children()
	var closest_slot: MarkerSlot = null	
	var min_dist = INF
	
	# Get current slot if exists
	var current_occupied_slot: MarkerSlot = null
	if tower_root.has_meta("current_slot"):
		current_occupied_slot = tower_root.get_meta("current_slot")

	for slot in slots:
		if slot is MarkerSlot:
			# A slot is available if it's not occupied OR if it's our current slot
			var is_available = not slot.is_occupied or slot == current_occupied_slot
			if is_available:
				var dist = tower_root.global_position.distance_to(slot.global_position)
				if dist < min_dist and dist <= slot.snap_radius:
					min_dist = dist
					closest_slot = slot

	if closest_slot:
		# Clear previous slot occupancy if moving to a different slot
		if current_occupied_slot and current_occupied_slot != closest_slot:
			current_occupied_slot.is_occupied = false
			current_occupied_slot.current_tower = null

		# Snap to the slot
		tower_root.global_position = closest_slot.global_position

		# Update new slot occupancy
		closest_slot.is_occupied = true
		closest_slot.current_tower = tower_root
		tower_root.set_meta("current_slot", closest_slot)
		current_slot = closest_slot
		
		print("Snapped to slot at: %s" % closest_slot.global_position)
	else:
		# No slot in range - return to current slot if we have one
		if current_occupied_slot:
			tower_root.global_position = current_occupied_slot.global_position
			print("Returned to current slot")
		else:
			# This should rarely happen - tower spawned without a slot
			tower_root.global_position = original_position
			print("WARNING: Tower has no valid slot!")

func on_spawn() -> void:
	# Called when a defender is instantiated programmatically
	call_deferred("_snap_to_nearest_slot")
	call_deferred("_update_tier_label")
	
func _update_tier_label() -> void:
	if not tier_label:
		tier_label = tower_root.get_node_or_null("TierLabel")
	if tier_label and tower_root.has_method("tier"):
		tier_label.text = "Tier %d" % tower_root.tier
		print("Tier label updated to:", tier_label.text)
