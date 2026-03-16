extends CanvasLayer

@onready var heavy_count = $MarginContainer/StatsContainer/ShardCounters/HeavyCount
@onready var thrust_count = $MarginContainer/StatsContainer/ShardCounters/ThrustCount
@onready var bullet_count = $MarginContainer/StatsContainer/ShardCounters/BulletCount

func _process(_delta):
	heavy_count.text = "Heavy: " + str(PlayerData.attacks["red"])
	thrust_count.text = "Thrust: " + str(PlayerData.attacks["blue"])
	bullet_count.text = "Bullet: " + str(PlayerData.attacks["green"])
