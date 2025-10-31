extends Button

func _ready():
	# 1. Connect to the global signal from VolumeManager
	#    This keeps the button's visual state in sync with SFX volume changes
	VolumeManager.sfx_volume_changed.connect(_on_VolumeManager_sfx_volume_changed)
	
	# 2. Set the initial pressed state (pressed if SFX volume is 0)
	var pressed = (VolumeManager.get_sfx_volume() == 0.0)
	
	# 3. Connect this button's own toggled signal
	connect("toggled", _on_toggled)


# Called when THIS button is toggled by the user
func _on_toggled(is_pressed: bool):
	# Tell the VolumeManager to toggle SFX mute state
	VolumeManager.toggle_sfx_mute()


# Called when the global SFX volume changes (for example, via the slider)
func _on_VolumeManager_sfx_volume_changed(linear_value: float):
	# Update this button's pressed state without triggering its own toggled signal again
	set_block_signals(true)
	var pressed = (linear_value == 0.0)
	set_block_signals(false)
