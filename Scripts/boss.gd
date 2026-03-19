extends CharacterBody2D

@onready var body_sprite = $BodySprite
@onready var head_sprite = $HeadSprite
@onready var orbit_center = $OrbitCenter
@onready var core_hp_bar = $HealthBar

# Cubes
@onready var red_cube = $OrbitCenter/RedCube
@onready var red_hp_bar = $OrbitCenter/RedCube/HealthBar
@onready var blue_cube = $OrbitCenter/BlueCube
@onready var blue_hp_bar = $OrbitCenter/BlueCube/HealthBar
@onready var green_cube = $OrbitCenter/GreenCube
@onready var green_hp_bar = $OrbitCenter/GreenCube/HealthBar

var player: CharacterBody2D

var enemy_bullet_scene: PackedScene = load(Global.SCENES.enemy_bullet)

# Boss Stats
# Chase & Detection Variables
var is_awake: bool = false
var detection_radius: float = 150.0 # Starts small
var detection_growth_rate: float = 22.83 # Expands by 40px every second
var move_speed: float = 150.0 # Exactly matches Player base speed!
var attack_range: float = 350.0 # How close the boss gets before stopping to attack
var core_max_health: int = 2000
var core_health: int = 2000
var cube_max_health: int = 150

# State Tracking
enum State { IDLE, ATTACKING, STUNNED, VULNERABLE }
var current_state = State.IDLE
var orbit_speed: float = 1.5

# Cube Data
var active_cubes = {
	"red": {"node": null, "hp": 550, "is_alive": true},
	"blue": {"node": null, "hp": 550, "is_alive": true},
	"green": {"node": null, "hp": 550, "is_alive": true}
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
	
	# Set up cube colors and make sure they are in groups so player attacks can hit them
	red_cube.add_to_group("BossCube")
	blue_cube.add_to_group("BossCube")
	green_cube.add_to_group("BossCube")
	
func _physics_process(delta: float):
	player = get_tree().get_first_node_in_group("Player")
	
	# --- 1. THE SLEEPING PHASE (Expanding Zone) ---
	if not is_awake:
		detection_radius += detection_growth_rate * delta
		queue_redraw() # Constantly update the drawn circle
		
		if player and global_position.distance_to(player.global_position) <= detection_radius:
			wake_up()
		return # Stop here. Do not spin or attack while asleep!

	# --- 2. THE AWAKE PHASE (Orbit & Tracking) ---
	if current_state != State.STUNNED and current_state != State.VULNERABLE:
		orbit_center.rotation += orbit_speed * delta
		red_cube.global_rotation = 0
		blue_cube.global_rotation = 0
		green_cube.global_rotation = 0
		
	# 2. Head Tracking Math
	if player:
		var angle_to_player = global_position.angle_to_point(player.global_position)
		var angle_degrees = rad_to_deg(angle_to_player)
		var adjusted_angle = fposmod(angle_degrees + 22.5, 360.0)
		
		var frame_index = int(adjusted_angle / 45.0) % 8
		
		# --- FIX: ADD THIS EYE OFFSET ---
		var eye_correction = 6 # <-- Change this to 1, 2, 3, etc. until the big eye faces you!
		head_sprite.frame = (frame_index + eye_correction) % 8

	# --- 3. MOVEMENT & TREMORS ---
	# Only move if the boss is IDLE (not currently attacking or stunned)
	if current_state == State.IDLE and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		
		if distance > attack_range:
			# Chase the player!
			var direction = global_position.direction_to(player.global_position)
			velocity = direction * move_speed
			move_and_slide()
			
			# Light camera tremors while the massive Titan walks
			get_tree().call_group("Camera", "apply_shake", 2.5) 
		else:
			# In range! Stop moving so it can attack.
			velocity = Vector2.ZERO
	else:
		# Stop moving if attacking, stunned, or vulnerable
		velocity = Vector2.ZERO

func wake_up():
	is_awake = true
	PlayerData.is_boss_active = true # Tell the game the boss is fighting!
	queue_redraw() 
	print("The Titan has awakened!")
	
	get_tree().call_group("Camera", "apply_shake", 30.0) 
	
	# --- CLEAR THE ARENA ---
	for shard in get_tree().get_nodes_in_group("Shards"):
		shard.queue_free()
		
	# Make sure your slimes are actually in a group called "Slime" or "slime"
	for slime in get_tree().get_nodes_in_group("slime"): 
		slime.queue_free()
	
	start_boss_loop()

# Draws the expanding purple detection zone so the player can see their doom approaching!
func _draw():
	if not is_awake:
		# Draws a highly visible, slightly transparent purple ring
		draw_arc(Vector2.ZERO, detection_radius, 0, TAU, 64, Color(0.6, 0.0, 0.8, 0.6), 4.0)

# --- CORE COMBAT LOOP ---

func start_boss_loop():
	while core_health > 0:
		if current_state == State.VULNERABLE or not is_instance_valid(player):
			await get_tree().create_timer(1.0).timeout 
			continue
			
		if current_state == State.IDLE:
			# Check distance BEFORE starting the attack timer!
			var distance = global_position.distance_to(player.global_position)
			
			if distance <= attack_range:
				await get_tree().create_timer(2.0).timeout # Charge up time
				
				# Ensure boss is still IDLE (didn't get stunned while waiting)
				if current_state == State.IDLE: 
					pick_random_attack()
			else:
				# Player is too far away. Wait 0.2 seconds and check distance again
				await get_tree().create_timer(0.2).timeout
		else:
			await get_tree().process_frame

func pick_random_attack():
	# Only pick from cubes that are currently alive
	var available_attacks = []
	for color in active_cubes:
		if active_cubes[color]["is_alive"]:
			available_attacks.append(color)
			
	if available_attacks.is_empty():
		return # All cubes dead, boss should be vulnerable
		
	var chosen_attack = available_attacks.pick_random()
	execute_attack(chosen_attack)

func execute_attack(color: String):
	current_state = State.ATTACKING
	orbit_speed = 6.0 # Spin fast before attacking!
	
	# Brief wind-up time
	await get_tree().create_timer(1.0).timeout 
	orbit_speed = 1.5
	
	match color:
		"red":
			perform_red_slam()
		"blue":
			perform_blue_snipe()
		"green":
			perform_green_burst()
			
	# Boss Recovery time after attacking
	await get_tree().create_timer(1.0).timeout 
	if current_state == State.ATTACKING:
		current_state = State.IDLE

# --- DAMAGE HANDLING ---

func damage_cube(color: String, amount: int):
	if not active_cubes[color]["is_alive"]: return
	
	active_cubes[color]["hp"] -= amount
	
	match color:
		"red": red_hp_bar.value = active_cubes[color]["hp"]
		"blue": blue_hp_bar.value = active_cubes[color]["hp"]
		"green": green_hp_bar.value = active_cubes[color]["hp"]
	
	# Get the Sprite directly so we don't tint the health bar!
	var cube_node = active_cubes[color]["node"]
	var cube_sprite = cube_node.get_node("Sprite2D") # Ensure your sprite is named Sprite2D!
	
	cube_sprite.modulate = Color(3, 3, 3)
	await get_tree().create_timer(0.1).timeout
	
	if is_instance_valid(cube_sprite):
		# Reset to the BRIGHT colors, not standard dark colors!
		if color == "red": cube_sprite.modulate = Color(2.0, 0.5, 0.5)
		elif color == "blue": cube_sprite.modulate = Color(0.5, 0.5, 2.0)
		elif color == "green": cube_sprite.modulate = Color(0.5, 2.0, 0.5)

	if active_cubes[color]["hp"] <= 0:
		kill_cube(color)

func kill_cube(color: String):
	active_cubes[color]["is_alive"] = false
	active_cubes[color]["node"].visible = false # Hide it instead of deleting it so we can respawn it
	
	# Brief stun for breaking a cube
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
	head_sprite.modulate = Color(0.5, 0.5, 0.5) # Look weak
	
	# Player has 8 seconds to hit the core!
	print("CORE EXPOSED!")
	await get_tree().create_timer(8.0).timeout
	
	if core_health > 0:
		respawn_cubes()

func respawn_cubes():
	print("Respawning Cubes! Core Heals!")
	current_state = State.STUNNED
	
	# Boss heals a little bit if you didn't finish it
	core_health = min(core_max_health, core_health + 200) 
	head_sprite.modulate = Color.WHITE
	
	for color in active_cubes:
		active_cubes[color]["is_alive"] = true
		active_cubes[color]["hp"] = cube_max_health
		active_cubes[color]["node"].visible = true
		if color == "red": red_hp_bar.value = cube_max_health
		elif color == "blue": blue_hp_bar.value = cube_max_health
		elif color == "green": green_hp_bar.value = cube_max_health
		
	orbit_speed = -5.0 # Spin backwards while reforming!
	await get_tree().create_timer(2.0).timeout
	orbit_speed = 1.5
	current_state = State.IDLE
	
	core_hp_bar.value = core_health # Update core bar since he healed
	
		

# Your player attacks should call this when hitting the Boss's main CharacterBody2D
func take_damage(amount: int):
	if current_state == State.VULNERABLE:
		core_health -= amount
		core_hp_bar.value = core_health
		# Flash core white
		body_sprite.modulate = Color(3, 3, 3)
		await get_tree().create_timer(0.1).timeout
		body_sprite.modulate = Color.WHITE
		
		if core_health <= 0:
			die()
	else:
		# Show a blocked/shielded effect - maybe flash blue or play a "tink" sound
		pass

func die():
	print("TITAN DEFEATED!")
	# Stop everything, play explosion, change to victory screen
	queue_free()

func perform_red_slam():
	if not is_instance_valid(player): return
	print("Red Slam Attack!")
	
	var slam_radius = 160.0
	var target_pos = player.global_position
	
	# Save the cube's local spot in the triangle so we can put it back later
	var original_local_pos = red_cube.position 
	
	# 1. Detach from orbit rotation so it can fly freely!
	red_cube.top_level = true 
	
	# 2. Draw the Warning Circle on the ground
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
	
	# 3. Fly the Cube high up into the air!
	var jump_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump_tween.tween_property(red_cube, "global_position", target_pos + Vector2(0, -400), 0.6)
	await jump_tween.finished
	
	# 4. Smash the Cube down onto the player!
	var smash_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	smash_tween.tween_property(red_cube, "global_position", target_pos, 0.15)
	await smash_tween.finished
	
	# 5. Boom! Damage and Shake
	if is_instance_valid(warning_circle):
		warning_circle.color = Color(1.0, 0.0, 0.0, 0.8)
	get_tree().call_group("Camera", "apply_shake", 45.0) 
	
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

	# 6. Float the Cube back to the boss
	var return_tween = create_tween()
	# Calculate where its spot in the orbit currently is
	var return_target = orbit_center.global_position + original_local_pos.rotated(orbit_center.rotation)
	return_tween.tween_property(red_cube, "global_position", return_target, 0.4)
	await return_tween.finished
	
	# 7. Re-attach it to the orbit!
	red_cube.top_level = false
	red_cube.position = original_local_pos

func perform_blue_snipe():
	if not is_instance_valid(player) or enemy_bullet_scene == null: return
	print("Blue Laser Snipe!")
	
	var sprite = blue_cube.get_node("Sprite2D")
	sprite.modulate = Color(3.0, 3.0, 4.0)
	var flash_tween = create_tween()
	flash_tween.tween_property(sprite, "modulate", Color(0.5, 0.5, 2.0), 0.5)
	
	var bullet = enemy_bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	
	# --- SHOOT FROM THE EYES ---
	# (Adjust the -15 if the bullets spawn too high or low on the face)
	var eye_pos = head_sprite.global_position + Vector2(0, -15)
	bullet.global_position = eye_pos
	
	# Make it MASSIVE
	bullet.scale = Vector2(3.5, 3.5) 
	
	var direction = eye_pos.direction_to(player.global_position)
	bullet.rotation = direction.angle()
	
	# Ensure compatibility with your bullet script variables
	if "target_pos" in bullet:
		bullet.target_pos = bullet.global_position + (direction * 2000.0)
	elif "direction" in bullet:
		bullet.direction = direction
		
	if "damage" in bullet:
		bullet.damage = 25 # High damage

func perform_green_burst():
	if enemy_bullet_scene == null: return
	print("Green Burst Attack!")
	
	# Visual flair: Flash the green cube!
	var sprite = green_cube.get_node("Sprite2D")
	sprite.modulate = Color(3.0, 4.0, 3.0)
	var flash_tween = create_tween()
	flash_tween.tween_property(sprite, "modulate", Color(0.5, 2.0, 0.5), 0.5)
	
	var burst_count = 8
	var angle_step = TAU / burst_count 
	
	# --- SHOOT FROM THE EYES ---
	var eye_pos = head_sprite.global_position + Vector2(0, -15)
	
	for i in range(burst_count):
		var bullet = enemy_bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		
		bullet.global_position = eye_pos
		bullet.scale = Vector2(1.8, 1.8) # Slightly larger than normal bullets
		
		var current_angle = i * angle_step
		var direction = Vector2(cos(current_angle), sin(current_angle))
		bullet.rotation = current_angle
		
		if "target_pos" in bullet:
			bullet.target_pos = bullet.global_position + (direction * 1500.0)
		elif "direction" in bullet:
			bullet.direction = direction
			
		if "damage" in bullet:
			bullet.damage = 15 # Lower damage, but hard to dodge

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		if area.has_method("take_damage"):
			area.take_damage(PlayerData.current_damage)
			queue_free() # Destroy the bullet
