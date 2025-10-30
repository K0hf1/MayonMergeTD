extends PathFollow2D

var previous_x: float
var warrior_node: Node = null
var animated_sprite: AnimatedSprite2D = null
var run_speed: float = 0.0

func _ready() -> void:
	previous_x = global_position.x
	
	# Check if the enemy is already a child
	if get_child_count() > 0:
		_setup_enemy(get_child(0))
	else:
		# Wait a frame for dynamically spawned enemies
		await get_tree().process_frame
		if get_child_count() > 0:
			_setup_enemy(get_child(0))
		else:
			print("❌ No enemy attached to PathFollow2D")

func _setup_enemy(enemy_node: Node) -> void:
	warrior_node = enemy_node
	print("✓ Attached enemy: ", warrior_node.name)
	
	
	# Find sprite for flipping
	animated_sprite = warrior_node.get_node_or_null("AnimatedSprite2D")
	if not animated_sprite:
		animated_sprite = warrior_node.get_node_or_null("Sprite2D")

	
	if animated_sprite:
		print("✓ Found sprite for animation control")
	else:
		print("❌ No sprite found under ", warrior_node.name)
	
	# Get run speed from the enemy script
	if warrior_node.has_method("get"):
		run_speed = warrior_node.get("run_speed")
		print("✓ run_speed set from enemy: ", run_speed)
	else:
		print("⚠️ Enemy node missing 'run_speed' property")

func _process(delta: float) -> void:
	if not is_instance_valid(animated_sprite):
		return
	
	progress += run_speed * delta
	
	var current_x = global_position.x
	if current_x > previous_x:
		animated_sprite.flip_h = false
	elif current_x < previous_x:
		animated_sprite.flip_h = true
	
	previous_x = current_x
