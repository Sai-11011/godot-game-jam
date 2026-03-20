extends Area2D

@export var shard_type: String
@onready var sprite = $Sprite2D # Now pointing to the Sprite2D!

# Preload your friend's textures
var red_tex = load("uid://erw6fso80wek")
var green_tex = load("uid://8rdtmqddhjge")
var blue_tex = load("uid://dw7nc86tymwy6")
var primal_tex = load("uid://b2fxhwvvcvday")

var is_claimed: bool = false 

func _ready():
	add_to_group("Shards")
	
	# Assign the correct sprite
	if shard_type == "red":
		sprite.texture = red_tex
	elif shard_type == "blue":
		sprite.texture = blue_tex
	elif shard_type == "green":
		sprite.texture = green_tex
	elif shard_type == "main_orb":
		sprite.texture = primal_tex
		scale = Vector2(1.0,1.0)
		
	Global.apply_levitation(self, 12.0, 1.0)

func _on_body_entered(body: Node2D):
	if is_claimed:
		return 

	if body.name == "Player":
		is_claimed = true # Lock it!
		
		if shard_type == "main_orb":
			# THE PLAYER GOT THE ORB!
			PlayerData.has_top_orb = true
			PlayerData.is_boss_active = true # Start the boss phase from your enemy spawner!
			# Add any special screen flashes or sounds here!
		else:
			# Normal shard logic
			PlayerData.collect_shard(shard_type) 
			PlayerData.apply_stats(shard_type)
			
		queue_free()
		
	elif body.is_in_group("slime"):
		if body.slime_color == shard_type and not body.is_eating:
			is_claimed = true 
			body.eat(self)
