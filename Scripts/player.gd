extends CharacterBody2D

@onready var sprite = $PlayerAnimation


var max_speed = 200
var acceleration = 800
var friction = 900

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	if direction != Vector2.ZERO:
		sprite.play("walk")
		velocity = velocity.move_toward(direction * max_speed, acceleration * delta)
	else:
		sprite.play("idle")
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()
