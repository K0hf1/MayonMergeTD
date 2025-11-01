extends Area2D

# Stats (set by Defender via AttackModule)
var damage: int = 1
var homing_speed: float = 400.0
var steer_force: float = 25.0

# Homing
var target: Node2D = null
var is_homing: bool = false

# Movement
var velocity: Vector2 = Vector2.ZERO
var has_hit: bool = false

# Lifetime
var max_lifetime: float = 15.0
var lifetime_timer: float = 0.0

# SFX Manager
var button_sfx_manager: Node = null

@onready var sprite = $AnimatedSprite2D

func _ready():
	# Play flying animation
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("fly"):
		sprite.play("fly")
	
	add_to_group("projectiles")
	area_entered.connect(_on_area_entered)
	tree_exiting.connect(_on_tree_exiting)
	print("🚀 Projectile spawned | Damage:", damage, " | Speed:", homing_speed)

func _on_tree_exiting():
	pass  # Optional debug

func _process(delta):
	if has_hit:
		return
	
	lifetime_timer += delta
	if lifetime_timer > max_lifetime:
		queue_free()
		return
	
	if is_homing and is_instance_valid(target):
		# Homing movement
		var direction_to_target = (target.global_position - global_position).normalized()
		velocity = velocity.lerp(direction_to_target * homing_speed, steer_force * delta)
		global_position += velocity * delta
		if velocity.length() > 0:
			rotation = velocity.angle()
		
		# Hit detection
		if global_position.distance_to(target.global_position) < 30:
			_hit_target()
	elif is_homing and not is_instance_valid(target):
		queue_free()  # Target died
	else:
		# Straight movement
		global_position += velocity * delta
		rotation = velocity.angle()

# --- Setters (called from AttackModule) ---
func set_stats(new_damage: int, new_speed: float) -> void:
	damage = new_damage
	homing_speed = new_speed
	velocity = velocity.normalized() * homing_speed  # Adjust velocity if already set

func set_direction(new_direction: Vector2) -> void:
	velocity = new_direction.normalized() * homing_speed

func set_target(new_target: Node2D) -> void:
	target = new_target
	is_homing = true

func set_steer_force(force: float) -> void:
	steer_force = clamp(force, 5.0, 50.0)

func set_sfx_manager(sfx_manager: Node) -> void:
	button_sfx_manager = sfx_manager

func _hit_target():
	if has_hit:
		return
	has_hit = true

	if button_sfx_manager and button_sfx_manager.has_method("play_projectile_hit"):
		button_sfx_manager.play_projectile_hit()

	if target and target.has_method("take_damage"):
		target.take_damage(damage)

	queue_free()

func _on_area_entered(area: Area2D):
	if has_hit:
		return
	if area.is_in_group("Enemy"):
		_hit_target()
