extends Node

var selected_tower: Node2D = null
var towers: Array = []

func register_tower(tower: Node2D):
	towers.append(tower)
	var area = tower.get_node_or_null("DetectionArea")
	if area:
		area.connect("input_event", Callable(self, "_on_tower_clicked").bind(tower))

func _on_tower_clicked(viewport, event, shape_idx, tower):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_tower(tower)

func select_tower(tower: Node2D):
	if selected_tower:
		_deselect_tower(selected_tower)
	selected_tower = tower
	_highlight_tower(tower)
	print("🔍 Selected tower:", tower.name)

func _highlight_tower(tower: Node2D):
	# simple example — change modulate color
	tower.modulate = Color(1, 1, 0.6)

func _deselect_tower(tower: Node2D):
	tower.modulate = Color(1, 1, 1)
	selected_tower = null
