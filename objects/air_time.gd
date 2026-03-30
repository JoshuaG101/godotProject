extends PlayerState

func physics_update(delta):
	var dir = player.get_input_direction()
	player.air_accelerate(dir, delta)
	
	if player.is_on_floor():
		state_machine.transition_to("Idle")
	
	if Input.is_action_just_pressed("jump"):
		if player.is_on_wall_only() and player.wall_jump_count < player.MAX_WALL_JUMPS:
			state_machine.transition_to("WallJump")
		elif player.jump_count < player.MAX_JUMPS:
			state_machine.transition_to("Jump")
