extends Node3D

## Configuration
@export var h_sensitivity := 0.003
@export var v_sensitivity := 0.003
@export var h_acceleration := 11.0
@export var v_acceleration := 11.0
@export var cam_v_max_deg := 75.0
@export var cam_v_min_deg := -55.0
@export var lock_on_dist := 20.0

## Nodes
@onready var h_pivot: Node3D = $h
@onready var v_spring_arm: SpringArm3D = $h/v
@onready var player_camera: Camera3D = $h/v/Camera3D

## State
var camrot_h := 0.0
var camrot_v := 0.0
var locked_target: Node3D = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camrot_h = h_pivot.rotation.y
	camrot_v = v_spring_arm.rotation.x

func _input(event: InputEvent) -> void:
	# Free look only if not locked
	if event is InputEventMouseMotion and locked_target == null:
		camrot_h -= event.relative.x * h_sensitivity
		camrot_v -= event.relative.y * v_sensitivity
		
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("lock_on"):
		toggle_lock_on()
		
	# Target Swapping Logic
	if locked_target and is_instance_valid(locked_target):
		if event.is_action_pressed("target_right"):
			swap_target(1)
		elif event.is_action_pressed("target_left"):
			swap_target(-1)

func _physics_process(delta: float) -> void:
	# If target is killed or removed, unlock
	if locked_target and not is_instance_valid(locked_target):
		locked_target = null

	if locked_target:
		# 1. Get position (Adjust Y offset to look at chest/head instead of feet)
		var target_pos = locked_target.global_position
		target_pos.y += 1.5 
		
		var dir_to_enemy = (target_pos - h_pivot.global_position).normalized()
		
		# 2. Calculate Horizontal Angle (Yaw)
		var target_h_rot = atan2(dir_to_enemy.z, -dir_to_enemy.x) #do not change this makes it so that the camera faces the enemy
		
		# 3. Calculate Vertical Angle (Pitch)
		var horizontal_dist = Vector2(dir_to_enemy.x, dir_to_enemy.z).length()
		var target_v_rot = atan2(dir_to_enemy.y, horizontal_dist)
		
		# 4. Interpolate rotation variables
		camrot_h = lerp_angle(camrot_h, target_h_rot, delta * 5.0)
		camrot_v = lerp_angle(camrot_v, -target_v_rot, delta * 5.0)

	# --- APPLY ROTATIONS ---
	camrot_v = clamp(camrot_v, deg_to_rad(cam_v_min_deg), deg_to_rad(cam_v_max_deg))
	
	h_pivot.rotation.y = lerpf(h_pivot.rotation.y, camrot_h, delta * h_acceleration)
	v_spring_arm.rotation.x = lerpf(v_spring_arm.rotation.x, camrot_v, delta * v_acceleration)

func toggle_lock_on():
	if locked_target:
		locked_target = null
	else:
		locked_target = get_closest_enemy()

func get_closest_enemy() -> Node3D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var closest: Node3D = null
	var max_dist = lock_on_dist
	
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < max_dist:
			# Check if enemy is on screen
			if player_camera.is_position_in_frustum(enemy.global_position):
				closest = enemy
				max_dist = dist
	return closest

func swap_target(direction: int):
	var enemies = get_tree().get_nodes_in_group("enemy")
	var candidates = []

	# Find all potential enemies that are on screen and alive
	for enemy in enemies:
		if enemy == locked_target or not is_instance_valid(enemy): 
			continue
		
		if global_position.distance_to(enemy.global_position) < lock_on_dist:
			if player_camera.is_position_in_frustum(enemy.global_position):
				candidates.append(enemy)

	if candidates.is_empty():
		return

	# Sort by screen X coordinate (left to right)
	candidates.sort_custom(func(a, b):
		return player_camera.unproject_position(a.global_position).x < \
			   player_camera.unproject_position(b.global_position).x
	)

	# Find where our current target would be in the horizontal order
	var current_x = player_camera.unproject_position(locked_target.global_position).x
	var next_idx = -1
	
	for i in range(candidates.size()):
		var cand_x = player_camera.unproject_position(candidates[i].global_position).x
		if cand_x > current_x:
			next_idx = i
			break
	
	# Select based on direction
	if direction > 0: # Right
		if next_idx != -1:
			locked_target = candidates[next_idx]
	else: # Left
		# If next_idx is -1, all candidates are to the left, so pick the right-most of them
		# Otherwise pick the one immediately before next_idx
		var prev_idx = next_idx - 1 if next_idx != -1 else candidates.size() - 1
		if prev_idx >= 0:
			locked_target = candidates[prev_idx]
