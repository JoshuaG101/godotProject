extends Node
class_name HitLaunchState

# Track whether this state is currently overriding enemy physics
var is_active := false

# Internal tracking timers and vectors
var launch_velocity := Vector3.ZERO
var float_timer := 0.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Reference back up to the enemy parent
@onready var enemy: CharacterBody3D = get_parent().get_parent() 

func setup_launch(force: float, direction: Vector3, float_time: float):
	if not enemy:
		return
		
	is_active = true
	float_timer = float_time
	
	# Combine the normalized direction vector with our knockback force magnitude
	launch_velocity = direction * force
	
	# Apply this velocity directly to the enemy's core physics vector right away
	enemy.velocity = launch_velocity
	print("Launch activated! Velocity: ", enemy.velocity, " Float Time: ", float_time)

func _physics_process(delta: float) -> void:
	if not is_active or not enemy:
		return

	# --- PHASE 1: THE INITIAL UPWARD LAUNCH ---
	if launch_velocity.y > 0:
		# Decay the launch impulse using standard gravity over time
		launch_velocity.y -= gravity * delta
		enemy.velocity = launch_velocity
		
		# Once the upward velocity zeroes out, we hit the peak (apex) of the launch
		if launch_velocity.y <= 0:
			launch_velocity.y = 0
			print("Reached peak of launch. Entering apex float phase.")

	# --- PHASE 2: THE APEX FLOAT PHASE ---
	elif float_timer > 0.0:
		float_timer -= delta
		# Hold the enemy perfectly still in the air horizontally and vertically
		enemy.velocity = Vector3.ZERO 
		
		if float_timer <= 0.0:
			print("Float phase finished. Falling back to earth.")

	# --- PHASE 3: FALLING BACK TO EARTH ---
	else:
		# Apply standard gravity until the character hits the floor array
		enemy.velocity.y -= gravity * delta
		
		# Slowly decay horizontal residual knockback velocities if any remain
		enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 5.0 * delta)
		enemy.velocity.z = move_toward(enemy.velocity.z, 0.0, 5.0 * delta)
		
		if enemy.is_on_floor():
			# Reset state properties entirely so normal AI patrol loops resume
			is_active = false
			launch_velocity = Vector3.ZERO
			float_timer = 0.0
			print("Enemy landed safely. Relinquishing physics control.")
