extends CharacterBody3D

@export var RUN_SPEED := 6.0
@export var GRAVITY := 20.0

@onready var camera_mount = $Camera_mount
@onready var visuals = $Armature
@onready var anim_player = $AnimationPlayer
@onready var input_gatherer = $Input
@onready var state_machine = $Model

func _physics_process(delta: float) -> void:
	# 1. Apply Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	# 2. Get Input and let State Machine handle logic
	var input_pkg = input_gatherer.gather_input()
	state_machine.process_state(input_pkg, delta)
	
	# 3. Final Move
	move_and_slide()

func handle_visuals(delta: float):
	if velocity.length() > 0.1:
		var look_target = global_position + Vector3(velocity.x, 0, velocity.z)
		visuals.look_at(look_target, Vector3.UP)

# Keep your original calculate_movement_direction here so states can call it
func calculate_movement_direction(input_dir: Vector2) -> Vector3:
	var camera_basis: Basis = camera_mount.global_transform.basis
	var forward = camera_basis.z
	var right = camera_basis.x
	forward.y = 0
	right.y = 0
	return (forward * input_dir.y + right * input_dir.x).normalized()
