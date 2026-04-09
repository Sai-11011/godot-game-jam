extends Node

var last_played = {}

# --- YOUR AUDIO NODES ---
@onready var player_steps := $Player/PlayerSteps
@onready var player_hit := $Player/PlayerGetsHit
@onready var player_green_charge := $Player/BulletCharge
@onready var player_death := $Player/Death

@onready var boss_red_attack := $Boss/BossRedCubeAttack
@onready var boss_blue_attack := $Boss/BossBlueBulletAttack
@onready var boss_movement := $Boss/BossMovement
@onready var boss_hit := $Boss/BossGetsHitts

@onready var ranger_movement := $Ranger/RangerMovement
@onready var ranger_fire := $Ranger/RangerFire
@onready var ranger_take_hit := $Ranger/Hit2

@onready var tank_get_hit := $Tank/TankGetHit

@onready var slime_movement := $Slime/SlimeMove
@onready var slime_eating := $Slime/SlimeEating

# --- BGM NODES ---
@onready var bgm_1 := $BGM/Layer1
@onready var bgm_2 := $BGM/Layer2
@onready var bgm_3 := $BGM/Layer3
@onready var bgm_4 := $BGM/Layer4

# --- OFFSET LOGIC FOR THE BOSS HITS (Tower Hits.mp3) ---
var boss_hit_offsets: Array[float] = [0.0, 3.2, 6.4, 9.6, 12.8, 16.0] # <-- Change these to your actual seconds!
var current_boss_hit_index: int = 0
var single_hit_duration: float = 1.0 # How long one slice of the audio lasts

var current_bgm_phase: int = 0

# ==========================================
# BGM SYSTEMS
# ==========================================

func start_bgm():
	# Play all tracks simultaneously so their beats are permanently synced
	bgm_1.play()
	bgm_2.play()
	bgm_3.play()
	bgm_4.play()
	
	# Instantly mute everything except Layer 1
	bgm_1.volume_db = -16.0
	bgm_2.volume_db = -50.0
	bgm_3.volume_db = -50.0
	bgm_4.volume_db = -50.0
	current_bgm_phase = 1

func switch_bgm_phase(phase: int):
	if current_bgm_phase == phase:
		return
	current_bgm_phase = phase
	
	# create_tween().set_parallel(true) means all volume changes happen at the same time
	var tween = create_tween().set_parallel(true)
	var fade_time = 0.5 # A smooth 2-second crossfade
	
	# First, tell all tracks to fade to silent
	tween.tween_property(bgm_1, "volume_db", -50.0, fade_time)
	tween.tween_property(bgm_2, "volume_db", -50.0, fade_time)
	tween.tween_property(bgm_3, "volume_db", -50.0, fade_time)
	tween.tween_property(bgm_4, "volume_db", -50.0, fade_time)
	
	# Then, override the silent command for the specific track we want to hear!
	if phase == 1:
		tween.tween_property(bgm_1, "volume_db", -16.0, fade_time)
	elif phase == 2:
		tween.tween_property(bgm_2, "volume_db", -16.0, fade_time)
	elif phase == 3:
		tween.tween_property(bgm_3, "volume_db", -16.0, fade_time)
	elif phase == 4:
		tween.tween_property(bgm_4, "volume_db", -16.0, fade_time)

# --- CORE SYSTEMS ---
func can_play(sound_name: String, cooldown: float) -> bool:
	var current_time = Time.get_ticks_msec() / 1000.0
	if not last_played.has(sound_name) or current_time - last_played[sound_name] >= cooldown:
		last_played[sound_name] = current_time
		return true
	return false

func play_at(stream: AudioStream, pos: Vector2, pitch_min := 0.9, pitch_max := 1.1, max_dist := 2000.0, cut_off_time := 0.0):
	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	player.position = pos
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.max_distance = max_dist 
	
	get_tree().current_scene.add_child(player)
	player.play()
	
	# --- THE FIX: KILL THE SOUND EARLY IF REQUESTED ---
	if cut_off_time > 0.0:
		get_tree().create_timer(cut_off_time).timeout.connect(player.queue_free)
	else:
		player.finished.connect(player.queue_free)

# ==========================================
# CALLABLE FUNCTIONS FOR YOUR GAME SCRIPTS
# ==========================================

# --- PLAYER ---
func play_player_steps(pos: Vector2):
	if can_play("player_steps", 0.4):
		# We use play_at now! It will spawn, play, and cut off at 0.4s
		play_at(player_steps.stream, pos, 0.8, 1.2, 400.0, 0.4)

func play_player_hit(pos: Vector2):
	if can_play("player_hit", 0.2):
		play_at(player_hit.stream, pos, 0.9, 1.1)

func play_player_green_charge():
	# UI/Ability sounds usually don't need to be 2D spatial
	player_green_charge.play()

func play_player_death():
	player_death.play()

# --- BOSS ---
func play_boss_red_attack(pos: Vector2):
	play_at(boss_red_attack.stream, pos, 0.9, 1.1)

func play_boss_blue_attack(pos: Vector2):
	play_at(boss_blue_attack.stream, pos, 0.9, 1.1)

func play_boss_movement(pos: Vector2):
	if can_play("boss_move", 0.5):
		play_at(boss_movement.stream, pos, 0.8, 1.0,500,0.4)

func play_boss_hit(pos: Vector2):
	if can_play("boss_hit", 0.1):
		# 1. Grab the current start time
		var start_time = boss_hit_offsets[current_boss_hit_index]
		
		# 2. Cycle to the next hit for next time
		current_boss_hit_index = (current_boss_hit_index + 1) % boss_hit_offsets.size()
		
		# 3. Spawn the player and play it from the offset!
		var player = AudioStreamPlayer2D.new()
		player.stream = boss_hit.stream
		player.position = pos
		player.pitch_scale = randf_range(0.9, 1.1)
		get_tree().current_scene.add_child(player)
		player.play(start_time)
		
		# 4. Stop it exactly when the single hit finishes
		get_tree().create_timer(single_hit_duration).timeout.connect(player.queue_free)

# --- ENEMIES ---
func play_ranger_movement(pos: Vector2):
	if can_play("ranger_move", 0.5):
		play_at(ranger_movement.stream, pos, 0.9, 1.1,400,0.5)

func play_ranger_fire(pos: Vector2):
	play_at(ranger_fire.stream, pos, 0.9, 1.2)

func play_ranger_hit(pos: Vector2):
	if can_play("ranger_hit", 0.1):
		play_at(ranger_take_hit.stream, pos, 0.85, 1.15)

func play_tank_hit(pos: Vector2):
	if can_play("tank_hit", 0.2):
		play_at(tank_get_hit.stream, pos, 0.7, 0.9) # Lower pitch for heavy rock!

func play_slime_movement(pos: Vector2):
	if can_play("slime_move", 0.4):
		play_at(slime_movement.stream, pos, 0.8, 1.2, 350,0.4)

func play_slime_eating(pos: Vector2):
	if can_play("slime_eating", 0.5):
		play_at(slime_eating.stream, pos, 0.9, 1.1)
