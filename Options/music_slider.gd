extends HSlider

func _ready():
	# Set the slider's starting value from our global settings
	value = VolumeManager.get_music_volume()
	
	# Connect the slider's "value_changed" signal to our function
	connect("value_changed", _on_value_changed)


# This function runs every time the player moves the slider
func _on_value_changed(new_value: float):
	# Tell our global settings to update the volume
	VolumeManager.set_music_volume(new_value)
