extends Node2D

# --- Defender Properties ---
@export var defender_name: String = "T14 - Manananggal"
@export var tier: int = 14
@export var damage: int = 80
@export var projectile_speed: float = 400.0
@export var attack_cooldown: float = 0.62

# --- Runtime Variables ---
var enemies_in_range: Array[Node2D] = []
var target_enemy: Node2D = null
const ENEMY_GROUP_NAME: String = "Enemy"

@onready var info_label: Label = $InfoLabel


func _ready() -> void:

	# --- Animation & Detection Setup ---
	$AnimatedSprite2D.play("Idle")
	_connect_hover_signals()
	_setup_detection_area()
	_update_info_label()
	
func _connect_hover_signals() -> void:
	var hover_area = get_node_or_null("HoverArea")
	if not hover_area:
		push_error("⚠️ Defender: Missing 'HoverArea' node!")
		return

	# Avoid duplicate connections
	if not hover_area.is_connected("mouse_entered", Callable(self, "_on_hover_area_mouse_entered")):
		hover_area.mouse_entered.connect(_on_hover_area_mouse_entered)
	if not hover_area.is_connected("mouse_exited", Callable(self, "_on_hover_area_mouse_exited")):
		hover_area.mouse_exited.connect(_on_hover_area_mouse_exited)

	print("✅ HoverArea signals connected for defender:", defender_name)



# --- Setup Detection Area (Under AttackModule) ---
func _setup_detection_area() -> void:
	var detection_area = get_node_or_null("AttackModule/DetectionArea")
	if detection_area:
		detection_area.area_entered.connect(_on_detection_area_area_entered)
		detection_area.area_exited.connect(_on_detection_area_area_exited)
	else:
		push_error("⚠️ Defender: Missing 'AttackModule/DetectionArea' path!")


# --- Info Label Setup ---
func _update_info_label() -> void:
	info_label.text = "%s" % [defender_name]
	info_label.visible = false


# --- Mouse Hover Events ---
func _on_hover_area_mouse_entered() -> void:
	print("🖱️ Hover entered!")
	info_label.visible = true


func _on_hover_area_mouse_exited() -> void:
	print("🖱️ Hover exited!")
	info_label.visible = false


# --- Targeting Logic ---
func _process(delta: float) -> void:
	_update_target_enemy()

	if target_enemy and is_instance_valid(target_enemy):
		_track_enemy()
	else:
		if $AnimatedSprite2D.animation != "Idle":
			$AnimatedSprite2D.play("Idle")


func _update_target_enemy() -> void:
	for i in range(enemies_in_range.size() - 1, -1, -1):
		var enemy = enemies_in_range[i]
		if not is_instance_valid(enemy) \
		or (enemy.has_method("is_dead") and enemy.is_dead()) \
		or not enemy.is_in_group(ENEMY_GROUP_NAME):
			enemies_in_range.remove_at(i)
	
	if enemies_in_range.is_empty():
		target_enemy = null
		return

	var closest_distance := INF
	var potential_target: Node2D = null
	for enemy in enemies_in_range:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			potential_target = enemy

	target_enemy = potential_target


func _track_enemy() -> void:
	if not target_enemy or not is_instance_valid(target_enemy):
		return
	
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


# --- Detection Area Signals ---
func _on_detection_area_area_entered(area: Area2D) -> void:
	if area.is_in_group(ENEMY_GROUP_NAME) and not enemies_in_range.has(area):
		enemies_in_range.append(area)


func _on_detection_area_area_exited(area: Area2D) -> void:
	if area.is_in_group(ENEMY_GROUP_NAME):
		enemies_in_range.erase(area)
		if area == target_enemy:
			target_enemy = null


# --- Allow AttackModule Access to Target ---
func get_target() -> Node2D:
	return target_enemy
