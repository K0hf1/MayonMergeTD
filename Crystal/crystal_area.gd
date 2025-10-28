extends Area2D

signal crystal_destroyed

var game_over_ui = null
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	animated_sprite.play("idleCrystal")
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	# Listen for restart input
	if get_tree().paused:
		if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
			restart_game()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		print("💔 HEART CRYSTAL DESTROYED! GAME OVER!")
		
		# Destroy enemy
		if area.get_parent() != null:
			area.get_parent().queue_free()
		else:
			area.queue_free()
		
		# Game over
		game_over()

func game_over():
	# Play destruction animation
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("destroyCrystal"):
		animated_sprite.play("destroyCrystal")
		await animated_sprite.animation_finished
	
	crystal_destroyed.emit()
	show_game_over_screen()
	get_tree().paused = true

func show_game_over_screen():
	var label = Label.new()
	label.text = "GAME OVER\n\nPress SPACE to Restart"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color.RED)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(label)
	
	game_over_ui = canvas_layer

func restart_game():
	print("🔄 Restarting game...")
	
	# Remove game over UI
	if game_over_ui != null:
		game_over_ui.queue_free()
		game_over_ui = null
	
	# Unpause first
	get_tree().paused = false
	
	# NEW: Clean up coins, enemies, and towers BEFORE reloading
	_cleanup_before_restart()
	
	# Now reload the scene
	get_tree().reload_current_scene()

func _cleanup_before_restart() -> void:
	"""Clean up all coins, enemies, and towers before restarting"""
	print("🧹 Cleaning up before restart...")
	
	# Clean up coins from root
	var coins = get_tree().get_nodes_in_group("Coin")
	print("Removing %d coins..." % coins.size())
	for coin in coins:
		if is_instance_valid(coin):
			coin.queue_free()
	
	# Clean up enemies
	var enemies = get_tree().get_nodes_in_group("Enemy")
	print("Removing %d enemies..." % enemies.size())
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	# Clean up projectiles
	var projectiles = get_tree().get_nodes_in_group("projectiles")
	print("Removing %d projectiles..." % projectiles.size())
	for projectile in projectiles:
		if is_instance_valid(projectile):
			projectile.queue_free()
	
	# Try to reset GameManager coins
	var game_manager = get_tree().root.find_child("GameManager", true, false)
	if game_manager and game_manager.has_method("reset_coins"):
		game_manager.reset_coins()
		print("✓ GameManager coins reset")
	
	print("✓ Cleanup complete")
