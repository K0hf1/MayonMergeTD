extends Node

var music_manager
var button_sfx_manager

func _ready():
	music_manager = get_tree().root.find_child("MusicManager", true, false)
	button_sfx_manager = get_tree().root.find_child("ButtonSFXManager", true, false)

	if music_manager:
		print("🎵 MusicManager linked")
	if button_sfx_manager:
		print("🎚️ ButtonSFXManager linked")

func play_click():
	if button_sfx_manager and button_sfx_manager.has_method("play_button_click"):
		button_sfx_manager.play_button_click()

func play_music(volume := 1.0):
	if music_manager and music_manager.has_method("set_music_volume"):
		music_manager.set_music_volume(volume)
