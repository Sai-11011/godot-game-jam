extends Node2D

@onready var slime_scene: PackedScene = load(Global.SCENES.slime)
@onready var ranger_scene: PackedScene = load(Global.SCENES.ranger)
@onready var tank_scene: PackedScene

@export var player: CharacterBody2D 
 
#max enemy in map
var max_slimes = 50
var max_rangers = 50
var max_tanks = 50

var spawn_radius: int = 400

func _on_enemy_spawn_timer_timeout():
	if player == null:
		push_error("Player is missing in the Inspector!")
		return
	
	spawn_radius = player.spawn_radius
	spawn_ranger()

func spawn_ranger():
	var current_enemies = get_tree().get_nodes_in_group("Ranger").size()
	if current_enemies >= max_rangers:
		return
	var new_ranger = ranger_scene.instantiate()
	
	var random_angle = randf_range(0.0, TAU) 
	var spawn_offset = Vector2.RIGHT.rotated(random_angle) * spawn_radius
	new_ranger.global_position = player.global_position + spawn_offset
	
	add_child(new_ranger)
	
func spawn_slime():
	var current_enemies = get_tree().get_nodes_in_group("Slime").size()
	if current_enemies >= max_slimes:
		return
	var new_slime = slime_scene.instantiate()
	var available_colors = ["red", "blue", "green"]
	var chosen_color = available_colors[randi() % available_colors.size()]
	
	new_slime.slime_color = chosen_color 
	
	var random_angle = randf_range(0.0, TAU) 
	var spawn_offset = Vector2.RIGHT.rotated(random_angle) * spawn_radius
	new_slime.global_position = player.global_position + spawn_offset
	
	add_child(new_slime)
