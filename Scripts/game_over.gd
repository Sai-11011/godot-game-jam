extends Control

@onready var main_scene := load(Global.SCENES.main)
@onready var start_scene := load(Global.SCENES.start_ui)

func _ready() -> void:
	PlayerData.reset_data()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_packed(main_scene)

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_packed(start_scene)
