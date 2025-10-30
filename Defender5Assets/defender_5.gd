extends Node2D

# Tier of this defender
@export var tier: int = 5

# Projectile stats - now managed here!
@export var damage: int = 1
@export var projectile_speed: float = 400.0

# List of enemies currently in range
var enemies_in_range: Array[Node2D] = []

# Current nearest enemy node
var target_enemy: Node2D = null

const ENEMY_GROUP_NAME: String = "Enemy"

func _ready() -> void:
	$AnimatedSprite2D.play("Idle")
	
	if has_node("DetectionArea"):
		$DetectionArea.area_entered.connect(_on_detection_area_area_entered)
		$DetectionArea.area_exited.connect(_on_detection_area_area_exited)
	else:
		push_error("Defender missing 'DetectionArea' child node.")

func get_target() -> Node2D:
	return target_enemy

func _process(delta: float) -> void:
	_update_target_enemy()
	
	if target_enemy and is_instance_valid(target_enemy):
		_track_enemy()
	else:
		if $AnimatedSprite2D.animation != "Idle":
			$AnimatedSprite2D.play("Idle")

# --- Targeting Logic ---

func _update_target_enemy() -> void:
	for i in range(enemies_in_range.size() - 1, -1, -1):
		if not is_instance_valid(enemies_in_range[i]):
			enemies_in_range.remove_at(i)
	
	if enemies_in_range.is_empty():
		target_enemy = null
		return

	var closest_distance: float = INF
	var potential_target: Node2D = null

	for enemy in enemies_in_range:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			potential_target = enemy

	target_enemy = potential_target

func _track_enemy() -> void:
	var direction_vector = target_enemy.global_position - global_position
	
	var abs_x = abs(direction_vector.x)
	var abs_y = abs(direction_vector.y)

	var animation_name: String
	
	if abs_x > abs_y:
		animation_name = "Attack_Right" if direction_vector.x > 0 else "Attack_Left"
	else:
		animation_name = "Attack_Down" if direction_vector.y > 0 else "Attack_Up"
			
	if $AnimatedSprite2D.animation != animation_name:
		$AnimatedSprite2D.play(animation_name)

# --- Area2D Signal Handlers ---

func _on_detection_area_area_entered(area: Area2D) -> void:
	if area.is_in_group(ENEMY_GROUP_NAME) and not enemies_in_range.has(area):
		enemies_in_range.append(area)

func _on_detection_area_area_exited(area: Area2D) -> void:
	if area.is_in_group(ENEMY_GROUP_NAME):
		enemies_in_range.erase(area)
		if area == target_enemy:
			target_enemy = null

# NEW: Called by AttackModule to spawn projectiles with proper stats
func spawn_projectile(projectile_scene: PackedScene, direction: Vector2) -> Area2D:
	var projectile = projectile_scene.instantiate() as Area2D
	add_child(projectile)
	projectile.global_position = global_position
	projectile.set_direction(direction)
	projectile.set_stats(damage, projectile_speed)  # Pass stats here!
	return projectile
