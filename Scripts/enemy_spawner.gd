extends Node2D

@onready var slime_scene: PackedScene = load(Global.SCENES.slime)
@onready var ranger_scene: PackedScene = load(Global.SCENES.ranger)
# @onready var tank_scene: PackedScene # Commented out until ready

@export var player: CharacterBody2D 

var max_slimes = 30
var max_rangers = 80
# var max_tanks = 50

# Create the "Donut"
var min_spawn_radius: float = 400.0
var max_spawn_radius: float = 1000.0

func _on_enemy_spawn_timer_timeout():
	if player == null:
		return
	
	if randf() < 0.3:
		spawn_ranger()
	else:
		spawn_slime()


# 🧠 NEW HELPER FUNCTION: Finds a safe spot to spawn

func spawn_ranger():
	var current_enemies = get_tree().get_nodes_in_group("Ranger").size()
	if current_enemies >= max_rangers:
		return
		
	var new_ranger = ranger_scene.instantiate()
	new_ranger.global_position = get_valid_spawn_position() # Use the helper function!
	add_child(new_ranger)
	
func spawn_slime():
	var current_enemies = get_tree().get_nodes_in_group("Slime").size()
	if current_enemies >= max_slimes:
		return
		
	var new_slime = slime_scene.instantiate()
	var available_colors = ["red", "blue", "green"]
	new_slime.slime_color = available_colors[randi() % available_colors.size()]
	
	new_slime.global_position = get_valid_spawn_position() # Use the helper function!
	add_child(new_slime)

func get_valid_spawn_position() -> Vector2:
	var max_attempts = 15 # Don't get stuck in an infinite loop!
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	
	# We want to check Layer 1 (where your pillars and arena walls are)
	query.collision_mask = 1 
	
	for i in range(max_attempts):
		# 1. Pick a random coordinate
		var random_angle = randf_range(0.0, TAU) 
		var random_distance = randf_range(min_spawn_radius, max_spawn_radius)
		var spawn_offset = Vector2.RIGHT.rotated(random_angle) * random_distance
		var target_pos = player.global_position + spawn_offset
		
		# 2. Ping the physics engine at this exact coordinate
		query.position = target_pos
		var hits = space_state.intersect_point(query)
		
		# 3. If 'hits' is empty, there is no wall here! Safe to spawn!
		if hits.is_empty():
			return target_pos
			
	# Fallback: If it's too crowded and we fail 15 times, just spawn at the player's feet
	return player.global_position
