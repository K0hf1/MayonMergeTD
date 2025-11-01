extends Node

signal coin_changed(new_amount: int)

@export var starting_coins: int = 20
var coins: int = 0


func _ready() -> void:
	coins = starting_coins
	print("💰 CoinManager initialized with:", coins)
	coin_changed.emit(coins)


func add(amount: int) -> void:
	if amount <= 0:
		push_warning("⚠️ Tried to add invalid coin amount: %d" % amount)
		return

	coins += amount
	coin_changed.emit(coins)
	print("💰 +%d (Total: %d)" % [amount, coins])


func try_deduct(amount: int) -> bool:
	if amount <= 0:
		push_warning("⚠️ Tried to deduct invalid coin amount: %d" % amount)
		return false

	if coins < amount:
		print("❌ Not enough coins: have %d, need %d" % [coins, amount])
		return false

	coins -= amount
	coin_changed.emit(coins)
	print("💸 -%d (Remaining: %d)" % [amount, coins])
	return true


func reset(new_value: int = starting_coins) -> void:
	coins = new_value
	coin_changed.emit(coins)
	print("🔁 Coins reset to:", coins)
