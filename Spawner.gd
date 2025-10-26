extends Path2D

@export var spawn_time: float = 1.0   # Time between enemy spawns
var timer: float = 0.0
var enemies_to_spawn: int = 0
var spawning: bool = false

# The enemy scene to instantiate
var follower_scene = preload("res://EnemyPath.tscn")  # Replace with your enemy scene path

# Reference to the Start Wave button (optional, set in the editor or via code)
@onready var start_wave_button = get_node_or_null("/root/Main/UI/StartWaveButton")

func _process(delta: float) -> void:
	if not spawning:
		return

	timer += delta
	
	if timer >= spawn_time and enemies_to_spawn > 0:
		spawn_enemy()
		timer = 0.0
		enemies_to_spawn -= 1
		
		# Wave finished
		if enemies_to_spawn <= 0:
			spawning = false
			if start_wave_button:
				start_wave_button.disabled = false  # Re-enable the button when wave ends

func spawn_enemy():
	var new_follower = follower_scene.instantiate()
	call_deferred("add_child", new_follower)

func start_wave(enemy_count: int):
	if enemies_to_spawn > 0:
		# Optional: ignore if a wave is already running
		return

	enemies_to_spawn = enemy_count
	spawning = true
	timer = 0.0

	# Disable the button while the wave is active
	if start_wave_button:
		start_wave_button.disabled = true
