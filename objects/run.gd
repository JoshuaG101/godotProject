extends Node
class_name Run

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func check_relevance(input : InputPackage):
	if input.action.has("jump") and player.is_on_floor():
		return "jump"
	if input.input_direction == Vector2.ZERO:
		return "idle"
	return "okay"
	
func update(input: Input)
	player.velocity = vel
	player.move_and_slide
	
func velocity_by_input(input : InputPackage, delta : float) -> Vector3:
	var new_velocity = player.velocity
	
	var direction = player.transform.basis * Vector3(input.input_direction.x, 0, input.input_direction.y)).normalized
