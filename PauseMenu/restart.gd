extends Button


func _ready() -> void:
	print("✓ Restart Button initialized")

func _on_pressed() -> void:
	print("\n▶️ RESTART BUTTON PRESSED!")
	
	# ✅ Unpause first
	get_tree().paused = false
	print("✓ Game unpaused")
	
	# ✅ Get GameManager and call restart_level()
	var game_manager = get_tree().root.find_child("GameManager", true, false)
	
	if game_manager and game_manager.has_method("restart_level"):
		print("✓ Calling GameManager.restart_level()...")
		game_manager.restart_level()
		print("✅ Cleanup complete!")
		
		# ✅ NOW reload the scene after cleanup
		print("🔄 Reloading scene...")
		await get_tree().process_frame  # Wait one frame for cleanup to finish
		get_tree().reload_current_scene()
	else:
		print("⚠️ GameManager not found! Reloading scene...")
		get_tree().reload_current_scene()
