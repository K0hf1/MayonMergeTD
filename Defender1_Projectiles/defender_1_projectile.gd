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

func _physics_process(delta):
	position += direction * speed * delta

func set_direction(new_direction: Vector2):
	direction = new_direction.normalized()
	rotation = direction.angle()

# New: Method for the enemy to safely retrieve the damage value
func get_damage() -> int:
	return damage
