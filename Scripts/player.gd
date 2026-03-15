extends CharacterBody2D
#NODE
@onready var red_pointer = $Compass/Red
@onready var blue_pointer = $Compass/Blue
@onready var green_pointer = $Compass/Green
@onready var sprite = $PlayerAnimation
#STATS
var attack_stats := PlayerData.attack_stats
var acceleration = 800
var friction = 900
var can_attack: bool = true 
var facing_dir: String = "right" 
#SCENES
var slash_scene: PackedScene = load(Global.SCENES.slash)

func _physics_process(delta: float) -> void:
	# MOVEMENT LOGIC
	var direction = Input.get_vector("left", "right", "up", "down")
	if direction != Vector2.ZERO:
		var speed = PlayerData.current_speed
		# 4-Way Directional ANIMATION Logic
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				facing_dir = "right"
			else:
				facing_dir = "left"
		else:
			if direction.y > 0:
				facing_dir = "down"
			else:
				facing_dir = "up"
		sprite.play("walk_" + facing_dir)
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
	else:
		sprite.play("idle_" + facing_dir)
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()
	
	update_compass(red_pointer, "red")
	update_compass(blue_pointer, "blue")
	update_compass(green_pointer, "green")
	
	if Input.is_action_just_pressed("attack"):
		perform_base_attack()

# UI ARROWS
func update_compass(pointer: Polygon2D, target_color: String):
	var shards = get_tree().get_nodes_in_group("shards")
	var nearest_shard = null
	var shortest_distance = INF
	
	for shard in shards:
		if shard.shard_type == target_color:
			var distance = global_position.distance_to(shard.global_position)
			if distance < shortest_distance:
				shortest_distance = distance
				nearest_shard = shard
	
	if nearest_shard:
		pointer.visible = true
		pointer.look_at(nearest_shard.global_position)
	else:
		pointer.visible = false

# ATTACKS
func perform_base_attack():
	if not can_attack or slash_scene == null:
		return 
	can_attack = false 
	
	var slash = slash_scene.instantiate()
	get_tree().current_scene.add_child(slash)
	
	var current_range = attack_stats["base"]["range"]
	var target = get_closest_enemy(current_range)
	
	if target:
		slash.global_position = global_position
		slash.look_at(target.global_position)
	else:
		slash.global_position = global_position
		var default_dir = Vector2.ZERO
		if facing_dir == "right": default_dir = Vector2.RIGHT
		elif facing_dir == "left": default_dir = Vector2.LEFT
		elif facing_dir == "up": default_dir = Vector2.UP
		elif facing_dir == "down": default_dir = Vector2.DOWN
		slash.rotation = default_dir.angle()

	slash.global_position += Vector2.RIGHT.rotated(slash.rotation) * 10.0
	
	var cooldown_time = attack_stats["base"]["cooldown"]
	await get_tree().create_timer(cooldown_time).timeout
	can_attack = true

func get_closest_enemy(attack_range: float) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	var closest_enemy = null
	var shortest_distance = attack_range 
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= shortest_distance:
			shortest_distance = distance
			closest_enemy = enemy
			
	return closest_enemy
