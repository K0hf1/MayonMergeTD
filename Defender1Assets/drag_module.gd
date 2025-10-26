extends Node2D

# Drag state
var dragging: bool = false
var offset: Vector2 = Vector2.ZERO
var original_position: Vector2

# Reference to the defender root node
var tower_root: Node2D

# Reference to the parent node that holds tower slots
@export var slots_parent: Node

# Current slot reference
var current_slot: MarkerSlot = null

func _ready() -> void:
	tower_root = get_parent() as Node2D
	original_position = tower_root.global_position

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

func _on_drag_button_up() -> void:
	dragging = false

	# Get this defender's tier from root
	var my_tier = tower_root.tier

	# --- Check collision with other defenders ---
	var collided_defender = _get_collided_defender()
	if collided_defender:
		var other_tier = collided_defender.tier
		if other_tier == my_tier:
			# Same tier → delete both and request merge
			if tower_root.has_meta("current_slot"):
				current_slot.is_occupied = false
				current_slot.current_tower = null
			if collided_defender.has_meta("current_slot"):
				var other_slot: MarkerSlot = collided_defender.get_meta("current_slot")
				other_slot.is_occupied = false
				other_slot.current_tower = null

			get_tree().root.get_node("main/GameManager").request_merge(tower_root, collided_defender)
			tower_root.queue_free()
			collided_defender.queue_free()
			return
		else:
			# Different tier → swap positions
			_swap_with_defender(collided_defender)
			return

	# --- No collision → snap to nearest slot ---
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

func _swap_with_defender(other_defender: Node2D) -> void:
	if not (tower_root.has_meta("current_slot") and other_defender.has_meta("current_slot")):
		return

	var my_slot: MarkerSlot = tower_root.get_meta("current_slot")
	var other_slot: MarkerSlot = other_defender.get_meta("current_slot")

	# Step 1: temporarily free the slots
	my_slot.is_occupied = false
	other_slot.is_occupied = false
	my_slot.current_tower = null
	other_slot.current_tower = null

	# Step 2: swap positions
	tower_root.global_position = other_slot.global_position
	other_defender.global_position = my_slot.global_position

	# Step 3: update slot occupancy and metadata
	my_slot.current_tower = other_defender
	my_slot.is_occupied = true

	other_slot.current_tower = tower_root
	other_slot.is_occupied = true

	# Step 4: update each defender's current_slot meta
	tower_root.set_meta("current_slot", other_slot)
	other_defender.set_meta("current_slot", my_slot)


func _snap_to_nearest_slot() -> void:
	var slots = slots_parent.get_children()
	var closest_slot: MarkerSlot = null	
	var min_dist = INF

	for slot in slots:
		if slot is MarkerSlot and not slot.is_occupied:
			var dist = tower_root.global_position.distance_to(slot.global_position)
			if dist < min_dist and dist <= slot.snap_radius:
				min_dist = dist
				closest_slot = slot

	if closest_slot:
		# Snap to nearest slot
		tower_root.global_position = closest_slot.global_position

		# Clear previous slot occupancy if any
		if tower_root.has_meta("current_slot"):
			var old_slot: MarkerSlot = tower_root.get_meta("current_slot")
			old_slot.is_occupied = false
			old_slot.current_tower = null

		# Update new slot occupancy
		closest_slot.is_occupied = true
		closest_slot.current_tower = tower_root
		tower_root.set_meta("current_slot", closest_slot)
		current_slot = closest_slot
	else:
		# No slot → return to original position
		tower_root.global_position = original_position
		

func on_spawn() -> void:
	# Called when a defender is instantiated programmatically
	_snap_to_nearest_slot()
