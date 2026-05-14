extends Move
class_name Run

const SPEED = 6.0 # Matches Steve's RUN_SPEED

func update(input: InputPackage, delta: float):
	if input.input_direction != Vector2.ZERO:
		# Calculate direction using your existing player method
		var move_dir = player.calculate_movement_direction(input.input_direction)
		player.velocity.x = move_dir.x * SPEED
		player.velocity.z = move_dir.z * SPEED
		
		# Handle the visual rotation (looking where he moves)
		player.handle_visuals(delta)
		
		if player.anim_player.has_animation("Armature|run"):
			player.anim_player.play("Armature|run", 0.2)
	else:
		# This prevents the "infinite slide" when in the Run state with no input
		player.velocity.x = move_toward(player.velocity.x, 0, SPEED)
		player.velocity.z = move_toward(player.velocity.z, 0, SPEED)
