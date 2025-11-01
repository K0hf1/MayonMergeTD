extends Node2D

@export var projectile_scene: PackedScene
@export var projectile_steer_force: float = 40.0
@export var projectile_fade_time: float = 0.1  # optional

const TIMER_PATH = "AttackTimer" 
var defender_root: Node2D = null
var button_sfx_manager: Node = null

func _ready() -> void:
	defender_root = get_parent()
	if not defender_root:
		push_error("AttackModule must be a child of Defender node.")
		return
	
	_find_button_sfx_manager()
	
	if has_node(TIMER_PATH):
		var attack_timer = get_node(TIMER_PATH)
		attack_timer.wait_time = defender_root.attack_cooldown
		attack_timer.timeout.connect(_on_attack_timer_timeout)
		attack_timer.start()
	else:
		push_error("AttackModule missing 'AttackTimer' node")

func _find_button_sfx_manager() -> void:
	button_sfx_manager = get_node_or_null("/root/Main/ButtonSFXManager")
	if not button_sfx_manager:
		button_sfx_manager = get_tree().root.find_child("ButtonSFXManager", true, false)

func _on_attack_timer_timeout() -> void:
	var target = _get_current_target()
	if target and is_instance_valid(target):
		_shoot_projectile(target)

func _get_current_target() -> Node2D:
	if defender_root.has_method("get_target"):
		return defender_root.get_target()
	return null

func _shoot_projectile(target: Node2D) -> void:
	if projectile_scene == null:
		push_error("Projectile scene not set!")
		return
	
	if button_sfx_manager and button_sfx_manager.has_method("play_projectile_fire"):
		button_sfx_manager.play_projectile_fire()
	
	var projectile = projectile_scene.instantiate()
	projectile.global_position = defender_root.global_position
	var direction = (target.global_position - defender_root.global_position).normalized()

	if projectile.has_method("set_stats"):
		projectile.set_stats(defender_root.damage, defender_root.projectile_speed)
	if projectile.has_method("set_direction"):
		projectile.set_direction(direction)
	if projectile.has_method("set_homing_speed"):
		projectile.set_homing_speed(defender_root.projectile_speed)
	if projectile.has_method("set_steer_force"):
		projectile.set_steer_force(projectile_steer_force)
	if projectile.has_method("set_target"):
		projectile.set_target(target)
	if projectile.has_method("set_sfx_manager"):
		projectile.set_sfx_manager(button_sfx_manager)

	defender_root.get_parent().add_child(projectile)
