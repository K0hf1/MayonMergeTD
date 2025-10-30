extends Button

func _on_pressed() -> void:
	$"../PauseMenu".visible = true
	get_tree().paused = true
