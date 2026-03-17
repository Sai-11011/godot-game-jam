extends CharacterBody2D

#NODE
@onready var red_pointer = $Compass/Red
@onready var blue_pointer = $Compass/Blue
@onready var green_pointer = $Compass/Green
@onready var sprite = $PlayerAnimation
@onready var thrust_hitbox = $ThrustHitbox
@onready var heavy_particles =  $HeavyBuffParticles
@onready var camera = $Camera2D

#STATS
var attack_stats := PlayerData.attack_stats
var acceleration = 800
var friction = 900
var can_attack: bool = true 
var can_heavy_attack: bool = true
var facing_dir: String = "right" 
var current_zoom := 1.0
var spawn_radius:= 800
var is_attacking: bool = false

#SCENES
var slash_scene: PackedScene = load(Global.SCENES.slash)
var bullet_scene: PackedScene = load(Global.SCENES.bullet)

func _physics_process(delta: float) -> void:
	# MOVEMENT LOGIC
	var direction = Input.get_vector("left", "right", "up", "down")
	if direction != Vector2.ZERO:
		var speed = PlayerData.current_speed
		# 4-Way Directional ANIMATION Logic
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				facing_dir = "right"
			else:
				facing_dir = "left"
		else:
			if direction.y > 0:
				facing_dir = "down"
			else:
				facing_dir = "up"
		if not is_attacking:
			sprite.play("walk_" + facing_dir)
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
	else:
		if not is_attacking:
			sprite.play("idle_" + facing_dir)
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()
	
	update_compass(red_pointer, "red")
	update_compass(blue_pointer, "blue")
	update_compass(green_pointer, "green")
	
	#input keys
	if Input.is_action_just_pressed("attack"):
		perform_base_attack()
	if Input.is_action_just_pressed("thrust"):
		perform_thrust_attack()
	if Input.is_action_just_pressed("bullet"): 
		perform_bullet_attack()
	if Input.is_action_just_pressed("heavy"):
		perform_heavy_attack()
	if Input.is_action_just_pressed("zoom"):
		apply_zoom()

# UI ARROWS
func update_compass(pointer: Polygon2D, target_color: String):
	var shards = get_tree().get_nodes_in_group("Shards")
	var nearest_shard = null
	var shortest_distance = INF
	
	for shard in shards:
		if shard.shard_type == target_color:
			var distance = global_position.distance_to(shard.global_position)
			if distance < shortest_distance:
				shortest_distance = distance
				nearest_shard = shard
	
	if nearest_shard:
		pointer.visible = true
		pointer.look_at(nearest_shard.global_position)
	else:
		pointer.visible = false

# ATTACKS
func perform_base_attack():
	if not can_attack or slash_scene == null:
		return 
	can_attack = false 
	
	var slash = slash_scene.instantiate()
	get_tree().current_scene.add_child(slash)
	
	var current_range = attack_stats["base"]["range"]
	var target = get_closest_enemy(current_range)
	
	if target:
		slash.global_position = global_position
		slash.look_at(target.global_position)
	else:
		slash.global_position = global_position
		var default_dir = Vector2.ZERO
		if facing_dir == "right": default_dir = Vector2.RIGHT
		elif facing_dir == "left": default_dir = Vector2.LEFT
		elif facing_dir == "up": default_dir = Vector2.UP
		elif facing_dir == "down": default_dir = Vector2.DOWN
		slash.rotation = default_dir.angle()

	slash.global_position += Vector2.RIGHT.rotated(slash.rotation) * 10.0
	
	var cooldown_time = attack_stats["base"]["cooldown"]
	await get_tree().create_timer(cooldown_time).timeout
	can_attack = true

func perform_thrust_attack():
	if not can_attack or PlayerData.attacks["blue"] <= 0:
		return 
		
	can_attack = false 
	PlayerData.attacks["blue"] -= 1
	
	var thrust_stats = PlayerData.attack_stats.thrust
	var thrust_range = thrust_stats["range"]
	var attack_duration = thrust_stats["attack_time"]
	var cooldown_time = thrust_stats["cooldown"]
	
	# Get the direction with the most enemies!
	var dash_dir = get_best_thrust_direction(thrust_range)
	
	if dash_dir == Vector2.ZERO:
		if facing_dir == "right": dash_dir = Vector2.RIGHT
		elif facing_dir == "left": dash_dir = Vector2.LEFT
		elif facing_dir == "up": dash_dir = Vector2.UP
		elif facing_dir == "down": dash_dir = Vector2.DOWN
	var target_pos = global_position + (dash_dir * thrust_range)
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, attack_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var hit_radius = 40.0 
	var enemies = get_tree().get_nodes_in_group("Enemy")
	
	for enemy in enemies:
		# This Godot math function draws a perfect, unbroken line from start to finish
		var closest_point = Geometry2D.get_closest_point_to_segment(enemy.global_position, global_position, target_pos)
		
		if closest_point.distance_to(enemy.global_position) <= hit_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(PlayerData.current_damage)
				PlayerData.apply_knockback(enemy, global_position, "thrust")
	
	# GHOST TRAIL LOGIC
	while tween.is_running():
		spawn_ghost_trail()
		await get_tree().create_timer(0.03).timeout
	
	# RESTORE ATTACK ABILITY AFTER COOLDOWN
	await get_tree().create_timer(cooldown_time).timeout
	can_attack = true

func perform_bullet_attack():
	if not can_attack or bullet_scene == null or PlayerData.attacks["green"] <= 0:
		return 
		
	can_attack = false 
	PlayerData.attacks["green"] -= 1
	is_attacking = true
	
	var bullet_stats = PlayerData.attack_stats.bullet
	var bullet_range = bullet_stats["range"]
	var cooldown_time = bullet_stats["cooldown"]
	var target_pos = get_best_bullet_target_pos(bullet_range)
	
	# 1. Shift the offset to fix the art, then play!
	sprite.offset = Vector2(0, -16) 
	sprite.play("bullet")
	sprite.frame = 0
	
	# 2. Wait for the exact attack frame
	var target_frame = 5
	while sprite.frame < target_frame and sprite.is_playing():
		await sprite.frame_changed
	
	var bullet = bullet_scene.instantiate()
	var spawn_offset = Vector2.UP * 30.0
	spawn_offset.x -= 1 
	bullet.global_position = global_position + spawn_offset
	bullet.target_pos = target_pos 
	get_tree().current_scene.add_child(bullet)
	
	var total_frames = sprite.sprite_frames.get_frame_count("bullet")
	if sprite.is_playing() and sprite.animation == "bullet" and sprite.frame < (total_frames - 1):
		await sprite.animation_finished
	sprite.offset = Vector2.ZERO
	is_attacking = false
	sprite.play("idle_" + facing_dir)
	
	await get_tree().create_timer(cooldown_time).timeout
	can_attack = true

func perform_heavy_attack():
	if not can_heavy_attack or PlayerData.attacks["red"] <= 0:
		return 
		
	can_heavy_attack = false 
	PlayerData.attacks["red"] -= 1 
	
	var buff_duration = PlayerData.attack_stats["high"]["attack_time"]
	var cooldown_time = PlayerData.attack_stats["high"]["cooldown"]
	
	# 1. TURN ON THE POWER UP
	heavy_particles.emitting = true
	PlayerData.current_damage *= 5.0 # DOUBLE DAMAGE!
	sprite.modulate = Color(1.5, 0.5, 0.5) 
	PlayerData.heavy_is_active = true
	
	# 2. WAIT FOR BUFF TO END (You can still use other attacks during this time!)
	await get_tree().create_timer(buff_duration).timeout
	
	# 3. TURN OFF THE POWER UP
	heavy_particles.emitting = false
	sprite.modulate = Color.WHITE
	
	# Safely reset damage based on your current shards
	PlayerData.apply_stats() 
	PlayerData.heavy_is_active = false
	# 4. START COOLDOWN
	await get_tree().create_timer(cooldown_time).timeout
	can_heavy_attack = true

# AUTO TARGETS FORM HERE 
func get_best_thrust_direction(attack_range: float) -> Vector2:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	var enemies_in_range = []
	# 1. Gather all enemies close enough to hit
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) <= attack_range:
			enemies_in_range.append(enemy)
	if enemies_in_range.is_empty():
		return Vector2.ZERO
	# 2. The 8 possible dash directions
	var directions_to_check = [
		Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT,
		Vector2(1, 1).normalized(), Vector2(1, -1).normalized(),
		Vector2(-1, 1).normalized(), Vector2(-1, -1).normalized()
	]
	var best_dir = Vector2.ZERO
	var max_hit_count = -1
	# 3. Score each direction to see which catches the most enemies
	for dir in directions_to_check:
		var current_hit_count = 0
		
		for enemy in enemies_in_range:
			var dir_to_enemy = global_position.direction_to(enemy.global_position)
			
			# The dot product checks if the enemy is roughly in front of this direction
			# > 0.8 means they are inside a narrow line/cone in that direction
			if dir.dot(dir_to_enemy) > 0.8:
				current_hit_count += 1
				
		if current_hit_count > max_hit_count:
			max_hit_count = current_hit_count
			best_dir = dir
			
	return best_dir

func get_closest_enemy(attack_range: float) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	var closest_enemy = null
	var shortest_distance = attack_range 
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= shortest_distance:
			shortest_distance = distance
			closest_enemy = enemy
			
	return closest_enemy

func get_best_bullet_target_pos(attack_range: float) -> Vector2:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	var enemies_in_range = []
	
	# Calculate the exact world boundaries of the player's screen
	var screen_rect = get_viewport_rect()
	var transform_inv = get_canvas_transform().affine_inverse()
	var top_left = transform_inv * screen_rect.position
	var bottom_right = transform_inv * (screen_rect.position + screen_rect.size)
	var camera_rect = Rect2(top_left, bottom_right - top_left)
	
	# 1. Gather all enemies close enough to shoot AND currently visible on screen
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) <= attack_range:
			# Only add them if they are inside the camera rectangle!
			if camera_rect.has_point(enemy.global_position):
				enemies_in_range.append(enemy)
			
	# 2. If nobody is around, just shoot straight ahead to our max range!
	if enemies_in_range.is_empty():
		var default_dir = Vector2.ZERO
		if facing_dir == "right": default_dir = Vector2.RIGHT
		elif facing_dir == "left": default_dir = Vector2.LEFT
		elif facing_dir == "up": default_dir = Vector2.UP
		elif facing_dir == "down": default_dir = Vector2.DOWN
		return global_position + (default_dir * attack_range)
		
	# 3. Score each enemy based on how many friends are near them
	var best_target_pos = enemies_in_range[0].global_position
	var max_cluster_size = -1
	var explosion_radius = 100.0 
	
	for potential_target in enemies_in_range:
		var cluster_size = 0
		
		for other_enemy in enemies_in_range:
			if potential_target.global_position.distance_to(other_enemy.global_position) <= explosion_radius:
				cluster_size += 1
				
		if cluster_size > max_cluster_size:
			max_cluster_size = cluster_size
			best_target_pos = potential_target.global_position
			
	return best_target_pos
# effects
func spawn_ghost_trail():
	var ghost = Sprite2D.new()
	# Grab the exact frame of animation the player is currently in
	ghost.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	ghost.global_position = global_position
	
	get_tree().current_scene.add_child(ghost)
	
	ghost.modulate = Color(0.695, 0.719, 1.0, 0.78) 
	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.4)
	tween.tween_callback(ghost.queue_free)

func _on_thrust_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		if body.has_method("take_damage"):
			body.take_damage(PlayerData.current_damage)

func apply_zoom():
	if current_zoom == 1.0:
		spawn_radius = 500
		current_zoom = 1.5
	elif current_zoom == 1.5:
		spawn_radius = 400
		current_zoom = 2
	elif current_zoom == 2:
		spawn_radius = 300
		current_zoom = 3
	else :
		spawn_radius = 800
		current_zoom = 1
	camera.zoom = Vector2(current_zoom,current_zoom)
