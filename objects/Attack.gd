extends Move
class_name Attack

var attack_timer := 0.0
var current_anim_duration := 0.5
var light_combo_step := 1

# Added tracking variables to safely cache state properties for the hitbox signal
var current_damage := 10.0
var current_kb_force := 4.0
var current_kb_dir := Vector3.ZERO
var current_float_time := 0.0

# Reference to easily manipulate Steve's structural Hitbox node
var hitbox: Hitbox:
	get:
		return player.hitbox if player else null

func check_relevance(input: InputPackage) -> String:
	if attack_timer <= 0.0:
		if input.input_direction != Vector2.ZERO:
			return "run"
		return "idle"
	return "okay"

func on_enter_state():
	player.velocity.x = 0
	player.velocity.z = 0
	
	var input_pkg = player.input_gatherer.gather_input()
	var state_machine = get_parent()
	var dodge_state = state_machine.states.get("dodge")
	
	if dodge_state and dodge_state.dodge_timer > 0:
		play_dodge_counter_attack(dodge_state.type_of_dodge_performed)
		return

	if input_pkg.actions.has("heavy_attack"):
		play_heavy_attack()
	elif input_pkg.actions.has("light_attack"):
		play_light_combo()

func play_dodge_counter_attack(dodge_type: String):
	var base_anim = ""
	
	match dodge_type:
		"left":
			base_anim = "fastestLeftHook"
			setup_hitbox_data(15.0, 5.0, Vector3.ZERO)
		"right":
			base_anim = "fastestRightHook"
			setup_hitbox_data(15.0, 5.0, Vector3.ZERO)
		"forward":
			base_anim = "uppercut"
			# Brought knockback_force down from 14.0 to ~6.0 for a clean ~3ft launch
			# Added a 0.5 second apex float time parameter
			var forward_vector = -player.visuals.global_transform.basis.z.normalized()
			var launch_dir = (forward_vector * 0.4 + Vector3.UP * 1.2).normalized()
			setup_hitbox_data(25.0, 6.0, launch_dir, 0.5) 
		"back":
			base_anim = "chargeAttacke2"
			var launch_dir = -player.visuals.global_transform.basis.z.normalized()
			setup_hitbox_data(35.0, 22.0, launch_dir)
			
	play_prefixed_animation(base_anim)
	set_attack_window(base_anim)

# Sets up parameters locally inside this tracking state instance and applies to active Hitbox node
func setup_hitbox_data(dmg: float, kb_force: float, kb_dir: Vector3 = Vector3.ZERO, float_duration: float = 0.0):
	current_damage = dmg
	current_kb_force = kb_force
	current_kb_dir = kb_dir
	current_float_time = float_duration

	if hitbox:
		hitbox.damage = dmg
		hitbox.knockback_force = kb_force
		hitbox.knockback_direction = kb_dir 
		if "float_time" in hitbox:
			hitbox.float_time = float_duration

func play_light_combo():
	var base_anim = "fastestHeadbutt"
	setup_hitbox_data(10.0, 4.0, Vector3.ZERO) 
	
	play_prefixed_animation(base_anim, 0.05)
	set_attack_window(base_anim)
	light_combo_step = (light_combo_step % 4) + 1

func play_heavy_attack():
	var base_anim = "heavy_attack_1" 
	setup_hitbox_data(20.0, 10.0, Vector3.ZERO) 
	
	play_prefixed_animation(base_anim, 0.1)
	set_attack_window(base_anim)

func set_attack_window(base_name: String):
	var full_name = "Armature|" + base_name
	if anim_player and anim_player.has_animation(full_name):
		current_anim_duration = anim_player.get_animation(full_name).length
	else:
		current_anim_duration = 0.4
	attack_timer = current_anim_duration

func update(_input: InputPackage, delta: float):
	attack_timer -= delta
	
	# --- HITBOX WINDOW ACTIVATION ---
	var elapsed = current_anim_duration - attack_timer
	if elapsed > (current_anim_duration * 0.2) and elapsed < (current_anim_duration * 0.6):
		if hitbox: hitbox.monitoring = true
	else:
		if hitbox: hitbox.monitoring = false

func on_exit_state():
	if hitbox: hitbox.monitoring = false 
	await get_tree().create_timer(0.8).timeout
	if get_parent().current_state != self:
		light_combo_step = 1

func play_prefixed_animation(base_name: String, blend: float = 0.1):
	if not anim_player:
		return
		
	var prefixed_name = "Armature|" + base_name
	
	if anim_player.has_animation(base_name):
		anim_player.play(base_name, blend)
	elif anim_player.has_animation(prefixed_name):
		anim_player.play(prefixed_name, blend)
	else:
		print_rich("[color=yellow]Animation Warning:[/color] Neither '%s' nor '%s' found." % [base_name, prefixed_name])

# Signal handler hooked to the Hitbox's body_entered signal
# Replace the bottom signal inside attack.gd with this implementation
func _on_hitbox_body_entered(body):
	if body.has_method("take_damage") and hitbox:
		# 1. Pull the data dynamically directly from the hitbox properties right at impact frame
		var kb_dir = hitbox.knockback_direction
		var kb_force = hitbox.knockback_force
		var float_time = hitbox.float_time if "float_time" in hitbox else current_float_time
		
		var final_knockback = kb_dir * kb_force
		
		# 2. Safe Fallback handling: If the hitbox directional property is flat/neutral, calculate facing vectors
		if kb_dir == Vector3.ZERO and player:
			var forward_vector = -player.visuals.global_transform.basis.z.normalized()
			var lift_modifier = Vector3.UP * 0.4
			final_knockback = (forward_vector + lift_modifier).normalized() * kb_force

		# 3. Fire into enemy body script
		body.take_damage(hitbox.damage, final_knockback, float_time)
