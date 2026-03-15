extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
var stats =Global.enemies_data.slime
var health = stats.base_health
var slime_color: String 
var current_shard: Node2D = null 
var speed: float
var is_eating: bool = false
var facing_dir: String = "down" # Remembers where to bite!

func _ready():
	# 1. Color the sprites
	add_to_group("slime")
	if slime_color == "red":
		anim.modulate = Color.LIGHT_SALMON
	elif slime_color == "blue":
		anim.modulate = Color.LIGHT_BLUE
	elif slime_color == "green":
		anim.modulate = Color.LIGHT_GREEN
		
	speed = stats["speed"]

func _physics_process(_delta):
	if is_eating:
		return
	var target_shard = get_nearest_matching_shard()

	if target_shard:
		var direction = global_position.direction_to(target_shard.global_position)
		velocity = direction * speed
		# 4 dir movement
		if abs(velocity.x) > abs(velocity.y):
			if velocity.x > 0:
				facing_dir = "right"
			else:
				facing_dir = "left"
		else:
			if velocity.y > 0:
				facing_dir = "down"
			else:
				facing_dir = "up"
		anim.play("move_" + facing_dir)
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		anim.pause()

func get_nearest_matching_shard() -> Node2D:
	var shards = get_tree().get_nodes_in_group("shards")
	var nearest = null
	var shortest_distance = INF
	
	for shard in shards:
		# ONLY care about shards that match the slime's color!
		if shard.shard_type == slime_color:
			var distance = global_position.distance_to(shard.global_position)
			if distance < shortest_distance:
				shortest_distance = distance
				nearest = shard
				
	return nearest

func eat(target_shard: Node2D):
	is_eating = true
	current_shard = target_shard
	anim.pause() 
	# Wait for 1 full second
	await get_tree().create_timer(1.0).timeout
	if not is_instance_valid(self) or not is_inside_tree():
		return
	anim.play("eat_" + facing_dir)
	await anim.animation_finished
	
	if is_instance_valid(target_shard):
		current_shard.queue_free()

	is_eating = false
	current_shard = null

func take_damage(damage_amount: float):
	health -= damage_amount
	print("Slime took damage! Remaining health: ", health)
	
	if health <= 0:
		die()

func die():
	if is_instance_valid(current_shard):
		current_shard.is_claimed = false
	queue_free()
