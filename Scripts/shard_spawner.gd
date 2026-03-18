extends Node2D

@export var shard_scene: PackedScene = load(Global.SCENES.shards)

# Limit memory usage
var max_shards_on_map: int = 50 

var min_spawn_radius: float = 600.0 
var max_spawn_radius: float = 1000.0

var player: Node2D

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	$SpawnTimer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout():
	if shard_scene == null:
		push_error("Shard Scene is missing in the Inspector!")
		return
		
	# 1. RESOURCE MANAGEMENT: Delete the oldest shard if we hit the limit
	var current_shards = get_tree().get_nodes_in_group("Shards")
	if current_shards.size() >= max_shards_on_map:
		current_shards[0].queue_free() 
		
	# 2. EXPLOIT FIX: Spawn relative to the player
	if player:
		var new_shard = shard_scene.instantiate()
		
		var available_colors = ["red", "blue", "green"]
		var chosen_color = available_colors[randi() % available_colors.size()]
		new_shard.shard_type = chosen_color 
		
		new_shard.global_position = get_valid_spawn_position()
		new_shard.add_to_group("Shards")
		add_child(new_shard)

func get_valid_spawn_position() -> Vector2:
	var max_attempts = 15 # Don't get stuck in an infinite loop!
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	
	# We want to check Layer 1 (where your pillars and arena walls are)
	query.collision_mask = 1 
	
	for i in range(max_attempts):
		var random_angle = randf_range(0.0, TAU) 
		var random_distance = randf_range(min_spawn_radius, max_spawn_radius)
		var spawn_offset = Vector2.RIGHT.rotated(random_angle) * random_distance
		var target_pos = player.global_position + spawn_offset
		
		query.position = target_pos
		var hits = space_state.intersect_point(query)
		
		if hits.is_empty():
			return target_pos
			
	return player.global_position
