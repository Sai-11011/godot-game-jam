extends CharacterBody2D

var knockback_velocity: Vector2 = Vector2.ZERO
@onready var nav_agent = $NavigationAgent2D
@onready var anim = $AnimatedSprite2D
var stats = Global.enemies_data.slime
var health = stats.base_health
var slime_color: String 
var current_shard: Node2D = null 
var speed: float
var is_eating: bool = false
var facing_dir: String = "down" 


# --- AI VARIABLES ---
var vision_range: float = Global.enemies_data.slime.vision
var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0

func _ready():
	# Color the sprites
	add_to_group("slime")
	if slime_color == "red":
		anim.modulate = Color.LIGHT_SALMON
	elif slime_color == "blue":
		anim.modulate = Color.LIGHT_BLUE
	elif slime_color == "green":
		anim.modulate = Color.LIGHT_GREEN
		
	speed = stats["speed"]
	
	# Fetch vision range dynamically from Global data
	if stats.has("vision"):
		vision_range = stats["vision"]
		
	# Start with a random direction so they don't stand frozen at spawn
	pick_new_wander_direction()

func _physics_process(delta):
	# PRIORITY 1: Knockback overrides everything
	if knockback_velocity != Vector2.ZERO:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 3000 * delta)
		
	# PRIORITY 2: Eating stops movement completely
	elif is_eating:
		velocity = Vector2.ZERO
		
	# PRIORITY 3 & 4: Chasing vs Wandering
	else:
		var target_shard = get_nearest_matching_shard()
		
		if target_shard:
			# navigation
			nav_agent.target_position = target_shard.global_position
			var next_path_pos = nav_agent.get_next_path_position()
			var direction = global_position.direction_to(next_path_pos)
			velocity = direction * speed
		else:
			# NO TARGET IN RANGE: Wander randomly
			wander_timer -= delta
			if wander_timer <= 0:
				pick_new_wander_direction()
			# Walk slightly slower when just wandering around
			velocity = wander_direction * (speed * 0.5) 

		# 4-direction movement animation
		if velocity != Vector2.ZERO:
			if abs(velocity.x) > abs(velocity.y):
				if velocity.x > 0: facing_dir = "right"
				else: facing_dir = "left"
			else:
				if velocity.y > 0: facing_dir = "down"
				else: facing_dir = "up"
			anim.play("move_" + facing_dir)
			AudioManager.play_slime_movement(global_position)
		else:
			anim.pause()
			
	# Move and slide natively handles sliding against solid walls
	move_and_slide()

func pick_new_wander_direction():
	# Pick a random angle and move that way for 1 to 3 seconds
	wander_direction = Vector2.RIGHT.rotated(randf() * TAU)
	wander_timer = randf_range(1.0, 3.0)

func get_nearest_matching_shard() -> Node2D:
	var shards = get_tree().get_nodes_in_group("Shards")
	var nearest = null
	var shortest_distance = INF
	
	for shard in shards:
		# ONLY care about shards that match the slime's color!
		if shard.shard_type == slime_color:
			var distance = global_position.distance_to(shard.global_position)
			# THE FIX: Must be the closest AND within their vision range!
			if distance < shortest_distance and distance <= vision_range:
				shortest_distance = distance
				nearest = shard
				
	return nearest

func eat(target_shard: Node2D):
	is_eating = true
	current_shard = target_shard
	anim.pause() 
	# Wait for 1 full second
	await get_tree().create_timer(1.0).timeout
	if not is_instance_valid(self) or not is_inside_tree():
		return
	anim.play("eat_" + facing_dir)
	await anim.animation_finished
	
	if is_instance_valid(target_shard):
		current_shard.queue_free()
		AudioManager.play_slime_eating(global_position)

	is_eating = false
	current_shard = null

func take_damage(damage_amount: float):
	health -= damage_amount
	#AudioManager.play_sfx("enemy_hit")
	var flash_tween = create_tween()
	anim.modulate = Color(3.0, 3.0, 3.0)
	var orig_color = Color.WHITE
	if slime_color == "red": orig_color = Color.LIGHT_SALMON
	elif slime_color == "blue": orig_color = Color.LIGHT_BLUE
	elif slime_color == "green": orig_color = Color.LIGHT_GREEN
	flash_tween.tween_property(anim, "modulate", orig_color, 0.15)
	if health <= 0:
		die()

func die():
	if is_instance_valid(current_shard):
		current_shard.is_claimed = false
	queue_free()

func receive_knockback(force_vector: Vector2):
	knockback_velocity = force_vector
