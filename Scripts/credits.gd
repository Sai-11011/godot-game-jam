extends ScrollContainer

@onready var text_node = $MarginContainer/RichTextLabel

@export_range(1,70,0.1) var credits_time : float = 1
@export_range(0,10000,0.1) var margin_increment : float = 0

@onready var margin : MarginContainer = $MarginContainer

func _ready() -> void:
	text_node.add_theme_font_size_override("normal_font_size", 28)
	
	# 🔧 Fix bold size via BBCode
	text_node.text = text_node.text.replace("[b]", "[b][font_size=36]")
	text_node.text = text_node.text.replace("[/b]", "[/font_size][/b]")
	
	# 🔧 Fix italic size via BBCode
	text_node.text = text_node.text.replace("[i]", "[i][font_size=32]")
	text_node.text = text_node.text.replace("[/i]", "[/font_size][/i]")
	
	var tween = create_tween()
	
	await get_tree().create_timer(0.01).timeout
	
	var text_box_size = text_node.size.y
	print("Text_box_size: ", text_box_size)
	
	var window_size = DisplayServer.window_get_size().y
	margin.add_theme_constant_override("margin_top", window_size + margin_increment)
	margin.add_theme_constant_override("margin_bottom", window_size + margin_increment)
	
	var scroll_amount = ceil(text_box_size * 3/4 + window_size * 2 + margin_increment)
	
	tween.tween_property(
		self,
		"scroll_vertical",
		scroll_amount,
		credits_time
	)
	
	tween.play()
