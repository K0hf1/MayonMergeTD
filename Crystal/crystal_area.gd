extends Area2D

signal crystal_destroyed

var game_over_ui = null  # Store reference to UI
@onready var animated_sprite = $AnimatedSprite2D # Cache the sprite node

func _ready():
	animated_sprite.play("idleCrystal")
	# REMOVED: area_entered.connect(_on_area_entered) (Assumed to be connected in editor)
	
	# Process even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	# Listen for restart input
	if get_tree().paused:
		# KEY_SPACE is the correct constant for Godot 4
		if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
			restart_game()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		print("💔 HEART CRYSTAL DESTROYED! GAME OVER!")
		
		# Destroy enemy (Assumes Enemy root is a PathFollow2D or similar parent container)
		if area.get_parent() != null:
			area.get_parent().queue_free()
		else:
			area.queue_free()
		
		# Game over
		game_over()

func game_over():
	# Play destruction animation (FIXED for Godot 4)
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("destroyCrystal"):
		animated_sprite.play("destroyCrystal")
		await animated_sprite.animation_finished
	
	crystal_destroyed.emit()
	show_game_over_screen()
	get_tree().paused = true

func show_game_over_screen():
	# This function uses Control nodes, ensuring they work when paused (process_mode=ALWAYS)
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
	
	# Store reference so we can delete it later
	game_over_ui = canvas_layer

func restart_game():
	print("🔄 Restarting game...")
	
	# Remove game over UI
	if game_over_ui != null:
		game_over_ui.queue_free()
		game_over_ui = null
	
	# Unpause and restart
	get_tree().paused = false
	get_tree().reload_current_scene()
