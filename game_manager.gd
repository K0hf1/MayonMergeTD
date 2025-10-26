extends Node2D

@export var tower_prefab: PackedScene    # drag your Tier 1 tower scene here in the editor
@export var tower_slots_parent_path: NodePath  # Path to the Node2D containing MarkerSlots
@onready var spawner = $"../Path2D"
@onready var start_wave_button = get_node("../UI/StartWaveButton")
@export var defender_base_path: String = "res://DefenderXAssets/defender"

var tower_slots: Array[MarkerSlot] = []
var tower_slots_parent: Node2D = null

func _ready() -> void:
	# Get tower_slots_parent from the path
	if tower_slots_parent_path:
		tower_slots_parent = get_node(tower_slots_parent_path)
	
	# If still not set, try common locations
	if not tower_slots_parent:
		print("Searching for tower slots parent...")
		# Try parent's child named "TowerSlots" or similar
		var parent = get_parent()
		for child in parent.get_children():
			if child.name.contains("Slot") or child.name.contains("slot"):
				tower_slots_parent = child
				print("Found potential slots parent: %s" % child.name)
				break
		
		# If still not found, use parent itself
		if not tower_slots_parent:
			tower_slots_parent = parent
			print("Using parent as slots parent: %s" % parent.name)
	
	# Gather all MarkerSlot children
	print("=== Gathering tower slots from: %s ===" % tower_slots_parent.name)
	_gather_slots_recursive(tower_slots_parent)
	
	print("Total slots found: %d" % tower_slots.size())
	
	if tower_slots.is_empty():
		print("ERROR: No MarkerSlots found! Check that:")
		print("  1. MarkerSlot script is attached to Marker2D nodes")
		print("  2. Set 'Tower Slots Parent Path' in inspector (e.g., '../TowerSlots')")

func _gather_slots_recursive(node: Node) -> void:
	"""Recursively search for MarkerSlot nodes"""
	for child in node.get_children():
		if child is MarkerSlot:
			tower_slots.append(child)
			print("Found MarkerSlot at: %s (name: %s)" % [child.global_position, child.name])
		else:
			# Search children recursively
			_gather_slots_recursive(child)

func _on_buy_tower_button_pressed() -> void:
	# Find empty slots by checking the MarkerSlot's is_occupied property
	var available_slots = []
	print("=== Checking slot availability ===")
	for slot in tower_slots:
		print("Slot at %s - Occupied: %s, Tower: %s" % [slot.global_position, slot.is_occupied, slot.current_tower])
		if not slot.is_occupied:
			available_slots.append(slot)
	
	print("Found %d available slots out of %d total" % [available_slots.size(), tower_slots.size()])
	
	# Stop if there are no more available slots
	if available_slots.is_empty():
		print("No available tower slots left!")
		return
	
	# Pick one random empty slot
	var chosen_slot: MarkerSlot = available_slots[randi() % available_slots.size()]
	
	# Spawn a new Tier 1 tower instance
	var folder_name = "Defender1Assets"
	var scene_name = "defender1.tscn"
	var scene_path = "res://%s/%s" % [folder_name, scene_name]
	
	if not ResourceLoader.exists(scene_path):
		print("Tier 1 tower scene not found!")
		return
	
	var tower_scene = load(scene_path)
	var new_tower: Node2D = tower_scene.instantiate()
	get_parent().add_child(new_tower)
	
	# Set initial position at the chosen slot
	new_tower.global_position = chosen_slot.global_position
	
	# Assign slots_parent to DragModule and snap immediately
	var drag_module = new_tower.get_node("DragModule")
	if drag_module:
		drag_module.slots_parent = tower_slots_parent
		# Call snap deferred to ensure the node is fully in the scene tree
		drag_module.call_deferred("on_spawn")
	
	print("Tier 1 Tower spawned at:", chosen_slot.global_position)
	print("Available slots remaining: %d" % _count_available_slots())

func _count_available_slots() -> int:
	"""Helper function to count how many slots are still available"""
	var count = 0
	for slot in tower_slots:
		if not slot.is_occupied:
			count += 1
	return count

func _on_start_wave_button_pressed():
	if start_wave_button:
		start_wave_button.disabled = true
	if spawner:
		spawner.start_wave(5)

func request_merge(defender1: Node2D, defender2: Node2D) -> void:
	# Determine new tier
	var new_tier: int = defender1.tier + 1
	
	# Maximum tier allowed
	if new_tier > 14:
		print("Maximum tier reached: ", new_tier)
		return
	
	# Construct folder + scene path dynamically
	var folder_name = "Defender%dAssets" % new_tier
	var scene_name = "defender%d.tscn" % new_tier
	var scene_path = "res://%s/%s" % [folder_name, scene_name]
	
	# Check if scene exists
	if not ResourceLoader.exists(scene_path):
		print("No scene found for tier ", new_tier, " at path: ", scene_path)
		return
	
	# Load and instantiate the merged defender
	var merged_scene: PackedScene = load(scene_path)
	var merged_defender: Node2D = merged_scene.instantiate()
	
	# Place merged defender at midpoint of original defenders
	merged_defender.global_position = (defender1.global_position + defender2.global_position) / 2
	
	# Add to the scene tree (same parent as original defenders)
	get_parent().add_child(merged_defender)
	
	# CRITICAL: Set the tier property on the new defender
	if "tier" in merged_defender:
		merged_defender.tier = new_tier
		print("Set merged defender tier to: ", new_tier)
	else:
		print("WARNING: Merged defender doesn't have 'tier' property!")
	
	# Assign slots_parent so snap works
	var drag_module = merged_defender.get_node("DragModule")
	if drag_module:
		drag_module.slots_parent = tower_slots_parent
		
		# Snap to nearest tower slot
		if drag_module.has_method("on_spawn"):
			drag_module.on_spawn()
	
	print("Merged defender created at tier ", new_tier)
	print("Available slots after merge: %d" % _count_available_slots())
