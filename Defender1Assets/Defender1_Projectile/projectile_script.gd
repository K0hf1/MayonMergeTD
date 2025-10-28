extends Area2D

var damage: int = 1
var direction: Vector2 = Vector2.RIGHT
var homing_speed: float = 600.0  # INCREASED from 400
var steer_force: float = 25.0  # INCREASED from 20

# Homing
var target: Node2D = null
var is_homing: bool = false

# Movement
var velocity: Vector2 = Vector2.ZERO
var has_hit: bool = false
var last_target_pos: Vector2 = Vector2.ZERO

@onready var sprite = $AnimatedSprite2D

func _ready():
	print("🚀 PROJECTILE READY at position: ", global_position, " | Damage: ", damage)
	add_to_group("projectiles")
	area_entered.connect(_on_area_entered)
	
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("fly"):
		sprite.play("fly")

func _process(delta):
	if has_hit:
		return
	
	# HOMING MODE
	if is_homing and is_instance_valid(target):
		var target_pos = target.global_position
		var distance_to_target = global_position.distance_to(target_pos)
		
		# Hit detection
		if distance_to_target < 30:
			_hit_target()
			return
		
		# ALWAYS aim at target's CURRENT position (not prediction)
		var direction_to_target = (target_pos - global_position).normalized()
		
		# Smoothly steer towards target
		velocity = velocity.lerp(direction_to_target * homing_speed, steer_force * delta)
		
		# Move
		global_position += velocity * delta
		
		# Rotate
		if velocity.length() > 0:
			rotation = velocity.angle()
		
		# Debug every 20 frames
		if int(get_tree().get_frame()) % 20 == 0:
			print("Homing: dist=", int(distance_to_target), " speed=", int(velocity.length()), " target=", target.name)
	
	# STRAIGHT MODE
	else:
		global_position += direction * homing_speed * delta
		rotation = direction.angle()

func set_direction(new_direction: Vector2):
	direction = new_direction.normalized()
	velocity = direction * homing_speed

func set_stats(new_damage: int, new_speed: float):
	damage = new_damage
	homing_speed = new_speed
	print("📊 Projectile stats - Damage: ", damage, " Speed: ", homing_speed)

func set_target(new_target: Node2D):
	target = new_target
	is_homing = true
	last_target_pos = target.global_position
	velocity = (target.global_position - global_position).normalized() * homing_speed
	print("✓ Projectile HOMING to: ", target.name)

func set_steer_force(force: float):
	steer_force = clamp(force, 5.0, 50.0)

func set_homing_speed(speed: float):
	homing_speed = speed

func _hit_target():
	has_hit = true
	
	if target and target.has_method("take_damage"):
		print("💥 HIT! Damage: ", damage)
		target.take_damage(damage)
	
	# Fade and disappear
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	await tween.finished
	queue_free()

func _on_area_entered(area: Area2D):
	if has_hit:
		return
	
	if area.is_in_group("Enemy"):
		_hit_target()

func get_damage() -> int:
	return damage
