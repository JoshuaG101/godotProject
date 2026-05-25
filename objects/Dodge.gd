extends Move
class_name Dodge

@export var DODGE_SPEED := 12.0
@export var DODGE_DURATION := 0.4
@export var IFRAMES: float = 13.0
@export var TARGET_FPS: float = 60.0

var dodge_timer := 0.0
var current_dodge_dir := Vector2.ZERO

static var last_dodge_side := ""      
static var consecutive_dodge_count := 0
var type_of_dodge_performed := "" 

func check_relevance(input: InputPackage) -> String:
	if input.actions.has("light_attack") or input.actions.has("heavy_attack"):
		return "attack"
	
	if dodge_timer <= 0.0:
		# --- DODGE TO SPRINT HANDOFF ---
		# If they keep moving and are still holding the button, transition directly to running
		if input.input_direction != Vector2.ZERO:
			return "run"
		return "idle"
		
	return "okay"

func on_enter_state():
	var input_pkg = player.input_gatherer.gather_input()
	current_dodge_dir = input_pkg.dodge_direction
	
	if current_dodge_dir == Vector2.ZERO:
		current_dodge_dir = Vector2.DOWN 
		
	dodge_timer = DODGE_DURATION
	determine_dodge_and_play_anim()
	
	# --- INVINCIBILITY LOGIC START ---
	player.is_invincible = true
	
	# Calculate duration in seconds (13 / 60 = ~0.216s)
	var iframe_duration = IFRAMES / TARGET_FPS
	
	# Wait for the i-frames to finish, then disable invincibility safely
	get_tree().create_timer(iframe_duration).timeout.connect(
		func(): 
			# Only turn off if we haven't already dodged again or left the state
			if player: 
				player.is_invincible = false
	)

func determine_dodge_and_play_anim():
	var x = current_dodge_dir.x
	var y = current_dodge_dir.y
	
	if abs(x) > abs(y):
		if x > 0:
			process_side_dodge("right")
		else:
			process_side_dodge("left")
	else:
		if y < 0:
			type_of_dodge_performed = "forward"
			play_prefixed_animation("forwardDodge") 
			reset_consecutive_tracking()
		else:
			type_of_dodge_performed = "back"
			play_prefixed_animation("backDodge")
			reset_consecutive_tracking()

func process_side_dodge(side: String):
	type_of_dodge_performed = side
	if last_dodge_side == side:
		consecutive_dodge_count += 1
	else:
		consecutive_dodge_count = 1
		last_dodge_side = side
		
	if side == "right":
		if consecutive_dodge_count >= 2:
			play_prefixed_animation("dodgeRight2") 
		else:
			play_prefixed_animation("dodgeRight")   
	elif side == "left":
		if consecutive_dodge_count >= 2:
			play_prefixed_animation("mixamo_com2")  
		else:
			play_prefixed_animation("mixamo_com")   

func reset_consecutive_tracking():
	last_dodge_side = ""
	consecutive_dodge_count = 0

func update(input: InputPackage, delta: float):
	dodge_timer -= delta
	
	var move_dir = player.calculate_movement_direction(current_dodge_dir)
	player.velocity.x = move_dir.x * DODGE_SPEED
	player.velocity.z = move_dir.z * DODGE_SPEED
	
	player.handle_visuals(delta)

func on_exit_state():
	# Modified: Do not violently kill velocity here if transitioning directly into running.
	# This avoids a jarring stutter frame at the end of the dodge roll.
	pass

func play_prefixed_animation(base_name: String, blend: float = 0.1):
	if not anim_player:
		return
	var prefixed_name = "Armature|" + base_name
	if anim_player.has_animation(base_name):
		anim_player.play(base_name, blend)
	elif anim_player.has_animation(prefixed_name):
		anim_player.play(prefixed_name, blend)
