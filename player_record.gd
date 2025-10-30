extends Node

# Player progress saved across runs
var highest_wave: int = 0
var highest_tier: int = 1         # NEW: lifetime highest merged tower tier (1..14)

const SAVE_PATH := "user://player_record.cfg"

# ------------------------------
# Wave functions (existing)
# ------------------------------
func update_wave_record(current_wave: int) -> void:
	if current_wave > highest_wave:
		highest_wave = current_wave
		print("🎉 New highest wave achieved:", highest_wave)
		save()

func get_highest_wave() -> int:
	return highest_wave

# ------------------------------
# Tier functions (NEW)
# ------------------------------
# Call this when a merge produces a tower of `tier`.
func update_highest_tier(tier: int) -> void:
	tier = clamp(tier, 1, 14)
	if tier > highest_tier:
		highest_tier = tier
		print("🏆 New lifetime highest tier achieved:", highest_tier)
		save()

func get_highest_tier() -> int:
	return highest_tier

# ------------------------------
# Save / Load
# ------------------------------
func save() -> void:
	var config := ConfigFile.new()
	config.set_value("PlayerRecord", "highest_wave", highest_wave)
	config.set_value("PlayerRecord", "highest_tier", highest_tier)
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
		# Ensure sensible defaults
		highest_wave = 0
		highest_tier = 1
		return

	highest_wave = config.get_value("PlayerRecord", "highest_wave", 0)
	highest_tier = config.get_value("PlayerRecord", "highest_tier", 0)

	# Migration: if highest_tier was not saved before (0), derive from highest_wave
	if highest_tier <= 0:
		highest_tier = clamp(ceil(highest_wave / 5.0), 1, 14)
		print("🔧 Migrated highest_tier from highest_wave:", highest_tier)

	print("📂 PlayerRecord loaded: Highest wave =", highest_wave, "Highest tier =", highest_tier)
