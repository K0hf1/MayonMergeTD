extends Node

var highest_wave: int = 0
const SAVE_PATH := "user://player_record.cfg"

func update_wave_record(current_wave: int) -> void:
	if current_wave > highest_wave:
		highest_wave = current_wave
		print("🎉 New highest wave achieved:", highest_wave)
		save()

func get_highest_wave() -> int:
	return highest_wave

# --- SAVE / LOAD ---

func save() -> void:
	var config := ConfigFile.new()
	config.set_value("PlayerRecord", "highest_wave", highest_wave)
	var err := config.save(SAVE_PATH)
	if err != OK:
		push_error("Failed to save PlayerRecord: %s" % err)
	else:
		print("💾 PlayerRecord saved successfully!")

func load() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		print("ℹ️ No previous PlayerRecord found, starting fresh")
		return
	highest_wave = config.get_value("PlayerRecord", "highest_wave", 0)
	print("📂 PlayerRecord loaded: Highest wave =", highest_wave)
