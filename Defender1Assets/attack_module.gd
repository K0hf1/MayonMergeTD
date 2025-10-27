extends Node2D

@export var projectile_scene: PackedScene # <--- Drag your projectile scene here!
@export var attack_cooldown: float = 0.75 # Time between shots

# Path to the timer node inside this module
const TIMER_PATH = "AttackTimer" 

# The root defender node (parent)
var defender_root: Node2D = null

func _ready() -> void:
	# 1. Get a reference to the parent defender (the Node2D root)
	defender_root = get_parent()
	
	if not defender_root:
		push_error("AttackModule must be a child of the defender root node.")
		return
		
	# 2. Setup and connect the Attack Timer
	if has_node(TIMER_PATH):
		var attack_timer = get_node(TIMER_PATH)
		attack_timer.wait_time = attack_cooldown
		
		# Connect the Timer's timeout signal to the attack function
		attack_timer.timeout.connect(_on_attack_timer_timeout)
		attack_timer.start()
	else:
		push_error("AttackModule is missing 'AttackTimer' child node.")

# --- Attack Logic ---

# Triggered every time the AttackTimer times out.
func _on_attack_timer_timeout() -> void:
	# 1. Attempt to get the current target from the parent defender
	var target = _get_current_target()
	
	# 2. If a valid target is found, shoot the projectile
	if target and is_instance_valid(target):
		_shoot_projectile(target)

# Calls a method on the parent defender to retrieve the tracked enemy.
func _get_current_target() -> Node2D:
	# We rely on the parent defender (defender1.gd) having a public 'get_target()' method
	if defender_root.has_method("get_target"):
		return defender_root.get_target()
	
	return null

# Spawns and initializes the projectile with defender's stats.
func _shoot_projectile(target: Node2D) -> void:
	if projectile_scene == null:
		push_error("Projectile scene not set on AttackModule!")
		return
		
	# 1. Instantiate the projectile
	var projectile = projectile_scene.instantiate()
	
	# 2. Calculate the direction from the defender to the target
	var direction = (target.global_position - defender_root.global_position).normalized()
	
	# 3. Set its starting position (defender's global position)
	projectile.global_position = defender_root.global_position
	
	# 4. Initialize the projectile's movement using the exposed method
	if projectile.has_method("set_direction"):
		projectile.set_direction(direction)
	
	# 5. NEW: Pass the defender's stats to the projectile
	if projectile.has_method("set_stats"):
		projectile.set_stats(defender_root.damage, defender_root.projectile_speed)
	
	# 6. Add the projectile to the main scene tree (or defender's parent)
	defender_root.get_parent().add_child(projectile)
