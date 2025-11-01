extends Area2D

## -------------------------------
## CONFIG
## -------------------------------
var coin_value: int = 0   # Value comes from enemy on spawn
var is_collected: bool = false

## Cached managers
var coin_manager: Node = null
var button_sfx_manager: Node = null


## -------------------------------
## LIFECYCLE
## -------------------------------
func _ready() -> void:
	add_to_group("Coin")
	print("=== COIN SPAWNED ===")
	print("💰 Value:", coin_value, "| 📍Position:", global_position, "| Parent:", get_parent().name)
	
	z_index = 1
	collision_layer = 3
	collision_mask = 0
	set_physics_process(false)
	visible = true

	_find_managers()
	_configure_sprite()
	_play_drop_sound()

	# Connect mouse input for collection
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


## -------------------------------
## MANAGER FINDERS
## -------------------------------
func _find_managers() -> void:
	# CoinManager lookup (cached once)
	coin_manager = get_node_or_null("/root/Main/CoinManager")
	if not coin_manager:
		coin_manager = get_tree().root.find_child("CoinManager", true, false)

	if coin_manager:
		print("✓ Coin found CoinManager at:", coin_manager.get_path())
	else:
		print("❌ CoinManager NOT found!")

	# ButtonSFXManager lookup (for audio)
	button_sfx_manager = get_node_or_null("/root/Main/ButtonSFXManager")
	if not button_sfx_manager:
		button_sfx_manager = get_tree().root.find_child("ButtonSFXManager", true, false)

	if button_sfx_manager:
		print("✓ Coin found ButtonSFXManager")
	else:
		print("⚠️  ButtonSFXManager NOT found!")


## -------------------------------
## SPRITE SETUP
## -------------------------------
func _configure_sprite() -> void:
	if not has_node("AnimatedSprite2D"):
		return

	var sprite = $AnimatedSprite2D
	sprite.visible = true
	sprite.modulate = Color.WHITE
	sprite.self_modulate = Color.WHITE
	sprite.scale = Vector2.ONE
	sprite.position = Vector2.ZERO
	sprite.z_index = 1

	print("Coin settings - Z-Index:", z_index, " Sprite Z-Index:", sprite.z_index)

	if sprite.sprite_frames:
		var anims = sprite.sprite_frames.get_animation_names()
		if "Idle" in anims:
			sprite.play("Idle")
			print("▶️ Playing Idle animation")


## -------------------------------
## AUDIO HELPERS
## -------------------------------
func _play_drop_sound() -> void:
	if button_sfx_manager and button_sfx_manager.has_method("play_coin_drop"):
		button_sfx_manager.play_coin_drop()
		print("🔊 Coin drop sound played")


## -------------------------------
## INPUT EVENTS
## -------------------------------
func _on_mouse_entered() -> void:
	if is_collected:
		return
	is_collected = true
	print("🪙 Coin collected!")
	collect_coin()

func _on_mouse_exited() -> void:
	pass


## -------------------------------
## COLLECTION LOGIC
## -------------------------------
func collect_coin() -> void:
	print("Coin being collected - value:", coin_value, "- updating counter immediately!")

	# Play collect sound
	if button_sfx_manager and button_sfx_manager.has_method("play_coin_collect"):
		button_sfx_manager.play_coin_collect()
		print("🔊 Coin collect sound played")

	# Directly update CoinManager
	if coin_manager and coin_manager.has_method("add"):
		coin_manager.add(coin_value)
		print("✅ Added coin value to CoinManager:", coin_value)
	else:
		print("❌ CoinManager missing or no add() method")

	# Play pickup animation (non-blocking)
	play_pickup_animation()

	# Queue removal after delay
	await get_tree().create_timer(3.0).timeout
	queue_free()


## -------------------------------
## ANIMATION
## -------------------------------
func play_pickup_animation() -> void:
	if not has_node("AnimatedSprite2D"):
		return

	var sprite = $AnimatedSprite2D
	if not sprite.sprite_frames:
		return

	var anims = sprite.sprite_frames.get_animation_names()
	if "Pickup" in anims:
		monitoring = false
		sprite.play("Pickup")
		print("🎞️ Pickup animation started")
	else:
		print("No Pickup animation found")


## -------------------------------
## PUBLIC API
## -------------------------------
func set_coin_value(value: int) -> void:
	"""
	Called by Enemy when spawning the coin.
	"""
	coin_value = value
	print("💰 Coin value set by enemy:", coin_value)
