extends Node

# SHARD INVENTORY 
var shards_collected := {
	"red": 0,
	"blue": 0,
	"green": 0,
	"top": 0
}
# ATTACK INVENTORY
var attacks := {
	"red":0,
	"blue":0,
	"green":0
}

# PLAYER BASE STATS 
var max_health: int = 100
var current_health: int = 100
var base_damage: float = 20.0 
var current_damage: float = 20.0
var base_speed: float = 250.0
var current_speed: float = 250.0

# SHARD CAPS & MULTIPLIERS 
const MAX_SPEED_BONUS: float = 1 # +100% max
var is_prime_heart_active: bool = false

# ENEMY SCALING
var enemy_stat_multiplier: float = 1.0 
var game_time_seconds: float = 0.0

func _process(delta):
	game_time_seconds += delta

# CORE UPGRADE FUNCTION
func collect_shard(color: String):
	if shards_collected.has(color):
		shards_collected[color] += 1
		if color == "green":
			attacks[color] += 3   # 3 Bullets per Green Shard
		else:
			attacks[color]+= 1 # 1 Attack use increasc for other Shards
		apply_stats()

func apply_stats():
	# Red Shard -> +5% Base Attack Damage per shard
	var red_bonus = shards_collected["red"] * 0.05
	current_damage = base_damage * (1.0 + red_bonus)
	
	# Blue Shard -> +10% Movement Speed (Capped at +100%)
	var blue_bonus = min(shards_collected["blue"] * 0.1, MAX_SPEED_BONUS)
	current_speed = base_speed * (1.0 + blue_bonus)
	
	# Green Shard -> +15 Max Health
	max_health = 100 + (shards_collected["green"] * 15)
	
	# Top Orb -> +50% to all stats
	if shards_collected["top"] > 0:
		is_prime_heart_active = true
		current_damage *= 1.50
		current_speed *= 1.50
		max_health = int(max_health * 1.50)

# ENEMY SCALING FUNCTION 
func increase_enemy_difficulty():
	enemy_stat_multiplier += 0.05
	print("Difficulty Increased! Multiplier is now: ", enemy_stat_multiplier)
