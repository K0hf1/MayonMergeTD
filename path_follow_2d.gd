extends PathFollow2D

@export var run_speed: float = 200.0
var previous_x: float
var warrior_node: Node = null
var animated_sprite: AnimatedSprite2D = null

func _ready() -> void:
	previous_x = global_position.x
	
	# Find the Warrior node and AnimatedSprite2D
	warrior_node = get_child(0)  # First child
	if warrior_node:
		print("✓ Found Warrior: ", warrior_node.name)
		animated_sprite = warrior_node.get_node_or_null("AnimatedSprite2D")
		if animated_sprite:
			print("✓ Found AnimatedSprite2D")
		else:
			print("❌ AnimatedSprite2D not found in ", warrior_node.name)
			# Try alternative paths
			animated_sprite = warrior_node.get_node_or_null("Sprite2D")
			if animated_sprite:
				print("✓ Found Sprite2D instead")
	else:
		print("❌ No child nodes found!")

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
