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

func player_steps():
	if can_play("player_steps", 0.35): # Only let footsteps trigger every 0.35 seconds 
		randomize_pitch($PlayerSteps, 0.85, 1.15)
		$PlayerSteps.play()

func sword_charge():
	if can_play("sword_charge", 0.5):
		$SwordCharge.play()

func hit1():
	randomize_pitch($Hit1, 0.85, 1.15)
	$Hit1.play()

func hit2():
	randomize_pitch($Hit2, 0.85, 1.15)
	$Hit2.play()

func hit3():
	randomize_pitch($Hit3, 0.85, 1.15)
	$Hit3.play()

func death():
	if can_play("death", 0.5):
		$Death.play()

func slime_move():
	# Only allow a globally shared slime movement sound every 0.6 seconds
	# This stops 10 slimes from breaking your eardrums 
	if can_play("slime_move", 0.6):
		randomize_pitch($SlimeMove, 0.8, 1.2)
		$SlimeMove.play()

func slime_eating():
	if can_play("slime_eating", 0.5):
		randomize_pitch($SlimeEating, 0.9, 1.1)
		$SlimeEating.play()

func shield_flying():
	if can_play("shield_flying", 0.5):
		$ShieldFlying.play()

func shield_fire():
	if can_play("shield_fire", 0.2):
		randomize_pitch($ShieldFire, 0.9, 1.1)
		$ShieldFire.play()

func play_random_hit():
	# If your thrust/slash hits 5 enemies instantly,
	# this forces it to only play ONE punchy hit sound rather than 5 distorted layered sounds
	if can_play("hit_global", 0.15):
		var r = randi() % 3
		if r == 0: hit1()
		elif r == 1: hit2()
		else: hit3()
