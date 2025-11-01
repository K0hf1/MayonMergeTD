extends Path2D
class_name EnemySpawner

@export var spawn_interval_wave_1_4: float = 1.0
@export var spawn_interval_wave_5_plus: float = 0.5

var current_wave: int = 0
var spawn_queue: Array = []
var is_spawning: bool = false

var follower_scene: PackedScene = preload("res://EnemyPath.tscn")

var wave_manager: Node = null
var game_manager: Node = null

var enemy_scenes: Dictionary = {
	"Warrior": preload("res://Enemy1Assets/EnemyWarrior.tscn"),
	"Archer": preload("res://Enemy2Assets/EnemyArcher.tscn"),
	"Lancer": preload("res://Enemy3Assets/EnemyLancer.tscn"),
	"Monk": preload("res://Enemy4Assets/EnemyMonk.tscn"),
}

# ===============================
# 🚀 INITIALIZATION
# ===============================

func _ready() -> void:
	wave_manager = get_tree().root.find_child("WaveManager", true, false)
	game_manager = get_tree().root.find_child("GameManager", true, false)

	if wave_manager:
		print("✅ EnemySpawner connected to WaveManager:", wave_manager.name)
	else:
		push_warning("⚠️ No WaveManager found in scene tree!")

	print("EnemySpawner initialized. Enemy types:", enemy_scenes.keys())

# ===============================
# 🎬 WAVE SPAWNING ENTRY POINT
# ===============================

func spawn_wave(enemy_data: Array, wave_number: int) -> void:
	current_wave = wave_number
	spawn_queue.clear()

	# Flatten wave data into a simple spawn list
	for enemy_set in enemy_data:
		for i in range(enemy_set["count"]):
			spawn_queue.append(enemy_set["type"])

	if spawn_queue.is_empty():
		push_warning("⚠️ No enemies to spawn for Wave %d" % wave_number)
		return

	is_spawning = true
	print("🎬 Starting Wave %d spawn sequence (%d enemies)" % [wave_number, spawn_queue.size()])
	_spawn_next_enemy()

# ===============================
# 🧠 SPAWN LOGIC
# ===============================

func _spawn_next_enemy() -> void:
	if spawn_queue.is_empty():
		is_spawning = false
		print("✅ All enemies spawned for Wave %d" % current_wave)

		if wave_manager and wave_manager.has_method("end_wave"):
			wave_manager.end_wave()
		return

	var enemy_type = spawn_queue.pop_front()
	_spawn_enemy(enemy_type)

	var delay = spawn_interval_wave_1_4 if current_wave <= 4 else spawn_interval_wave_5_plus
	get_tree().create_timer(delay).timeout.connect(_spawn_next_enemy)

func _spawn_enemy(enemy_type: String) -> void:
	if not follower_scene:
		push_error("❌ Follower scene not loaded! Check res://EnemyPath.tscn")
		return

	var follower = follower_scene.instantiate()
	add_child(follower)

	if not enemy_scenes.has(enemy_type):
		push_warning("⚠️ Unknown enemy type: %s" % enemy_type)
		return

	var enemy_scene = enemy_scenes[enemy_type]
	var enemy_instance = enemy_scene.instantiate()
	follower.add_child(enemy_instance)

	print("🧩 Spawned", enemy_type, "at follower:", follower)

	# Set properties if available
	if enemy_instance.has_method("set_wave"):
		enemy_instance.set_wave(current_wave)

	# Notify managers
	if game_manager and game_manager.has_method("enemy_spawned"):
		game_manager.enemy_spawned()
	if wave_manager and wave_manager.has_method("enemy_spawned"):
		wave_manager.enemy_spawned()
