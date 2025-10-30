extends Control

@onready var coin_label = $Container/CoinLabel
var game_manager: Node = null

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
		coin_label.add_theme_color_override("font_color", Color.WHITE)
		
		print("Label settings:")
		print("  - Visible: ", coin_label.visible)
		print("  - Font Color: ", coin_label.get_theme_color("font_color"))
	else:
		print("✗ ERROR: CoinLabel NOT found!")
	
	# Find and connect to GameManager
	_find_game_manager()

func _find_game_manager() -> void:
	"""Find the GameManager from various possible locations"""
	
	# Try Path 1: Direct path to GameManager at root
	game_manager = get_node_or_null("/root/GameManager")
	
	# Try Path 2: GameManager in Main
	if not game_manager:
		game_manager = get_node_or_null("/root/Main/GameManager")
	
	# Try Path 3: Search entire tree
	if not game_manager:
		game_manager = get_tree().root.find_child("GameManager", true, false)
	
	if game_manager:
		print("✓ GameManager found at: ", game_manager.get_path())
		
		# Connect to coin_collected signal
		if game_manager.has_signal("coin_collected"):
			game_manager.coin_collected.connect(_on_coin_collected)
			print("✓ Connected to coin_collected signal")
		else:
			print("❌ GameManager does NOT have coin_collected signal!")
		
		# Get initial coin count
		if game_manager.has_method("get_coins_collected"):
			var initial_coins = game_manager.get_coins_collected()
			update_coin_display(initial_coins)
			print("✓ Initial coins loaded: ", initial_coins)
		
		# Display current wave info
		if "current_wave" in game_manager:
			print("📊 Current wave: ", game_manager.current_wave)
	else:
		print("❌ ERROR: GameManager NOT found!")
		print("   Searched paths:")
		print("   - /root/GameManager")
		print("   - /root/Main/GameManager")
		print("   - Tree search")

func update_coin_display(coin_count: int) -> void:
	"""Update the coin label with new count"""
	if coin_label:
		var old_text = coin_label.text
		coin_label.text = "Coins: %d" % coin_count
		print("💰 Label updated: ", old_text, " → ", coin_label.text)
	else:
		print("✗ ERROR: coin_label is null!")

func _on_coin_collected(coin_amount: int) -> void:
	"""Called when the coin_collected signal is emitted"""
	print("📢 SIGNAL RECEIVED: coin_collected(%d)" % coin_amount)
	
	if game_manager and game_manager.has_method("get_coins_collected"):
		var total_coins = game_manager.get_coins_collected()
		update_coin_display(total_coins)
		print("✓ Total coins now: ", total_coins)
	else:
		print("❌ Cannot get coins from GameManager!")
