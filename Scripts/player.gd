extends CharacterBody2D

@onready var sprite = $PlayerAnimation
var acceleration = 800
var friction = 900

# We add this variable to remember the last direction the player moved
var is_facing_right = true 

@onready var red_pointer = $Compass/Red
@onready var blue_pointer = $Compass/Blue
@onready var green_pointer = $Compass/Green

func update_compass(pointer: Polygon2D, target_color: String):
	var shards = get_tree().get_nodes_in_group("shards")
	
	# DEBUG PRINT 1: Are they in the group?
	if target_color == "red": # Only print once per frame to avoid spam
		print("Total shards found in group: ", shards.size())
	
	var nearest_shard = null
	var shortest_distance = INF
	
	for shard in shards:
		if shard.shard_type == target_color:
			var distance = global_position.distance_to(shard.global_position)
			if distance < shortest_distance:
				shortest_distance = distance
				nearest_shard = shard
				
	if nearest_shard:
		# DEBUG PRINT 2: Did we find the right color?
		print("Found a ", target_color, " shard! Pointing to it.")
		pointer.visible = true
		pointer.look_at(nearest_shard.global_position)
	else:
		pointer.visible = false

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	if direction != Vector2.ZERO:
		var speed = PlayerData.current_speed
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
	
	# Continuously update all three pointers
	update_compass(red_pointer, "red")
	update_compass(blue_pointer, "blue")
	update_compass(green_pointer, "green")
