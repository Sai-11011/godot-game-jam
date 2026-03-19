extends Control 

var main_game_scene: PackedScene = load("res://Scenes/main.tscn") 

# Drag your new ControlsOverlay panel here!
@onready var controls_overlay = $ControlsOverlay 
@onready var info_panel = $ControlsOverlay/MarginContainer/VBoxContainer/RichTextLabel

func _ready():
	# Ensure the overlay is hidden when the game starts
	controls_overlay.hide()

func _on_play_pressed() -> void:
	if Global.has_method("reset_data"): 
		PlayerData.reset_data()
	if main_game_scene:
		get_tree().change_scene_to_packed(main_game_scene)

# Connect your new BackButton's pressed signal to this:
func _on_back_button_pressed() -> void:
	# Hide the controls page and go back to the menu!
	controls_overlay.hide()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_intro_pressed() -> void:
	controls_overlay.show()
