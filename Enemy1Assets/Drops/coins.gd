extends Area2D

var coin_value: int = 1  # Will be set by GameManager via set_coin_value()
var is_collected: bool = false
var game_manager: Node = null
var button_sfx_manager: Node = null  # ✅ UPDATED: Changed from sfx_manager to button_sfx_manager

func _ready() -> void:
	add_to_group("Coin")
	print("=== COIN SPAWNED ===")
	print("Coin position: ", global_position)
	print("Coin value (initial): ", coin_value)
	print("Coin parent: ", get_parent().name)
	
	z_index = 1
	
	# Set collision layers
	collision_layer = 3
	collision_mask = 0
	
	# Find GameManager early
	_find_game_manager()
	
	# ✅ UPDATED: Find ButtonSFXManager instead of CoinSFXManager
	_find_button_sfx_manager()
	
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
		sprite.z_index = 1
		
		print("Coin settings - Z-Index: ", z_index, " Sprite Z-Index: ", sprite.z_index)
		
		if sprite.sprite_frames:
			var anims = sprite.sprite_frames.get_animation_names()
			if "Idle" in anims:
				sprite.play("Idle")
				print("Playing Idle animation")
	
	# ✅ UPDATED: Play coin drop sound from ButtonSFXManager
	if button_sfx_manager and button_sfx_manager.has_method("play_coin_drop"):
		button_sfx_manager.play_coin_drop()
		print("🔊 Coin drop sound played")

## Find GameManager
func _find_game_manager() -> void:
	# Try Path 1: Direct path
	game_manager = get_node_or_null("/root/GameManager")
	
	# Try Path 2: GameManager in Main
	if not game_manager:
		game_manager = get_node_or_null("/root/Main/GameManager")
	
	# Try Path 3: Search entire tree
	if not game_manager:
		game_manager = get_tree().root.find_child("GameManager", true, false)
	
	if game_manager:
		print("✓ Coin found GameManager at: ", game_manager.get_path())
	else:
		print("❌ Coin ERROR: GameManager NOT found!")

## ✅ UPDATED: Find ButtonSFXManager instead of CoinSFXManager
func _find_button_sfx_manager() -> void:
	button_sfx_manager = get_node_or_null("/root/Main/ButtonSFXManager")
	
	if not button_sfx_manager:
		button_sfx_manager = get_tree().root.find_child("ButtonSFXManager", true, false)
	
	if button_sfx_manager:
		print("✓ Coin found ButtonSFXManager")
	else:
		print("⚠️  Coin WARNING: ButtonSFXManager NOT found!")

## Set the coin value (MUST be called by GameManager via _setup_coin_for_wave)
func set_coin_value(value: int) -> void:
	coin_value = value
	print("💰 Coin value UPDATED to: ", coin_value)

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
	print("Coin being collected - value: ", coin_value, " - updating counter immediately!")
	
	# ✅ UPDATED: Play collect sound from ButtonSFXManager
	if button_sfx_manager and button_sfx_manager.has_method("play_coin_collect"):
		button_sfx_manager.play_coin_collect()
		print("🔊 Coin collect sound played")
	
	# UPDATE COUNTER IMMEDIATELY (don't wait for animation)
	if game_manager and game_manager.has_method("on_coin_collected"):
		game_manager.on_coin_collected(coin_value)
		print("✓ Counter updated with coin value: ", coin_value)
	else:
		print("❌ GameManager not found or method missing!")
		print("   GameManager: ", game_manager)
		if game_manager:
			print("   Has on_coin_collected: ", game_manager.has_method("on_coin_collected"))
	
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
			else:
				print("No Pickup animation found")
