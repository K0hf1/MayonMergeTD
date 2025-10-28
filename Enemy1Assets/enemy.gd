extends Area2D

# Set a slightly higher default health (e.g., 100) for better testing with varying damage.
@export var max_health: int = 10
@export var damage_to_base: int = 10
@export var coin_scene: PackedScene  # Drag your coin.tscn here in the editor
@export var coin_spawn_offset: Vector2 = Vector2.ZERO

var current_health: int
var health_bar: ProgressBar
var is_dead_flag: bool = false  # Track if enemy is dead

# Cache the AnimatedSprite2D node for safer and faster access
@onready var animated_sprite = $AnimatedSprite2D

func _ready() -> void:
	current_health = max_health
	is_dead_flag = false
	
	# Safety check before attempting to play animation (FIXED for Godot 4)
	if is_instance_valid(animated_sprite) and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("EnemyRun"):
		animated_sprite.play("EnemyRun")
	
	# Connect collision for fireballs
	var error = area_entered.connect(_on_area_entered)
	if error != OK:
		push_error("Failed to connect area_entered signal on enemy.")
	
	# Create health bar
	create_health_bar()
	
	print("Warrior initialized with ", max_health, " health")

## -----------------------------------------------------------------------------
## HEALTH BAR FUNCTIONS
## -----------------------------------------------------------------------------

var health_bar_style_fill: StyleBoxFlat
var health_bar_style_bg: StyleBoxFlat

func create_health_bar():
	health_bar = ProgressBar.new()
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.show_percentage = false
	
	health_bar.custom_minimum_size = Vector2(40, 10)
	health_bar.position = Vector2(-20, 10) 
	
	health_bar_style_bg = StyleBoxFlat.new()
	health_bar_style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	
	health_bar_style_fill = StyleBoxFlat.new()
	health_bar_style_fill.bg_color = Color(0, 1, 0, 1)
	
	health_bar.add_theme_stylebox_override("background", health_bar_style_bg)
	health_bar.add_theme_stylebox_override("fill", health_bar_style_fill)
	
	add_child(health_bar)

func update_health_bar():
	if health_bar != null:
		health_bar.value = current_health
		
		var health_percent = float(current_health) / float(max_health)
		
		var start_color = Color(1, 0, 0)
		var end_color = Color(0, 1, 0)
		
		health_bar_style_fill.bg_color = start_color.lerp(end_color, health_percent)

## -----------------------------------------------------------------------------
## COMBAT & STATE FUNCTIONS
## -----------------------------------------------------------------------------

func _on_area_entered(area):
	# Safety check: Ensure the projectile isn't already being freed
	if not is_instance_valid(area):
		return
		
	# Hit by projectile
	if area.is_in_group("projectiles"):
		var projectile_damage = 25
		
		# FIXED: Use has_method and get_damage() instead of the invalid area.has("damage")
		if area.has_method("get_damage"):
			projectile_damage = area.get_damage()
		# NOTE: If get_damage() fails for some reason, projectile_damage defaults to 25.
		
		take_damage(projectile_damage)
		
		# Free the projectile immediately after damage is applied
		area.queue_free()

func take_damage(amount: int):
	if current_health <= 0:
		return
		
	current_health -= amount
	print("Enemy took ", amount, " damage! Health: ", current_health, "/", max_health)
	
	update_health_bar()
	flash_red()
	
	if current_health <= 0:
		die()

func flash_red():
	if is_instance_valid(animated_sprite):
		animated_sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout 
		animated_sprite.modulate = Color.WHITE

func die():
	print("Enemy destroyed!")
	
	is_dead_flag = true  # Mark as dead
	set_process(false)
	set_physics_process(false)
	monitoring = false
	
	# Drop coin before playing death animation
	drop_coin()
	
	# Play death animation
	if is_instance_valid(animated_sprite) and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("EnemyDeath"):
		animated_sprite.play("EnemyDeath")
		await animated_sprite.animation_finished 
	
	# Notify game manager that enemy died
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").enemy_died(self)
	
	# Remove the enemy container node
	if is_instance_valid(get_parent()):
		get_parent().queue_free()
	else:
		queue_free()

## NEW: Check if enemy is dead
func is_dead() -> bool:
	return is_dead_flag or current_health <= 0

## -----------------------------------------------------------------------------
## COIN DROP FUNCTION
## -----------------------------------------------------------------------------

func drop_coin() -> void:
	# Drop a coin at the enemy's position
	if coin_scene:
		var coin = coin_scene.instantiate()
		coin.global_position = global_position + coin_spawn_offset
		coin.z_index = 100  # Make sure it's on top of everything
		
		# Add to the root of the scene, not the enemy parent
		get_tree().get_root().add_child(coin)
		print("Coin dropped at: ", coin.global_position, " with z_index: ", coin.z_index)
	else:
		print("WARNING: No coin scene assigned to enemy!")
