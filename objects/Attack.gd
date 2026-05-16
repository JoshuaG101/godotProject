# attack.gd
extends Move
class_name Attack

var attack_timer := 0.0
var current_anim_duration := 0.5
var light_combo_step := 1

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
	
	# If we successfully canceled an active dodge state into this attack
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
		"right":
			base_anim = "fastestRightHook"
		"forward":
			base_anim = "uppercut"
		"back":
			base_anim = "chargeAttacke2"
			
	play_prefixed_animation(base_anim)
	set_attack_window(base_anim)

func play_light_combo():
	# Looks for: Armature|light_attack_1, Armature|light_attack_2, etc.
	# (Rename the text here if your base files use names like "punch_1")
	var base_anim = "light_attack_" + str(light_combo_step)
	play_prefixed_animation(base_anim, 0.05)
	
	set_attack_window(base_anim)
	light_combo_step = (light_combo_step % 4) + 1

func play_heavy_attack():
	# Default heavy action name (Expand to heavy_attack_ + step if you make a combo sequence for it)
	var base_anim = "heavy_attack_1" 
	play_prefixed_animation(base_anim, 0.1)
	
	set_attack_window(base_anim)

func set_attack_window(base_name: String):
	var full_name = "Armature|" + base_name
	if anim_player and anim_player.has_animation(full_name):
		current_anim_duration = anim_player.get_animation(full_name).length
	else:
		current_anim_duration = 0.4 # Safe fall-back duration if missing
	attack_timer = current_anim_duration

func update(_input: InputPackage, delta: float):
	attack_timer -= delta

func on_exit_state():
	# If they take too long to chain another attack, reset combo sequence back to hit 1
	await get_tree().create_timer(0.8).timeout
	if get_parent().current_state != self:
		light_combo_step = 1

## Automatically adds the prefix and safely tests existence
func play_prefixed_animation(base_name: String, blend: float = 0.1):
	var full_name = "Armature|" + base_name
	if anim_player and anim_player.has_animation(full_name):
		anim_player.play(full_name, blend)
	else:
		print_rich("[color=orange]Attack Warning:[/color] Animation not found: '%s'" % full_name)
