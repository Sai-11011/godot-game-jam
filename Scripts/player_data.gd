extends Node

signal max_health_update
var is_game_started := false

var is_testing := true
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
	"blue":0,
	"green":0
}

var attack_stats := {
	"base":{
		"range":230,
		"cooldown":0.3,
		"attack_time":0.25,#duration of attack 
	},
	"high":{
		"range":0,#this buffs all attacks for 5 seconds
		"cooldown":3,
		"attack_time":5,
	},
	"thrust":{
		"range":200,
		"cooldown":1,
		"attack_time":0.1#player moves to the range in this time
	},
	"bullet":{
		"range":500,#longest range
		"cooldown":0.6,
		"attack_time":10 #unti queue free
	}
}
# Add this near the top with your other variables
var is_boss_active: bool = false

# PLAYER BASE STATS 
var max_health: int = 100
var current_health: int = 100
var base_damage: float = 20.0 # 20
var current_damage: float = 20.0 #20
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
	if not is_game_started: 
		return
	game_time_seconds += delta

# CORE UPGRADE FUNCTION
# CORE UPGRADE FUNCTION
func collect_shard(color: String):
	# 1. NEW: Check if it's the Primal Heart first!
	# (Make sure "main_orb" matches whatever string your shard script sends!)
	if color == "main_orb" or color == "top_orb": 
		has_top_orb = true
		apply_stats(color) # Force stats to recalculate and heal immediately!
		return
		
	# 2. Normal Shard Logic
	if shards_collected.has(color):
		#AudioManager.play_sfx("shard_pickup")
		shards_collected[color] += 1
		if color == "green":
			attacks[color] += 3   # 3 Bullets per Green Shard
		else:
			attacks[color] += 1   # 1 Attack use increase for other Shards
		
		apply_stats(color)

func apply_stats(color_collected=""):
	# 1. Base Max Health from Green Shards
	max_health = 100 + (shards_collected["green"] * 15)
	
	# 2. Dynamic Caps & Primal Heart Multipliers
	var current_speed_cap = MAX_SPEED_BONUS # Normally 1.0 (+100%)
	
	if has_top_orb:
		is_prime_heart_active = true
		current_speed_cap = 1.5 # Increases the blue shard limit to +150%
		max_health = int(max_health * 1.50)
		
	# 3. Apply Damage and Speed with the new dynamic cap
	var red_bonus = shards_collected["red"] * 0.05
	current_damage = base_damage * (1.0 + red_bonus)
	
	var blue_bonus = min(shards_collected["blue"] * 0.1, current_speed_cap)
	current_speed = base_speed * (1.0 + blue_bonus)
	
	# 4. Primal Heart extra base multipliers
	if has_top_orb:
		current_damage *= 1.50
		current_speed *= 1.50
		
	# 5. HEALING LOGIC
	if color_collected == "main_orb" or color_collected == "top_orb":
		current_health = max_health # FULL HEAL when collecting Primal Heart!
	elif color_collected == "green":
		current_health += int(max_health * 0.15) # Normal 15% heal
		
	current_health = min(current_health, max_health)
	max_health_update.emit()
	
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

func reset_data():
	# Reset Health & Stats
	max_health = 100
	current_health = 100
	base_damage = 20.0 
	current_damage = 20.0
	base_speed = 150.0
	current_speed = 150.0
	
	# Reset Inventory
	shards_collected = {"red": 0, "blue": 0, "green": 0}
	attacks = {"red": 0, "blue": 0, "green": 0}
	has_top_orb = false
	
	# Reset Game Scaling
	enemy_stat_multiplier = 1.0 
	game_time_seconds = 0.0
	
	is_boss_active = false
	
	# --- ADD THIS TO PREVENT TIMER BUGS ON RESTART! ---
	is_game_started = false
