extends Node2D

# Tier of this defender
@export var tier: int = 1

# List of enemies currently in range (detected by DetectionArea)
# The nodes in this array are the enemy's root Area2D nodes
var enemies_in_range: Array[Node2D] = []

# Variable to hold the current nearest enemy node
var target_enemy: Node2D = null

const ENEMY_GROUP_NAME: String = "Enemy"

func _ready() -> void:
	# 1. Play the Idle animation at the start
	$AnimatedSprite2D.play("Idle")
	
	# 2. Connect the Area2D signals for detection (Listening for AREA signals)
	if has_node("DetectionArea"):
		$DetectionArea.area_entered.connect(_on_detection_area_area_entered)
		$DetectionArea.area_exited.connect(_on_detection_area_area_exited)
	else:
		push_error("Defender missing 'DetectionArea' child node.")

# This method allows the AttackModule to retrieve the current target.
func get_target() -> Node2D:
	return target_enemy
	
func _process(delta: float) -> void:
	# 1. Update the target by finding the closest enemy in range
	_update_target_enemy()
	
	# 2. Track and face the enemy if one is found and is valid
	if target_enemy and is_instance_valid(target_enemy):
		_track_enemy()
	else:
		# If no enemy is targeted, return to Idle animation
		if $AnimatedSprite2D.animation != "Idle":
			$AnimatedSprite2D.play("Idle")

# --- Targeting Logic ---

func _update_target_enemy() -> void:
	# Clean up the list by removing invalid nodes using a reverse loop.
	for i in range(enemies_in_range.size() - 1, -1, -1):
		if not is_instance_valid(enemies_in_range[i]):
			enemies_in_range.remove_at(i)
	
	if enemies_in_range.is_empty():
		target_enemy = null
		return

	var closest_distance: float = INF
	var potential_target: Node2D = null

	# Iterate through all valid enemies to find the closest one.
	for enemy in enemies_in_range:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			potential_target = enemy

	target_enemy = potential_target

# Calculates the direction to the enemy and plays the corresponding facing animation.
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

# --- Area2D Signal Handlers (UPDATED to listen for AREA) ---

func _on_detection_area_area_entered(area: Area2D) -> void:
	if area.is_in_group(ENEMY_GROUP_NAME) and not enemies_in_range.has(area):
		enemies_in_range.append(area)

func _on_detection_area_area_exited(area: Area2D) -> void:
	if area.is_in_group(ENEMY_GROUP_NAME):
		enemies_in_range.erase(area)
		if area == target_enemy:
			target_enemy = null
