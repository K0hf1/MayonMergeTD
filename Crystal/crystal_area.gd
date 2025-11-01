extends Area2D

signal crystal_destroyed

var game_manager = null
var music_manager = null
@onready var animated_sprite = $AnimatedSprite2D


func _ready():
	animated_sprite.play("idleCrystal")
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_find_music_manager()
	_find_game_manager()

## Find Game Manager
func _find_game_manager() -> void:
	game_manager = get_node_or_null("../GameManager")
	
	if not game_manager:
		game_manager = get_tree().root.find_child("GameManager", true, false)
	
	if game_manager:
		print("✓ Crystal found GameManager")
	else:
		print("⚠️  Crystal WARNING: GameManager NOT found!")

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
		
		# ✅ Call cleanup on GameManager BEFORE changing scene
		if game_manager and game_manager.has_method("restart_level"):
			print("✓ Calling GameManager.restart_level()...")
			game_manager.restart_level()
		
		# ✅ Stop current music
		if music_manager and music_manager.has_method("stop_music"):
			print("⏹️  Stopping current music...")
			music_manager.stop_music()
		
		# Game over
		game_over()

func game_over():
	# ✅ Play destruction animation
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("destroyCrystal"):
		animated_sprite.play("destroyCrystal")
		await animated_sprite.animation_finished
	
	crystal_destroyed.emit()
	
	# ✅ Pause game
	print("⏸️  Pausing game...")
	get_tree().paused = true
	
	print("🔄 Changing to GameOver scene...")
	call_deferred("_change_to_game_over")
	
func _change_to_game_over():
	get_tree().change_scene_to_file("res://GameOver/GameOver.tscn")
