extends Node2D

@onready var slime_scene: PackedScene = load(Global.SCENES.slime)
@export var player: CharacterBody2D 

const SPAWN_RADIUS: float = 300.0

func _ready():
	$EnemySpawnTimer.timeout.connect(_on_enemy_spawn_timer_timeout)

func _on_enemy_spawn_timer_timeout():
	if slime_scene == null or player == null:
		push_error("Slime Scene or Player is missing in the Inspector!")
		return
		
	var new_slime = slime_scene.instantiate()
	
	# Randomize the Slime Color Preference
	var available_colors = ["red", "blue", "green"]
	var chosen_color = available_colors[randi() % available_colors.size()]
	
	# Assign the color to the variable we made in slime.gd
	new_slime.slime_color = chosen_color 
	
	# Calculate a Random Position around the Player (The "Donut" math)
	var random_angle = randf_range(0.0, TAU) 
	var spawn_offset = Vector2.RIGHT.rotated(random_angle) * SPAWN_RADIUS
	
	# Spawn relative to the player's current moving position
	new_slime.global_position = player.global_position + spawn_offset
	
	add_child(new_slime)
