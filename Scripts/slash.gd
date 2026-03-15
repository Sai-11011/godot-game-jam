extends Area2D

var speed: float = 600.0

func _ready():
	$Timer.timeout.connect(_on_timer_timeout)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float):
	var forward_direction = Vector2.RIGHT.rotated(rotation)
	global_position += forward_direction * speed * delta

func _on_timer_timeout():
	queue_free()

func _on_body_entered(body: Node2D):
	# Check if the thing we hit is an enemy
	if body.is_in_group("Enemy"):
		if body.has_method("take_damage"):
			body.take_damage(PlayerData.current_damage)
