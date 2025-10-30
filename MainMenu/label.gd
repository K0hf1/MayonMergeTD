extends Label

@export var bob_amplitude: float = 2.0
@export var bob_frequency: float = 5.0

var time_passed: float = 0.0
var initial_y: float

func _ready():
	initial_y = position.y

func _process(delta):
	time_passed += delta
	var new_y = initial_y + (sin(time_passed * bob_frequency) * bob_amplitude)
	position.y = new_y
