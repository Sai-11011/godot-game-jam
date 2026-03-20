extends CharacterBody2D

@onready var body_sprite = $BodySprite
@onready var head_sprite = $HeadSprite
@onready var orbit_center = $OrbitCenter
@onready var core_hp_bar = $HealthBar
@onready var death_sprite = $DeathSprite

# Cubes
@onready var red_cube = $OrbitCenter/RedCube
@onready var red_hp_bar = $OrbitCenter/RedCube/HealthBar
@onready var blue_cube = $OrbitCenter/BlueCube
@onready var blue_hp_bar = $OrbitCenter/BlueCube/HealthBar
@onready var green_cube = $OrbitCenter/GreenCube
@onready var green_hp_bar = $OrbitCenter/GreenCube/HealthBar

var player: CharacterBody2D
var player_cam: Camera2D = null # Cleanly decla
@onready var sleeping_sprite = $SleepingSprite
@onready var boss_camera = $BossCamera
var enemy_bullet_scene: PackedScene = load(Global.SCENES.enemy_bullet)
var win_scene = load(Global.SCENES.win)
# Boss Stats
var is_awake: bool = false
var detection_radius: float = 150.0 
var detection_growth_rate: float = 22.83 
var move_speed: float = 150.0 
var attack_range: float = 350.0 
var core_max_health: int = 3000
var core_health: int = 3000
var cube_max_health: int = 450
var is_intro_playing: bool = false
var is_waking_up: bool = false
var is_dying: bool = false

# State Tracking
enum State { IDLE, ATTACKING, STUNNED, VULNERABLE }
var current_state = State.IDLE
var orbit_speed: float = 1.5

# Cube Data
var active_cubes = {
	"red": {"node": null, "hp": 150, "is_alive": true},
	"blue": {"node": null, "hp": 150, "is_alive": true},
	"green": {"node": null, "hp": 150, "is_alive": true}
}

func _ready():
	add_to_group("Boss")
	active_cubes["red"]["node"] = red_cube
	active_cubes["blue"]["node"] = blue_cube
	active_cubes["green"]["node"] = green_cube
	
	core_hp_bar.max_value = core_max_health
	core_hp_bar.value = core_health
	red_hp_bar.max_value = cube_max_health
	red_hp_bar.value = cube_max_health
	blue_hp_bar.max_value = cube_max_health
	blue_hp_bar.value = cube_max_health
	green_hp_bar.max_value = cube_max_health
	green_hp_bar.value = cube_max_health
	
	red_cube.add_to_group("BossCube")
	blue_cube.add_to_group("BossCube")
	green_cube.add_to_group("BossCube")
	
	# Hide awake boss, show sleeping boss
	body_sprite.hide()
	head_sprite.hide()
	orbit_center.hide()
	core_hp_bar.hide()
	sleeping_sprite.show()
	
	play_intro_cutscene()

func _physics_process(delta: float):
	if is_intro_playing or is_waking_up: 
		return
		
	player = get_tree().get_first_node_in_group("Player")
	
	# --- 1. THE SLEEPING PHASE ---
	if not is_awake:
		if is_intro_playing: return
		
		detection_radius += detection_growth_rate * delta
		queue_redraw() 
		
		if player and global_position.distance_to(player.global_position) <= detection_radius:
			wake_up()
		return 

	# --- 2. THE AWAKE PHASE ---
	if current_state != State.STUNNED and current_state != State.VULNERABLE:
		orbit_center.rotation += orbit_speed * delta
		red_cube.global_rotation = 0
		blue_cube.global_rotation = 0
		green_cube.global_rotation = 0
		
	if player:
		var angle_to_player = global_position.angle_to_point(player.global_position)
		var angle_degrees = rad_to_deg(angle_to_player)
		var adjusted_angle = fposmod(angle_degrees + 22.5, 360.0)
		
		var frame_index = int(adjusted_angle / 45.0) % 8
		var eye_correction = 6 
		head_sprite.frame = (frame_index + eye_correction) % 8

	# --- 3. MOVEMENT ---
	if current_state == State.IDLE and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		
		if distance > attack_range:
			var direction = global_position.direction_to(player.global_position)
			velocity = direction * move_speed
			move_and_slide()
			get_tree().call_group("Camera", "apply_shake", 0) 
			AudioManager.play_boss_movement(global_position)
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

func play_intro_cutscene():
	is_intro_playing = true
	if is_instance_valid(player):
		player.is_invincible = true # Protect the player during intro
	await get_tree().create_timer(0.1).timeout
	player = get_tree().get_first_node_in_group("Player")
	
	if is_instance_valid(player):
		player_cam = player.get_node_or_null("Camera2D")
		
	if player_cam:
		player_cam.enabled = false
		
	# FIX: Keep top_level FALSE at first so it is FORCED to stay perfectly on the boss!
	boss_camera.top_level = false 
	boss_camera.position = Vector2.ZERO # Center it exactly on the boss node
	boss_camera.enabled = true
	boss_camera.make_current()
	boss_camera.zoom = Vector2(1.5, 1.5) 
	
	# Look at the sleeping Titan for a moment
	await get_tree().create_timer(1.2).timeout
	
	# NOW detach the camera so it can smoothly pan over to the Player
	boss_camera.top_level = true 
	boss_camera.global_position = self.global_position 
	
	if is_instance_valid(player):
		var pan_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pan_tween.tween_property(boss_camera, "global_position", player.global_position, 1.5)
		await pan_tween.finished
	
	# Hand control back to the player
	if not is_awake:
		boss_camera.enabled = false
		if player_cam:
			player_cam.enabled = true
			player_cam.make_current()
			
	boss_camera.zoom = Vector2(1.0, 1.0) 
	is_intro_playing = false
	PlayerData.is_game_started = true
	if is_instance_valid(player):
		player.is_invincible = false # Restore damage once control is back

func wake_up():
	is_waking_up = true # 1. LOCK THE BOSS!
	if is_instance_valid(player):
		player.is_invincible = true # God Mode: Engaged
	is_awake = true
	PlayerData.is_boss_active = true 
	queue_redraw() 
	print("The Titan has awakened!")
	
	# 1. HIDE SLEEPING, INSTANTLY SHOW BOSS
	sleeping_sprite.hide()
	body_sprite.show()
	head_sprite.show()
	orbit_center.show()
	core_hp_bar.show()
	
	# 2. AWAKENING FLASH EFFECT & SHAKE (Happens immediately!)
	get_tree().call_group("Camera", "apply_shake", 10.0) 
	body_sprite.modulate = Color(3.0, 3.0, 3.0)
	head_sprite.modulate = Color(3.0, 3.0, 3.0)
	
	var flash_tween = create_tween().set_parallel(true)
	flash_tween.tween_property(body_sprite, "modulate", Color.WHITE, 0.6)
	flash_tween.tween_property(head_sprite, "modulate", Color.WHITE, 0.6)
	
	# Wait for the flash to finish before moving the camera!
	await flash_tween.finished
	
	# 3. NOW PAN THE CAMERA TO THE BOSS
	if is_instance_valid(player):
		player_cam = player.get_node_or_null("Camera2D")
		if player_cam:
			player_cam.enabled = false
			
	boss_camera.top_level = true
	if is_instance_valid(player):
		boss_camera.global_position = player.global_position
	boss_camera.enabled = true 
	boss_camera.make_current()
	
	var pan_to_boss = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pan_to_boss.tween_property(boss_camera, "global_position", self.global_position, 1.0)
	await pan_to_boss.finished
	
	# Dramatic pause to look at the fully awakened boss
	await get_tree().create_timer(0.6).timeout 
	
	# 4. PAN BACK TO THE PLAYER
	if is_instance_valid(player):
		var pan_to_player = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pan_to_player.tween_property(boss_camera, "global_position", player.global_position, 1.0)
		await pan_to_player.finished
	
	boss_camera.enabled = false
	if player_cam:
		player_cam.enabled = true
		player_cam.make_current()
			
	for slime in get_tree().get_nodes_in_group("slime"): 
		slime.queue_free()
	
	is_waking_up = false # 2. UNLOCK THE BOSS!
	start_boss_loop()
	if is_instance_valid(player):
		player.is_invincible = false # God Mode: Disengaged

func _draw():
	if not is_awake:
		draw_arc(Vector2.ZERO, detection_radius, 0, TAU, 64, Color(0.6, 0.0, 0.8, 0.6), 4.0)

func start_boss_loop():
	while core_health > 0:
		if current_state == State.VULNERABLE or not is_instance_valid(player):
			await get_tree().create_timer(1.0).timeout 
			continue
			
		if current_state == State.IDLE:
			var distance = global_position.distance_to(player.global_position)
			
			if distance <= attack_range:
				await get_tree().create_timer(2.0).timeout 
				if current_state == State.IDLE: 
					pick_random_attack()
			else:
				await get_tree().create_timer(0.2).timeout
		else:
			await get_tree().process_frame

func pick_random_attack():
	var available_attacks = []
	for color in active_cubes:
		if active_cubes[color]["is_alive"]:
			available_attacks.append(color)
			
	if available_attacks.is_empty():
		return 
		
	var chosen_attack = available_attacks.pick_random()
	execute_attack(chosen_attack)

func execute_attack(color: String):
	current_state = State.ATTACKING
	orbit_speed = 6.0 
	
	await get_tree().create_timer(1.0).timeout 
	orbit_speed = 1.5
	
	match color:
		"red": perform_red_slam()
		"blue": perform_blue_snipe()
		"green": perform_green_burst()
			
	await get_tree().create_timer(1.0).timeout 
	if current_state == State.ATTACKING:
		current_state = State.IDLE

func damage_cube(color: String, amount: int):
	if not active_cubes[color]["is_alive"]: return
	
	var cube_node = active_cubes[color]["node"]
	var cube_sprite = cube_node.get_node("Sprite2D") 
	
	# --- NEW: ARMOR THRESHOLD CHECK ---
	if amount < 25:
		# Flash grey to show the attack bounced off
		cube_sprite.modulate = Color(0.5, 0.5, 0.5)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(cube_sprite):
			if color == "red": cube_sprite.modulate = Color(2.0, 0.5, 0.5)
			elif color == "blue": cube_sprite.modulate = Color(0.5, 0.5, 2.0)
			elif color == "green": cube_sprite.modulate = Color(0.5, 2.0, 0.5)
		return # Stop the function here, take 0 damage!
	
	active_cubes[color]["hp"] -= amount
	AudioManager.play_boss_hit(global_position)
	
	match color:
		"red": red_hp_bar.value = active_cubes[color]["hp"]
		"blue": blue_hp_bar.value = active_cubes[color]["hp"]
		"green": green_hp_bar.value = active_cubes[color]["hp"]
	
	cube_sprite.modulate = Color(3, 3, 3)
	await get_tree().create_timer(0.1).timeout
	
	if is_instance_valid(cube_sprite):
		if color == "red": cube_sprite.modulate = Color(2.0, 0.5, 0.5)
		elif color == "blue": cube_sprite.modulate = Color(0.5, 0.5, 2.0)
		elif color == "green": cube_sprite.modulate = Color(0.5, 2.0, 0.5)

	if active_cubes[color]["hp"] <= 0:
		kill_cube(color)

func kill_cube(color: String):
	active_cubes[color]["is_alive"] = false
	active_cubes[color]["node"].visible = false 
	
	current_state = State.STUNNED
	print(color + " cube broken! Boss Stunned!")
	await get_tree().create_timer(1.5).timeout
	
	check_all_cubes_dead()

func check_all_cubes_dead():
	var all_dead = true
	for color in active_cubes:
		if active_cubes[color]["is_alive"]:
			all_dead = false
			break
			
	if all_dead:
		trigger_vulnerable_phase()
	else:
		current_state = State.IDLE

func trigger_vulnerable_phase():
	current_state = State.VULNERABLE
	orbit_speed = 0.0
	head_sprite.modulate = Color(0.5, 0.5, 0.5) 
	
	print("CORE EXPOSED!")
	await get_tree().create_timer(8.0).timeout
	
	if core_health > 0:
		respawn_cubes()

func respawn_cubes():
	print("Respawning Cubes! Core Heals!")
	current_state = State.STUNNED
	
	core_health = min(core_max_health, core_health + 200) 
	head_sprite.modulate = Color.WHITE
	
	for color in active_cubes:
		active_cubes[color]["is_alive"] = true
		active_cubes[color]["hp"] = cube_max_health
		active_cubes[color]["node"].visible = true
		if color == "red": red_hp_bar.value = cube_max_health
		elif color == "blue": blue_hp_bar.value = cube_max_health
		elif color == "green": green_hp_bar.value = cube_max_health
		
	orbit_speed = -5.0 
	await get_tree().create_timer(2.0).timeout
	orbit_speed = 1.5
	current_state = State.IDLE
	
	core_hp_bar.value = core_health 

func take_damage(amount: int):
	# --- NEW: ARMOR THRESHOLD CHECK ---
	if amount < 25:
		# Flash blue so the player knows the core is too tough
		body_sprite.modulate = Color(0.5, 0.5, 2.0)
		await get_tree().create_timer(0.1).timeout
		body_sprite.modulate = Color.WHITE
		return # Stop the function here, take 0 damage!

	if current_state == State.VULNERABLE or current_state == State.STUNNED:
		core_health -= amount
		AudioManager.play_boss_hit(global_position)
		core_hp_bar.value = core_health
		
		body_sprite.modulate = Color(3, 3, 3)
		await get_tree().create_timer(0.1).timeout
		body_sprite.modulate = Color.WHITE
		
		if core_health <= 0:
			die()
	else:
		body_sprite.modulate = Color(0.5, 0.5, 2.0)
		await get_tree().create_timer(0.1).timeout
		body_sprite.modulate = Color.WHITE

func die():
	if is_dying: return # If already dead, ignore any extra hits!
	is_dying = true
	print("TITAN DEFEATED!")
	current_state = State.STUNNED # Stop the boss from attacking
	
	# 1. Instantly hide the cubes and health bar
	orbit_center.hide() 
	core_hp_bar.hide()
	
	# 2. Pan the camera to the Boss
	if is_instance_valid(player):
		player_cam = player.get_node_or_null("Camera2D")
		if player_cam:
			player_cam.enabled = false
			
	boss_camera.top_level = true
	if is_instance_valid(player):
		boss_camera.global_position = player.global_position
	boss_camera.enabled = true
	boss_camera.make_current()
	boss_camera.zoom = Vector2(1.5, 1.5) 
	
	var pan_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pan_tween.tween_property(boss_camera, "global_position", global_position, 1.0)
	await pan_tween.finished
	
	# 3. Dramatic pause before crumbling...
	await get_tree().create_timer(0.5).timeout
	
	# 4. Swap to the Death Sprite and play the animation!
	body_sprite.hide()
	head_sprite.hide()
	death_sprite.show()
	death_sprite.play("death")
	
	# 5. Massive screen shake as it falls apart
	get_tree().call_group("Camera", "apply_shake", 40.0) 
	
	# 6. Wait for the crumble animation to completely finish
	await death_sprite.animation_finished
	
	# 7. One last pause to look at the rubble before showing the Win Screen
	await get_tree().create_timer(1.5).timeout
	
	get_tree().change_scene_to_packed(win_scene)
	queue_free()

func receive_knockback(_force: Vector2):
	pass 

func perform_red_slam():
	if not is_instance_valid(player): return
	
	var slam_radius = 80.0
	var target_pos = player.global_position
	var original_local_pos = red_cube.position 
	
	red_cube.top_level = true 
	
	var warning_circle = Polygon2D.new()
	warning_circle.color = Color(1.0, 0.0, 0.0, 0.3)
	var points = PackedVector2Array()
	for i in range(32):
		var angle = (i / 32.0) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * slam_radius)
	warning_circle.polygon = points
	warning_circle.global_position = target_pos
	warning_circle.scale = Vector2.ZERO
	get_tree().current_scene.add_child(warning_circle)
	
	var circle_tween = create_tween()
	circle_tween.tween_property(warning_circle, "scale", Vector2.ONE, 0.6)
	
	var jump_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump_tween.tween_property(red_cube, "global_position", target_pos + Vector2(0, -400), 0.6)
	await jump_tween.finished
	
	var smash_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	smash_tween.tween_property(red_cube, "global_position", target_pos, 0.15)
	await smash_tween.finished
	
	if is_instance_valid(warning_circle):
		warning_circle.color = Color(1.0, 0.0, 0.0, 0.8)
	get_tree().call_group("Camera", "apply_shake", 45.0) 
	AudioManager.play_boss_red_attack(target_pos)
	
	if is_instance_valid(player):
		var distance = target_pos.distance_to(player.global_position)
		if distance <= slam_radius:
			if player.has_method("take_damage"):
				player.take_damage(40) 
			if Global.has_method("apply_knockback"):
				Global.apply_knockback(target_pos, player, 1000.0)
				
	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(warning_circle):
		warning_circle.queue_free()

	var return_tween = create_tween()
	var return_target = orbit_center.global_position + original_local_pos.rotated(orbit_center.rotation)
	return_tween.tween_property(red_cube, "global_position", return_target, 0.4)
	await return_tween.finished
	
	red_cube.top_level = false
	red_cube.position = original_local_pos

func perform_blue_snipe():
	if not is_instance_valid(player) or enemy_bullet_scene == null: return
	
	var sprite = blue_cube.get_node("Sprite2D")
	sprite.modulate = Color(3.0, 3.0, 4.0)
	var flash_tween = create_tween()
	flash_tween.tween_property(sprite, "modulate", Color(0.5, 0.5, 2.0), 0.5)
	
	var bullet = enemy_bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	AudioManager.play_boss_blue_attack(global_position)
	var eye_pos = head_sprite.global_position + Vector2(0, -15)
	bullet.global_position = eye_pos
	bullet.scale = Vector2(3.5, 3.5) 
	
	var direction = eye_pos.direction_to(player.global_position)
	bullet.rotation = direction.angle()
	
	if "target_pos" in bullet:
		bullet.target_pos = bullet.global_position + (direction * 2000.0)
	elif "direction" in bullet:
		bullet.direction = direction
		
	if "damage" in bullet:
		bullet.damage = 25 

func perform_green_burst():
	if enemy_bullet_scene == null: return
	
	var sprite = green_cube.get_node("Sprite2D")
	sprite.modulate = Color(3.0, 4.0, 3.0)
	var flash_tween = create_tween()
	flash_tween.tween_property(sprite, "modulate", Color(0.5, 2.0, 0.5), 0.5)
	
	var burst_count = 8
	var angle_step = TAU / burst_count 
	var eye_pos = head_sprite.global_position + Vector2(0, -15)
	
	for i in range(burst_count):
		var bullet = enemy_bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		AudioManager.play_boss_blue_attack(global_position)
		bullet.global_position = eye_pos
		bullet.scale = Vector2(1.8, 1.8) 
		bullet.modulate = Color(0.5, 2.0, 0.5)
		
		var current_angle = i * angle_step
		var direction = Vector2(cos(current_angle), sin(current_angle))
		bullet.rotation = current_angle
		
		if "target_pos" in bullet:
			bullet.target_pos = bullet.global_position + (direction * 1500.0)
		elif "direction" in bullet:
			bullet.direction = direction
			
		if "damage" in bullet:
			bullet.damage = 15
