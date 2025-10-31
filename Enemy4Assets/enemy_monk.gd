extends Area2D

# ===== ENEMY STATS =====
@export var max_health: int = 50
@export var damage_to_base: int = 10
@export var coin_value: int = 15
@export var run_speed: float = 20.0

# ===== SCALING SETTINGS =====
@export var base_health: int = 50
@export var health_growth_rate: float = 1.10  # 10% per wave (capped at 9.99%)
@export var speed_growth_rate: float = 1.03   # 3% per wave
@export var base_wave_for_scaling: int = 5    # Start scaling at wave 5

# ===== COIN DROPPING =====
@export var coin_scene: PackedScene
@export var coin_spawn_offset: Vector2 = Vector2.ZERO

var current_health: int
var health_bar: ProgressBar
var is_dead_flag: bool = false
var game_manager: Node = null
var current_wave: int = 1

@onready var animated_sprite = $AnimatedSprite2D


func _ready() -> void:
	current_health = max_health
	is_dead_flag = false
	
	_find_game_manager()
	add_to_group("Enemy")
	
	# ✅ Scale stats for wave 5+
	if current_wave >= base_wave_for_scaling:
		_apply_wave_scaling()
	
	if is_instance_valid(animated_sprite) and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("EnemyRun"):
		animated_sprite.play("EnemyRun")
	
	var error = area_entered.connect(_on_area_entered)
	if error != OK:
		push_error("Failed to connect area_entered signal on enemy.")
	
	create_health_bar()
	print("✓ run_speed set from enemy: ", run_speed)
	print("Enemy initialized with ", max_health, " health | Coin value: ", coin_value)

## ✅ NEW: Apply wave scaling for wave 5+
func _apply_wave_scaling() -> void:
	"""Scale health and speed for wave 5 and above"""
	if current_wave < base_wave_for_scaling:
		return
	
	# ✅ Health scaling (nonlinear, like tower cost)
	var waves_above_base = current_wave - base_wave_for_scaling
	var scaled_health = int(base_health * pow(health_growth_rate, waves_above_base))
	
	max_health = scaled_health
	current_health = max_health
	
	# ✅ Speed scaling (3% per wave)
	var scaled_speed = run_speed * pow(speed_growth_rate, waves_above_base)
	run_speed = scaled_speed
	
	print("🌊 Wave %d scaling applied!" % current_wave)
	print("   📊 Scaled Health: %d (%.1f%% increase per wave)" % [max_health, (health_growth_rate - 1.0) * 100])
	print("   ⚡ Scaled Speed: %.2f (3%% increase per wave)" % run_speed)

## Set current wave (called by GameManager/Spawner)
func set_wave(wave: int) -> void:
	current_wave = wave
	if wave >= base_wave_for_scaling:
		_apply_wave_scaling()

func _find_game_manager() -> void:
	game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		game_manager = get_node_or_null("/root/Main/GameManager")
	if not game_manager:
		game_manager = get_tree().root.find_child("GameManager", true, false)
	
	if game_manager:
		print("✓ Enemy found GameManager")
		# ✅ REMOVED: Don't read current_wave here
		# Let Spawner call set_wave() after instantiation instead

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

func _on_area_entered(area):
	# ✅ IGNORE IF ENEMY IS DEAD
	if is_dead_flag:
		return
	
	if not is_instance_valid(area):
		return
	
	if area.is_in_group("projectiles"):
		var projectile_damage = 25
		if area.has_method("get_damage"):
			projectile_damage = area.get_damage()
		take_damage(projectile_damage)
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
	print("💀 Enemy destroyed!")
	current_health = 0
	is_dead_flag = true
	set_process(false)
	set_physics_process(false)

	# ✅ Use deferred call to safely disable monitoring
	set_deferred("monitoring", false)
	
	drop_coin()
	
	if is_instance_valid(animated_sprite) and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("EnemyDeath"):
		animated_sprite.play("EnemyDeath")
		await animated_sprite.animation_finished 
	
	if game_manager and game_manager.has_method("enemy_died"):
		game_manager.enemy_died(self)
		print("✓ Called enemy_died() on GameManager")
	
	# Mark as dead
	is_dead_flag = true
	remove_from_group("Enemy")
	print("✓ Removed from 'Enemy' group")
	
	# Directly notify GameManager deferred
	call_deferred("_notify_game_manager_wave_complete")
	
	# Remove the node
	queue_free()


func is_dead() -> bool:
	return is_dead_flag or current_health <= 0

func drop_coin() -> void:
	if coin_scene:
		call_deferred("_spawn_coin")

func _spawn_coin() -> void:
	var coin = coin_scene.instantiate()
	coin.global_position = global_position + coin_spawn_offset
	coin.z_index = 100
	get_tree().get_root().add_child(coin)

	if coin.has_method("set_coin_value"):
		coin.set_coin_value(coin_value)
		print("💰 Coin dropped with value: ", coin_value)
	print("Coin dropped at: ", coin.global_position)

func _notify_game_manager_wave_complete() -> void:
	"""Check active_enemies counter instead of group"""
	if game_manager and game_manager.has_method("check_all_waves_complete"):
		print("✅ WAVE CHECK: active_enemies = ", game_manager.active_enemies)
		if game_manager.active_enemies == 0:
			print("✅ CALLING check_all_waves_complete()!")
			game_manager.check_all_waves_complete()
		else:
			print("⏳ Still ", game_manager.active_enemies, " active enemies")
