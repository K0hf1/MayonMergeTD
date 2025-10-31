extends Button

func _on_pressed() -> void:
	# Show the pause menu
	$"../PauseMenu".visible = true
	get_tree().paused = true

	# 🔇 Mute the Master bus when paused
	var master_index = AudioServer.get_bus_index("Master")
	if master_index != -1:
		AudioServer.set_bus_mute(master_index, true)
