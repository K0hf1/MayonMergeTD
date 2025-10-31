extends Node

# --- Music and Player ---
@export var menu_music: AudioStream = preload("res://Audio/Music/main_menu.mp3")
var music_player: AudioStreamPlayer = null

# --- Volume and Fade ---
@export var music_volume_db: float = 0.0
@export var fade_in_duration: float = 1.0  # How long to fade in at the start
@export var fade_out_duration: float = 0.5 # How long to fade out on transition

var is_transitioning: bool = false

func _ready() -> void:
	# Create the audio player
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	# Set the "Music" bus, just like your other manager
	if AudioServer.get_bus_index("Music") != -1:
		music_player.bus = "Music"
	else:
		music_player.bus = "Master"
	
	# Start playing the menu music with a fade-in
	play_menu_music()

func play_menu_music() -> void:
	if not menu_music:
		print("❌ ERROR: Main menu music not loaded!")
		return
	
	if music_player.playing:
		return # Already playing

	print("🎵 Playing main menu music...")
	music_player.stream = menu_music
	music_player.volume_db = -80 # Start silent
	music_player.play()
	
	# Create a tween to fade in the music
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(music_player, "volume_db", music_volume_db, fade_in_duration)

## This is the new function your start button will call
func fade_out_and_change_scene(scene_path: String) -> void:
	# Prevent this from running multiple times if clicked fast
	if is_transitioning:
		return
	
	# If music isn't playing, just change scene
	if not music_player or not music_player.playing:
		get_tree().change_scene_to_file(scene_path)
		return

	print("🎵 Fading out main menu music...")
	is_transitioning = true
	
	# Create a tween to fade out the music
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN) # Ease_IN is good for fade-outs
	tween.tween_property(music_player, "volume_db", -80, fade_out_duration)
	
	# IMPORTANT: Wait for the fade to finish
	await tween.finished
	
	music_player.stop()
	print("✓ Fade complete. Changing scene to: ", scene_path)
	
	# Finally, change the scene
	get_tree().change_scene_to_file(scene_path)
