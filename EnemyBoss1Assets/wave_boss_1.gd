extends Area2D

# ===== BOSS STATS =====
@export var max_health: int = 1000
@export var damage_to_base: int = 50
@export var coin_value: int = 100
@export var run_speed: float = 25.0  # base speed

# ===== BOSS SCALING =====
@export var base_health: int = 1000
@export var health_growth_rate: float = 1.15   # 15% more health per wave
@export var speed_growth_rate: float = 1.03    # 3% faster per wave
@export var base_wave_for_scaling: int = 10    # start scaling at wave 10
@export var speed_multiplier_cap: float = 2.5  # max 2.5x base speed

# ===== COINS =====
@export var coin_scene: PackedScene
@export var coin_spawn_offset: Vector2 = Vector2.ZERO
@export var coin_growth_rate: float = 1.10     # +10% per wave
@export var coin_max_value: int = 9999         # safety cap

# ===== INTERNAL =====
var current_health: int
var current_wave: int = 1
var is_dead_flag: bool = false
var health_bar: ProgressBar
var game_manager: Node = null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	current_health = base_health
	is_dead_flag = false

	_find_game_manager()
	add_to_group("Enemy")

	if current_wave >= base_wave_for_scaling:
		_apply_wave_scaling()

	if animated_sprite and animated_sprite.sprite_frames.has_animation("EnemyRun"):
		animated_sprite.play("EnemyRun")

	area_entered.connect(_on_area_entered)
	create_health_bar()

	print("👑 Boss initialized | Health:", current_health, "| Speed:", run_speed)

# ===== WAVE SCALING (Boss Only) =====
func _apply_wave_scaling() -> void:
	var waves_above_base = current_wave - base_wave_for_scaling
	if waves_above_base < 0:
		return

	# Health scaling
	current_health = int(base_health * pow(health_growth_rate, waves_above_base))
	max_health = current_health

	# Speed scaling with relative cap
	var scaled_speed = run_speed * pow(speed_growth_rate, waves_above_base)
	run_speed = min(scaled_speed, run_speed * speed_multiplier_cap)

	# Coin scaling
	var scaled_coin = int(coin_value * pow(coin_growth_rate, waves_above_base))
	coin_value = clamp(scaled_coin, 0, coin_max_value)

	print("👑 Boss wave scaling | Wave:", current_wave, "| HP:", max_health, "| Speed:", run_speed, "| Coins:", coin_value)

func set_wave(wave: int) -> void:
	current_wave = wave
	_apply_wave_scaling()

# ===== GAME MANAGER =====
func _find_game_manager() -> void:
	game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		game_manager = get_tree().root.find_child("GameManager", true, false)

# ===== HEALTH BAR =====
var health_bar_style_fill: StyleBoxFlat
var health_bar_style_bg: StyleBoxFlat

func create_health_bar():
	health_bar = ProgressBar.new()
	health_bar.max_value = base_health
	health_bar.value = current_health
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(100, 12)
	health_bar.position = Vector2(-50, -80)
	health_bar.z_index = 200

	health_bar_style_bg = StyleBoxFlat.new()
	health_bar_style_bg.bg_color = Color(0.1, 0.1, 0.1, 0.9)

	health_bar_style_fill = StyleBoxFlat.new()
	health_bar_style_fill.bg_color = Color(1, 0, 0)

	health_bar.add_theme_stylebox_override("background", health_bar_style_bg)
	health_bar.add_theme_stylebox_override("fill", health_bar_style_fill)
	add_child(health_bar)

func update_health_bar():
	if health_bar:
		health_bar.value = current_health
		var health_percent = float(current_health) / float(base_health)
		health_bar_style_fill.bg_color = Color(1, 0, 0).lerp(Color(1, 1, 0), health_percent)

# ===== DAMAGE & DEATH =====
func _on_area_entered(area):
	if is_dead_flag or not is_instance_valid(area):
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
	print("👑 Boss took", amount, "damage | Health:", current_health)
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
	print("💀 Boss defeated!")
	is_dead_flag = true
	set_process(false)
	set_physics_process(false)
	set_deferred("monitoring", false)

	drop_coin()

	if animated_sprite and animated_sprite.sprite_frames.has_animation("EnemyDeath"):
		animated_sprite.play("EnemyDeath")
		await animated_sprite.animation_finished

	remove_from_group("Enemy")

	if game_manager:
		var wave_manager = game_manager.get_node_or_null("WaveManager")
		if wave_manager and wave_manager.has_method("enemy_died"):
			wave_manager.enemy_died(self)

	queue_free()

# ===== COINS =====
func drop_coin() -> void:
	if coin_scene:
		call_deferred("_spawn_coin")

func _spawn_coin() -> void:
	var coin = coin_scene.instantiate()
	coin.global_position = global_position + coin_spawn_offset
	get_tree().root.add_child(coin)
	if coin.has_method("set_coin_value"):
		coin.set_coin_value(coin_value)
	print("💰 Boss dropped coins worth:", coin_value)
