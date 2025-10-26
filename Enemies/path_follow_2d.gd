extends PathFollow2D

@export var run_speed: float = 100.0
var previous_x: float

func _ready() -> void:
	previous_x = global_position.x

func _process(delta: float) -> void:
	progress += run_speed * delta
	
	var current_x = global_position.x
	if current_x > previous_x:
		$Warrior/AnimatedSprite2D.flip_h = false
	elif current_x < previous_x:
		$Warrior/AnimatedSprite2D.flip_h = true
		
	previous_x = current_x
