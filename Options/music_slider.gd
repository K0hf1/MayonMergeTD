extends HSlider

func _ready():
	# Set initial value to match saved music volume
	value = VolumeManager.get_music_volume()

	# Connect slider value changes to our function
	connect("value_changed", _on_value_changed)


func _on_value_changed(new_value: float):
	# Update the music volume in VolumeManager
	VolumeManager.set_music_volume(new_value)
