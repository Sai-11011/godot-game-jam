extends Area2D

@export var shard_type: String
@onready var visual_rect = $ColorRect

var is_claimed: bool = false 

func _ready():
	add_to_group("Shards")
	if shard_type == "red":
		visual_rect.color = Color.RED
	elif shard_type == "blue":
		visual_rect.color = Color.BLUE
	elif shard_type == "green":
		visual_rect.color = Color.GREEN
	elif shard_type == "main_orb":
		visual_rect.color = Color.WHITE 
		scale = Vector2(2.0, 2.0)
		
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
