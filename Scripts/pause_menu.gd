extends CanvasLayer

@onready var start_ui = load(Global.SCENES.start_ui)

func _ready():
	# Hide the menu when the game first loads
	hide()

func _unhandled_input(event: InputEvent) -> void:
	# Check if the player pressed the Escape key
	if event.is_action_pressed("ui_cancel"):
		# Don't let them pause during the opening cutscene or victory screen!
		if not PlayerData.get("is_game_started"): 
			return
			
		toggle_pause()

func toggle_pause():
	# Flip the current pause state
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	
	visible = is_paused

func _on_resume_button_pressed() -> void:
	toggle_pause()


func _on_back_button_pressed() -> void:
	get_tree().paused = false
	# Change this to whatever your main menu scene is named
	get_tree().change_scene_to_packed(start_ui)

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	PlayerData.reset_data()
	get_tree().reload_current_scene()
