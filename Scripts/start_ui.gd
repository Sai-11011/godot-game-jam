extends Control 

var main_game_scene: PackedScene = load("res://Scenes/main.tscn") 

# Drag your RichTextLabel in here!
@onready var info_panel = $MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/RichTextLabel 

func _ready():
	# Make sure the controls show up by default when the game boots!
	_on_controls_pressed()

func _on_play_pressed() -> void:
	if Global.has_method("reset_data"): 
		PlayerData.reset_data()
		
	if main_game_scene:
		get_tree().change_scene_to_packed(main_game_scene)

# Connect your "Controls" button to this:
func _on_controls_pressed() -> void:
	info_panel.text = "[center][b]HOW TO PLAY[/b][/center]\n\n[b]WASD[/b] - Move\n[b]Left Click[/b] - Base Slash\n[b]Scroll Wheel[/b] - Zoom Camera\n\n[color=#ff3333][b][E] Heavy Attack[/b][/color] - 5x Damage Buff\n[color=#3333ff][b][Shift] Thrust[/b][/color] - Invincible Dash\n[color=#33ff33][b][Right Click] Bullet[/b][/color] - Ranged Attack\n\n[i]Gather shards to power your abilities. You have exactly 5 minutes before the Titan awakens...[/i]"

# Connect your "Credits" button to this:
func _on_credits_pressed() -> void:
	info_panel.text = "[center][b]CREDITS[/b][/center]\n\n[b]Programming & Design:[/b]\nYour Name Here\n\n[b]Art & Animation:[/b]\nYour Friend's Name Here\n\n[b]Audio:[/b]\nAsset Pack / Composer Name\n\n[i]Created in 48 Hours for the Jam![/i]"

func _on_quit_pressed() -> void:
	get_tree().quit()
