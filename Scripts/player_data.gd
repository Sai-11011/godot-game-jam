extends Node

signal max_health_update

# SHARD INVENTORY 
var shards_collected := {
	"red": 0,
	"blue": 0,
	"green": 0,
}
var has_top_orb := false
 
# KNOCKBACK FORCE
var knockback_forces := {
	"slash": 300.0,   
	"thrust": 800.0,  
	"bullet": 900.0   
}

# ATTACK INVENTORY
var attacks := {
	"red":0,
	"blue":10,
	"green":100
}

var attack_stats := {
	"base":{
		"range":130,
		"cooldown":0.3,
		"attack_time":0.18,#duration of attack 
	},
	"high":{
		"range":0,#this buffs all attacks for 5 seconds
		"cooldown":3,
		"attack_time":5,
	},
	"thrust":{
		"range":199,
		"cooldown":1,
		"attack_time":0.1#player moves to the range in this time
	},
	"bullet":{
		"range":500,#longest range
		"cooldown":0.6,
		"attack_time":10 #unti queue free
	}
}

# PLAYER BASE STATS 
var max_health: int = 100
var current_health: int = 100
var base_damage: float = 20.0 
var current_damage: float = 20.0
var base_speed: float = 150.0
var current_speed: float = 150.0
var heavy_is_active :bool = false

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
	current_health += int(max_health * 0.15)
	current_health = min(current_health,max_health)
	max_health_update.emit()
	
	# Top Orb -> +50% to all stats
	if has_top_orb :
		is_prime_heart_active = true
		current_damage *= 1.50
		current_speed *= 1.50
		max_health = int(max_health * 1.50)

# ENEMY SCALING FUNCTION 
func increase_enemy_difficulty():
	enemy_stat_multiplier += 0.05
	print("Difficulty Increased! Multiplier is now: ", enemy_stat_multiplier)

func apply_knockback(enemy: Node2D, source_pos: Vector2, attack_type: String):
	if enemy.has_method("receive_knockback"):
		var force = knockback_forces.get(attack_type, 0.0)
		var push_dir = source_pos.direction_to(enemy.global_position)
		if push_dir == Vector2.ZERO:
			push_dir = Vector2.RIGHT.rotated(randf() * TAU)
		var knockback_vector = push_dir * force
		
		enemy.receive_knockback(knockback_vector)
