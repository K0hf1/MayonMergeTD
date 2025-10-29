extends Area2D

# ===== ENEMY STATS =====
@export var max_health: int = 10
@export var damage_to_base: int = 10
@export var coin_value: int = 15
@export var run_speed: float = 35.0

# ===== COIN DROPPING =====
@export var coin_scene: PackedScene
@export var coin_spawn_offset: Vector2 = Vector2.ZERO

var current_health: int
var health_bar: ProgressBar
var is_dead_flag: bool = false
var game_manager: Node = null

@onready var animated_sprite = $AnimatedSprite2D

func _ready() -> void:
	current_health = max_health
	is_dead_flag = false
	
	_find_game_manager()
	add_to_group("Enemy")
	
	if is_instance_valid(animated_sprite) and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("EnemyRun"):
		animated_sprite.play("EnemyRun")
	
	var error = area_entered.connect(_on_area_entered)
	if error != OK:
		push_error("Failed to connect area_entered signal on enemy.")
	
	create_health_bar()
	print("Enemy initialized with ", max_health, " health | Coin value: ", coin_value)

func _find_game_manager() -> void:
	game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		game_manager = get_node_or_null("/root/Main/GameManager")
	if not game_manager:
		game_manager = get_tree().root.find_child("GameManager", true, false)
	
	if game_manager:
		print("✓ Enemy found GameManager")

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
