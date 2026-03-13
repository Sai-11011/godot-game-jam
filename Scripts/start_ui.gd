extends Control

@onready var main_scene := load(Global.SCENES.main)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_packed(main_scene)
