# Player.gd
extends CharacterBody3D

@export var RUN_SPEED := 6.0
@export var GRAVITY := 20.0

@onready var camera_mount: Node3D = $Camera_mount
@onready var visuals: Node3D = $Armature
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var input_gatherer: InputGatherer = $Input
@onready var model: StateMachine = $Model

func _physics_process(delta: float) -> void:
	# Apply Gravity universally
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0

	# Let the state machine drive everything else
	var input_pkg = input_gatherer.gather_input()
	model.process_state(input_pkg, delta)
	
	move_and_slide()

# Helper method so your state nodes can handle turning smoothly
func handle_visuals(delta: float):
	if velocity.x == 0 and velocity.z == 0 and not camera_mount.locked_target:
		return
		
	if camera_mount.locked_target:
		var target_pos = camera_mount.locked_target.global_position
		target_pos.y = global_position.y 
		var target_transform = visuals.global_transform.looking_at(target_pos, Vector3.UP)
		visuals.global_transform = visuals.global_transform.interpolate_with(target_transform, delta * 15.0)
	else:
		var look_target = global_position + Vector3(velocity.x, 0, velocity.z)
		visuals.look_at(look_target, Vector3.UP)

func calculate_movement_direction(input: Vector2) -> Vector3:
	var forward: Vector3
	var right: Vector3
	
	if camera_mount.locked_target:
		var to_enemy = (camera_mount.locked_target.global_position - global_position).normalized()
		to_enemy.y = 0
		forward = to_enemy 
		right = to_enemy.cross(Vector3.UP).normalized()
		return (forward * -input.y + right * input.x).normalized()
	else:
		var camera_basis: Basis = camera_mount.h_pivot.global_transform.basis
		forward = camera_basis.z
		right = camera_basis.x
		forward.y = 0
		right.y = 0
		return (forward * input.y + right * input.x).normalized()
