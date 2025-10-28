extends Control

@onready var coin_label = $Container/CoinLabel

func _ready() -> void:
	print("=== COIN COUNTER SCRIPT STARTED ===")
	print("Node name: ", name)
	print("Node path: ", get_path())
	
	# Verify the label exists
	if coin_label:
		print("✓ CoinLabel found")
		coin_label.text = "Coins: 0"
		
		# Force visibility settings
		coin_label.visible = true
		coin_label.modulate = Color.WHITE
		coin_label.add_theme_color_override("font_color", Color.WHITE)  # White text
		
		print("Label settings:")
		print("  - Visible: ", coin_label.visible)
		print("  - Font Color: ", coin_label.get_theme_color("font_color"))
	else:
		print("✗ ERROR: CoinLabel NOT found!")
	
	# Get initial coin count
	if has_node("/root/GameManager"):
		var game_manager = get_node("/root/GameManager")
		update_coin_display(game_manager.coins_collected)
		print("✓ Connected to GameManager")

func update_coin_display(coin_count: int) -> void:
	if coin_label:
		coin_label.text = "Coins: %d" % coin_count
		print("✓ Label updated to: ", coin_label.text)
	else:
		print("✗ ERROR: coin_label is null!")
