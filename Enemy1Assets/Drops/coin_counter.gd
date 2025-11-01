extends Control

@onready var coin_label = $HBoxContainer/CoinLabel
@onready var coin_sprite = $HBoxContainer/CoinSprite

var coin_manager: Node = null


func _ready() -> void:
	print("=== COIN COUNTER SCRIPT STARTED ===")
	print("Node name: ", name)
	print("Node path: ", get_path())
	
	# Verify the label exists
	if coin_label:
		coin_label.text = "0"
		coin_label.visible = true
		coin_label.modulate = Color.WHITE
		coin_label.add_theme_color_override("font_color", Color.WHITE)
		print("✓ CoinLabel configured")
	else:
		print("✗ ERROR: CoinLabel NOT found!")

	# Play coin spin animation
	if coin_sprite and coin_sprite is AnimatedSprite2D:
		if "Coin_spin" in coin_sprite.sprite_frames.get_animation_names():
			coin_sprite.play("Coin_spin")
			print("🎞️ Coin spin animation started!")
		else:
			print("⚠️ Coin_spin animation not found in CoinSprite!")
	else:
		print("❌ CoinSprite not found or not AnimatedSprite2D!")

	# Find CoinManager and connect signal
	_find_coin_manager()


func _find_coin_manager() -> void:
	# Try direct path
	coin_manager = get_node_or_null("/root/Main/CoinManager")
	if not coin_manager:
		coin_manager = get_tree().root.find_child("CoinManager", true, false)

	if coin_manager:
		print("✓ CoinManager found at:", coin_manager.get_path())
		if coin_manager.has_signal("coin_changed"):
			coin_manager.coin_changed.connect(_on_coin_changed)
			print("✓ Connected to coin_changed signal")

		# Initialize display
		if "coins" in coin_manager:
			update_coin_display(coin_manager.coins)
	else:
		print("❌ CoinManager NOT found!")


func _on_coin_changed(new_amount: int) -> void:
	update_coin_display(new_amount)
	print("💰 Coin count updated:", new_amount)


func update_coin_display(coin_count: int) -> void:
	if coin_label:
		coin_label.text = "%d" % coin_count
		print("💰 CoinLabel updated to:", coin_label.text)
	else:
		print("✗ ERROR: coin_label is null!")
