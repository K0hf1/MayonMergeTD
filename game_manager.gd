extends Node2D

@export var tower_prefab: PackedScene    # drag your Tier 1 tower scene here in the editor
@onready var tower_slots_parent = get_parent().get_node("TowerSlots")
@onready var spawner = $"../Path2D"

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

	# Spawn a new tower instance
	var new_tower = tower_prefab.instantiate()
	get_parent().add_child(new_tower)
	new_tower.global_position = chosen_slot.global_position

	# Mark the slot as occupied
	occupied_slots.append(chosen_slot)

	print("Tower spawned at:", chosen_slot.global_position)


func _on_start_wave_button_pressed():
	spawner.start_wave(5)  # test value
