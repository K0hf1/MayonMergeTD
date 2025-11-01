extends Node2D

@onready var tower_manager: Node = $TowerManager
@onready var wave_manager: Node = $WaveManager
@onready var coin_manager: Node = $CoinManager
@onready var audio_linker: Node = $AudioLinker

signal wave_started(wave_number)
signal wave_ended(wave_number)
signal coin_changed(new_amount)

func _ready():
	print("✅ GameManager initialized")

	PlayerRecord.load()
	print("Best Wave:", PlayerRecord.highest_wave)

	# Link signals
	tower_manager.coin_manager = coin_manager
	wave_manager.connect("wave_started", self._on_wave_started)
	wave_manager.connect("wave_completed", self._on_wave_completed)
	coin_manager.connect("coin_changed", self._on_coin_changed)

func _on_wave_started(wave_number):
	print("▶️ Wave started:", wave_number)
	wave_started.emit(wave_number)

func _on_wave_completed(wave_number):
	print("✅ Wave ended:", wave_number)
	PlayerRecord.update_wave_record(wave_number)
	wave_ended.emit(wave_number)

	# ✅ Update TowerManager with new wave (so tower cost refreshes)
	if tower_manager and tower_manager.has_method("set_current_wave"):
		tower_manager.set_current_wave(wave_number)


func _on_coin_changed(new_amount):
	print("💰 Coins updated:", new_amount)


func _on_start_wave_button_pressed():
	wave_manager = $WaveManager
	if wave_manager and wave_manager.has_method("start_next_wave"):
		wave_manager.start_next_wave()
	else:
		push_warning("⚠️ WaveManager not ready or missing start_next_wave()")
