extends Node2D

@onready var slime_scene: PackedScene = load(Global.SCENES.slime)
@onready var ranger_scene: PackedScene
@onready var tank_scene: PackedScene

@export var player: CharacterBody2D 

var spawn_radius: int = 400

func _on_enemy_spawn_timer_timeout():
	spawn_radius = player.spawn_radius
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
	var spawn_offset = Vector2.RIGHT.rotated(random_angle) * spawn_radius
	new_slime.global_position = player.global_position + spawn_offset
	
	add_child(new_slime)
