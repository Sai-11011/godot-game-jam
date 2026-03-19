extends Area2D

@export var cube_color: String 

func take_damage(amount: int):
	get_parent().get_parent().damage_cube(cube_color, amount)

func receive_knockback(_force: Vector2):
	pass # Cubes ignore knockback too!
