extends Area2D

# ===== ENEMY STATS =====
@export var max_health: int = 30
@export var damage_to_base: int = 10
@export var coin_value: int = 3
@export var run_speed: float = 50.0

# ===== SCALING SETTINGS =====
@export var base_health: int = 30
@export var health_growth_rate: float = 1.10  # 10% per wave
@export var speed_growth_rate: float = 1.03   # 3% per wave
@export var base_wave_for_scaling: int = 5    # Start scaling at wave 5

# ===== COIN DROPPING =====
@export var coin_scene: PackedScene
@export var coin_spawn_offset: Vector2 = Vector2.ZERO

# ===== INTERNAL STATE =====
var current_health: int
var current_wave: int = 1
var is_dead_flag: bool = false
var health_bar: ProgressBar
var game_manager: Node = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	current_health = max_health
	is_dead_flag = false

	_find_game_manager()
	add_to_group("Enemy")

	# Apply wave scaling if needed
	if current_wave >= base_wave_for_scaling:
		_apply_wave_scaling()

	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("EnemyRun"):
		animated_sprite.play("EnemyRun")

	area_entered.connect(_on_area_entered)
	create_health_bar()

	print("✓ Enemy initialized | Health:", max_health, "| Coin:", coin_value, "| Speed:", run_speed)

# ===== WAVE SCALING =====
func _apply_wave_scaling() -> void:
	var waves_above_base = current_wave - base_wave_for_scaling
	if waves_above_base < 0:
		return

	current_health = int(base_health * pow(health_growth_rate, waves_above_base))
	max_health = current_health
	run_speed = run_speed * pow(speed_growth_rate, waves_above_base)

	print("🌊 Wave %d scaling applied! Health: %d | Speed: %.2f" % [current_wave, max_health, run_speed])

func set_wave(wave: int) -> void:
	current_wave = wave
	_apply_wave_scaling()

# ===== GAME MANAGER =====
func _find_game_manager() -> void:
	game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		game_manager = get_node_or_null("/root/Main/GameManager")
	if not game_manager:
		game_manager = get_tree().root.find_child("GameManager", true, false)
	if game_manager:
		print("✓ Enemy found GameManager")

# ===== HEALTH BAR =====
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
	if health_bar:
		health_bar.value = current_health
		var health_percent = float(current_health) / float(max_health)
		health_bar_style_fill.bg_color = Color(1, 0, 0).lerp(Color(0, 1, 0), health_percent)

# ===== DAMAGE & DEATH =====
func _on_area_entered(area):
	if is_dead_flag:
		return
	if not is_instance_valid(area):
		return
	if area.is_in_group("projectiles"):
		var damage = 25
		if area.has_method("get_damage"):
			damage = area.get_damage()
		take_damage(damage)
		area.queue_free()

func take_damage(amount: int):
	if is_dead_flag:
		return
	current_health -= amount
	print("Enemy took", amount, "damage | Health:", current_health, "/", max_health)
	update_health_bar()
	flash_red()
	if current_health <= 0:
		die()

func flash_red():
	if animated_sprite:
		animated_sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate = Color.WHITE

func die():
	if is_dead_flag:
		return

	print("💀 Enemy destroyed!")
	is_dead_flag = true
	current_health = 0
	set_process(false)
	set_physics_process(false)
	set_deferred("monitoring", false)

	drop_coin()

	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("EnemyDeath"):
		animated_sprite.play("EnemyDeath")
		await animated_sprite.animation_finished

	remove_from_group("Enemy")
	print("✓ Removed from 'Enemy' group")

	# Notify WaveManager instead of GameManager
	if game_manager:
		var wave_manager = game_manager.get_node_or_null("WaveManager")
		if wave_manager and wave_manager.has_method("enemy_died"):
			wave_manager.enemy_died(self)
			print("✓ Notified WaveManager of enemy death")
		else:
			print("⚠️ WaveManager or enemy_died() not found!")

	queue_free()

func is_dead() -> bool:
	return is_dead_flag or current_health <= 0

# ===== COINS =====
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
	print("💰 Coin dropped at", coin.global_position, "value:", coin_value)
