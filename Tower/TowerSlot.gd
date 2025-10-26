extends Marker2D
class_name MarkerSlot

var is_occupied: bool = false
var current_tower: Node2D = null
@export var snap_radius: float = 50.0

func is_in_snap_range(global_pos: Vector2) -> bool:
	return global_pos.distance_to(global_position) <= snap_radius
