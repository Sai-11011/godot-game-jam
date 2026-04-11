extends Node2D

# Load the player scene using your Global dictionary
var player_scene: PackedScene = load(Global.SCENES.player)

# Get a reference to your Ysort node exactly as it's named in the scene tree
@onready var ysort_node = $Ysort

func _ready() -> void:
	AudioManager.switch_bgm_phase(2)
	spawn_player()
	

func spawn_player():
	if player_scene == null:
		push_error("Player scene is missing!")
		return
		
	var player_instance = player_scene.instantiate()
	
	# 1. Pick a random angle (TAU is a full 360 degree circle in radians)
	var random_angle = randf_range(0.0, TAU)
	
	# 2. Pick a random distance away from the center (1000 to 4000 pixels)
	var random_radius = randf_range(1000.0, 4000.0)
	
	# 3. Calculate the exact X and Y coordinates using vector math
	var spawn_pos = Vector2.RIGHT.rotated(random_angle) * random_radius
	
	# 4. Set the position 
	player_instance.global_position = spawn_pos
	
	# 5. Add the player specifically to the Ysort node!
	if ysort_node:
		ysort_node.add_child(player_instance)
	else:
		push_error("Ysort node not found! Check your spelling.")
		add_child(player_instance) # Fallback just in case
	
	print("Player spawned at: ", spawn_pos)
