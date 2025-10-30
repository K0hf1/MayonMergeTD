extends Node

# NEW: Signal to notify UI (slider, mute button) when the volume changes
signal music_volume_changed(linear_value: float)

const MUSIC_BUS_NAME: String = "Music"
var music_bus_index: int

# NEW: Variable to remember the volume before muting
var last_music_volume: float = 1.0

func _ready():
	music_bus_index = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	if music_bus_index == -1:
		print("❌ ERROR: AudioSettings could not find bus '%s'" % MUSIC_BUS_NAME)
		return
	
	# Get the saved or default volume and store it
	last_music_volume = get_music_volume()
	if last_music_volume == 0.0:
		last_music_volume = 1.0 # Default to 1.0 if started as muted

## Sets the music bus volume from a linear value (0.0 to 1.0)
func set_music_volume(linear_value: float):
	if music_bus_index == -1:
		return

	# NEW: If the new volume is not 0, remember it
	if linear_value > 0.0:
		last_music_volume = linear_value

	# Mute or set volume
	if linear_value == 0.0:
		AudioServer.set_bus_mute(music_bus_index, true)
	else:
		AudioServer.set_bus_mute(music_bus_index, false)
		AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(linear_value))
	
	# NEW: Emit the signal to update all UI elements
	music_volume_changed.emit(linear_value)

## Gets the music bus volume as a linear value (0.0 to 1.0)
func get_music_volume() -> float:
	if music_bus_index == -1:
		return 1.0

	if AudioServer.is_bus_mute(music_bus_index):
		return 0.0
	else:
		return db_to_linear(AudioServer.get_bus_volume_db(music_bus_index))

## NEW: The function our mute button will call
func toggle_music_mute():
	var current_volume = get_music_volume()
	
	if current_volume > 0.0:
		# Currently on, so mute it
		set_music_volume(0.0)
	else:
		# Currently muted, so restore to the last volume
		set_music_volume(last_music_volume)
