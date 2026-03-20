extends Camera2D

# --- SHAKE SETTINGS ---
var shake_strength: float = 0.0
var shake_fade: float = 7.0 # How fast the shake settles down
var max_shake: float = 120.0 # The absolute cap so the screen doesn't fly away

# --- ZOOM SETTINGS ---
var zoom_tween: Tween
var default_zoom: Vector2

func _ready() -> void:
	# Automatically add any camera using this script to the group!
	add_to_group("Camera")
	randomize()
	default_zoom = zoom

func _process(delta: float) -> void:
	# --- THE TRAUMA SHAKE LOGIC ---
	if shake_strength > 0:
		# Smoothly fade the shake strength back down to 0
		shake_strength = lerpf(shake_strength, 0, shake_fade * delta)
		
		# Apply random jitter based on the current strength
		offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	else:
		# Reset perfectly to center when not shaking
		offset = Vector2.ZERO

# --- JUICY FUNCTIONS TO CALL FROM OTHER SCRIPTS ---

func apply_shake(strength: float) -> void:
	# Add the new shake to the current shake, but cap it so it doesn't break the game
	shake_strength = min(shake_strength + strength, max_shake)

func smooth_zoom(target_zoom: Vector2, duration: float = 0.3) -> void:
	# Kill any old zoom animations if we trigger a new one really fast
	if zoom_tween and zoom_tween.is_running():
		zoom_tween.kill()
		
	# Glide smoothly to the new zoom level using a Sine wave transition
	zoom_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	zoom_tween.tween_property(self, "zoom", target_zoom, duration)
