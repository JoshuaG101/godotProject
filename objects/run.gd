extends Move
class_name Run

# Adjust these speed multipliers as needed
@export var SPRINT_SPEED_MULTIPLIER := 1.6

# Inside Idle.gd
func check_relevance(input: InputPackage) -> String:
	if input.actions.has("light_attack") or input.actions.has("heavy_attack"):
		return "attack"
	if input.actions.has("dodge"):
		return "dodge"
	if input.actions.has("jump") and player.is_on_floor():
		return "jump"
	if input.input_direction != Vector2.ZERO:
		return "run"
		
	return "okay"

func update(input: InputPackage, delta: float):
	if input.input_direction != Vector2.ZERO:
		var move_dir = player.calculate_movement_direction(input.input_direction)
		
		# --- SPRINT VELOCITY CHECK ---
		# Checks if your input gatherer reports the dodge action being held down
		var current_speed = player.RUN_SPEED
		var is_sprinting = input.actions.has("dodge_held") or Input.is_action_pressed("dodge")
		
		if is_sprinting:
			current_speed *= SPRINT_SPEED_MULTIPLIER
		
		player.velocity.x = move_dir.x * current_speed
		player.velocity.z = move_dir.z * current_speed
		
		player.handle_visuals(delta)
		
		# --- ANIMATION SPEED SCALING ---
		if anim_player:
			# Dynamically speed up animation playback when sprinting
			anim_player.speed_scale = SPRINT_SPEED_MULTIPLIER if is_sprinting else 1.0
			
			if player.camera_mount.locked_target:
				var local_velocity = player.visuals.global_transform.basis.inverse() * player.velocity
				if abs(local_velocity.x) > abs(local_velocity.z):
					if local_velocity.x < 0:
						_play_animation_fallback(["leftStep", "run"])
					else:
						_play_animation_fallback(["rightStep", "run"])
				else:
					if local_velocity.z < 0:
						_play_animation_fallback(["forwardStep", "run"])
					else:
						_play_animation_fallback(["forwardStep", "run"]) 
			else:
				# Use custom sprint animation name if you have one, otherwise reuse 'run'
				var run_anims = ["sprint", "Armature|sprint", "run", "Armature|run"] if is_sprinting else ["run", "Armature|run"]
				_play_animation_fallback(run_anims)
	else:
		if anim_player:
			anim_player.speed_scale = 1.0
			
		player.velocity.x = move_toward(player.velocity.x, 0, player.RUN_SPEED)
		player.velocity.z = move_toward(player.velocity.z, 0, player.RUN_SPEED)

func on_exit_state():
	if anim_player:
		anim_player.speed_scale = 1.0

func _play_animation_fallback(anim_names: Array):
	for anim in anim_names:
		if anim_player.has_animation(anim):
			anim_player.play(anim, 0.2)
			return
