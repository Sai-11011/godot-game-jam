extends CanvasLayer

@onready var heavy_count = $MarginContainer/StatsContainer/ShardCounters/HeavyCount
@onready var thrust_count = $MarginContainer/StatsContainer/ShardCounters/ThrustCount
@onready var bullet_count = $MarginContainer/StatsContainer/ShardCounters/BulletCount
@onready var health_bar = $MarginContainer/StatsContainer/HealthBar
@onready var health_label = $MarginContainer/StatsContainer/HealthBar/HealthLabel

func _ready() -> void:
	# 1. Connect to the max health signal from your PlayerData Autoload
	PlayerData.max_health_update.connect(update_health_bar)
	
	# 2. Find the player and connect to their damage signal
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.health_bar_update.connect(update_health_bar)
		
	update_health_bar()
	
#func update_health_bar() -> void:
	#health_bar.max_value = PlayerData.max_health
	#health_bar.value = PlayerData.current_health

func _process(_delta):
	heavy_count.text = "Heavy: " + str(PlayerData.attacks["red"])
	thrust_count.text = "Thrust: " + str(PlayerData.attacks["blue"])
	bullet_count.text = "Bullet: " + str(PlayerData.attacks["green"])

func update_health_bar() -> void:
	health_bar.max_value = PlayerData.max_health
	health_bar.value = PlayerData.current_health
	
	# This creates the "100 / 100" text format!
	health_label.text = str(PlayerData.current_health) + " / " + str(PlayerData.max_health)
