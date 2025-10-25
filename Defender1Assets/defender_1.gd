extends Node2D

func _ready() -> void:
	# Play the Idle animation at the start
	$AnimatedSprite2D.play("Idle")

func _process(delta: float) -> void:
	pass
