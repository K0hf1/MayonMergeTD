extends Node2D

# Tier of this defender
@export var tier: int = 2

func _ready() -> void:
	# Play the Idle animation at the start
	$AnimatedSprite2D.play("Idle")

func _process(delta: float) -> void:
	pass
