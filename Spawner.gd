extends Path2D

@export var spawn_time: float = 1.0
@export var spawn_time_wave_5_plus: float = 0.1  # Minimum delay for wave 5+
var timer: float = 0.0
var enemies_to_spawn: Array = []
var spawning: bool = false
var current_wave: int = 0

var follower_scene = preload("res://EnemyPath.tscn")

@onready var start_wave_button = get_node_or_null("/root/Main/UI/StartWaveButton")
var game_manager: Node = null

# Enemy scene paths
var enemy_scenes: Dictionary = {
	"Warrior": "res://Enemy1Assets/EnemyWarrior.tscn",
	"Archer": "res://Enemy2Assets/EnemyArcher.tscn",
	"Lancer": "res://Enemy3Assets/EnemyLancer.tscn",
	"Monk": "res://Enemy4Assets/EnemyMonk.tscn",
}


func _ready() -> void:
	# Find GameManager
	game_manager = get_node_or_null("../GameManager")
	
	if not game_manager:
		game_manager = get_node_or_null("/root/GameManager")
	
	if not game_manager:
		game_manager = get_tree().root.find_child("GameManager", true, false)
	
	if game_manager:
		print("✓ Spawner: GameManager found at: ", game_manager.get_path())
	else:
		print("❌ Spawner: GameManager NOT FOUND!")

func _process(delta: float) -> void:
	if not spawning or enemies_to_spawn.is_empty():
		return

	timer += delta
	
	# ✅ Determine spawn delay based on wave
	var current_spawn_time = spawn_time if current_wave <= 4 else spawn_time_wave_5_plus
	
	if timer >= current_spawn_time:
		spawn_enemy()
		timer = 0.0
		
		# Only mark spawning as complete when all enemies spawned
		if enemies_to_spawn.is_empty():
			spawning = false
			print("✓ All enemies spawned for wave %d" % current_wave)

func spawn_enemy():
	"""Spawn an enemy of the specified type"""
	if enemies_to_spawn.is_empty():
		return
	
	var enemy_type = enemies_to_spawn.pop_front()
	print("🔄 Spawning: ", enemy_type)
	
	# Create wrapper node (PathFollow2D)
	var new_follower = follower_scene.instantiate()
	add_child(new_follower)
	
	if enemy_scenes.has(enemy_type):
		var enemy_scene = load(enemy_scenes[enemy_type])
		var enemy_instance = enemy_scene.instantiate()
		new_follower.add_child(enemy_instance)
	else:
		push_warning("⚠️ Unknown enemy type: " + str(enemy_type))

	
	# Notify GameManager that enemy was spawned
	if game_manager and game_manager.has_method("enemy_spawned"):
		game_manager.enemy_spawned()

func start_wave(wave_number: int):
	if spawning:
		print("⚠️  Wave already in progress!")
		return

	current_wave = wave_number
	
	# Clear old enemy group entries from previous waves
	_clear_dead_enemies_from_group()
	
	# Notify GameManager about the wave
	if game_manager and game_manager.has_method("set_current_wave"):
		game_manager.set_current_wave(wave_number)
	
	# Get enemy configuration for this wave
	if game_manager and game_manager.has_method("get_wave_enemy_config"):
		var config = game_manager.get_wave_enemy_config(wave_number)
		enemies_to_spawn.clear()
		
		# Build spawn queue with enemy types
		for enemy_data in config["enemies"]:
			var enemy_type = enemy_data["type"]
			var count = enemy_data["count"]
			for i in range(count):
				enemies_to_spawn.append(enemy_type)
		
		print("🌊 Wave %d started! Spawning %d total enemies" % [wave_number, enemies_to_spawn.size()])
		print("   Enemy queue: %s" % [enemies_to_spawn])
	else:
		print("❌ Cannot get wave config from GameManager")
		return
	
	spawning = true
	timer = 0.0

	if start_wave_button:
		start_wave_button.disabled = true

func _clear_dead_enemies_from_group() -> void:
	"""Remove invalid nodes from Enemy group"""
	var all_enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy in all_enemies:
		if not is_instance_valid(enemy):
			enemy.remove_from_group("Enemy")

func stop_wave() -> void:
	"""Stop the current wave"""
	spawning = false
	enemies_to_spawn.clear()
	timer = 0.0
	print("⛔ Wave %d stopped" % current_wave)

func reset_waves() -> void:
	"""Reset wave counter"""
	current_wave = 0
	stop_wave()
	print("✓ Waves reset to 0")
