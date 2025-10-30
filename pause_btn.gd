extends Button



func _on_pressed() -> void:
	get_tree().paused = true
	$"../PauseMenu".visible = true
