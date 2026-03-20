extends Node2D

@onready var shard_scene: PackedScene = load(Global.SCENES.shards)

# Limit memory usage
var max_shards_on_map: int = 8

var min_spawn_radius: float = 800.0 
var max_spawn_radius: float = 1000.0

var player: CharacterBody2D

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
	var max_attempts = 15 
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.collision_mask = 1 
	
	# --- NEW: Arena Boundary Limit (6999 - 300 margin) ---
	var max_arena_radius = 6699.0
	
	# Calculate the camera bounds for the SLEEPING phase
	var transform_inv = get_canvas_transform().affine_inverse()
	var viewport_rect = get_viewport_rect()
	var top_left = transform_inv * viewport_rect.position
	var bottom_right = transform_inv * (viewport_rect.position + viewport_rect.size)
	var camera_rect = Rect2(top_left, bottom_right - top_left).grow(150.0)
	
	for i in range(max_attempts):
		var target_pos = Vector2.ZERO
		
		if PlayerData.is_boss_active:
			# BOSS AWAKE
			var random_angle = randf_range(0.0, TAU)
			var boss_phase_distance = randf_range(400.0, 600.0) 
			target_pos = player.global_position + (Vector2.RIGHT.rotated(random_angle) * boss_phase_distance)
				
		else:
			# BOSS SLEEPING
			var direction_away = Vector2.ZERO.direction_to(player.global_position)
			if direction_away == Vector2.ZERO:
				direction_away = Vector2.RIGHT
			
			var random_angle = randf_range(-PI/3, PI/3)
			var random_distance = randf_range(min_spawn_radius, max_spawn_radius)
			var spawn_dir = direction_away.rotated(random_angle)
			target_pos = player.global_position + (spawn_dir * random_distance)
			
		# --- NEW: THE DOG LEASH ---
		# If the math pushed the shard outside the arena, snap it back inside!
		if target_pos.length() > max_arena_radius:
			target_pos = target_pos.limit_length(max_arena_radius)
			
		# Camera & Wall Checks
		if PlayerData.is_boss_active or not camera_rect.has_point(target_pos):
			query.position = target_pos
			var hits = space_state.intersect_point(query)
			if hits.is_empty():
				return target_pos 
					
	# Emergency Fallbacks (Also Leashed!)
	var fallback_pos = Vector2.ZERO
	if PlayerData.is_boss_active:
		fallback_pos = player.global_position + (Vector2.RIGHT.rotated(randf_range(0, TAU)) * 500.0)
	else:
		var direction_away = Vector2.ZERO.direction_to(player.global_position)
		if direction_away == Vector2.ZERO:
			direction_away = Vector2.RIGHT
		fallback_pos = player.global_position + (direction_away * 1200.0)
		
	return fallback_pos.limit_length(max_arena_radius)
