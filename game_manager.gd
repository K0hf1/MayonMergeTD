extends Node2D

@export var tower_prefab: PackedScene    # drag your Tier 1 tower scene here in the editor
@onready var tower_slots_parent = get_parent().get_node("TowerSlots")
@onready var spawner = $"../Path2D"
@onready var start_wave_button = get_node("../UI/StartWaveButton")
@export var defender_base_path: String = "res://DefenderXAssets/defender"

var tower_slots: Array[Marker2D] = []
var occupied_slots: Array[Marker2D] = []


func _ready() -> void:
	# Gather all tower slot markers
	for child in tower_slots_parent.get_children():
		if child is Marker2D:
			tower_slots.append(child)


func _on_buy_tower_button_pressed() -> void:
	# Find empty (unoccupied) tower slots
	var available_slots = []
	for slot in tower_slots:
		if not occupied_slots.has(slot):
			available_slots.append(slot)

	# Stop if there are no more available slots
	if available_slots.is_empty():
		print("No available tower slots left!")
		return

	# Pick one random empty slot
	var chosen_slot: Marker2D = available_slots[randi() % available_slots.size()]

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

	# Mark the slot as occupied
	occupied_slots.append(chosen_slot)

	print("Tier 1 Tower spawned at:", chosen_slot.global_position)



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

	# Assign slots_parent so snap works
	var drag_module = merged_defender.get_node("DragModule")
	if drag_module:
		# Adjust this path to your actual TowerSlots node
		drag_module.slots_parent = get_node("/root/main/TowerSlots")
		
		# Snap to nearest tower slot
		if drag_module.has_method("on_spawn"):
			drag_module.on_spawn()

	print("Merged defender created at tier ", new_tier)
