extends CanvasLayer

@onready var heavy_count = $MarginContainer/StatsContainer/ShardCounters/HeavyCount
@onready var thrust_count = $MarginContainer/StatsContainer/ShardCounters/ThrustCount
@onready var bullet_count = $MarginContainer/StatsContainer/ShardCounters/BulletCount
@onready var health_bar = $MarginContainer/StatsContainer/HealthBar
@onready var player_stats = $MarginContainer/PanelContainer/PlayerStats

@onready var primal_ui = $PrimalChoiceUI
@onready var btn_heavy = $PrimalChoiceUI/VBoxContainer/RedButton
@onready var btn_thrust = $PrimalChoiceUI/VBoxContainer/BlueButton
@onready var btn_bullet = $PrimalChoiceUI/VBoxContainer/GreenButton


func _ready() -> void:
	add_to_group("HUD") 
	visible = false
	primal_ui.hide()
	
	# 1. Connect to the max health signal from your PlayerData Autoload
	PlayerData.max_health_update.connect(update_health_bar)
	btn_heavy.pressed.connect(choose_heavy)
	btn_thrust.pressed.connect(choose_thrust)
	btn_bullet.pressed.connect(choose_bullet)
	# 2. Find the player and connect to their damage signal
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.health_bar_update.connect(update_health_bar)
		
	update_health_bar()
	

func _process(_delta):
	if not PlayerData.get("is_game_started"): 
		return
	
	if not visible:
		visible = true
	
	# 1. Update Attack Counters
	# 1. Update Attack Counters (Shows ∞ if they have over 9000 ammo!)
	heavy_count.text = "Heavy: " +  str(PlayerData.attacks["red"])
	thrust_count.text = "Thrust: " +  str(PlayerData.attacks["blue"])
	bullet_count.text = "Bullet: " + str(PlayerData.attacks["green"])

	# 2. Build the BBCode Stats String
	var stats_text = "[b]PLAYER STATS[/b]\n"
	
	# Add Damage (Red)
	stats_text += "[color=red]Damage:[/color] " + str(snapped(PlayerData.current_damage, 0.1)) + "\n"
	
	# Add Speed (Blue)
	stats_text += "[color=#4287f5]Speed:[/color] " + str(snapped(PlayerData.current_speed, 0.1)) + "\n"
	
	# Add Health (Green)
	stats_text += "[color=#42f566]Max HP:[/color] " + str(PlayerData.max_health)
	
	# Optional: Show a cool glowing indicator if they get the rare orb!
	if PlayerData.has_top_orb:
		stats_text += "\n[pulse freq=1.0 color=#ffd700][b]PRIME HEART ACTIVE[/b][/pulse]"
		
	# 3. Apply it to the RichTextLabel
	player_stats.text = stats_text

func update_health_bar() -> void:
	health_bar.max_value = PlayerData.max_health
	health_bar.value = PlayerData.current_health

# --- THE PRIMAL CHOICE LOGIC ---
func show_primal_choice():
	get_tree().paused = true # Freeze the game!
	primal_ui.show()

func choose_heavy():
	PlayerData.attacks["red"] = 9999
	resume_game()

func choose_thrust():
	PlayerData.attacks["blue"] = 9999
	resume_game()

func choose_bullet():
	PlayerData.attacks["green"] = 9999
	resume_game()

func resume_game():
	primal_ui.hide()
	get_tree().paused = false # Unfreeze the game!
