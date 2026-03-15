extends Node2D

@export var shard_scene: PackedScene = load(Global.SCENES.shards)

# Map boundaries (adjust these based on your final arena size)
var min_spawn_radius: float = 500.0
var max_spawn_radius: float = 2500.0

func _ready():
	$SpawnTimer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout():
	if shard_scene == null:
		push_error("Shard Scene is missing in the Inspector!")
		return
		
	var new_shard = shard_scene.instantiate()
	
	var available_colors = ["red", "blue", "green"]
	var chosen_color = available_colors[randi() % available_colors.size()]
	
	new_shard.shard_type = chosen_color 
	
	# Calculate a Random Position (The "Arena Scatter" math)
	var random_angle = randf_range(0.0, TAU) 
	var random_distance = randf_range(min_spawn_radius, max_spawn_radius) 
	
	# Combine angle and distance to get the final coordinate
	var spawn_pos = Vector2.RIGHT.rotated(random_angle) * random_distance
	
	# Assuming the center of your map is at (0,0)
	new_shard.global_position = spawn_pos
	
	add_child(new_shard)
