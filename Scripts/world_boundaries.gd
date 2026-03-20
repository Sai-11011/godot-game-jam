extends StaticBody2D

var player: CharacterBody2D 

# Arena Size Settings
@export var inner_radius: float = 6999 
@export var ring_thickness: float = 1000.0 
@export var resolution: int = 64 

# Fades in much closer now!
@export var warning_distance: float = 150.0 

@onready var border_line = $Line2D
var flash_tween: Tween
var is_flashing: bool = false

func _ready() -> void:
	# 1. Add the Arena to a group so the player's dash can shout at it!
	add_to_group("Arena")
	
	player = get_tree().get_first_node_in_group("Player")
	generate_indestructible_arena()
	
	border_line.default_color.a = 0.0
	border_line.width = 10.0 # Base thickness

func generate_indestructible_arena() -> void:
	var line_points = PackedVector2Array()
	var center_of_blocks = inner_radius + (ring_thickness / 2.0)
	var block_length = (TAU * center_of_blocks) / resolution
	
	for i in range(resolution + 1):
		var angle = (i / float(resolution)) * TAU
		var wall_block = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(ring_thickness, block_length * 1.5) 
		wall_block.shape = rect_shape
		wall_block.position = Vector2(cos(angle), sin(angle)) * center_of_blocks
		wall_block.rotation = angle
		add_child(wall_block)
		line_points.append(Vector2(cos(angle), sin(angle)) * inner_radius)
		
	border_line.points = line_points

func _process(delta: float) -> void:
	# --- NEW: Find the player dynamically if they just spawned! ---
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
		
	# If we are currently flashing from a dash impact, ignore normal walking fades!
	if not is_instance_valid(player) or is_flashing: 
		return

	# Assuming your boundary is at (0,0) with the rest of the map
	var distance_to_center = player.global_position.distance_to(Vector2.ZERO)
	var distance_to_wall = abs(inner_radius - distance_to_center)

	# --- HOLOGRAPHIC FADE ---
	if distance_to_wall < warning_distance:
		# Max opacity from walking is 0.7 (70%) so it looks like a soft hologram
		var target_alpha = 0.7 - (distance_to_wall / warning_distance) * 0.7
		border_line.default_color.a = lerp(border_line.default_color.a, max(target_alpha, 0.0), 10.0 * delta)
	else:
		border_line.default_color.a = lerp(border_line.default_color.a, 0.0, 10.0 * delta)

# --- NEW: THE KINETIC IMPACT ANIMATION ---
func flash_barrier():
	# Stop any old animations if we dash into it twice really fast
	if flash_tween and flash_tween.is_running():
		flash_tween.kill()
		
	is_flashing = true
	
	# Instantly spike the brightness and thickness
	border_line.default_color.a = 1.5 # Overbright!
	border_line.width = 40.0 # Huge thickness!
	
	flash_tween = create_tween().set_parallel(true)
	
	# Smoothly snap the thickness back to 10 using an ELASTIC bounce
	flash_tween.tween_property(border_line, "width", 10.0, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	# Fade the color back down to normal
	flash_tween.tween_property(border_line, "default_color:a", 0.7, 0.3)
	
	# When finished, give control back to the _process loop
	flash_tween.chain().tween_callback(func(): is_flashing = false)
