extends Area2D

@export var cube_color: String 

func take_damage(amount: int):
	get_parent().get_parent().damage_cube(cube_color, amount)
