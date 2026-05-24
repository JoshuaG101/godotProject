extends Move
class_name Attack

# --- ATTACK CONFIGURATION DATABASE ---
# Maps animations to their exact frame windows, stats, and specific body-tied hitbox nodes.
const ATTACK_DATABASE := {
	"fastestHeadbutt": {
		"damage": 10.0,
		"kb_force": 4.0,
		"kb_dir": Vector3.ZERO,
		"float_time": 0.0,
		"start_frame": 3.0,
		"end_frame": 8.0,
		"is_directional": false,
		"hitbox_node": "HeadHitbox" # Tied to Head BoneAttachment3D
	},
	"heavy_attack_1": {
		"damage": 20.0,
		"kb_force": 10.0,
		"kb_dir": Vector3.ZERO,
		"float_time": 0.0,
		"start_frame": 8.0,
		"end_frame": 16.0,
		"is_directional": false,
		"hitbox_node": "RightHandHitbox"
	},
	"fastestLeftHook": {
		"damage": 15.0,
		"kb_force": 5.0,
		"kb_dir": Vector3.ZERO,
		"float_time": 0.0,
		"start_frame": 4.0,
		"end_frame": 10.0,
		"is_directional": false,
		"hitbox_node": "LeftHandHitbox" # Tied to Left Hand BoneAttachment3D
	},
	"fastestRightHook": {
		"damage": 15.0,
		"kb_force": 5.0,
		"kb_dir": Vector3.ZERO,
		"float_time": 0.0,
		"start_frame": 4.0,
		"end_frame": 10.0,
		"is_directional": false,
		"hitbox_node": "RightHandHitbox"
	},
	"uppercut": {
		"damage": 25.0,
		"kb_force": 6.0,
		"kb_dir": Vector3.ZERO,
		"float_time": 0.5,
		"start_frame": 6.0,
		"end_frame": 12.0,
		"is_directional": true,
		"hitbox_node": "RightHandHitbox"
	},
	"chargeAttacke2": {
		"damage": 35.0,
		"kb_force": 22.0,
		"kb_dir": Vector3.ZERO,
		"float_time": 0.0,
		"start_frame": 14.0,
		"end_frame": 22.0,
		"is_directional": true,
		"hitbox_node": "RightHandHitbox"
	}
}

# --- STATE VARIABLES ---
var attack_timer := 0.0
var current_anim_duration := 0.5
var light_combo_step := 1

# Tracks properties for the currently executing attack configuration
var current_attack_meta: Dictionary = {}

# Active character-tied hitbox node reference for the current swing frame window
var active_hitbox: Hitbox = null

# --- ENGINE VIRTUAL METHODS ---

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

func update(_input: InputPackage, delta: float):
	attack_timer -= delta
	
	if current_attack_meta.is_empty() or not active_hitbox:
		return

	var elapsed_time = current_anim_duration - attack_timer
	var current_frame = elapsed_time * 30.0
	
	var start = current_attack_meta.get("start_frame", 0.0)
	var end = current_attack_meta.get("end_frame", 999.0)
	
	# --- HITBOX FRAME MONITORING ---
	if current_frame >= start and current_frame <= end:
		active_hitbox.monitoring = true
	else:
		active_hitbox.monitoring = false

func on_exit_state():
	# Clean up and force turn off whatever hitbox was active during execution
	if active_hitbox: 
		active_hitbox.monitoring = false 
	
	active_hitbox = null
	current_attack_meta.clear()
	
	await get_tree().create_timer(0.8).timeout
	if get_parent().current_state != self:
		light_combo_step = 1

# --- CORE EXECUTION ROUTINE ---

func execute_attack(base_anim: String):
	var meta = {
		"damage": 10.0,
		"kb_force": 4.0,
		"kb_dir": Vector3.ZERO,
		"float_time": 0.0,
		"start_frame": 0.0,
		"end_frame": 999.0,
		"is_directional": false,
		"hitbox_node": "RightHandHitbox" # Default fallback node location
	}
	
	if ATTACK_DATABASE.has(base_anim):
		meta = ATTACK_DATABASE[base_anim].duplicate()
		
	# Process custom directional logic relative to local space transform vectors
	if meta.get("is_directional", false) and player:
		var forward_vector = -player.visuals.global_transform.basis.z.normalized()
		if base_anim == "uppercut":
			meta["kb_dir"] = (forward_vector * 0.4 + Vector3.UP * 1.2).normalized()
		else:
			meta["kb_dir"] = forward_vector

	current_attack_meta = meta
	
	# 1. Look up the specific body-tied hitbox node on the player scene structure
	var node_path = meta.get("hitbox_node", "RightHandHitbox")
	if player and player.has_node(node_path):
		active_hitbox = player.get_node(node_path) as Hitbox
		
		# 2. Make sure this specific hitbox is wired to our hit code handler
		if active_hitbox and not active_hitbox.body_entered.is_connected(_on_hitbox_body_entered):
			active_hitbox.body_entered.connect(_on_hitbox_body_entered)
	else:
		# Fallback to structural default property hook if paths are broken
		active_hitbox = player.hitbox if player else null

	# Populate structural data blocks inside the located active hitbox
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
	var base_anim = "fastestHeadbutt"
	execute_attack(base_anim)
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
	# Check against active_hitbox tracking bounds directly
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
