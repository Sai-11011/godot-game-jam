extends Node

# SCENES IDS
const SCENES := {
	"player":"uid://chny23dbskf7g",
	"start_ui":"uid://bw1j84xhoel56",
	"main":"uid://vw6xnynjt3vm",
	"shards":"uid://c2ibw0tgue5r6",
	"shard_spawner":"uid://lpy8gwja1wd3",
	"slime":"uid://rgk1e6hvv0pp",
	"slash":"uid://u1prav8aslt0"
}

# ENEMY DATA 
var  enemies_data := {
	"slime":{
		"speed" : 240,
		"damage" : 0,
		"base_health" : 20
	},
	"eye":{
		"speed" : 220,
		"damage" : 30,
		"base_health" : 60
	},
	"sheild":{
		"speed" : 120,
		"damage" : 10,
		"base_health" : 150
	},
}

# global functions

func apply_levitation(visual_node: CanvasItem, float_distance: float = 8.0, duration: float = 1.0):
	var tween = visual_node.create_tween().set_loops()
	
	var start_y = visual_node.position.y
	
	# Tween UP: Smoothly move the Y position up
	tween.tween_property(visual_node, "position:y", start_y - float_distance, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Tween DOWN: Smoothly move the Y position back to the start
	tween.tween_property(visual_node, "position:y", start_y, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
