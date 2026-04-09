extends CharacterBody2D

signal health_bar_update

#NODE
@onready var red_pointer = $Compass/Red
@onready var blue_pointer = $Compass/Blue
@onready var green_pointer = $Compass/Green
@onready var sprite = $PlayerAnimation
@onready var thrust_hitbox = $ThrustHitbox
@onready var heavy_particles =  $HeavyBuffParticles
@onready var camera = $PlayerPCam
@onready var core_light = $PlayerAnimation/PointLight2D
@onready var dash_particles = $DashParticles

#STATS
var attack_stats: Dictionary = PlayerData.attack_stats
var acceleration = 3000 # Increased from 800
var friction = 3500     # Increased from 1000
var can_attack: bool = true 
var can_heavy_attack: bool = true
var facing_dir: String = "right" 
var current_zoom := 2.0
var spawn_radius:= 800
var is_attacking: bool = false
var is_hit: bool = false
var is_dead: bool = false
var is_invincible: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO

#SCENES
var slash_scene: PackedScene = load(Global.SCENES.slash)
var bullet_scene: PackedScene = load(Global.SCENES.bullet)
var game_over_scene : PackedScene = load(Global.SCENES.game_over)

func _ready():
	start_heart_pulse()

func _physics_process(delta: float) -> void:
	# MOVEMENT LOGIC
	if knockback_velocity != Vector2.ZERO:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 3000 * delta)
		move_and_slide()
		return 
	
	var direction = Input.get_vector("left", "right", "up", "down")
	if direction != Vector2.ZERO:
		var speed = PlayerData.current_speed
		# 4-Way Directional ANIMATION Logic
		if abs(direction.x) >= abs(direction.y):
			if direction.x > 0:
				facing_dir = "right"
			else:
				facing_dir = "left"
		else:
			if direction.y > 0:
				facing_dir = "down"
			else:
				facing_dir = "up"
		if not is_attacking :
			sprite.play("walk_" + facing_dir)
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
		
		AudioManager.play_player_steps(global_position)
		
	else:
		if not is_attacking and not is_hit:
			sprite.play("idle_" + facing_dir)
			
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
	move_and_slide()
	
	if Input.is_action_pressed("attack"):
		perform_base_attack()
	
	update_compass(red_pointer, "red")
	update_compass(blue_pointer, "blue")
	update_compass(green_pointer, "green")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("thrust"):
		perform_thrust_attack()
	elif event.is_action_pressed("bullet"): 
		perform_bullet_attack()
	elif event.is_action_pressed("heavy"):
		perform_heavy_attack()
	elif event.is_action_pressed("zoom"):
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
	
	if is_instance_valid(target) and "global_position" in target:
		slash.global_position = global_position
		if slash.global_position != target.global_position:
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
	
	# --- CLEAN RECOIL JUICE (No light code) ---
	var recoil_dir = Vector2.LEFT.rotated(slash.rotation)
	var original_sprite_pos = sprite.position
	
	var recoil_tween = create_tween()
	recoil_tween.tween_property(sprite, "position", original_sprite_pos + (recoil_dir * 12.0), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	recoil_tween.tween_property(sprite, "position", original_sprite_pos, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# ------------------------------------------
	
	var cooldown_time = attack_stats["base"]["cooldown"]
	await get_tree().create_timer(cooldown_time).timeout
	can_attack = true

func perform_thrust_attack():
	if not can_attack or PlayerData.attacks["blue"] <= 0:
		return 
		
	can_attack = false 
	PlayerData.attacks["blue"] -= 1
	is_invincible = true # BECOME INVINCIBLE
	
	var thrust_stats = PlayerData.attack_stats.thrust
	var thrust_range = thrust_stats["range"]
	var attack_duration = thrust_stats["attack_time"]
	var cooldown_time = thrust_stats["cooldown"]
	
	var dash_dir = Vector2.ZERO
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	if input_dir != Vector2.ZERO:
		# 1. ESCAPE MODE: Dash the way you are holding
		dash_dir = input_dir.normalized()
	else:
		# 2. COMBAT MODE: Auto-lock onto enemies
		dash_dir = get_best_thrust_direction(thrust_range)
		
		# 3. FALLBACK: Dash the way we are facing
		if dash_dir == Vector2.ZERO:
			if facing_dir == "right": dash_dir = Vector2.RIGHT
			elif facing_dir == "left": dash_dir = Vector2.LEFT
			elif facing_dir == "up": dash_dir = Vector2.UP
			elif facing_dir == "down": dash_dir = Vector2.DOWN
			
	var start_pos = global_position # Save where we started the dash!
	var target_pos = global_position + (dash_dir * thrust_range)
	
	flash_light_color(Color(0.5, 0.5, 2.0), attack_duration)
	
	flash_light_color(Color(0.5, 0.5, 2.0), attack_duration)
	
	# --- NEW: SQUASH AND STRETCH JUICE ---
	var original_scale = sprite.scale
	# Stretch the sprite forward, squash it flat!
	sprite.scale = Vector2(1.8, 0.5) 
	# Point the sprite in the direction of the dash
	sprite.rotation = dash_dir.angle() 
	# -------------------------------------
	# --- NEW: DASH DUST JUICE ---
	# Point the dust in the exact OPPOSITE direction of the dash
	dash_particles.rotation = dash_dir.angle() + PI 
	dash_particles.restart() # 'restart()' forces One-Shot particles to explode immediately
	# ----------------------------
	# Phase through space using the Tween
	var tween = create_tween()
	
	tween.tween_property(self, "global_position", target_pos, attack_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# --- DAMAGE ENEMIES ALONG THE DASH PATH (SYNCED TIMING) ---
	var hit_radius = 40.0 
	var enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var closest_point = Geometry2D.get_closest_point_to_segment(enemy.global_position, start_pos, target_pos)
			
			if closest_point.distance_to(enemy.global_position) <= hit_radius:
				# Calculate the exact millisecond the player will reach this enemy!
				var distance_to_enemy = start_pos.distance_to(closest_point)
				var time_to_impact = (distance_to_enemy / thrust_range) * attack_duration
				
				# Fire a delayed signal so the hit happens when you actually touch them
				get_tree().create_timer(time_to_impact).timeout.connect(func():
					if is_instance_valid(enemy):
						if enemy.has_method("take_damage"):
							enemy.take_damage(PlayerData.current_damage)
							
							# Push them outward from wherever the player is at this exact moment
							PlayerData.apply_knockback(enemy, global_position, "thrust")
							
							enemy.modulate = Color(5.0, 5.0, 5.0) 
							var flash = create_tween()
							flash.tween_property(enemy, "modulate", Color.WHITE, 0.2)
				)
				
	# Ghost trail loop (This also waits for the dash to physically finish)
	while tween and tween.is_running():
		if not is_inside_tree(): break 
		spawn_ghost_trail()
		await get_tree().create_timer(0.03).timeout
		
	# --- COLLISION PROPEL LOGIC (WALLS) ---
	if is_inside_tree():
		var is_stuck = test_move(global_transform, Vector2.ZERO)
		if is_stuck:
			var step = 10.0 
			var max_forward_checks = 15 
			var found_safe_spot = false
			
			for i in range(1, max_forward_checks + 1):
				var test_transform = global_transform
				test_transform.origin += dash_dir * (step * i)
				if not test_move(test_transform, Vector2.ZERO):
					global_position = test_transform.origin
					trigger_wall_pop_effect()
					found_safe_spot = true
					break
					
			if not found_safe_spot:
				for i in range(1, 50): 
					var test_transform = global_transform
					test_transform.origin -= dash_dir * (step * i)
					if not test_move(test_transform, Vector2.ZERO):
						global_position = test_transform.origin
						trigger_wall_pop_effect()
						break

	# --- ANTI-STUCK SYSTEM (ENEMIES) ---
	# We ONLY check this once at the very end of the dash!
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) < 70.0:
			# Calculate direction FROM player TO enemy
			var push_dir = global_position.direction_to(enemy.global_position) 
			if push_dir == Vector2.ZERO: 
				push_dir = dash_dir
				
			# SHUT DOWN PLAYER BOUNCE! Push the ENEMY away instead!
			if enemy.has_method("receive_knockback"):
				enemy.receive_knockback(push_dir * 1000.0) # Massive shove!
				
	is_invincible = false # REMOVE INVINCIBILITY
	
	# --- NEW: RESTORE SPRITE ---
	sprite.scale = original_scale
	sprite.rotation = 0.0
	# ---------------------------
	
	await get_tree().create_timer(cooldown_time).timeout
	can_attack = true

func perform_bullet_attack():
	if not can_attack or bullet_scene == null or PlayerData.attacks["green"] <= 0:
		return 
		
	can_attack = false 
	PlayerData.attacks["green"] -= 1
	is_attacking = true
	#AudioManager.play_sfx("player_shoot")
	
	var bullet_stats = PlayerData.attack_stats.bullet
	var bullet_range = bullet_stats["range"]
	var cooldown_time = bullet_stats["cooldown"]
	var target_pos = get_best_bullet_target_pos(bullet_range)
	
	# 1. Shift the offset to fix the art, then play!
	AudioManager.play_player_green_charge()
	sprite.offset = Vector2(0, -16) 
	sprite.play("bullet")
	sprite.frame = 0
	
	# 2. Wait for the exact attack frame safely!
	var target_frame = 5
	while sprite.animation == "bullet" and sprite.frame < target_frame:
		if not is_inside_tree(): return # <-- SAFETY CHECK
		await get_tree().process_frame 
		
	if not is_inside_tree(): return # <-- SAFETY CHECK
		
	if sprite.animation != "bullet":
		is_attacking = false
		can_attack = true
		return 
	
	var bullet = bullet_scene.instantiate()
	var spawn_offset = Vector2.UP * 30.0
	spawn_offset.x -= 1 
	bullet.global_position = global_position + spawn_offset
	bullet.target_pos = target_pos 
	get_tree().current_scene.add_child(bullet)
	flash_light_color(Color(0.5, 2.0, 0.5), 0.4)
	
	var total_frames = sprite.sprite_frames.get_frame_count("bullet")
	if sprite.is_playing() and sprite.animation == "bullet" and sprite.frame < (total_frames - 1):
		await sprite.animation_finished
		
	if not is_inside_tree(): return # <-- SAFETY CHECK
	
	sprite.offset = Vector2.ZERO
	is_attacking = false
	facing_dir = "right"
	sprite.play("idle_" + facing_dir)
	
	await get_tree().create_timer(cooldown_time).timeout
	
	if not is_inside_tree(): return # <-- SAFETY CHECK
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
	get_tree().call_group("Camera", "apply_shake", 15.0)
	
	PlayerData.current_damage *= 3.0 # DOUBLE DAMAGE!
	sprite.modulate = Color(1.5, 0.5, 0.5) 
	PlayerData.heavy_is_active = true
	trigger_impact_frame()
	flash_light_color(Color(2.0, 0.5, 0.5), buff_duration)
	
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

func apply_hit_stop(duration: float = 0.05):
	# Freeze the engine
	get_tree().paused = true
	# Wait for the duration (the 'true' makes the timer ignore the pause!)
	await get_tree().create_timer(duration, true).timeout
	# Unfreeze
	get_tree().paused = false

func trigger_impact_frame():
	# 1. Create a CanvasLayer to draw over the HUD
	var canvas = CanvasLayer.new()
	canvas.layer = 100 
	
	# 2. Create the flash block
	var flash = ColorRect.new()
	flash.color = Color.WHITE
	flash.set_anchors_preset(Control.PRESET_FULL_RECT) 
	
	canvas.add_child(flash)
	get_tree().current_scene.add_child(canvas)
	
	# Flash White (slightly longer)
	await get_tree().create_timer(0.05, true).timeout
	flash.color = Color.BLACK
	
	# Flash Black
	await get_tree().create_timer(0.05, true).timeout
	
	# Delete the whole canvas
	canvas.queue_free()

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
			
			if dir.dot(dir_to_enemy) > 0.8:
				current_hit_count += 1
				
		if current_hit_count > max_hit_count:
			max_hit_count = current_hit_count
			best_dir = dir
			
	return best_dir

func get_closest_enemy(attack_range: float) -> Node2D:
	var valid_boss_targets = []
	
	# 1. ALWAYS target live cubes first
	valid_boss_targets.append_array(get_tree().get_nodes_in_group("BossCube"))
	
	# 2. ONLY add the main Boss body to the target list if it can actually take damage!
	var bosses = get_tree().get_nodes_in_group("Boss")
	for boss in bosses:
		if is_instance_valid(boss):
			# We check the manual_state variable we made in Phase 4!
			var state = boss.get("manual_state")
			if state == "vulnerable" or state == "stunned":
				valid_boss_targets.append(boss)
				
	# 3. Try to target the Cubes (or the Exposed Core) FIRST
	var closest_boss = find_closest_in_array(valid_boss_targets, attack_range)
	if closest_boss != null:
		return closest_boss
		
	# 4. If no boss targets are near, fallback to targeting regular minions
	var regular_enemies = get_tree().get_nodes_in_group("Enemy")
	return find_closest_in_array(regular_enemies, attack_range)

# Replace your old helper function with this safe version
func find_closest_in_array(target_array: Array, attack_range: float) -> Node2D:
	var closest = null
	var shortest_distance = attack_range 
	
	for target in target_array:
		# SAFETY CHECK: Ensure the node actually has the 'visible' and 'global_position' properties
		if not is_instance_valid(target) or not "visible" in target or not target.visible: 
			continue 
			
		if not "global_position" in target:
			continue
			
		var distance = global_position.distance_to(target.global_position)
		if distance <= shortest_distance:
			shortest_distance = distance
			closest = target
			
	return closest

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
func receive_knockback(force_vector: Vector2):
	# If the player is invincible (like during a dash), ignore the push!
	if is_invincible: return 
	
	knockback_velocity = force_vector
	
	# Optional: Cancel attacks if you get hit hard
	is_attacking = false

func trigger_wall_pop_effect():
	# Flash the player
	var current_color = sprite.modulate
	sprite.modulate = Color(2.0, 3.0, 3.0, 1.0) 
	var flash_tween = create_tween()
	flash_tween.tween_property(sprite, "modulate", current_color, 0.2)
	
	# --- NEW: TELL THE ARENA TO FLASH! ---
	get_tree().call_group("Arena", "flash_barrier")
	
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
	apply_hit_stop(0.05)
	if body.is_in_group("Enemy"):
		if body.has_method("take_damage"):
			body.take_damage(PlayerData.current_damage)

func apply_zoom():
	if current_zoom == 1.5:
		current_zoom = 2.0
	elif current_zoom == 2.0 :
		current_zoom = 1.0
	else :
		current_zoom = 1.5
		
	camera.zoom = Vector2(current_zoom, current_zoom)

func take_damage(damage: int) -> void:
	if is_dead or is_invincible or not PlayerData.is_game_started:
		return 
		
	PlayerData.current_health -= damage
	AudioManager.play_player_hit(global_position)
	health_bar_update.emit()
	is_attacking = false 
	
	if PlayerData.current_health <= 0:
		is_dead = true
		flash_red()
		# Wait just a split second for the red flash to finish, then die
		await get_tree().create_timer(0.2).timeout 
		if is_inside_tree():
			die()
	else:
		# Just flash red and instantly let the player keep moving!
		flash_red()

func flash_red():
	sprite.modulate = Color(1, 0.3, 0.3, 0.7)
	await get_tree().create_timer(0.15).timeout
	
	# Check if we should return to the Heavy Buff color or normal White
	if PlayerData.heavy_is_active:
		sprite.modulate = Color(1.5, 0.5, 0.5) 
	else:
		sprite.modulate = Color.WHITE

func die():
	AudioManager.play_player_death()
	if get_tree() != null: 
		set_physics_process(false)
		can_attack = false
		get_tree().change_scene_to_packed(game_over_scene)

func start_heart_pulse():
	# Create a tween that loops forever with a smooth sine wave transition
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	var pulse_time = 0.6 # Seconds it takes for one half of the heartbeat
	
	# 1. Breathe IN (Gets brighter and larger)
	tween.tween_property(core_light, "energy", 1.5, pulse_time)
	tween.parallel().tween_property(core_light, "texture_scale", 1.2, pulse_time)
	
	# 2. Breathe OUT (Gets dimmer and smaller)
	tween.tween_property(core_light, "energy", 0.8, pulse_time)
	tween.parallel().tween_property(core_light, "texture_scale", 0.8, pulse_time)

func flash_light_color(ability_color: Color, fade_time: float):
	if not is_instance_valid(core_light): return
	
	# Instantly snap to the new bright color
	core_light.color = ability_color
	
	# Smoothly fade back to white (or whatever your default heart color is)
	var color_tween = create_tween()
	color_tween.tween_property(core_light, "color", Color.WHITE, fade_time)

func _on_hit_box_area_entered(area: Area2D) -> void:
	# 1. COLLECTIBLES (Shards)
	if area.is_in_group("Shards"):
		if not area.get("is_claimed"): 
			area.is_claimed = true
			
			if area.shard_type == "main_orb":
				PlayerData.has_top_orb = true
				PlayerData.is_boss_active = true
				PlayerData.collect_shard("main_orb") 
				
				# --- NEW: SAFE MENU POPUP ---
				# If we grabbed it while dashing, wait a split second for the dash to finish!
				if is_invincible:
					await get_tree().create_timer(PlayerData.attack_stats.thrust["attack_time"]).timeout
					
				get_tree().call_group("HUD", "show_primal_choice")
			else:
				PlayerData.collect_shard(area.shard_type)
				
			area.queue_free()
			
	# 2. ENEMY ATTACKS (Bullets)
	# (Make sure your enemy bullet scenes are added to a group called "EnemyBullet")
	elif area.is_in_group("EnemyBullet"): 
		if "damage" in area:
			take_damage(area.damage)
			area.queue_free() # Destroy the bullet on impact
