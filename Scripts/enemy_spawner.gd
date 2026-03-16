extends Node2D

@onready var slime_scene: PackedScene = load(Global.SCENES.slime)
@export var player: CharacterBody2D 

const SPAWN_RADIUS: float = 400.0

func _ready():
	$EnemySpawnTimer.timeout.connect(_on_enemy_spawn_timer_timeout)

func _on_enemy_spawn_timer_timeout():
	spawn_slime()

func spawn_slime():
	if slime_scene == null or player == null:
		push_error("Slime Scene or Player is missing in the Inspector!")
		return
		
	var new_slime = slime_scene.instantiate()
	var available_colors = ["red", "blue", "green"]
	var chosen_color = available_colors[randi() % available_colors.size()]
	
	new_slime.slime_color = chosen_color 
	
	var random_angle = randf_range(0.0, TAU) 
	var spawn_offset = Vector2.RIGHT.rotated(random_angle) * SPAWN_RADIUS
	
	# Spawn relative to the player's current moving position
	new_slime.global_position = player.global_position + spawn_offset
	
	add_child(new_slime)
