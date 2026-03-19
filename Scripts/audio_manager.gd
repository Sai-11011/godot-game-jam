extends Node

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
