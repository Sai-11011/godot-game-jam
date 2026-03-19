extends CharacterBody2D

@onready var sprite := $Sprite2D
@onready var anim_player := $AnimationPlayer
@onready var nav_agent = $NavigationAgent2D

var player: CharacterBody2D
@onready var shard_scene: PackedScene = load(Global.SCENES.shards)
var stats : Dictionary = Global.enemies_data.tank 
var health : int = stats.base_health
var speed : int = stats.speed
var damage : int = stats.damage
var vision : int = stats.vision

var knockback_velocity: Vector2 = Vector2.ZERO

# Tank specific combat variables
var is_attacking: bool = false
var is_recovering: bool = false
var slam_radius: float = 100.0 
var current_warning_radius: float = 0.0
var show_warning: bool = false

# Direction tracking for your friend's new sprites
var facing_dir: String = "down" 

func _ready() -> void:
	add_to_group("Enemy")
	add_to_group("Tank")

func _physics_process(delta: float) -> void:
	if knockback_velocity != Vector2.ZERO:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 3000 * delta)
		move_and_slide()
		return
		
	if is_attacking or is_recovering:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	player = get_tree().get_first_node_in_group("Player")
	if player:
		var distance = global_position.distance_to(player.global_position)
		
		if distance <= 120.0:
			start_slam_attack()
		elif distance <= vision:
			nav_agent.target_position = player.global_position
			var next_path_pos = nav_agent.get_next_path_position()
			velocity = global_position.direction_to(next_path_pos) * speed
			
			update_facing_direction(velocity)
			
			# The heavy drag effect (disabled during jam if using walk animations instead)
			var drag_time = Time.get_ticks_msec() / 250.0
			sprite.scale.x = 1.0 + (sin(drag_time) * 0.06)
			sprite.scale.y = 1.0 - (sin(drag_time) * 0.06)
			sprite.rotation = sin(drag_time * 0.5) * 0.03
		else:
			velocity = Vector2.ZERO
			sprite.scale = sprite.scale.lerp(Vector2(1.0, 1.0), 5.0 * delta)
			sprite.rotation = lerp(sprite.rotation, 0.0, 5.0 * delta)

	move_and_slide()

func update_facing_direction(vel: Vector2):
	if abs(vel.x) > abs(vel.y):
		facing_dir = "right" if vel.x > 0 else "left"
	else:
		facing_dir = "down" if vel.y > 0 else "up"

# --- THE HAND SLAM MECHANIC ---

func start_slam_attack():
	is_attacking = true
	sprite.rotation = 0 
	sprite.scale = Vector2(1, 1)
	
	var wind_up_time = 1.5 # Your new 1.5 second delay!
	
	# 1. PLAY ANIMATION AND SYNC THE SPEED
	var anim_name = "slam_" + facing_dir
	if not anim_player.has_animation(anim_name):
		anim_name = "slam_down" 
		
	if anim_player.has_animation(anim_name):
		# Calculate exactly how much to slow down the animation so it takes 1.5 seconds
		var original_length = anim_player.get_animation(anim_name).length
		anim_player.speed_scale = original_length / wind_up_time
		anim_player.play(anim_name)
	
	# 2. START TELEGRAPH CIRCLE
	show_warning = true
	current_warning_radius = 0.0
	
	var circle_tween = create_tween()
	circle_tween.tween_method(update_warning_circle, 0.0, slam_radius, wind_up_time)
	
	# 3. TRIGGER THE SLAM WITH CODE
	await get_tree().create_timer(wind_up_time).timeout
	
	if is_attacking:
		execute_slam()

func execute_slam():
	# Reset the animation speed back to normal for walking!
	anim_player.speed_scale = 1.0 
	
	show_warning = false
	queue_redraw() 
	
	# Flash bright white on impact
	var flash_tween = create_tween()
	sprite.modulate = Color(3.0, 3.0, 3.0) 
	flash_tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0), 0.3)
	
	if is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		
		# Proximity Camera Shake
		var max_shake_distance = 800.0 
		if distance < max_shake_distance:
			var shake_multiplier = 1.0 - (distance / max_shake_distance)
			var dynamic_shake_strength = 35.0 * shake_multiplier 
			get_tree().call_group("Camera", "apply_shake", dynamic_shake_strength)
		
		# Damage & Knockback
		if distance <= slam_radius:
			if player.has_method("take_damage"):
				player.take_damage(damage)
			Global.apply_knockback(global_position, player, 800.0)
	
	# Recovery phase after the slam
	is_recovering = true
	await get_tree().create_timer(1.2).timeout 
	is_recovering = false
	is_attacking = false

func _draw():
	if show_warning:
		draw_arc(Vector2.ZERO, slam_radius, 0, TAU, 32, Color(1.0, 0.0, 0.0, 0.8), 2.0)
		draw_circle(Vector2.ZERO, current_warning_radius, Color(1.0, 0.0, 0.0, 0.4))

func update_warning_circle(new_radius: float):
	current_warning_radius = new_radius
	queue_redraw()

# --- COMBAT ---

func receive_knockback(force_vector: Vector2):
	knockback_velocity = force_vector * 0.3 

func take_damage(damage_amount: int):
	health -= damage_amount
	AudioManager.play_sfx("enemy_hit")
	var flash_tween = create_tween()
	sprite.modulate = Color(3.0, 3.0, 3.0)
	flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	if health <= 0:
		die()

func die():
	var random_roll = randf()
	
	# 1. Check for the 5% Rare Orb Drop (ONLY if we don't have it yet!)
	if not PlayerData.has_top_orb and random_roll <= 0.05:
		var orb = shard_scene.instantiate()
		orb.shard_type = "main_orb" # We will code this into the shard script next!
		orb.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", orb)
		
	# 2. Otherwise, drop a normal shard (This will be 100% of the time if they already have the orb)
	else:
		var shard = shard_scene.instantiate()
		var available_colors = ["red", "blue", "green"]
		shard.shard_type = available_colors[randi() % available_colors.size()]
		shard.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", shard)
		
	queue_free()
