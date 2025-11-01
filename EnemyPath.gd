extends PathFollow2D

var previous_x: float
var warrior_node: Node = null
var animated_sprite: AnimatedSprite2D = null
var run_speed: float = 0.0

func _ready() -> void:
	previous_x = global_position.x
	# Defer setup so dynamic parents/children are attached
	call_deferred("_deferred_setup")

func _deferred_setup() -> void:
	if get_child_count() > 0:
		_setup_enemy(get_child(0))
	else:
		# If still no child, print for debug
		print("❌ PathFollow2D has no child after deferred setup (will wait for spawn). Parent:", get_parent())

func _setup_enemy(enemy_node: Node) -> void:
	warrior_node = enemy_node
	print("✓ Attached enemy:", warrior_node.name, "to PathFollow2D:", self)

	animated_sprite = warrior_node.get_node_or_null("AnimatedSprite2D")
	if not animated_sprite:
		animated_sprite = warrior_node.get_node_or_null("Sprite2D")

	if animated_sprite:
		print("✓ Found sprite for animation control")
	else:
		print("❌ No sprite found under", warrior_node.name)

	# ✅ FIX: safely access run_speed (since it's a normal @export var)
	if enemy_node is Area2D and "run_speed" in enemy_node:
		run_speed = enemy_node.run_speed
		print("✓ run_speed set from enemy:", run_speed)
	else:
		# fallback if property not found
		if enemy_node.has_method("get"):
			run_speed = enemy_node.get("run_speed") if enemy_node.get("run_speed") != null else 0.0
		else:
			run_speed = 0.0
		print("⚠️ Enemy node missing 'run_speed' property, defaulting to 0")

func _process(delta: float) -> void:
	if animated_sprite == null:
		return

	# Move along path — prefer 'progress', fall back to 'offset' or 'unit_offset'
	if "progress" in self:
		self.progress += run_speed * delta
	elif "offset" in self:
		self.offset += run_speed * delta
	elif "unit_offset" in self:
		self.unit_offset += run_speed * delta
	else:
		# If none exist, do nothing (PathFollow2D should normally expose one)
		# Keep this silent in normal runs, but you can uncomment for debugging:
		# print("⚠️ PathFollow2D has no known motion property (progress/offset/unit_offset).")
		pass

	# Flip sprite horizontally based on movement direction
	var current_x = global_position.x
	if current_x > previous_x:
		animated_sprite.flip_h = false
	elif current_x < previous_x:
		animated_sprite.flip_h = true

	previous_x = current_x
