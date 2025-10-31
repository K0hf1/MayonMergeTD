extends Button


func _ready() -> void:
	print("✓ GameOver Restart Button initialized")

func _on_pressed() -> void:
	print("\n▶️ GAMEOVER RESTART BUTTON PRESSED!")
	
	# ✅ Unpause first
	get_tree().paused = false
	print("✓ Game unpaused")
	
	# ✅ Simply reload the main scene
	print("🔄 Loading main scene...")
	get_tree().change_scene_to_file("res://main.tscn")
