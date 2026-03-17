extends CharacterBody2D

@onready var sprites :={
	"up":load("uid://52sbav1hpplj"),
	"down": load("uid://bbn1o4ovcxkc4"),
	"left":load("uid://bl1dl2qoo1riw"),
	"right":load("uid://bu4gtyefhsdku")
}

@onready var sprite := $Sprite2D
@onready var nav_agent = $NavigationAgent2D
@onready var enemy_bullet_scene :PackedScene = load(Global.SCENES.enemy_bullet)

var can_shoot: bool = true
var shoot_cooldown: float = 1.5
var knockback_velocity: Vector2 = Vector2.ZERO
var stats : Dictionary = Global.enemies_data.ranger
var health : int = stats.base_health
var speed : int = stats.speed
var damage : int = stats.damage
var vision : int = stats.vision
var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var is_attacking := false
var facing_dir := "down"
var player

func _ready() -> void:
	add_to_group("Enemy")
	add_to_group("Ranger")
	pick_new_wander_direction()
	Global.apply_levitation(self, 16.0, 1.0)

func _physics_process(delta: float) -> void:
	if knockback_velocity != Vector2.ZERO:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 3000 * delta)
	elif is_attacking :
		velocity = Vector2.ZERO
	else:
		player = get_tree().get_first_node_in_group("Player")
		if player:
			var distance = global_position.distance_to(player.global_position)
			
			if distance < 100:
				# Player is too close! Back away to maintain distance
				var direction_away = player.global_position.direction_to(global_position)
				velocity = direction_away * speed
			elif distance <= 150:
				# Perfect shooting range (100 - 150px). Stop moving and shoot!
				velocity = Vector2.ZERO
				if can_shoot:
					shoot_at_player(player.global_position)
			elif distance <= vision:
				# Player is too far (outside 150px), walk towards them
				#nav_agent.target_position = player.global_position
				#var next_path_pos = nav_agent.get_next_path_position()
				var direction = global_position.direction_to(player.global_position)
				velocity = direction * speed
			else:
				# Player out of vision, wander
				wander_timer -= delta
				if wander_timer <= 0:
					pick_new_wander_direction()
				velocity = wander_direction * (speed * 0.5)
		if velocity != Vector2.ZERO:
			if abs(velocity.x) > abs(velocity.y):
				if velocity.x > 0: facing_dir = "right"
				else: facing_dir = "left"
			else:
				if velocity.y > 0: facing_dir = "down"
				else: facing_dir = "up"
			sprite.texture = sprites[facing_dir]
	move_and_slide()

func pick_new_wander_direction():
	wander_direction = Vector2.RIGHT.rotated(randf() * TAU)
	wander_timer = randf_range(1.0, 3.0)
	
func shoot_at_player(target_pos: Vector2):
	can_shoot = false
	is_attacking = true
	
	var aim_direction = global_position.direction_to(target_pos)
	if abs(aim_direction.x) > abs(aim_direction.y):
		if aim_direction.x > 0: facing_dir = "right"
		else: facing_dir = "left"
	else:
		if aim_direction.y > 0: facing_dir = "down"
		else: facing_dir = "up"
	sprite.texture = sprites[facing_dir]
	
	var bullet = enemy_bullet_scene.instantiate()
	get_parent().add_child(bullet) # ADD IT FIRST!
	
	# THEN do all the position and rotation math
	bullet.global_position = global_position
	bullet.direction = global_position.direction_to(target_pos)
	bullet.look_at(player.global_position + Vector2(0, 20))
	
	await get_tree().create_timer(shoot_cooldown).timeout
	
	can_shoot = true
	is_attacking = false

func receive_knockback(force_vector: Vector2):
	knockback_velocity = force_vector

func take_damage(damage_amount: int):
	health -= damage_amount
	if health <= 0:
		die()

func die():
	queue_free()
