extends Node

# ===== MUSIC PATHS =====
@export var gameplay_music: AudioStream = preload("res://Audio/Music/gameplay.mp3")
@export var wave_complete_music: AudioStream = preload("res://Audio/Music/wave_complete.mp3")
@export var game_over_music: AudioStream = preload("res://Audio/Music/game_over.mp3")

# ===== AUDIO PLAYER =====
var music_player: AudioStreamPlayer = null
var current_music: AudioStream = null
var is_transitioning: bool = false

# ===== VOLUME =====
@export var music_volume_db: float = 0.0
@export var fade_duration: float = 0.5
@export var fade_out_duration: float = 0.1  # ✅ NEW: Longer fade out
@export var fade_in_duration: float = 0.5   # ✅ NEW: Longer fade in

# ===== PLAYBACK SPEED =====
@export var gameplay_speed: float = 1.0
@export var wave_complete_speed: float = 0.8
@export var game_over_speed: float = 1.0

# ===== STATE =====
var current_state: String = ""

func _ready() -> void:
	# Set process mode to always run, even when paused
	process_mode = Node.PROCESS_MODE_INHERIT
	
	# Create audio player
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	print("✓ Music player created and added to scene")
	
	# Try to set Music bus
	if AudioServer.get_bus_index("Music") != -1:
		music_player.bus = "Music"
		print("✓ Music bus found and set")
	else:
		print("⚠️  Music bus not found, using Master bus")
		music_player.bus = "Master"
	
	# Set volume
	music_player.volume_db = music_volume_db
	
	print("✓ MusicManager initialized")
	print("  Music Player exists: ", music_player != null)
	print("  Fade Out Duration: ", fade_out_duration, "s")
	print("  Fade In Duration: ", fade_in_duration, "s")
	print("  Music Player Bus: ", music_player.bus)
	print("  Music Volume DB: ", music_player.volume_db)
	print("  Process Mode: ALWAYS (plays even when paused)")
	
	# Check if audio files exist
	if not gameplay_music:
		print("❌ ERROR: gameplay_music not loaded!")
		return
	else:
		print("✓ gameplay_music loaded: ", gameplay_music.resource_path)
	
	if not wave_complete_music:
		print("❌ ERROR: wave_complete_music not loaded!")
	else:
		print("✓ wave_complete_music loaded: ", wave_complete_music.resource_path)
	
	if not game_over_music:
		print("❌ ERROR: game_over_music not loaded!")
	else:
		print("✓ game_over_music loaded: ", game_over_music.resource_path)
	
	print("✓ MusicManager ready, waiting for GameManager to start music...")

## Play gameplay music
func play_gameplay_music() -> void:
	if current_state == "gameplay":
		print("⏸️  Already playing gameplay music, skipping...")
		return
	
	if music_player == null:
		print("❌ ERROR: music_player is NULL!")
		return
	
	print("🎵 Switching to gameplay music...")
	current_state = "gameplay"
	_fade_to_music(gameplay_music, "Gameplay Music", gameplay_speed, fade_out_duration, fade_in_duration)

## Play wave complete music
func play_wave_complete_music() -> void:
	if current_state == "wave_complete":
		print("⏸️  Already playing wave complete music, skipping...")
		return
	
	if music_player == null:
		print("❌ ERROR: music_player is NULL!")
		return
	
	print("🎵 Switching to wave complete music...")
	current_state = "wave_complete"
	_fade_to_music(wave_complete_music, "Wave Complete Music", wave_complete_speed, fade_out_duration, fade_in_duration)

## Play game over music
func play_game_over_music() -> void:
	if current_state == "game_over":
		print("⏸️  Already playing game over music, skipping...")
		return
	
	if music_player == null:
		print("❌ ERROR: music_player is NULL!")
		return
	
	print("🎵 Switching to game over music...")
	current_state = "game_over"
	_fade_to_music(game_over_music, "Game Over Music", game_over_speed, fade_out_duration, fade_in_duration)

## Internal: Fade to new music with custom durations
func _fade_to_music(new_music: AudioStream, music_name: String, speed: float = 1.0, fade_out: float = 1.0, fade_in: float = 2.0) -> void:
	# ✅ CRITICAL: Check if music_player exists
	if music_player == null:
		print("❌ ERROR: music_player is NULL in _fade_to_music!")
		return
	
	if is_transitioning:
		print("⏸️  Already transitioning, skipping...")
		return
	
	if not new_music:
		print("❌ No music stream provided!")
		return
	
	is_transitioning = true
	
	# ✅ Phase 1: Fade out current music
	if music_player and music_player.playing:
		print("🎵 Phase 1: Fading out current music (%.1fs)..." % fade_out)
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(music_player, "volume_db", -80, fade_out)
		await tween.finished
		music_player.stop()
		print("   ✓ Current music stopped")
	
	# ✅ Phase 2: Switch to new music
	if music_player:
		print("🎵 Phase 2: Switching stream to: ", music_name)
		print("   Speed: %.1f%%" % (speed * 100))
		current_music = new_music
		music_player.stream = new_music
		music_player.volume_db = -80  # Start silent
		music_player.pitch_scale = speed
		music_player.play()
		
		# Wait a frame to ensure it's playing
		await get_tree().process_frame
		print("   ✓ Is playing: ", music_player.playing if music_player else "PLAYER NULL")
		print("   ✓ Starting position: %.2f seconds" % music_player.get_playback_position())
		
		# ✅ Phase 3: Fade in new music with smooth curve
		print("🎵 Phase 3: Fading in new music (%.1fs)..." % fade_in)
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(music_player, "volume_db", music_volume_db, fade_in)
		await tween.finished
		
		print("✓ Transition complete!")
		print("   ✓ Now playing: ", music_name)
		print("   ✓ Current volume: ", music_player.volume_db, " db")
	
	is_transitioning = false

## Set music volume (0.0 to 1.0)
func set_music_volume(volume: float) -> void:
	music_volume_db = linear_to_db(clamp(volume, 0.0, 1.0))
	if music_player:
		music_player.volume_db = music_volume_db
	print("🔊 Music volume set to: ", volume * 100, "%")

## Set music speed
func set_music_speed(speed: float) -> void:
	if music_player:
		music_player.pitch_scale = speed
	print("⏱️  Music speed set to: ", speed * 100, "%")

## Pause music
func pause_music() -> void:
	if music_player:
		music_player.stream_paused = true
	print("⏸️  Music paused")

## Resume music
func resume_music() -> void:
	if music_player:
		music_player.stream_paused = false
	print("▶️  Music resumed")

## Stop music
func stop_music() -> void:
	if music_player:
		music_player.stop()
	print("⏹️  Music stopped")

## Get current music state
func get_current_state() -> String:
	return current_state

## Get is playing
func is_playing() -> bool:
	return music_player and music_player.playing
