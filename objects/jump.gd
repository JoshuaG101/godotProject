extends Move
class_name Jump

const JUMP_VELOCITY = 4.5

func check_relevance(input: InputPackage) -> String:
	if player.is_on_floor():
		input.actions.sort_custom(moves_priority_sort)
		return input.actions[0]
	return "okay"

func on_enter_state():
	player.velocity.y = JUMP_VELOCITY
	if player.anim_player.has_animation("jump"): # Optional
		player.anim_player.play("jump")
