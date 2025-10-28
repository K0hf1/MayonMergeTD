extends Area2D

var is_collected: bool = false

func _ready() -> void:
	add_to_group("Coin")
	print("=== COIN SPAWNED ===")
	print("Coin position: ", global_position)
	print("Coin parent: ", get_parent().name)
	
	z_index = 1
	
	# Set collision layers
	collision_layer = 3
	collision_mask = 0
	
	# Connect signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Keep stationary
	set_physics_process(false)
	
	# Ensure visibility
	visible = true
	
	if has_node("AnimatedSprite2D"):
		var sprite = $AnimatedSprite2D
		sprite.visible = true
		sprite.modulate = Color.WHITE
		sprite.self_modulate = Color.WHITE
		sprite.scale = Vector2(1, 1)
		sprite.offset = Vector2(0, 0)
		sprite.position = Vector2(0, 0)
		sprite.z_index = 100
		
		print("Coin settings - Z-Index: ", z_index, " Sprite Z-Index: ", sprite.z_index)
		
		if sprite.sprite_frames:
			var anims = sprite.sprite_frames.get_animation_names()
			if "Idle" in anims:
				sprite.play("Idle")
				print("Playing Idle animation")


func _process(delta: float) -> void:
	pass


func _on_mouse_entered() -> void:
	if is_collected:
		return
	
	print("Coin collected!")
	is_collected = true
	collect_coin()


func _on_mouse_exited() -> void:
	pass


func collect_coin() -> void:
	print("Coin being collected - updating counter immediately!")
	
	# UPDATE COUNTER IMMEDIATELY (don't wait for animation)
	var game_manager = get_tree().root.find_child("GameManager", true, false)
	if game_manager and game_manager.has_method("coin_collected"):
		game_manager.coin_collected()
		print("✓ Counter updated immediately!")
	
	# THEN play the pickup animation in parallel
	play_pickup_animation()
	
	# Remove after animation finishes
	await get_tree().create_timer(3.0).timeout
	queue_free()


func play_pickup_animation() -> void:
	"""Play pickup animation without blocking coin collection"""
	print("Playing pickup animation...")
	
	if has_node("AnimatedSprite2D"):
		var sprite = $AnimatedSprite2D
		
		if sprite.sprite_frames:
			var anims = sprite.sprite_frames.get_animation_names()
			
			if "Pickup" in anims:
				monitoring = false
				sprite.play("Pickup")
				print("Pickup animation started")
				# Don't wait - animation plays in background
			else:
				print("No Pickup animation found")
