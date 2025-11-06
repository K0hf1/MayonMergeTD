extends Node

# ------------------------------
# Player Progress Variables
# ------------------------------
var highest_wave: int = 0
var highest_tier: int = 1   # lifetime highest merged tier (1..14)

const SAVE_PATH := "user://player_record.cfg"


func _ready() -> void:
	load_record()  # ✅ Renamed to avoid conflict with built-in load()


# ------------------------------
# Wave functions
# ------------------------------
func update_wave_record(current_wave: int) -> void:
	if current_wave > highest_wave:
		highest_wave = current_wave
		print("🎉 New highest wave achieved:", highest_wave)
		save_record()


func get_highest_wave() -> int:
	return highest_wave


# ------------------------------
# Tier functions
# ------------------------------
func update_highest_tier(tier: int) -> void:
	tier = clamp(tier, 1, 14)
	if tier > highest_tier:
		highest_tier = tier
		print("🏆 New lifetime highest tier achieved:", highest_tier)
		save_record()


func get_highest_tier() -> int:
	return highest_tier


# ------------------------------
# Save / Load (Hybrid System)
# ------------------------------
func save_record() -> void:
	if OS.has_feature("HTML5"):
		_save_to_browser()
	else:
		_save_to_file()


func load_record() -> void:
	if OS.has_feature("HTML5"):
		_load_from_browser()
	else:
		_load_from_file()


# ------------------------------
# DESKTOP: ConfigFile system
# ------------------------------
func _save_to_file() -> void:
	var config := ConfigFile.new()
	config.set_value("PlayerRecord", "highest_wave", highest_wave)
	config.set_value("PlayerRecord", "highest_tier", highest_tier)
	var err := config.save(SAVE_PATH)
	if err != OK:
		push_error("❌ Failed to save PlayerRecord: %s" % err)
	else:
		print("💾 PlayerRecord saved successfully (desktop)")


func _load_from_file() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)  # ✅ Added missing argument
	if err != OK:
		print("ℹ️ No previous PlayerRecord found, starting fresh (desktop)")
		highest_wave = 0
		highest_tier = 1
		return

	highest_wave = config.get_value("PlayerRecord", "highest_wave", 0)
	highest_tier = config.get_value("PlayerRecord", "highest_tier", 1)

	print("📂 PlayerRecord loaded (desktop): wave =", highest_wave, ", tier =", highest_tier)


# ------------------------------
# HTML5: localStorage system
# ------------------------------
func _save_to_browser() -> void:
	if not Engine.has_singleton("JavaScriptBridge"):
		push_error("❌ JavaScriptBridge not available (HTML5 only)")
		return
	
	var js = Engine.get_singleton("JavaScriptBridge")
	var data = {
		"highest_wave": highest_wave,
		"highest_tier": highest_tier
	}
	var json_str = JSON.stringify(data)
	js.eval("window.localStorage.setItem('player_record', " + JSON.stringify(json_str) + ");")
	print("💾 PlayerRecord saved to browser localStorage")


func _load_from_browser() -> void:
	if not Engine.has_singleton("JavaScriptBridge"):
		push_error("❌ JavaScriptBridge not available (HTML5 only)")
		return
	
	var js = Engine.get_singleton("JavaScriptBridge")
	var json_str = js.eval("window.localStorage.getItem('player_record');")
	if json_str == null or json_str == "null":
		print("ℹ️ No previous PlayerRecord found, starting fresh (browser)")
		highest_wave = 0
		highest_tier = 1
		return

	var data = JSON.parse_string(json_str)
	if typeof(data) == TYPE_DICTIONARY:
		highest_wave = data.get("highest_wave", 0)
		highest_tier = data.get("highest_tier", 1)
		print("📂 PlayerRecord loaded (browser): wave =", highest_wave, ", tier =", highest_tier)
	else:
		print("⚠️ Invalid save data format in localStorage")
