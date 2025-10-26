extends Node2D

@export var fireball_scene: PackedScene
# These vars will likely be set by the parent Tower.gd script
@export var fire_rate: float = 1.0
@export var detection_range: float = 300.0 # Not used in behavior, only for visual reference

var can_shoot: bool = true
var enemies_in_range: Array = []

func _ready() -> void:
	# 1. Connect to the PARENT's signals (The parent is the Area2D)
	var parent_area = get_parent()
	if parent_area is Area2D:
		parent_area.area_entered.connect(_on_enemy_entered)
		parent_area.area_exited.connect(_on_enemy_exited)
		print("Signals connected to parent Area2D!")
	else:
		# If this error prints, your node setup is incorrect.
		print("ERROR: Parent is not an Area2D!") 
		
	# 2. Correct path to the sibling AnimatedSprite2D
	# Ensure the AnimatedSprite2D child node is named exactly "AnimatedSprite2D"
	var animated_sprite = parent_area.get_node_or_null("AnimatedSprite2D")
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("Idle"):
		animated_sprite.play("Idle")
	
	print("Tower Behavior ready.")

func _process(_delta: float) -> void: # <-- FIX APPLIED HERE
	# Clean invalid enemies
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))
	
	# Shoot at enemies
	if enemies_in_range.size() > 0 and can_shoot:
		shoot_at_enemy()

func _on_enemy_entered(area):
	if area.is_in_group("Enemy"):
		enemies_in_range.append(area)
		print("✅ Tower detected ENEMY!")

func _on_enemy_exited(area):
	enemies_in_range.erase(area)
	print("Enemy left range")

func shoot_at_enemy():
	
	var target = get_closest_enemy()
	if target == null:
		return
	
	# 1. Create fireball at PARENT's position (The Area2D root)
	var fireball = fireball_scene.instantiate()
	fireball.global_position = get_parent().global_position
	
	# 2. Aim at enemy using PARENT's position
	var direction = (target.global_position - get_parent().global_position).normalized()
	fireball.set_direction(direction)
	fireball.add_to_group("projectiles")
	
	# 3. Add the projectile to the root scene (Grandparent of this node)
	get_parent().get_parent().add_child(fireball)
	
	can_shoot = false
	# Timer is based on fire_rate property
	await get_tree().create_timer(1.0 / fire_rate).timeout 
	can_shoot = true

func get_closest_enemy():
	if enemies_in_range.is_empty():
		return null
	
	var closest = enemies_in_range[0]
	var tower_pos = get_parent().global_position # Use parent's position
	var closest_dist = tower_pos.distance_to(closest.global_position)
	
	for enemy in enemies_in_range:
		var dist = tower_pos.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy
	
	return closest
