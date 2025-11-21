extends Node2D

@export var defender_randomizer: NodePath
@export var defender_slots_parent_path: NodePath
@export var buy_defender_button_path: NodePath
@export var base_defender_cost := 5
@export var cost_growth_rate := 1.067

var current_defender_cost := base_defender_cost
var defender_slots: Array[MarkerSlot] = []
var coin_manager: Node = null
var buy_defender_button: Button = null
var feedback_manager: Node = null
var current_wave: int = 0

func _ready():
	_gather_slots()
	_find_coin_manager()
	_find_feedback_manager()

	# Button
	buy_defender_button = get_node_or_null(buy_defender_button_path)
	if not buy_defender_button:
		push_warning("Buy Defender button not assigned!")

	_update_defender_cost(0)

	print("✅ TowerManager ready with", defender_slots.size(), "slots")


# ---------------------------
# FINDERS
# ---------------------------
func _find_coin_manager():
	coin_manager = get_node_or_null("/root/Main/CoinManager")
	if not coin_manager:
		coin_manager = get_tree().root.find_child("CoinManager", true, false)

	if not coin_manager:
		push_warning("CoinManager not found!")


func _find_feedback_manager():
	feedback_manager = get_node_or_null("/root/Main/FeedbackManager")
	if not feedback_manager:
		feedback_manager = get_tree().root.find_child("FeedbackManager", true, false)

	if not feedback_manager:
		push_warning("FeedbackManager not found!")


# ---------------------------
# SLOT COLLECTION
# ---------------------------
func _gather_slots():
	var parent = get_node_or_null(defender_slots_parent_path)
	if not parent:
		push_warning("Defender slots parent not found!")
		return

	for child in parent.get_children():
		if child is MarkerSlot:
			defender_slots.append(child)


# ---------------------------
# COST UPDATING
# ---------------------------
func set_current_wave(wave_number: int):
	current_wave = wave_number
	_update_defender_cost(current_wave)
	print("🌊 Wave %d ended — Defender cost is now: %d" % [current_wave, current_defender_cost])


func _update_defender_cost(wave_number: int):
	current_defender_cost = int(base_defender_cost * pow(cost_growth_rate, wave_number))
	_update_buy_button_text()


func _update_buy_button_text():
	if buy_defender_button:
		buy_defender_button.text = "Buy Defender\n(%d Gold)" % current_defender_cost


# ---------------------------
# BUTTON INPUT
# ---------------------------
func _on_buy_defender_button_pressed() -> void:
	buy_defender()


# ---------------------------
# BUY DEFENDER
# ---------------------------
func buy_defender():
	# Check if all slots are full first
	var empty_slots = defender_slots.filter(func(s): return not s.is_occupied)
	if empty_slots.is_empty():
		_trigger_feedback("no_slots_left")
		return false

	# Then check if player has enough coins
	if not coin_manager or not coin_manager.try_deduct(current_defender_cost):
		_trigger_feedback("not_enough_coins")
		return false

	# Spawn defender
	_spawn_defender()
	return true



func _trigger_feedback(type: String):
	if feedback_manager:
		feedback_manager.show_feedback(type)
	else:
		print("⚠️ FeedbackManager missing — feedback:", type)


# ---------------------------
# SPAWN DEFENDER
# ---------------------------
func _spawn_defender():
	var empty_slots = defender_slots.filter(func(s): return not s.is_occupied)
	if empty_slots.is_empty():
		print("🚫 No available slots!")
		_trigger_feedback("no_slot")
		return

	var chosen_slot = empty_slots[randi() % empty_slots.size()]
	var tier = get_node(defender_randomizer).get_random_defender_tier()
	var scene_path = "res://Defender%dAssets/defender%d.tscn" % [tier, tier]

	if not ResourceLoader.exists(scene_path):
		push_warning("Defender scene missing: %s" % scene_path)
		return

	var defender = load(scene_path).instantiate()
	get_parent().add_child(defender)
	defender.global_position = chosen_slot.global_position

	chosen_slot.is_occupied = true
	chosen_slot.current_defender = defender
	defender.set_meta("current_slot", chosen_slot)

	var drag_module = defender.get_node_or_null("DragModule")
	if drag_module:
		var tm_slots = get_node_or_null("DefenderSlots")
		if tm_slots:
			drag_module.slots_parent = tm_slots
		drag_module.call_deferred("on_spawn")

	print("🎯 Spawned defender tier", tier)


# ---------------------------
# MERGING
# ---------------------------
func request_merge(def1: Node2D, def2: Node2D) -> void:
	var merge_handler = get_node_or_null("MergeHandler")
	if merge_handler:
		merge_handler.request_merge(def1, def2)
	else:
		push_warning("MergeHandler not found!")
