extends EnemyState
class_name HitLaunchState

var launch_velocity := Vector3.ZERO
var float_timer := 0.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Called automatically by our state_machine.change_state("launch", {"force": Vector3, "time": float})
func on_enter_state(msg: Dictionary = {}) -> void:
	var force_vector = msg.get("force", Vector3.ZERO)
	float_timer = msg.get("time", 0.0)
	
	launch_velocity = force_vector
	enemy.velocity = launch_velocity
	print("AI Launch State Entered!")

func update(delta: float) -> void:
	# PHASE 1: THE INITIAL UPWARD LAUNCH
	if launch_velocity.y > 0:
		launch_velocity.y -= gravity * delta
		enemy.velocity = launch_velocity
		
		if launch_velocity.y <= 0:
			launch_velocity.y = 0

	# PHASE 2: THE APEX FLOAT PHASE
	elif float_timer > 0.0:
		float_timer -= delta
		enemy.velocity = Vector3.ZERO 

	# PHASE 3: FALLING BACK TO EARTH
	else:
		enemy.velocity.y -= gravity * delta
		enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 5.0 * delta)
		enemy.velocity.z = move_toward(enemy.velocity.z, 0.0, 5.0 * delta)
		
		if enemy.is_on_floor():
			# Fall back to patrol/idle once landed
			state_machine.change_state("patrol")

func on_exit_state() -> void:
	launch_velocity = Vector3.ZERO
	float_timer = 0.0
