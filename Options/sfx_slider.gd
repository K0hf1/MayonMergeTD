extends HSlider

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure slider receives input
	value = VolumeManager.get_sfx_volume()
	connect("value_changed", Callable(self, "_on_value_changed"))

func _on_value_changed(new_value: float) -> void:
	VolumeManager.set_sfx_volume(new_value)
