extends CharacterBody2D

@onready var sprite = $PlayerAnimation

var speed = 200
var acceleration = 800
var friction = 900

# We add this variable to remember the last direction the player moved
var is_facing_right = true 

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	
	if direction != Vector2.ZERO:
		if direction.x > 0:
			sprite.play("walk-right")
			is_facing_right = true
		elif direction.x < 0:
			sprite.play("walk-left")
			is_facing_right = false
			
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
	else:
		if is_facing_right:
			sprite.play("idle-right")
		else:
			sprite.play("idle-left")
			
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()
