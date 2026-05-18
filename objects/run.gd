extends Move
class_name Run

func check_relevance(input: InputPackage) -> String:
	if input.actions.has("jump") and player.is_on_floor():
		return "jump"
	if input.actions.has("dodge"):
		return "dodge"
	
	# --- ADD THIS: Check for attacks while running ---
	if input.actions.has("light_attack") or input.actions.has("heavy_attack"):
		return "attack"
		
	if input.input_direction == Vector2.ZERO:
		return "idle"
	return "okay"

func update(input: InputPackage, delta: float):
	if input.input_direction != Vector2.ZERO:
		# Ask the player for direction relative to camera
		var move_dir = player.calculate_movement_direction(input.input_direction)
		
		player.velocity.x = move_dir.x * player.RUN_SPEED
		player.velocity.z = move_dir.z * player.RUN_SPEED
		
		player.handle_visuals(delta)
		
		if anim_player and anim_player.has_animation("Armature|run"):
			anim_player.play("Armature|run", 0.2)
	else:
		# Friction
		player.velocity.x = move_toward(player.velocity.x, 0, player.RUN_SPEED)
		player.velocity.z = move_toward(player.velocity.z, 0, player.RUN_SPEED)
