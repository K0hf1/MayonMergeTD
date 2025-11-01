extends Node
class_name WaveManager

@export var enemy_spawner_path: NodePath
@export var wave_start_delay := 3.0

var current_wave := 0
var enemy_spawner: Node

signal wave_started(wave_number)
signal wave_completed(wave_number)

func _ready():
	if enemy_spawner_path != NodePath(""):
		enemy_spawner = get_node(enemy_spawner_path)
		print("✅ WaveManager linked to EnemySpawner:", enemy_spawner.name)
	else:
		push_error("❌ WaveManager missing enemy_spawner_path reference!")

# ==============================
# 📦 WAVE GENERATION LOGIC
# ==============================

func _calculate_wave_enemy_count(wave_number: int) -> int:
	"""
	Enemy count scaling logic:
	- Wave 1: 5 Warrior
	- Wave 2: 5 Archers
	- Wave 3: 5 Lancers
	- Wave 4: 5 Monks
	- Wave 5: 10 enemies (randomized mix)
	- Wave 6+: +3 per wave (13, 16, 19, 22...)
	"""
	if wave_number <= 4:
		return 5
	elif wave_number == 5:
		return 10
	else:
		return 10 + 3 + (wave_number - 6) * 3


func _generate_wave_enemies(wave_number: int) -> Array:
	"""
	Wave progression:
	- Wave 1: All Warrior
	- Wave 2: All Archer
	- Wave 3: All Lancer
	- Wave 4: All Monk
	- Wave 5+: Randomized mix of all enemy types
	"""
	var total_enemies = _calculate_wave_enemy_count(wave_number)
	var enemy_composition = []

	if wave_number == 1:
		enemy_composition.append({"type": "Warrior", "count": total_enemies})
		print("🎯 Wave 1: All Warrior (%d enemies)" % total_enemies)

	elif wave_number == 2:
		enemy_composition.append({"type": "Archer", "count": total_enemies})
		print("🎯 Wave 2: All Archer (%d enemies)" % total_enemies)

	elif wave_number == 3:
		enemy_composition.append({"type": "Lancer", "count": total_enemies})
		print("🎯 Wave 3: All Lancer (%d enemies)" % total_enemies)

	elif wave_number == 4:
		enemy_composition.append({"type": "Monk", "count": total_enemies})
		print("🎯 Wave 4: All Monk (%d enemies)" % total_enemies)

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

		print("🎯 Wave %d Mix - Warrior:%d Archer:%d Lancer:%d Monk:%d (Total:%d)" %
			[wave_number, warriors, archers, lancers, monks, total_enemies])

	return enemy_composition

# ==============================
# 🚀 WAVE CONTROL
# ==============================

func start_next_wave():
	current_wave += 1
	print("🌊 Starting Wave %d" % current_wave)
	emit_signal("wave_started", current_wave)

	# Generate enemies
	var enemy_data = _generate_wave_enemies(current_wave)
	if enemy_spawner:
		enemy_spawner.spawn_wave(enemy_data, current_wave)
	else:
		push_error("❌ No EnemySpawner connected to WaveManager")

func end_wave():
	print("✅ Wave %d complete!" % current_wave)
	emit_signal("wave_completed", current_wave)
