extends Area2D

@export var speed: float = 400.0
@export var damage: int = 25
var direction: Vector2 = Vector2.RIGHT

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# Safety check for AnimatedSprite2D and animation frames
	if is_instance_valid(animated_sprite) and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("fly"):
		animated_sprite.play("fly")
	
	# Add to projectiles group
	add_to_group("projectiles")
	
	# NEW: Connect the collision signal
	area_entered.connect(_on_area_entered)

func _physics_process(delta):
	# Use translate for movement if you aren't rotating the entire node,
	# but position += ... is fine and already implemented.
	position += direction * speed * delta

func set_direction(new_direction: Vector2):
	direction = new_direction.normalized()
	rotation = direction.angle()

func get_damage() -> int:
	return damage

# --- NEW: Collision Handler ---

func _on_area_entered(area: Area2D) -> void:
	# Assuming your enemies are in the group "Enemy" (based on defender1.gd)
	const ENEMY_GROUP_NAME = "Enemy"
	
	if area.is_in_group(ENEMY_GROUP_NAME):
		# Apply damage logic:
		# Check if the enemy has a method to take damage (e.g., 'take_damage')
		if area.has_method("take_damage"):
			# Call the enemy's damage method, passing the projectile's damage value
			area.take_damage(damage) 
		
		# Immediately destroy the projectile after impact
		queue_free()
