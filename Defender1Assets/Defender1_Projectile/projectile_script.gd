extends Area2D

var damage: int = 1
var direction: Vector2 = Vector2.RIGHT
var homing_speed: float = 600.0
var steer_force: float = 25.0

# Homing
var target: Node2D = null
var is_homing: bool = false

# Movement
var velocity: Vector2 = Vector2.ZERO
var has_hit: bool = false
var last_target_pos: Vector2 = Vector2.ZERO

# Lifetime
var max_lifetime: float = 15.0
var lifetime_timer: float = 0.0

# Debug
var creation_time: float = 0.0

@onready var sprite = $AnimatedSprite2D

func _ready():
	creation_time = Time.get_ticks_msec() / 1000.0
	print("🚀 PROJECTILE CREATED at ", creation_time, " | position: ", global_position, " | Damage: ", damage)
	add_to_group("projectiles")
	area_entered.connect(_on_area_entered)
	tree_exiting.connect(_on_tree_exiting)
	
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("fly"):
		sprite.play("fly")

func _on_tree_exiting():
	"""Called when node is being removed from tree"""
	var current_time = Time.get_ticks_msec() / 1000.0
	var lifetime = current_time - creation_time
	print("🗑️  PROJECTILE REMOVED after ", lifetime, "s | has_hit: ", has_hit, " | is_homing: ", is_homing, " | target: ", target.name if target else "null")

func _process(delta):
	if has_hit:
		return
	
	# Lifetime countdown
	lifetime_timer += delta
	if lifetime_timer > max_lifetime:
		print("⏰ PROJECTILE TIMEOUT after ", max_lifetime, "s - queue_free()")
		queue_free()
		return
	
	# HOMING MODE - TARGET ALIVE
	if is_homing and is_instance_valid(target):
		var target_pos = target.global_position
		var distance_to_target = global_position.distance_to(target_pos)
		
		# Hit detection
		if distance_to_target < 30:
			_hit_target()
			return
		
		var direction_to_target = (target_pos - global_position).normalized()
		velocity = velocity.lerp(direction_to_target * homing_speed, steer_force * delta)
		
		global_position += velocity * delta
		
		if velocity.length() > 0:
			rotation = velocity.angle()
		
		if int(get_tree().get_frame()) % 20 == 0:
			print("🎯 Homing: dist=", int(distance_to_target), " speed=", int(velocity.length()), " target=", target.name)
	
	# TARGET DEAD - DISAPPEAR IMMEDIATELY
	elif is_homing and not is_instance_valid(target):
		print("💥 TARGET DIED! Projectile disappearing at time ", Time.get_ticks_msec() / 1000.0 - creation_time, "s")
		queue_free()
		return
	
	# STRAIGHT MODE (only if not homing)
	else:
		global_position += direction * homing_speed * delta
		rotation = direction.angle()

func set_direction(new_direction: Vector2):
	direction = new_direction.normalized()
	velocity = direction * homing_speed

func set_stats(new_damage: int, new_speed: float):
	damage = new_damage
	homing_speed = new_speed

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

func set_max_lifetime(lifetime: float):
	max_lifetime = clamp(lifetime, 5.0, 30.0)

func _hit_target():
	has_hit = true
	
	if target and target.has_method("take_damage"):
		print("💥 HIT! Damage: ", damage)
		target.take_damage(damage)
	
	queue_free()

func _on_area_entered(area: Area2D):
	if has_hit:
		return
	
	if area.is_in_group("Enemy"):
		_hit_target()

func get_damage() -> int:
	return damage
