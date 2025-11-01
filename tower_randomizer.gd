extends Node

# --- Base weights for each tower tier ---
const BASE_WEIGHTS = {
	1: 50.0,    # ~50% chance
	2: 25.0,    # ~25% chance
	3: 12.0,    # ~12% chance
	4: 6.0,     # ~6% chance
	5: 3.0,     # ~3% chance
	6: 1.8,     # ~1.8% chance
	7: 1.2,     # ~1.2% chance
	8: 0.8,     # ~0.8% chance
	9: 0.5,     # ~0.5% chance
	10: 0.35,   # ~0.35% chance
	11: 0.2,    # ~0.2% chance
	12: 0.15,   # ~0.15% chance
	13: 0.1,    # ~0.1% chance
	14: 0.05    # ~0.05% chance → roughly 1% after normalization
}

# --- Calculate the active tier cap based on lifetime highest tier ---
func get_tier_cap_from_progress(highest_tier: int) -> int:
	return clamp(highest_tier, 1, 14)

# --- Return a randomly selected tier based on lifetime progress ---
func get_random_tower_tier() -> int:
	var gm = get_parent()
	if not gm:
		push_warning("⚠️ TowerRandomizer: Missing GameManager parent — defaulting to Tier 1")
		return 1

	var player_record = PlayerRecord
	if not player_record:
		push_warning("⚠️ PlayerRecord not found under GameManager — defaulting to Tier 1")
		return 1
	
	print("🔍 Using PlayerRecord node at:", player_record.get_path())
	print("   Highest tier inside record:", player_record.highest_tier)


	var highest_tier = player_record.get_highest_tier()
	var tier_cap = get_tier_cap_from_progress(highest_tier)

	var active_tiers = {}
	var total_weight = 0.0

	for tier in BASE_WEIGHTS.keys():
		if tier <= tier_cap:
			active_tiers[tier] = BASE_WEIGHTS[tier]
			total_weight += BASE_WEIGHTS[tier]

	# Weighted random roll
	var roll = randf() * total_weight
	var cumulative = 0.0

	for tier in active_tiers.keys():
		cumulative += active_tiers[tier]
		if roll <= cumulative:
			print("🎲 Rolled Tower Tier:", tier, "(from cap:", tier_cap, ")")
			return tier

	return tier_cap  # fallback


# --- Debug: print current probabilities based on lifetime progress ---
func debug_print_probabilities(tier_cap: int = -1) -> void:
	var player_record = PlayerRecord
	if not player_record:
		print("⚠️ PlayerRecord missing — cannot display probabilities.")
		return

	var highest_tier = player_record.highest_tier
	if tier_cap == -1:
		tier_cap = get_tier_cap_from_progress(highest_tier)

	var total_weight = 0.0
	var active_tiers = {}

	for tier in BASE_WEIGHTS.keys():
		if tier <= tier_cap:
			active_tiers[tier] = BASE_WEIGHTS[tier]
			total_weight += BASE_WEIGHTS[tier]

	print("📊 Lifetime Tower Distribution (Highest Tier: %d)" % highest_tier)
	var sorted_tiers = active_tiers.keys()
	sorted_tiers.sort()

	for tier in sorted_tiers:
		var pct = (active_tiers[tier] / total_weight) * 100.0
		print("   • Tier %-2d → %.2f%%" % [tier, pct])
