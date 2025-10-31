extends Area2D

signal crystal_destroyed

var game_over_ui = null
var music_manager = null
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	animated_sprite.play("idleCrystal")
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_find_music_manager()

## Find Music Manager
func _find_music_manager() -> void:
	music_manager = get_node_or_null("/root/main/MusicManager")
	
	if not music_manager:
		music_manager = get_tree().root.find_child("MusicManager", true, false)
	
	if music_manager:
		print("✓ Crystal found MusicManager")
	else:
		print("⚠️  Crystal WARNING: MusicManager NOT found!")

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		print("💔 HEART CRYSTAL DESTROYED! GAME OVER!")
		
		# Destroy enemy
		if area.get_parent() != null:
			area.get_parent().queue_free()
		else:
			area.queue_free()
		
		# Set volume to 100%
		if music_manager and music_manager.has_method("set_music_volume"):
			print("🔊 Setting music volume to 100%...")
			music_manager.set_music_volume(1.0)
		
		# Play game over music
		if music_manager and music_manager.has_method("play_game_over_music"):
			print("🎵 Playing game over music...")
			music_manager.play_game_over_music()
		
		# Wait for music to start
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Game over
		game_over()

func game_over():
	# Play destruction animation
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("destroyCrystal"):
		animated_sprite.play("destroyCrystal")
		await animated_sprite.animation_finished
	
	crystal_destroyed.emit()
	
	# Pause after everything is set up
	get_tree().paused = true
	get_tree().change_scene_to_file("res://GameOver/GameOver.tscn")
