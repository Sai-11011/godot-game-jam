extends Area2D

@export var shard_type: String = "red" 
@onready var visual_rect = $ColorRect

var is_claimed: bool = false 

func _ready():
	add_to_group("shards")
	if shard_type == "red":
		visual_rect.color = Color.RED
	elif shard_type == "blue":
		visual_rect.color = Color.BLUE
	elif shard_type == "green":
		visual_rect.color = Color.GREEN
		
	Global.apply_levitation(visual_rect, 12.0, 1.0)

func _on_body_entered(body: Node2D):
	if is_claimed:
		return 

	if body.name == "Player":
		is_claimed = true # Lock it!
		PlayerData.collect_shard(shard_type) 
		PlayerData.apply_stats()
		queue_free()
		
	elif body.is_in_group("slime"):
		if body.slime_color == shard_type and not body.is_eating:
			is_claimed = true 
			
			body.eat(self)
