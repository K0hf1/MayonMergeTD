extends Button


func _ready():
	# 1. Connect to the global signal from VolumeManager
	# This updates the button's visual state if the slider changes the volume
	VolumeManager.music_volume_changed.connect(_on_VolumeManager_music_volume_changed)
	
	# 2. Set this button's starting state (pressed if volume is 0)
	# This works because the button is in "Toggle Mode"
	var pressed = (VolumeManager.get_music_volume() == 0.0)
	
	# 3. Connect this button's own "toggled" signal to its function
	connect("toggled", _on_toggled)


# This runs when THIS button is clicked by the user
func _on_toggled(is_pressed: bool):
	# Tell the VolumeManager to toggle the mute state
	VolumeManager.toggle_music_mute()


# This runs when the global volume changes (e.g., from the slider)
func _on_VolumeManager_music_volume_changed(linear_value: float):
	# Update this button's visual pressed state
	# We block signals to prevent an infinite loop (toggling -> changing value -> toggling)
	set_block_signals(true)
	var pressed = (linear_value == 0.0)
	set_block_signals(false)
