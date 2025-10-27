extends Area2D

# Remove @export variables - these come from the attacker now
var speed: float = 400.0  # Default fallback
var damage: int = 25      # Default fallback
var direction: Vector2 = Vector2.RIGHT

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# Safety check for AnimatedSprite2D and animation frames
	if is_instance_valid(animated_sprite) and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("fly"):
		animated_sprite.play("fly")
	
	# Add to projectiles group
	add_to_group("projectiles")
	
	# Connect the collision signal
	area_entered.connect(_on_area_entered)

func _physics_process(delta):
	position += direction * speed * delta

func set_direction(new_direction: Vector2):
	direction = new_direction.normalized()
	rotation = direction.angle()

# NEW: Set stats from the attacker (defender)
func set_stats(new_damage: int, new_speed: float) -> void:
	damage = new_damage
	speed = new_speed

func get_damage() -> int:
	return damage

func _on_area_entered(area: Area2D) -> void:
	const ENEMY_GROUP_NAME = "Enemy"
	
	if area.is_in_group(ENEMY_GROUP_NAME):
		if area.has_method("take_damage"):
			area.take_damage(damage) 
		
		queue_free()
