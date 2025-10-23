extends Path2D

@export var spawn_time: float = 1.0
var timer: float = 0.0

var follower_scene = preload("res://EnemyPath.tscn")

func _process(delta: float) -> void:
	timer += delta
	
	if timer >= spawn_time:
		var new_follower = follower_scene.instantiate()
		add_child.call_deferred(new_follower)
		timer = 0.0
