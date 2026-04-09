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
var player_cam: Camera2D = null
@onready var sleeping_sprite = $SleepingSprite
@onready var boss_camera = $BossPCam
var enemy_bullet_scene: PackedScene = load(Global.SCENES.enemy_bullet)
var win_scene = load(Global.SCENES.win)

# State Chart nodes
@onready var state_chart = $StateChart
@onready var awaking_state = $StateChart/Root/Waking
@onready var idle_state = $StateChart/Root/Idle
@onready var attacking_state = $StateChart/Root/Attacking
@onready var stunned_state = $StateChart/Root/Stunned
@onready var vulnerable_state = $StateChart/Root/Vulnerable

# Awaking Sequence Variables
var boss_shake_intensity: float = 10.0
var flash_brightness: float = 3.0
var flash_duration: float = 0.6
var cam_priority_high: int = 20
var cam_priority_low: int = 0
var cam_look_duration: float = 1.6
var cam_return_duration: float = 1.0

# --- Tuning & Effects ---
var armor_threshold: int = 25
var stun_duration: float = 1.5
var vulnerable_duration: float = 8.0
var bounce_flash_time: float = 0.1

var color_armor_cube: Color = Color(0.5, 0.5, 0.5) # Grey
var color_armor_core: Color = Color(0.5, 0.5, 2.0) # Blue-ish
var color_vulnerable: Color = Color(0.3, 0.3, 0.3) # Dimmed



# State Logic Variables
var idle_timer: float = 0.0
var time_between_attacks: float = 2.0

# Manual states for Stunned / Vulnerable (not yet migrated to State Chart)
var manual_state: String = "active"  # "active", "stunned", "vulnerable"

# Boss Stats
var is_awake: bool = false
var detection_radius: float = 150.0 
var detection_growth_rate: float = 50 
var move_speed: float = 150.0 
var attack_range: float = 350.0 
var core_max_health: int = 3000
var core_health: int = 3000
var cube_max_health: int = 450
var is_intro_playing: bool = false
var is_waking_up: bool = false
var is_dying: bool = false

var orbit_speed: float = 1.5
var force_skip: bool = false

# Cube Data
var active_cubes = {
	"red": {"node": null, "hp": 150, "is_alive": true},
	"blue": {"node": null, "hp": 150, "is_alive": true},
	"green": {"node": null, "hp": 150, "is_alive": true}
}

func _ready():
	Engine.time_scale = 1.0
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
	
	# Connect State Chart signals
	awaking_state.state_entered.connect(_on_awaking_state_entered)
	idle_state.state_processing.connect(_on_idle_state_processing)
	attacking_state.state_entered.connect(_on_attacking_state_entered)
	stunned_state.state_entered.connect(_on_stunned_state_entered)
	vulnerable_state.state_entered.connect(_on_vulnerable_state_entered)
	
	play_intro_cutscene()

func _physics_process(delta: float):
	# Spin cubes unless stunned or vulnerable
	if manual_state != "stunned" and manual_state != "vulnerable":
		orbit_center.rotation += orbit_speed * delta
		red_cube.global_rotation = 0
		blue_cube.global_rotation = 0
		green_cube.global_rotation = 0

	# Stop AI logic during cutscenes
	if is_intro_playing or is_waking_up: 
		return
		
	player = get_tree().get_first_node_in_group("Player")
	
	# --- SLEEPING PHASE ---
	if not is_awake:
		if is_intro_playing: return
		
		detection_radius += detection_growth_rate * delta
		queue_redraw() 
		
		if player and global_position.distance_to(player.global_position) <= detection_radius:
			is_awake = true
			state_chart.send_event("player_detected")
		return 

	# --- AWAKE PHASE - Head tracking ---
	if player:
		var angle_to_player = global_position.angle_to_point(player.global_position)
		var angle_degrees = rad_to_deg(angle_to_player)
		var adjusted_angle = fposmod(angle_degrees + 22.5, 360.0)
		
		var frame_index = int(adjusted_angle / 45.0) % 8
		var eye_correction = 6 
		head_sprite.frame = (frame_index + eye_correction) % 8

	# --- MOVEMENT (only if not stunned/vulnerable and we are in "active" manual state) ---
	# The State Chart handles Idle/Attacking, but movement should only happen when not stunned/vulnerable.
	# We'll use manual_state to block movement during those phases.
	if manual_state == "active" and is_instance_valid(player):
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
		player.is_invincible = true 
		
	boss_camera.priority = 0 
	
	# 1. IMPACT (Looking at the Player)
	await get_tree().create_timer(0.2).timeout
	get_tree().call_group("Camera", "apply_shake", 30.0) 
	await get_tree().create_timer(1.2).timeout
	
	get_tree().paused = true 
	var dialogue_resource = load(Global.titan_lore)
	var balloon_scene = load(Global.SCENES.balloon) 
	var balloon = balloon_scene.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(dialogue_resource, "impact_sequence")
	await DialogueManager.dialogue_ended
	get_tree().paused = false 
	
	# 2. PAN TO BOSS
	boss_camera.priority = 20
	await get_tree().create_timer(1.5).timeout
	
	get_tree().paused = true 
	var balloon_two = balloon_scene.instantiate()
	get_tree().current_scene.add_child(balloon_two)
	balloon_two.start(dialogue_resource, "scan_sequence")
	await DialogueManager.dialogue_ended
	get_tree().paused = false 
	
	# 3. PAN BACK TO PLAYER
	boss_camera.priority = 0
	await get_tree().create_timer(1.5).timeout
	
	is_intro_playing = false
	PlayerData.is_game_started = true
	if is_instance_valid(player):
		player.is_invincible = false

# STATES FUNCTIONS

func _on_awaking_state_entered():
	force_skip = false 
	# Make the boss immune to pause
	process_mode = Node.PROCESS_MODE_ALWAYS 
	get_tree().paused = true 
	
	is_waking_up = true 
	AudioManager.switch_bgm_phase(3)
	
	# Instant Visual Setup
	sleeping_sprite.hide()
	body_sprite.show()
	head_sprite.show()
	orbit_center.show()
	core_hp_bar.show()
	
	# Roar Shake
	get_tree().call_group("Camera", "apply_shake", boss_shake_intensity) 
	
	# --- 1. SHOW WAKE UP DIALOGUE ---
	var dialogue_resource = load(Global.titan_lore)
	var balloon_scene = load(Global.SCENES.balloon) 
	var balloon = balloon_scene.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(dialogue_resource, "wake_up_sequence")
	
	# Dialogue Manager is pause-aware by default, so we just wait
	await DialogueManager.dialogue_ended
	
	if force_skip:
		finish_wake_up()
		return

	# --- 2. CAMERA PAN TO BOSS ---
	boss_camera.priority = cam_priority_high
	
	await get_tree().create_timer(cam_look_duration, true).timeout 
	
	if force_skip: 
		finish_wake_up()
		return
		
	# --- 3. CAMERA RETURN TO PLAYER ---
	boss_camera.priority = cam_priority_low
	
	await get_tree().create_timer(cam_return_duration, true).timeout
	
	finish_wake_up()

func finish_wake_up():
	# Clean up logic
	get_tree().paused = false 
	process_mode = Node.PROCESS_MODE_INHERIT
	is_waking_up = false 
	
	for slime in get_tree().get_nodes_in_group("slime"): 
		slime.queue_free()
		
	# This event will now fire because the StateChart node is set to 'Always'
	state_chart.send_event("wake_finished")

func _on_idle_state_processing(delta: float):
	if not is_instance_valid(player): return
	
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= attack_range:
		idle_timer += delta
		if idle_timer >= time_between_attacks:
			idle_timer = 0.0
			state_chart.send_event("choose_attack")
	else:
		idle_timer = 0.0

func _on_attacking_state_entered():
	AudioManager.switch_bgm_phase(4)
	orbit_speed = 6.0 
	
	await get_tree().create_timer(1.0).timeout 
	orbit_speed = 1.5
	
	var available_attacks = []
	for color in active_cubes:
		if active_cubes[color]["is_alive"]:
			available_attacks.append(color)
			
	if not available_attacks.is_empty():
		var chosen_attack = available_attacks.pick_random()
		match chosen_attack:
			"red": await perform_red_slam()
			"blue": perform_blue_snipe()
			"green": perform_green_burst()
			
	await get_tree().create_timer(1.0).timeout 
	state_chart.send_event("attack_finished")

func _on_stunned_state_entered():
	manual_state = "stunned"
	velocity = Vector2.ZERO # Stop moving instantly
	
	# Wait for the duration, then recover
	await get_tree().create_timer(stun_duration).timeout
	
	# Check if we should go to Vulnerable or back to Idle
	check_all_cubes_dead()

func _on_vulnerable_state_entered():
	manual_state = "vulnerable"
	orbit_speed = 0.0
	head_sprite.modulate = color_vulnerable
	print("CORE EXPOSED!")
	
	# Wait for the vulnerable phase to finish
	await get_tree().create_timer(vulnerable_duration).timeout
	
	if core_health > 0:
		# Send the event to move back to Stunned while the cubes reboot
		state_chart.send_event("cubes_respawning")
		respawn_cubes()

func respawn_cubes():
	print("Respawning Cubes! Core Heals!")
	
	core_health = min(core_max_health, core_health + 200) 
	head_sprite.modulate = Color.WHITE
	core_hp_bar.value = core_health 
	
	for color in active_cubes:
		active_cubes[color]["is_alive"] = true
		active_cubes[color]["hp"] = cube_max_health
		active_cubes[color]["node"].visible = true
		if color == "red": red_hp_bar.value = cube_max_health
		elif color == "blue": blue_hp_bar.value = cube_max_health
		elif color == "green": green_hp_bar.value = cube_max_health
		
	# Give them a fast reverse-spin for 2 seconds as they boot up!
	orbit_speed = -5.0 
	await get_tree().create_timer(2.0).timeout
	orbit_speed = 1.5
	
	# We don't need to change manual_state here because the State Chart 
	# will naturally move from Stunned -> Idle and handle it for us!

func _draw():
	if not is_awake:
		draw_arc(Vector2.ZERO, detection_radius, 0, TAU, 64, Color(0.6, 0.0, 0.8, 0.6), 4.0)

func damage_cube(color: String, amount: int):
	if not active_cubes[color]["is_alive"]: return
	
	var cube_node = active_cubes[color]["node"]
	var cube_sprite = cube_node.get_node("Sprite2D") 
	
	# --- ARMOR THRESHOLD EFFECT ---
	if amount < armor_threshold:
		cube_sprite.modulate = color_armor_cube
		await get_tree().create_timer(bounce_flash_time).timeout
		if is_instance_valid(cube_sprite):
			# Restore the original elemental color
			if color == "red": cube_sprite.modulate = Color(2.0, 0.5, 0.5)
			elif color == "blue": cube_sprite.modulate = Color(0.5, 0.5, 2.0)
			elif color == "green": cube_sprite.modulate = Color(0.5, 2.0, 0.5)
		return # No damage taken!
	
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
	
	print(color + " cube broken!")
	state_chart.send_event("cube_broken") # The State Chart handles the stun now!

func check_all_cubes_dead():
	var all_dead = true
	for color in active_cubes:
		if active_cubes[color]["is_alive"]:
			all_dead = false
			break
			
	if all_dead:
		# Tell the State Chart to move to Vulnerable!
		state_chart.send_event("all_cubes_dead")
	else:
		# Tell the State Chart to go back to Idle!
		state_chart.send_event("recover")
		manual_state = "active"

func take_damage(amount: int):
	# --- CORE ARMOR EFFECT ---
	if amount < armor_threshold:
		body_sprite.modulate = color_armor_core
		await get_tree().create_timer(bounce_flash_time).timeout
		body_sprite.modulate = Color.WHITE
		return

	if manual_state == "vulnerable" or manual_state == "stunned":
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
	if is_dying: return
	
	is_dying = true
	
	# --- ANIME SLOW-MO DEATH ---
	Engine.time_scale = 0.2 	
	
	var time_tween = create_tween()
	time_tween.tween_property(Engine, "time_scale", 1.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	manual_state = "stunned"
	
	# Clean up enemies
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if is_instance_valid(enemy) and enemy != self:
			enemy.queue_free()
	
	orbit_center.hide() 
	core_hp_bar.hide()
	
	boss_camera.priority = 20
	# Wait 1.5 seconds in REAL time (ignores slow mo)
	await get_tree().create_timer(1.5, true, false, true).timeout
	print(manual_state)
	body_sprite.hide()
	head_sprite.hide()
	death_sprite.show()
	print("sprite showed")
	death_sprite.speed_scale = 1.0 # Let the animation speed naturally recover with the Tween
	death_sprite.play("death")
	print("animation played")
	get_tree().call_group("Camera", "apply_shake", 40.0) 
	
	# THE FIX: Bypass the buggy animation signal entirely. 
	# Wait exactly 2.5 real-world seconds to let the death animation play out safely.
	await get_tree().create_timer(2.5, true, false, true).timeout
	
	# Final Safety: Reset time scale before scene change
	Engine.time_scale = 1.0
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

# This function is called by the Skip Button
func skip_cutscene():
	force_skip = true
	# Snap camera back instantly
	boss_camera.priority = 0
	# Unpause the world
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_INHERIT
