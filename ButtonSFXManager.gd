extends Node

# ===== BUTTON SFX PATHS =====
@export var button_click_sfx: AudioStream = preload("res://Audio/SFX/button_click.mp3")
@export var merge_sfx: AudioStream = preload("res://Audio/SFX/merge.mp3")
@export var cannot_merge_sfx: AudioStream = preload("res://Audio/SFX/cannot_merge.mp3")

# ===== COIN SFX PATHS =====
@export var coin_drop_sfx: AudioStream = preload("res://Audio/SFX/coin_drop.mp3")
@export var coin_collect_sfx: AudioStream = preload("res://Audio/SFX/coin_collect.mp3")

# ===== PROJECTILE SFX PATHS ===== ✅ NEW
@export var projectile_fire_sfx: AudioStream = preload("res://Audio/SFX/projectile_fire.mp3")
@export var projectile_hit_sfx: AudioStream = preload("res://Audio/SFX/projectile_hit.mp3")

# ===== AUDIO PLAYER POOL =====
var audio_players: Array[AudioStreamPlayer] = []
var max_simultaneous_sounds: int = 10  # ✅ Increased to 10 for projectiles

func _ready() -> void:
	# Create pool of audio players
	for i in range(max_simultaneous_sounds):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"  # Make sure you have an SFX bus
		add_child(player)
		audio_players.append(player)
	
	print("✓ ButtonSFXManager initialized with %d audio players" % max_simultaneous_sounds)

# ===== BUTTON SFX =====

## Play button click sound (used for all buttons)
func play_button_click() -> void:
	_play_sfx(button_click_sfx)

## Play merge sound
func play_merge() -> void:
	_play_sfx(merge_sfx)

## Play cannot merge sound
func play_cannot_merge() -> void:
	_play_sfx(cannot_merge_sfx)

# ===== COIN SFX =====

## Play coin drop sound
func play_coin_drop() -> void:
	_play_sfx(coin_drop_sfx)

## Play coin collect sound
func play_coin_collect() -> void:
	_play_sfx(coin_collect_sfx)

# ===== PROJECTILE SFX ===== ✅ NEW

## Play projectile fire sound
func play_projectile_fire() -> void:
	_play_sfx(projectile_fire_sfx)

## Play projectile hit sound
func play_projectile_hit() -> void:
	_play_sfx(projectile_hit_sfx)

# ===== INTERNAL =====

## Internal: Play any SFX
func _play_sfx(audio: AudioStream) -> void:
	if not audio:
		print("❌ No audio stream provided!")
		return
	
	# Find an available player
	for player in audio_players:
		if not player.playing:
			player.stream = audio
			player.play()
			return
	
	print("⚠️  No available audio players!")
