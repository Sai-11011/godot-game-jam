extends Node

var last_played = {}

# A global cooldown system to stop sound spamming
func can_play(sound_name: String, cooldown: float) -> bool:
	var current_time = Time.get_ticks_msec() / 1000.0
	if not last_played.has(sound_name) or current_time - last_played[sound_name] >= cooldown:
		last_played[sound_name] = current_time
		return true
	return false

# A simple pitch randomizer so it sounds organic, not robotic
func randomize_pitch(audio_node: Node, min_pitch := 0.9, max_pitch := 1.1):
	if "pitch_scale" in audio_node:
		audio_node.pitch_scale = randf_range(min_pitch, max_pitch)

# 🔊 Função base reutilizável (ESSENCIAL)
func play_at(stream: AudioStream, pos: Vector2, pitch_min := 1.0, pitch_max := 1.0):
	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	player.position = pos

	if pitch_min != pitch_max:
		player.pitch_scale = randf_range(pitch_min, pitch_max)

	get_tree().current_scene.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)



func sword_charge(pos: Vector2):
	if can_play("sword_charge", 0.5):
		play_at($SwordCharge.stream, pos)

func hit1(pos: Vector2):
	play_at($Hit1.stream, pos, 0.85, 1.15)

func hit2(pos: Vector2):
	play_at($Hit2.stream, pos, 0.85, 1.15)

func hit3(pos: Vector2):
	play_at($Hit3.stream, pos, 0.85, 1.15)

func death(pos: Vector2):
	if can_play("death", 0.5):
		play_at($Death.stream, pos)

func slime_move(pos: Vector2):
	# Only allow a globally shared slime movement sound every 0.6 seconds
	if can_play("slime_move", 0.6):
		play_at($SlimeMove.stream, pos, 0.8, 1.2)

func slime_eating(pos: Vector2):
	if can_play("slime_eating", 0.5):
		play_at($SlimeEating.stream, pos, 0.9, 1.1)

func shield_flying(pos: Vector2):
	if can_play("shield_flying", 0.5):
		play_at($ShieldFlying.stream, pos)

func shield_fire(pos: Vector2):
	if can_play("shield_fire", 0.2):
		play_at($ShieldFire.stream, pos, 0.9, 1.1)

func play_random_hit(pos: Vector2):
	if can_play("hit_global", 0.15):
		var r = randi() % 3
		if r == 0:
			hit1(pos)
		elif r == 1:
			hit2(pos)
		else:
			hit3(pos)
