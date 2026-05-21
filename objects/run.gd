extends Move
class_name Run

func check_relevance(input: InputPackage) -> String:
	if input.actions.has("jump") and player.is_on_floor():
		return "jump"
	if input.actions.has("dodge"):
		return "dodge"
	
	# Check for attacks while running
	if input.actions.has("light_attack") or input.actions.has("heavy_attack"):
		return "attack"
		
	if input.input_direction == Vector2.ZERO:
		return "idle"
	return "okay"

func update(input: InputPackage, delta: float):
	if input.input_direction != Vector2.ZERO:
		# 1. Calculate movement relative to camera
		var move_dir = player.calculate_movement_direction(input.input_direction)
		
		player.velocity.x = move_dir.x * player.RUN_SPEED
		player.velocity.z = move_dir.z * player.RUN_SPEED
		
		# Rotate character visuals towards movement direction (if not locked-on)
		player.handle_visuals(delta)
		
		# 2. Handle running/strafing animations
		if anim_player:
			if player.camera_mount.locked_target:
				# Get movement relative to where the player model is currently facing
				var local_velocity = player.visuals.global_transform.basis.inverse() * player.velocity
				
				# Determine dominant direction based on local X and Z movement
				if abs(local_velocity.x) > abs(local_velocity.z):
					if local_velocity.x < 0:
						_play_animation_fallback(["leftStep", "run"])
					else:
						_play_animation_fallback(["rightStep", "run"])
				else:
					if local_velocity.z < 0:
						_play_animation_fallback(["forwardStep", "run"])
					else:
						# Fallback for backpedaling
						_play_animation_fallback(["forwardStep", "run"]) 
			else:
				# Default standard running when not locked on
				_play_animation_fallback(["run", "Armature|run"])
	else:
		# 3. Friction (No input direction)
		player.velocity.x = move_toward(player.velocity.x, 0, player.RUN_SPEED)
		player.velocity.z = move_toward(player.velocity.z, 0, player.RUN_SPEED)
		
		# Note: Let your 'Idle' state handle playing the idle animation 
		# once check_relevance transitions the player out of this state.

# Helper function to play the first available animation from a list
func _play_animation_fallback(anim_names: Array):
	for anim in anim_names:
		if anim_player.has_animation(anim):
			# Adjust the blend time (0.2) as needed for smooth transitions
			anim_player.play(anim, 0.2)
			return
