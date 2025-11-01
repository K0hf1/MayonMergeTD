extends Control

@onready var wave_label: Label = $RecordLabel
var player_record: Node = null
var wave_manager: Node = null

func _ready():
	# Find PlayerRecord
	player_record = get_tree().root.find_child("PlayerRecord", true, false)
	if not player_record:
		push_warning("PlayerRecord not found! Best wave will not display correctly.")
	
	# Find WaveManager
	wave_manager = get_tree().root.find_child("WaveManager", true, false)
	if wave_manager:
		wave_manager.connect("wave_started", Callable(self, "_on_wave_started"))
		wave_manager.connect("wave_completed", Callable(self, "_on_wave_completed"))
	else:
		push_warning("WaveManager not found!")

	# Show the best wave on game start
	_update_best_wave_display()

func _update_best_wave_display():
	if player_record and player_record.has_method("get_highest_wave"):
		var best_wave = player_record.get_highest_wave()
		wave_label.text = "Best Wave: %d" % best_wave
	else:
		wave_label.text = "Best Wave: 0"

func _on_wave_started(wave_number: int) -> void:
	# Show current wave
	wave_label.text = "Wave: %d" % wave_number

func _on_wave_completed(wave_number: int) -> void:
	if player_record and player_record.has_method("update_highest_wave"):
		player_record.update_highest_wave(wave_number)
		var new_best = player_record.get_highest_wave()
		wave_label.text = "Best Wave: %d" % new_best
	else:
		wave_label.text = "Best Wave: %d" % wave_number
