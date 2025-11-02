extends Button

var wave_manager: Node = null

func _ready() -> void:
	toggle_mode = true
	text = "Auto Wave Off"

	# Find WaveManager in the scene tree
	wave_manager = get_tree().root.find_child("WaveManager", true, false)

	if wave_manager:
		print("✅ AutoWaveToggle linked to WaveManager")
	else:
		push_warning("⚠️ WaveManager not found — Auto Wave will not work")

	# Connect the pressed signal
	pressed.connect(_on_toggled)
	

func _on_toggled() -> void:
	if not wave_manager:
		return

	if button_pressed:
		text = "Auto Wave On"
		wave_manager.set_auto_wave(true)
	else:
		text = "Auto Wave Off"
		wave_manager.set_auto_wave(false)
