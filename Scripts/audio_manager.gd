extends Node

<<<<<<< HEAD
func play_sfx(sound_name: String):
	# if has_node(sound_name):
	# 	get_node(sound_name).play()
	print("Play SFX: ", sound_name)

func play_bgm(track_name: String):
	print("Play BGM: ", track_name)
=======
func _ready() -> void:
	pass 

func player_steps():
	$PlayerSteps.play()

func sword_charge():
	$SwordCharge.play()

func hit1():
	$Hit1.play()

func hit2():
	$Hit2.play()

func hit3():
	$Hit3.play()

func death():
	$Death.play()

func slime_move():
	$SlimeMove.play()

func slime_eating():
	$SlimeEating.play()

func shield_flying():
	$ShieldFlying.play()

func shield_fire():
	$ShieldFire.play()
>>>>>>> ede5de3172291b8eaa500ba112a387e461f504d2
