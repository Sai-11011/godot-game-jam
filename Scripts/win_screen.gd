extends Control

@onready var time_label = $CenterContainer/VBoxContainer/TimeLabel
var main_menu_scene: String = Global.SCENES.start_ui # Update this path if needed!

func _ready():
	# Format the final time perfectly
	var time_in_seconds = PlayerData.game_time_seconds
	var minutes = int(time_in_seconds / 60.0)
	var seconds = int(time_in_seconds) % 60
	
	time_label.text = "Final Time: " + str(minutes) + ":" + str(seconds).pad_zeros(2)

func _on_menu_button_pressed() -> void:
	if Global.has_method("reset_data"): 
		PlayerData.reset_data()
	get_tree().change_scene_to_file(main_menu_scene)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
