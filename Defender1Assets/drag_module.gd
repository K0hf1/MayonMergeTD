extends Node2D

# Drag state
var dragging: bool = false
var offset: Vector2 = Vector2.ZERO
var original_position: Vector2

# Reference to tower root
var tower_root: Node2D

# Reference to the parent node that holds tower slots
@export var slots_parent: Node

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

	var slots = slots_parent.get_children()
	var closest_slot: MarkerSlot = null
	var min_dist = INF

	# Find nearest empty slot within snap radius
	for slot in slots:
		if slot is MarkerSlot and not slot.is_occupied:
			var dist = tower_root.global_position.distance_to(slot.global_position)
			if dist < min_dist and dist <= slot.snap_radius:
				min_dist = dist
				closest_slot = slot

	if closest_slot:
		# Snap to the nearest slot
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
	else:
		# No nearby slot → return to original position
		tower_root.global_position = original_position
