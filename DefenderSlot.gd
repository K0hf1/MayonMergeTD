extends Marker2D
class_name MarkerSlot

var is_occupied: bool = false
var current_defender: Node2D = null
@export var snap_radius: float = 50.0

# Visual debug indicator (optional)
var debug_label: Label = null
@export var show_debug_info: bool = false

func _ready() -> void:
	if show_debug_info:
		_create_debug_label()

func _create_debug_label() -> void:
	debug_label = Label.new()
	debug_label.name = "DebugLabel"
	
	# Style the label
	debug_label.add_theme_font_size_override("font_size", 12)
	debug_label.add_theme_color_override("font_color", Color.GREEN)
	debug_label.add_theme_color_override("font_outline_color", Color.BLACK)
	debug_label.add_theme_constant_override("outline_size", 1)
	
	# Position below the marker
	debug_label.position = Vector2(-15, 10)
	debug_label.z_index = 99
	
	add_child(debug_label)
	_update_debug_label()

func _update_debug_label() -> void:
	if debug_label:
		if is_occupied and current_defender:
			var tier = current_defender.tier if "tier" in current_defender else "?"
			debug_label.text = "T%s" % tier
			debug_label.add_theme_color_override("font_color", Color.RED)
		else:
			debug_label.text = "Empty"
			debug_label.add_theme_color_override("font_color", Color.GREEN)

func _process(delta: float) -> void:
	if show_debug_info:
		_update_debug_label()

func is_in_snap_range(global_pos: Vector2) -> bool:
	return global_pos.distance_to(global_position) <= snap_radius
