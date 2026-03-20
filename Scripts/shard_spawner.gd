extends Node2D

@export var shard_scene: PackedScene = load(Global.SCENES.shards)

# Limit memory usage
var max_shards_on_map: int = 8

var min_spawn_radius: float = 800.0 
var max_spawn_radius: float = 1000.0

var player: Node2D

func _on_spawn_timer_timeout():
	if shard_scene == null:
		push_error("Shard Scene is missing in the Inspector!")
		return
		
	# NEW: Find the player dynamically!
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
		
	# 1. RESOURCE MANAGEMENT: Delete the oldest shard if we hit the limit
	var current_shards = get_tree().get_nodes_in_group("Shards")
	if current_shards.size() >= max_shards_on_map:
		current_shards[0].queue_free()
		
	# 2. Spawn relative to the player
	if player:
		var new_shard = shard_scene.instantiate()
		
		var available_colors = ["red", "blue", "green"]
		var chosen_color = available_colors[randi() % available_colors.size()]
		new_shard.shard_type = chosen_color 
		
		new_shard.global_position = get_valid_spawn_position()
		new_shard.add_to_group("Shards")
		add_child(new_shard)

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
