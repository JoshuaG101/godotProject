# dodge.gd
extends Move
class_name Dodge

@export var DODGE_SPEED := 12.0
@export var DODGE_DURATION := 0.4

var dodge_timer := 0.0
var current_dodge_dir := Vector2.ZERO

# Tracking consecutive side-dodges
static var last_dodge_side := ""      # Tracks "left" or "right"
static var consecutive_dodge_count := 0

# Track what type of dodge we did so the Attack state can read it cleanly
var type_of_dodge_performed := "" 

func check_relevance(input: InputPackage) -> String:
	# Cancel directly into an attack if button is pressed mid-dodge
	if input.actions.has("light_attack") or input.actions.has("heavy_attack"):
		return "attack"
	
	if dodge_timer <= 0.0:
		if input.input_direction != Vector2.ZERO:
			return "run"
		return "idle"
		
	return "okay"

func on_enter_state():
	var input_pkg = player.input_gatherer.gather_input()
	current_dodge_dir = input_pkg.dodge_direction
	
	# If the button was pressed by itself (neutral), force a Back Dodge
	if current_dodge_dir == Vector2.ZERO:
		current_dodge_dir = Vector2.DOWN # Vector2.DOWN points backward in screen-space input
		
	dodge_timer = DODGE_DURATION
	determine_dodge_and_play_anim()

func determine_dodge_and_play_anim():
	var x = current_dodge_dir.x
	var y = current_dodge_dir.y
	
	# Determine primary direction based on vector axis strength
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
			play_prefixed_animation("dodgeRight2") # Will play Armature|dodgeRight2
		else:
			play_prefixed_animation("dodgeRight")   # Will play Armature|dodgeRight
	elif side == "left":
		if consecutive_dodge_count >= 2:
			play_prefixed_animation("mixamo_com2")  # Will play Armature|mixamo_com2
		else:
			play_prefixed_animation("mixamo_com")   # Will play Armature|mixamo_com

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
	player.velocity.x = 0
	player.velocity.z = 0

## Automatically adds the prefix and safely tests existence
func play_prefixed_animation(base_name: String, blend: float = 0.1):
	var full_name = "Armature|" + base_name
	if anim_player and anim_player.has_animation(full_name):
		anim_player.play(full_name, blend)
	else:
		print_rich("[color=yellow]Dodge Warning:[/color] Animation not found: '%s'" % full_name)
