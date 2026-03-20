extends ScrollContainer

@onready var text_node = $MarginContainer/RichTextLabel
@onready var margin : MarginContainer = $MarginContainer

# Use pixels per second for more natural control
@export_range(10, 500, 5) var scroll_speed : float = 100.0 
@export_range(0, 10000, 0.1) var margin_extra : float = 100.0

func _ready() -> void:
	# 1. Setup Text Styling
	text_node.add_theme_font_size_override("normal_font_size", 28)
	text_node.bbcode_enabled = true
	
	# Fix bold/italic sizes (using your existing logic)
	text_node.text = text_node.text.replace("[b]", "[b][font_size=36]")
	text_node.text = text_node.text.replace("[/b]", "[/font_size][/b]")
	text_node.text = text_node.text.replace("[i]", "[i][font_size=32]")
	text_node.text = text_node.text.replace("[/i]", "[/font_size][/i]")

	# 2. Layout Setup
	var window_height = get_viewport_rect().size.y
	
	# Add padding so credits start and end off-screen
	margin.add_theme_constant_override("margin_top", int(window_height + margin_extra))
	margin.add_theme_constant_override("margin_bottom", int(window_height + margin_extra))
	
	# Reset scroll position to top
	scroll_vertical = 0
	
	# 3. Wait for the engine to finish layout calculations
	await get_tree().process_frame
	
	# 4. Calculate total distance and time
	# The total scrollable range is the content height minus the container height
	var total_scroll_dist = margin.size.y - size.y
	var scroll_duration = total_scroll_dist / scroll_speed
	
	# 5. Execute Tween
	var tween = create_tween()
	tween.tween_property(
		self, 
		"scroll_vertical", 
		total_scroll_dist, 
		scroll_duration
	).set_trans(Tween.TRANS_LINEAR)
	
	# Optional: Emit a signal or change scene when finished
	tween.finished.connect(func(): print("Credits finished!"))
