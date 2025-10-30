extends Button


func _on_pressed() -> void:
	$"..".visible = false
	get_tree().paused = false
	print("im working")
