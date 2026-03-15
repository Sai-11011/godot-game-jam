extends Area2D

@export var shard_type: String = "red" 

@onready var visual_rect = $ColorRect

func _ready():
	if shard_type == "red":
		visual_rect.color = Color.RED
	elif shard_type == "blue":
		visual_rect.color = Color.BLUE
	elif shard_type == "green":
		visual_rect.color = Color.GREEN
		
	Global.apply_levitation(visual_rect, 8.0, 1.2)

func _on_body_entered(body: Node2D):
	if body.name == "Player":
		PlayerData.collect_shard(shard_type) 
		queue_free()
		
	elif body.is_in_group("Slime"):
		queue_free()
