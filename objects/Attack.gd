# attack.gd
extends Move
class_name Attack

var attack_timer := 0.0
var current_anim_duration := 0.5
var light_combo_step := 1

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
	
	# Reset generic knockback preset
	hitbox.knockback_direction = Vector3.ZERO 
	
	match dodge_type:
		"left":
			base_anim = "fastestLeftHook"
			setup_hitbox_data(15.0, 5.0) # Light hooks push away standardly
		"right":
			base_anim = "fastestRightHook"
			setup_hitbox_data(15.0, 5.0)
		"forward":
			base_anim = "uppercut"
			# Launch Enemy upward and slightly forward
			var forward_vector = -player.visuals.global_transform.basis.z.normalized()
			hitbox.knockback_direction = (forward_vector * 0.4 + Vector3.UP * 1.2).normalized()
			setup_hitbox_data(25.0, 14.0)
		"back":
			base_anim = "chargeAttacke2"
			# Strong horizontal launch straight backward away from player orientation
			hitbox.knockback_direction = -player.visuals.global_transform.basis.z.normalized()
			setup_hitbox_data(35.0, 22.0)
			
	play_prefixed_animation(base_anim)
	set_attack_window(base_anim)

func play_light_combo():
	var base_anim = "light_attack_" + str(light_combo_step)
	setup_hitbox_data(10.0, 4.0) # Consistent clean light hits
	
	play_prefixed_animation(base_anim, 0.05)
	set_attack_window(base_anim)
	light_combo_step = (light_combo_step % 4) + 1

func play_heavy_attack():
	var base_anim = "heavy_attack_1" 
	setup_hitbox_data(20.0, 10.0) # Staggering heavy swing
	
	play_prefixed_animation(base_anim, 0.1)
	set_attack_window(base_anim)

func setup_hitbox_data(dmg: float, kb_force: float):
	if hitbox:
		hitbox.damage = dmg
		hitbox.knockback_force = kb_force

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
	# Automatically activates the hitbox data during active hitting swing frames 
	# (e.g., active from 20% into the move until 60% through the animation length)
	var elapsed = current_anim_duration - attack_timer
	if elapsed > (current_anim_duration * 0.2) and elapsed < (current_anim_duration * 0.6):
		if hitbox: hitbox.monitoring = true
	else:
		if hitbox: hitbox.monitoring = false

func on_exit_state():
	if hitbox: hitbox.monitoring = false # Safeguard closure
	await get_tree().create_timer(0.8).timeout
	if get_parent().current_state != self:
		light_combo_step = 1

func play_prefixed_animation(base_name: String, blend: float = 0.1):
	var full_name = "Armature|" + base_name
	if anim_player and anim_player.has_animation(full_name):
		anim_player.play(full_name, blend)
