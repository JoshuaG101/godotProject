extends CharacterBody3D

## Configuration
@export var RUN_SPEED := 6.0
@export var GRAVITY := 20.0

## Nodes
@onready var camera_mount: Node3D = $Camera_mount
@onready var visuals: Node3D = $Armature
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var inpute_gatherer = $Input
@onready var model = $Model

func _physics_process(delta: float) -> void:
	# 1. Handle Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0

	# 2. Get Movement Input
	var input_dir := Input.get_vector("left", "right", "up", "down")
	
	if input_dir != Vector2.ZERO:
		var movement_dir = calculate_movement_direction(input_dir)
		velocity.x = movement_dir.x * RUN_SPEED
		velocity.z = movement_dir.z * RUN_SPEED
		
		# 3. Handle Visual Orientation
		if camera_mount.locked_target:
			var target_pos = camera_mount.locked_target.global_position
			target_pos.y = global_position.y 
			# Smoothly rotate to face enemy
			var target_transform = visuals.global_transform.looking_at(target_pos, Vector3.UP)
			visuals.global_transform = visuals.global_transform.interpolate_with(target_transform, delta * 15.0)
		else:
			var look_target = global_position + Vector3(velocity.x, 0, velocity.z)
			visuals.look_at(look_target, Vector3.UP)
		
		# 4. Handle Animations
		if anim_player.has_animation("Armature|run"):
			anim_player.play("Armature|run", 0.2)
	else:
		velocity.x = move_toward(velocity.x, 0, RUN_SPEED)
		velocity.z = move_toward(velocity.z, 0, RUN_SPEED)
		
		if camera_mount.locked_target:
			var target_pos = camera_mount.locked_target.global_position
			target_pos.y = global_position.y
			visuals.look_at(target_pos, Vector3.UP)
		
		if anim_player.has_animation("idle"):
			anim_player.play("idle", 0.3)

	# 5. Apply Movement
	move_and_slide()

func calculate_movement_direction(input: Vector2) -> Vector3:
	var forward: Vector3
	var right: Vector3
	
	if camera_mount.locked_target:
		# --- CIRCULAR STRAFE LOGIC ---
		# Vector pointing from player to enemy
		var to_enemy = (camera_mount.locked_target.global_position - global_position).normalized()
		to_enemy.y = 0 # Keep movement horizontal
		
		# 'Forward' input moves us along the line to the enemy
		forward = to_enemy 
		# 'Right' input moves us perpendicular to that line (The Circle)
		right = to_enemy.cross(Vector3.UP).normalized()
		
		# input.y is -1 for Up, +1 for Down. 
		# Multiplying by -input.y makes 'Up' move TOWARD the enemy.
		return (forward * -input.y + right * input.x).normalized()
	else:
		# --- STANDARD CAMERA RELATIVE LOGIC ---
		var camera_basis: Basis = camera_mount.h_pivot.global_transform.basis
		forward = camera_basis.z
		right = camera_basis.x
		
		forward.y = 0
		right.y = 0
		return (forward * input.y + right * input.x).normalized()
