extends Area2D

signal crystal_destroyed

var game_over_ui = null
var music_manager = null
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	animated_sprite.play("idleCrystal")
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# ✅ NEW: Find MusicManager
	_find_music_manager()
	
	# ✅ NEW: Connect area_entered signal
	area_entered.connect(_on_area_entered)

func _input(event):
	# Listen for restart input
	if get_tree().paused:
		if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
			restart_game()

## ✅ NEW: Find Music Manager
func _find_music_manager() -> void:
	music_manager = get_node_or_null("/root/main/MusicManager")
	
	if not music_manager:
		music_manager = get_tree().root.find_child("MusicManager", true, false)
	
	if music_manager:
		print("✓ Crystal found MusicManager")
	else:
		print("⚠️  Crystal WARNING: MusicManager NOT found!")

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		print("💔 HEART CRYSTAL DESTROYED! GAME OVER!")
		
		# Destroy enemy
		if area.get_parent() != null:
			area.get_parent().queue_free()
		else:
			area.queue_free()
		
		# ✅ CRITICAL: Set volume BEFORE pausing the game
		if music_manager and music_manager.has_method("set_music_volume"):
			print("🔊 Setting music volume to 100%...")
			music_manager.set_music_volume(1.0)  # Full volume for game over
		
		# ✅ CRITICAL: Play game over music BEFORE pausing
		if music_manager and music_manager.has_method("play_game_over_music"):
			print("🎵 Playing game over music...")
			music_manager.play_game_over_music()
		
		# ✅ CRITICAL: Wait for music to start BEFORE pausing
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Game over
		game_over()

func game_over():
	# Play destruction animation
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("destroyCrystal"):
		animated_sprite.play("destroyCrystal")
		await animated_sprite.animation_finished
	
	crystal_destroyed.emit()
	show_game_over_screen()
	
	# ✅ CRITICAL: Pause AFTER everything is set up
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
	
	# ✅ NEW: Stop game over music before restarting
	if music_manager and music_manager.has_method("stop_music"):
		print("🎵 Stopping game over music...")
		music_manager.stop_music()
	
	# Unpause first
	get_tree().paused = false
	
	# Clean up coins, enemies, and towers BEFORE reloading
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
