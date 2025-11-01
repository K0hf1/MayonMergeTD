extends Node

# ===== Signals =====
signal music_volume_changed(linear_value: float)
signal sfx_volume_changed(linear_value: float)

# ===== Bus Names =====
const MUSIC_BUS_NAME: String = "Music"
const SFX_BUS_NAME: String = "sfx"  # ✅ lowercase fix

# ===== Bus Indexes =====
var music_bus_index: int = -1
var sfx_bus_index: int = -1

# ===== Remember last volumes =====
var last_music_volume: float = 1.0
var last_sfx_volume: float = 1.0

func _ready():
	music_bus_index = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	sfx_bus_index = AudioServer.get_bus_index(SFX_BUS_NAME)

	if music_bus_index == -1:
		push_error("❌ Could not find Music bus")
	if sfx_bus_index == -1:
		push_error("❌ Could not find sfx bus")

	# Initialize saved or default volumes
	last_music_volume = get_music_volume()
	last_sfx_volume = get_sfx_volume()


# ============================================================
# 🎵 MUSIC CONTROL
# ============================================================
func set_music_volume(linear_value: float):
	if music_bus_index == -1:
		return

	if linear_value > 0.0:
		last_music_volume = linear_value

	if linear_value == 0.0:
		AudioServer.set_bus_mute(music_bus_index, true)
	else:
		AudioServer.set_bus_mute(music_bus_index, false)
		AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(linear_value))

	music_volume_changed.emit(linear_value)


func get_music_volume() -> float:
	if music_bus_index == -1:
		return 1.0

	if AudioServer.is_bus_mute(music_bus_index):
		return 0.0
	else:
		return db_to_linear(AudioServer.get_bus_volume_db(music_bus_index))


func toggle_music_mute():
	var current_volume = get_music_volume()
	if current_volume > 0.0:
		set_music_volume(0.0)
	else:
		set_music_volume(last_music_volume)


# ============================================================
# 🔊 SFX CONTROL
# ============================================================
func set_sfx_volume(linear_value: float):
	if sfx_bus_index == -1:
		return

	if linear_value > 0.0:
		last_sfx_volume = linear_value

	if linear_value == 0.0:
		AudioServer.set_bus_mute(sfx_bus_index, true)
	else:
		AudioServer.set_bus_mute(sfx_bus_index, false)
		AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(linear_value))

	sfx_volume_changed.emit(linear_value)


func get_sfx_volume() -> float:
	if sfx_bus_index == -1:
		return 1.0

	if AudioServer.is_bus_mute(sfx_bus_index):
		return 0.0
	else:
		return db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_index))


func toggle_sfx_mute():
	var current_volume = get_sfx_volume()
	if current_volume > 0.0:
		set_sfx_volume(0.0)
	else:
		set_sfx_volume(last_sfx_volume)
