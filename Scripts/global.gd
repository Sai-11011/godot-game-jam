extends Node

# SCENES IDS
const SCENES := {
	"player":"uid://casb6ahlpll03",
	"start_ui":"uid://bw1j84xhoel56",
	"main":"uid://vw6xnynjt3vm",
	"shards":"uid://c2ibw0tgue5r6",
	"shard_spawner":"uid://lpy8gwja1wd3",
	"slime":"uid://rgk1e6hvv0pp",
	"slash":"uid://u1prav8aslt0",
	"bullet":"uid://bbmy6821audd1",
	"ranger":"uid://drgiul5p1eh42",
	"enemy_bullet":"uid://bf41tpk8csayd",
	"game_over":"uid://d2hjnmw6yepcr",
	"tank":"uid://bs6kcurb4niw3",
	"win":"uid://cvocabs0gq8mi",
	"credits":"uid://b27w0j41si1s0",
	"balloon":"uid://c4powygd3cct8"
}

const titan_lore := "uid://b36cod86183hi"

# ENEMY DATA 
var  enemies_data := {
	"slime":{
		"speed" : 130,
		"damage" : 0,
		"base_health" : 20,
		"vision":1000
	},
	"ranger":{
		"speed" : 100,
		"damage" : 10,
		"base_health" : 60,
		"vision":200,#you change it for the best for the ranged attacker
	},
	"tank":{
		"speed" : 50,
		"damage" : 35,
		"base_health" : 160,
		"vision":350,#you change it for the best for the tank and heavy hitter
	},
}

# global functions
# The universal AI function any enemy can call!
func calculate_smart_velocity(enemy_pos: Vector2, nav_agent: NavigationAgent2D, target: Node2D, stats: Dictionary, wander_dir: Vector2) -> Vector2:
	var distance_to_target = INF
	if is_instance_valid(target):
		distance_to_target = enemy_pos.distance_to(target.global_position)
		
	if distance_to_target <= stats["vision"]:
		nav_agent.target_position = target.global_position
		
		if not nav_agent.is_navigation_finished():
			var next_path_pos = nav_agent.get_next_path_position()
			return enemy_pos.direction_to(next_path_pos) * stats["speed"]
			
	return wander_dir * (stats["speed"] * 0.5)

# function for the levitation effect
func apply_levitation(visual_node: CanvasItem, float_distance: float = 8.0, duration: float = 1.0):
	var tween = visual_node.create_tween().set_loops()
	
	var start_y = visual_node.position.y
	
	# Tween UP: Smoothly move the Y position up
	tween.tween_property(visual_node, "position:y", start_y - float_distance, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Tween DOWN: Smoothly move the Y position back to the start
	tween.tween_property(visual_node, "position:y", start_y, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func apply_knockback(source_pos: Vector2, target: Node2D, power: float):
	# Make sure the target actually has the ability to be pushed
	if target.has_method("receive_knockback"):
		# Calculate the angle from the explosion outward to the target
		var push_direction = source_pos.direction_to(target.global_position)
		target.receive_knockback(push_direction * power)
