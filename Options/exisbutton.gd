extends Button

func _on_pressed() -> void:
	$"..".visible = false


func _on_tree_exiting() -> void:
	$"../../MarginContainer".visible = true
	$"../../title".visible = true
