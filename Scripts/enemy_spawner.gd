extends Node2D

@onready var slime_scene: PackedScene = load(Global.SCENES.slime)
@onready var ranger_scene: PackedScene = load(Global.SCENES.ranger)
@onready var tank_scene: PackedScene = load(Global.SCENES.tank) 

var player: CharacterBody2D 

var max_slimes = 40
var max_rangers = 30
var max_tanks = 30

# Create the "Donut"
var min_spawn_radius: float = 500.0
var max_spawn_radius: float = 1000.0

func _on_enemy_spawn_timer_timeout():
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
	if player == null:
		return
	var random = randf()
	# --- BOSS PHASE SPAWN LOGIC ---
	if PlayerData.is_boss_active:
		var current_rangers = get_tree().get_nodes_in_group("ranger").size()
		var current_tanks = get_tree().get_nodes_in_group("tank").size()
		
		# Slower respawns during boss fight to be fair to the player
		if random < 0.4 and current_tanks < 3:
			spawn_tank()
		elif random < 0.8 and current_rangers < 5:
			spawn_ranger()
		# Slimes never spawn during the boss!
		return 

	# --- NORMAL SPAWN LOGIC ---
	if random < 0.3:
		spawn_tank()
	elif random < 0.6:
		spawn_ranger()
	else:
		spawn_slime()

func spawn_ranger():
	var current_enemies = get_tree().get_nodes_in_group("Ranger").size()
	if current_enemies >= max_rangers:
		return
		
	var new_ranger = ranger_scene.instantiate()
	new_ranger.global_position = get_valid_spawn_position() 
	add_child(new_ranger)

func spawn_tank():
	var current_enemies = get_tree().get_nodes_in_group("Tank").size()
	if current_enemies >= max_tanks:
		return
		
	var new_tank = tank_scene.instantiate()
	new_tank.global_position = get_valid_spawn_position() 
	add_child(new_tank)

func spawn_slime():
	var current_enemies = get_tree().get_nodes_in_group("Slime").size()
	if current_enemies >= max_slimes:
		return
		
	var new_slime = slime_scene.instantiate()
	var available_colors = ["red", "blue", "green"]
	new_slime.slime_color = available_colors[randi() % available_colors.size()]
	
	new_slime.global_position = get_valid_spawn_position() 
	add_child(new_slime)

func get_valid_spawn_position() -> Vector2:
	# 1. FIND THE DANGER CENTER
	var boss = get_tree().get_first_node_in_group("Boss")
	var danger_center = Vector2.ZERO
	if is_instance_valid(boss):
		danger_center = boss.global_position
		
	# 2. Get the exact arrow pointing AWAY from the danger!
	var direction_away = danger_center.direction_to(player.global_position)
	if direction_away == Vector2.ZERO:
		direction_away = Vector2.RIGHT # Fallback if exactly on top of 0,0
	
	# 3. CALCULATE THE CAMERA BOUNDS
	var transform_inv = get_canvas_transform().affine_inverse()
	var viewport_rect = get_viewport_rect()
	var top_left = transform_inv * viewport_rect.position
	var bottom_right = transform_inv * (viewport_rect.position + viewport_rect.size)
	var camera_rect = Rect2(top_left, bottom_right - top_left).grow(150.0)
	
	# 4. LOOP TO FIND A SPOT
	var max_attempts = 15 
	for i in range(max_attempts):
		# Rotate the "away" arrow slightly to create a cone
		var random_angle = randf_range(-PI/3, PI/3)
		var spawn_dir = direction_away.rotated(random_angle)
		
		var random_distance = randf_range(min_spawn_radius, max_spawn_radius)
		var target_pos = player.global_position + (spawn_dir * random_distance)
		
		# Only accept the spot if it's safely off-screen
		if not camera_rect.has_point(target_pos):
			return target_pos # We found a safe spot!
			
	# FALLBACK: If the loop fails, force them 1200 pixels straight away from the boss
	return player.global_position + (direction_away * 1200.0)
