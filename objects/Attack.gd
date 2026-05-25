extends Move
class_name Attack

# --- NEW: Link your data file here ---
@export var database: AttackDatabase

# --- STATE VARIABLES ---
var attack_timer := 0.0
var current_anim_duration := 0.5
var light_combo_step := 1
var current_attack_meta: Dictionary = {}
var active_hitbox: Hitbox = null
# --- ENGINE VIRTUAL METHODS ---

func check_relevance(input: InputPackage) -> String:
	# If the animation is complete, allow transitions out
	if attack_timer <= 0.0:
		if input.actions.has("light_attack") or input.actions.has("heavy_attack"):
			return "attack" # Chain into combo/next attack instantly
		if input.actions.has("dodge"):
			return "dodge"
		if input.actions.has("jump") and player.is_on_floor():
			return "jump"
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

func update(_input: InputPackage, delta: float):
	attack_timer -= delta
	
	if current_attack_meta.is_empty():
		return

	# Calculate current frame based on standard 30 FPS animation timeline
	var elapsed_time = current_anim_duration - attack_timer
	var current_frame = elapsed_time * 30.0
	
	# --- 1. FORWARD DASH LOGIC ---
	if current_attack_meta.has("forward_dash_speed"):
		var dash_start = current_attack_meta.get("dash_start_frame", 0.0)
		var dash_end = current_attack_meta.get("dash_end_frame", 0.0)
		
		if current_frame >= dash_start and current_frame <= dash_end:
			# Get the direction the player's model is looking (-Z is standard forward in Godot)
			var forward_direction = -player.visuals.global_transform.basis.z.normalized()
			var dash_speed = current_attack_meta.get("forward_dash_speed", 0.0)
			
			# Apply horizontal velocity
			player.velocity.x = forward_direction.x * dash_speed
			player.velocity.z = forward_direction.z * dash_speed
		else:
			# Stop moving forward when outside the dash window
			player.velocity.x = move_toward(player.velocity.x, 0, player.RUN_SPEED * 2.0 * delta)
			player.velocity.z = move_toward(player.velocity.z, 0, player.RUN_SPEED * 2.0 * delta)
	else:
		# Standard attack freeze behavior if no dash property exists
		player.velocity.x = 0
		player.velocity.z = 0
		
	# --- 2. HITBOX FRAME MONITORING ---
	if active_hitbox:
		var start = current_attack_meta.get("start_frame", 0.0)
		var end = current_attack_meta.get("end_frame", 999.0)
		
		if current_frame >= start and current_frame <= end:
			active_hitbox.monitoring = true
		else:
			active_hitbox.monitoring = false

func on_exit_state():
	if active_hitbox: 
		active_hitbox.monitoring = false 
	
	active_hitbox = null
	current_attack_meta.clear()
	
	await get_tree().create_timer(0.8).timeout
	if get_parent().current_state != self:
		light_combo_step = 1

# --- CORE EXECUTION ROUTINE ---

func execute_attack(base_anim: String):
	# Default fallback data structure
	var meta = {
		"damage": 10.0,
		"kb_force": 4.0,
		"kb_dir": Vector3.ZERO,
		"float_time": 0.0,
		"start_frame": 0.0,
		"end_frame": 999.0,
		"is_directional": false,
		"hitbox_node": "RightHandHitbox" 
	}
	
	# --- MODIFIED: Fetch from resource file safely ---
	if database && database.attacks.has(base_anim):
		meta = database.attacks[base_anim].duplicate()
	else:
		print_rich("[color=red]Database Error:[/color] Attack details missing or file unassigned for: %s" % base_anim)
		
	if meta.get("is_directional", false) and player:
		var forward_vector = -player.visuals.global_transform.basis.z.normalized()
		if base_anim == "uppercut":
			meta["kb_dir"] = (forward_vector * 0.4 + Vector3.UP * 1.2).normalized()
		else:
			meta["kb_dir"] = forward_vector

	current_attack_meta = meta
	
	# --- FIXED NODE PATH EXTRACTION ---
	var node_name = meta.get("hitbox_node", "RightHandHitbox")
	var bone_attachment_name = "LeftHand" if "Left" in node_name else "RightHand"
	if node_name == "HeadHitbox": 
		bone_attachment_name = "Head"

	var full_hitbox_path = "Armature/Skeleton3D/" + bone_attachment_name + "/" + node_name
	
	if player and player.has_node(full_hitbox_path):
		active_hitbox = player.get_node(full_hitbox_path) as Hitbox
		# SIGNAL CONNECTION REMOVED FROM HERE
	else:
		print_rich("[color=yellow]Hitbox Warning:[/color] Could not find %s." % full_hitbox_path)
		active_hitbox = null
		
	setup_hitbox_data(meta.damage, meta.kb_force, meta.get("kb_dir", Vector3.ZERO), meta.float_time)

	play_prefixed_animation(base_anim)
	set_attack_window(base_anim)

# --- INDIVIDUAL ATTACK WRAPPERS ---

func play_dodge_counter_attack(dodge_type: String):
	match dodge_type:
		"left": execute_attack("fastestLeftHook")
		"right": execute_attack("fastestRightHook")
		"forward": execute_attack("uppercut")
		"back": execute_attack("chargeAttacke2")

func play_light_combo():
	var base_anim := ""
	
	# Determine which animation plays depending on the active combo step
	match light_combo_step:
		1:
			base_anim = "jab"
			print("Combo Step 1: Jab")
		2:
			base_anim = "jab"
			print("Combo Step 2: Follow-up Jab")
		3:
			base_anim = "jabCross"
			print("Combo Step 3: Jab Cross!")
		4:
			base_anim = "chargePunch"
			print("Combo Step 4: Finisher Charge Punch!!")
			
	# Execute the selected animation
	execute_attack(base_anim)
	
	# Progress to the next step. (Loops back to 1 after completing step 4)
	light_combo_step = (light_combo_step % 4) + 1
	
func play_heavy_attack():
	execute_attack("heavy_attack_1")

# --- DATA MANAGEMENT & UTILITIES ---

func setup_hitbox_data(dmg: float, kb_force: float, kb_dir: Vector3 = Vector3.ZERO, float_duration: float = 0.0):
	if active_hitbox:
		active_hitbox.damage = dmg
		active_hitbox.knockback_force = kb_force
		active_hitbox.knockback_direction = kb_dir 
		if "float_time" in active_hitbox:
			active_hitbox.float_time = float_duration

func set_attack_window(base_name: String):
	var full_name = "Armature|" + base_name
	if anim_player and anim_player.has_animation(full_name):
		current_anim_duration = anim_player.get_animation(full_name).length
	else:
		current_anim_duration = 0.4
	attack_timer = current_anim_duration

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

# --- SIGNAL PROCESSING ---

func _on_hitbox_body_entered(body):
	if body.has_method("take_damage") and active_hitbox:
		var kb_dir = active_hitbox.knockback_direction
		var kb_force = active_hitbox.knockback_force
		var float_time = active_hitbox.float_time if "float_time" in active_hitbox else 0.0
		
		var final_knockback = kb_dir * kb_force
		
		if kb_dir == Vector3.ZERO and player:
			var forward_vector = -player.visuals.global_transform.basis.z.normalized()
			var lift_modifier = Vector3.UP * 0.4
			final_knockback = (forward_vector + lift_modifier).normalized() * kb_force

		body.take_damage(active_hitbox.damage, final_knockback, float_time)
