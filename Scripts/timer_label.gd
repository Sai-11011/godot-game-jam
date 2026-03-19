extends Label

func _process(_delta: float) -> void:
	# Stop updating the timer if the player dies or the boss is defeated
	if not is_instance_valid(get_tree().get_first_node_in_group("Player")) or not is_instance_valid(get_tree().get_first_node_in_group("Boss")):
		return
		
	# Get the total seconds from your Global PlayerData
	var time_in_seconds = PlayerData.game_time_seconds
	
	# Calculate Minutes and Seconds
	var minutes = int(time_in_seconds / 60.0)
	var seconds = int(time_in_seconds) % 60
	
	# Format it with a leading zero for seconds (e.g., 1:05 instead of 1:5)
	text = str(minutes) + ":" + str(seconds).pad_zeros(2)
