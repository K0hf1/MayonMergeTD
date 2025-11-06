extends Node
class_name WaveManager

@export var enemy_spawner_path: NodePath

var current_wave := 0
var enemy_spawner: Node
var active_enemies := 0  # Tracks alive enemies
var is_wave_active := false
var auto_wave_enabled := false
var auto_wave_delay := 2.0

signal wave_started(wave_number)
signal wave_completed(wave_number)

func _ready():
	if enemy_spawner_path != NodePath(""):
		enemy_spawner = get_node(enemy_spawner_path)
		print("✅ WaveManager linked to EnemySpawner:", enemy_spawner.name)
	else:
		push_error("❌ WaveManager missing enemy_spawner_path reference!")

# ---------------------------
# Wave Control
# ---------------------------
func start_next_wave():
	if is_wave_active:
		push_warning("⚠️ Wave already active")
		return

	current_wave += 1
	is_wave_active = true
	print("🌊 Starting Wave %d" % current_wave)
	emit_signal("wave_started", current_wave)

	if enemy_spawner:
		var enemy_data = enemy_spawner.prepare_wave(current_wave)
		active_enemies = 0  # Reset before spawning
		enemy_spawner.spawn_wave(enemy_data, current_wave)
	else:
		push_error("❌ No EnemySpawner connected to WaveManager")

# Called by EnemySpawner for each spawned enemy
func register_enemy():
	active_enemies += 1
	print("👾 Enemy registered | Active enemies:", active_enemies)

# Called by Enemy when it dies
func enemy_died(enemy: Node):
	active_enemies -= 1
	print("☠️ Enemy died | Remaining:", active_enemies)

	if active_enemies <= 0:
		print("✅ Wave %d complete!" % current_wave)
		is_wave_active = false   # ✅ Reset active wave flag
		emit_signal("wave_completed", current_wave)
		
		if auto_wave_enabled:
			await get_tree().create_timer(auto_wave_delay).timeout
			start_next_wave()

func set_auto_wave(enabled: bool) -> void:
	auto_wave_enabled = enabled
	print("🔁 Auto Wave:", "Enabled" if enabled else "Disabled")



# ---------------------------
# Wave Enemy Generation Logic
# ---------------------------
func _calculate_wave_enemy_count(wave_number: int) -> int:
	if wave_number <= 4:
		return 5
	elif wave_number == 5:
		return 10
	else:
		return 10 + 3 + (wave_number - 6) * 3

func _generate_wave_enemies(wave_number: int) -> Array:
	var enemy_composition = []

	# 🎯 Every 10th wave is a boss wave
	if wave_number % 10 == 0:
		enemy_composition.append({"type": "Boss1", "count": 1})
		return enemy_composition

	var total_enemies = _calculate_wave_enemy_count(wave_number)

	if wave_number == 1:
		enemy_composition.append({"type": "Warrior", "count": total_enemies})
	elif wave_number == 2:
		enemy_composition.append({"type": "Archer", "count": total_enemies})
	elif wave_number == 3:
		enemy_composition.append({"type": "Lancer", "count": total_enemies})
	elif wave_number == 4:
		enemy_composition.append({"type": "Monk", "count": total_enemies})
	else:
		var warriors = randi_range(int(total_enemies * 0.2), int(total_enemies * 0.4))
		var archers = randi_range(int(total_enemies * 0.2), int(total_enemies * 0.35))
		var lancers = randi_range(int(total_enemies * 0.15), int(total_enemies * 0.3))
		var monks = total_enemies - warriors - archers - lancers
		if monks < 0:
			monks = 0

		enemy_composition.append({"type": "Warrior", "count": warriors})
		enemy_composition.append({"type": "Archer", "count": archers})
		enemy_composition.append({"type": "Lancer", "count": lancers})
		enemy_composition.append({"type": "Monk", "count": monks})

	return enemy_composition
