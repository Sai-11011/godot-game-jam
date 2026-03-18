extends CharacterBody2D

@onready var sprite := $Polygon2D # Or $Sprite2D depending on your node!
@onready var nav_agent = $NavigationAgent2D

var player: CharacterBody2D

var stats : Dictionary = Global.enemies_data.tank 
var health : int = stats.base_health
var speed : int = stats.speed
var damage : int = stats.damage
var vision : int = stats.vision

var knockback_velocity: Vector2 = Vector2.ZERO

# Tank specific combat variables
var is_attacking: bool = false
var is_recovering: bool = false
var slam_radius: float = 140.0 
var current_warning_radius: float = 0.0
var show_warning: bool = false

func _ready() -> void:
	add_to_group("Enemy")
	add_to_group("Tank")
	# 🚨 REMOVED Global.apply_levitation! It is now grounded.

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
			# Player is close! Start the Jump Smash!
			start_jump_attack()
		elif distance <= vision:
			# Chase the player
			nav_agent.target_position = player.global_position
			var next_path_pos = nav_agent.get_next_path_position()
			velocity = global_position.direction_to(next_path_pos) * speed
			
			# --- NEW: THE HEAVY DRAG EFFECT ---
			var drag_time = Time.get_ticks_msec() / 250.0
			# Rhythmically squish down and stretch forward to look like it's heaving its weight
			sprite.scale.x = 1.0 + (sin(drag_time) * 0.06)
			sprite.scale.y = 1.0 - (sin(drag_time) * 0.06)
			# Tiny rotation to make it look like it's struggling
			sprite.rotation = sin(drag_time * 0.5) * 0.03
		else:
			velocity = Vector2.ZERO
			# Smoothly return to normal shape when standing still
			sprite.scale = sprite.scale.lerp(Vector2(1.0, 1.0), 5.0 * delta)
			sprite.rotation = lerp(sprite.rotation, 0.0, 5.0 * delta)

	move_and_slide()

# --- THE JUMP SMASH MECHANIC ---

func start_jump_attack():
	is_attacking = true
	sprite.rotation = 0 
	
	# 1. THE WIND-UP 
	var windup_tween = create_tween()
	windup_tween.tween_property(sprite, "scale", Vector2(1.15, 0.85), 0.3)
	windup_tween.tween_property(sprite, "modulate", Color(1.5, 0.5, 0.5), 0.3) 
	await windup_tween.finished
	
	# --- NEW: START THE GROWING TELEGRAPH ---
	show_warning = true
	current_warning_radius = 0.0
	
	var jump_up_time = 0.5
	var hang_time = 0.2
	var smash_down_time = 0.15
	var total_air_time = jump_up_time + hang_time + smash_down_time # 0.85 seconds
	
	# This smoothly animates current_warning_radius from 0 to slam_radius
	var circle_tween = create_tween()
	circle_tween.tween_method(update_warning_circle, 0.0, slam_radius, total_air_time)
	
	# 2. THE LEAP 
	var jump_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump_tween.tween_property(sprite, "position:y", -100.0, jump_up_time)
	jump_tween.parallel().tween_property(sprite, "scale", Vector2(1.3, 1.3), jump_up_time)
	await jump_tween.finished
	
	# Hang in the air
	await get_tree().create_timer(hang_time).timeout
	
	# 3. THE SMASH 
	var slam_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	slam_tween.tween_property(sprite, "position:y", 0.0, smash_down_time)
	slam_tween.parallel().tween_property(sprite, "scale", Vector2(1.0, 1.0), smash_down_time)
	await slam_tween.finished
	
	execute_slam()

func execute_slam():
	show_warning = false
	queue_redraw() 
	
	sprite.modulate = Color(3.0, 3.0, 3.0) # Flash bright white
	
	if is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		
		# 1. PROXIMITY CAMERA SHAKE
		var max_shake_distance = 800.0 # You feel the earthquake up to 800px away
		if distance < max_shake_distance:
			# Math: Maps distance to a multiplier between 1.0 (close) and 0.0 (far)
			var shake_multiplier = 1.0 - (distance / max_shake_distance)
			var dynamic_shake_strength = 35.0 * shake_multiplier 
			
			get_tree().call_group("Camera", "apply_shake", dynamic_shake_strength)
		
		# 2. DAMAGE & KNOCKBACK
		if distance <= slam_radius:
			if player.has_method("take_damage"):
				player.take_damage(damage)
				
			# Call our brand new universal knockback! 
			# 800.0 is the push power. Adjust as needed!
			Global.apply_knockback(global_position, player, 800.0)
	
	# 4. RECOVERY
	is_recovering = true
	await get_tree().create_timer(1.2).timeout 
	sprite.modulate = Color(1.0, 1.0, 1.0)
	is_recovering = false
	is_attacking = false

func _draw():
	if show_warning:
		draw_arc(Vector2.ZERO, slam_radius, 0, TAU, 32, Color(1.0, 0.0, 0.0, 0.8), 2.0)
		
		draw_circle(Vector2.ZERO, current_warning_radius, Color(1.0, 0.0, 0.0, 0.4))

# --- COMBAT ---

func receive_knockback(force_vector: Vector2):
	knockback_velocity = force_vector * 0.3 # Barely moves!

func take_damage(damage_amount: int):
	health -= damage_amount
	if health <= 0:
		queue_free()

func update_warning_circle(new_radius: float):
	current_warning_radius = new_radius
	queue_redraw()
