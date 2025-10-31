extends Button

func _on_pressed() -> void:
	# Hide the pause menu
	$"..".visible = false
	get_tree().paused = false

	# 🔊 Unmute the Master bus when resuming
	var master_index = AudioServer.get_bus_index("Master")
	if master_index != -1:
		AudioServer.set_bus_mute(master_index, false)
