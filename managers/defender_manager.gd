extends Node2D

@export var defender_randomizer: NodePath
@export var defender_slots_parent_path: NodePath
@export var buy_defender_button_path: NodePath
@export var base_defender_cost := 5
@export var cost_growth_rate := 1.067
@export var feedback_label_path: NodePath

@onready var feedback_label: Label = null

var current_defender_cost := base_defender_cost
var defender_slots: Array[MarkerSlot] = []
var coin_manager: Node = null
var buy_defender_button: Button = null
var current_wave: int = 0
var feedback_tween = null  # track the current tween, no type needed

func _ready():
	# Gather defender slots
	_gather_slots()
	
	# Find coin manager
	_find_coin_manager()
	
	# Assign buy defender button from exported path
	buy_defender_button = get_node_or_null(buy_defender_button_path)
	if not buy_defender_button:
		push_warning("Buy Defender button not assigned!")
	
	# Initialize defender cost and button text
	_update_defender_cost(0)
	
	print("✅ TowerManager ready with", defender_slots.size(), "slots")
	
	if feedback_label_path != NodePath(""):
		feedback_label = get_node_or_null(feedback_label_path)
		if feedback_label:
			feedback_label.visible = false
			feedback_label.modulate.a = 0.0
		else:
			push_warning("Feedback label not found!")


# --- COIN MANAGER ---
func _find_coin_manager():
	coin_manager = get_node_or_null("/root/Main/CoinManager")
	if not coin_manager:
		coin_manager = get_tree().root.find_child("CoinManager", true, false)
	if not coin_manager:
		push_warning("CoinManager not found!")


# --- DEFENDER SLOTS ---
func _gather_slots():
	var parent = get_node_or_null(defender_slots_parent_path)
	if not parent:
		push_warning("Defender slots parent not found!")
		return
	for child in parent.get_children():
		if child is MarkerSlot:
			defender_slots.append(child)


# --- DEFENDER COST & BUTTON TEXT ---
func _update_defender_cost(wave_number: int):
	current_defender_cost = int(base_defender_cost * pow(cost_growth_rate, wave_number))
	_update_buy_button_text()

func _update_buy_button_text():
	if buy_defender_button:
		buy_defender_button.text = "Buy Defender\n(%d Gold)" % current_defender_cost


func _show_not_enough_coins():
	if not feedback_label:
		return
	
	# Make label visible and reset alpha
	feedback_label.visible = true
	feedback_label.modulate.a = 1.0
	
	# Kill previous tween if it exists
	if feedback_tween and is_instance_valid(feedback_tween):
		feedback_tween.kill()
	
	# Create a new tween for fade out
	feedback_tween = get_tree().create_tween()
	feedback_tween.tween_property(feedback_label, "modulate:a", 0.0, 1.0)  # fade out over 1 second
	Callable(feedback_label, "hide")

# --- BUTTON INPUT ---
func _on_buy_defender_button_pressed() -> void:
	buy_defender()


# --- BUY DEFENDER ---
func buy_defender():
	if not coin_manager or not coin_manager.try_deduct(current_defender_cost):
		print("❌ Not enough gold!")
		_show_not_enough_coins()  # show feedback label
		return false
	_spawn_defender()
	return true


# --- SPAWN DEFENDER ---
func _spawn_defender():
	var empty_slots = defender_slots.filter(func(s): return not s.is_occupied)
	if empty_slots.is_empty():
		print("🚫 No available slots!")
		return

	var chosen_slot = empty_slots[randi() % empty_slots.size()]
	var tier = get_node(defender_randomizer).get_random_defender_tier()
	var scene_path = "res://Defender%dAssets/defender%d.tscn" % [tier, tier]
	if not ResourceLoader.exists(scene_path):
		push_warning("Defender scene not found: %s" % scene_path)
		return

	var defender = load(scene_path).instantiate()
	get_parent().add_child(defender)
	defender.global_position = chosen_slot.global_position
	print("🎯 Spawned defender tier", tier)
	

	# Mark slot as occupied
	chosen_slot.is_occupied = true
	chosen_slot.current_defender = defender
	defender.set_meta("current_slot", chosen_slot)

	# Initialize drag module if present
	var drag_module = defender.get_node_or_null("DragModule")
	if drag_module and not drag_module.slots_parent:
		var tm_slots = get_node_or_null("DefenderSlots")
		if tm_slots:
			drag_module.slots_parent = tm_slots
		drag_module.call_deferred("on_spawn")


# --- MERGE HANDLER ---
func request_merge(def1: Node2D, def2: Node2D) -> void:
	var merge_handler = get_node_or_null("MergeHandler")
	if merge_handler:
		merge_handler.request_merge(def1, def2)
	else:
		push_warning("MergeHandler not found!")


# --- WAVE HANDLING ---
func set_current_wave(wave_number: int):
	"""
	Call this from GameManager whenever the wave changes.
	Updates the defender cost and button text automatically.
	"""
	current_wave = wave_number
	_update_defender_cost(current_wave)
	
	# ✅ Print defender cost for this wave
	print("🌊 Wave %d ended — Defender cost is now: %d" % [current_wave, current_defender_cost])
