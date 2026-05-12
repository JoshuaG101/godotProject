extends Node3D

@export var h_sensitivity := 0.003
@export var v_sensitivity := 0.003
@export var h_acceleration := 11.0
@export var v_acceleration := 11.0
@export var cam_v_max_deg := 75.0
@export var cam_v_min_deg := -55.0

@onready var h_pivot: Node3D = $h
@onready var v_spring_arm: SpringArm3D = $h/v
@onready var player_camera: Camera3D = $h/v/Camera3D

var camrot_h := 0.0
var camrot_v := 0.0
var locked_target: Node3D = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camrot_h = h_pivot.rotation.y
	camrot_v = v_spring_arm.rotation.x

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and locked_target == null:
		camrot_h -= event.relative.x * h_sensitivity
		camrot_v -= event.relative.y * v_sensitivity
		
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("lock_on"):
		toggle_lock_on()

func _physics_process(delta: float) -> void:
	if locked_target:
		var target_pos = locked_target.global_position
		target_pos.y += 10 # Look at chest/head level
		
		# 1. Get vector from the MOUNT to the ENEMY
		# This is the 'True Forward' we want the camera to align with
		var global_mount_pos = h_pivot.global_position
		var dir_to_enemy = (target_pos - global_mount_pos).normalized()
		
		# 2. Calculate Horizontal Angle (Yaw)
		# atan2(-x, -z) is the standard for 'Forward' being -Z
		var target_h_rot = atan2(dir_to_enemy.x, dir_to_enemy.z)
		
		# 3. Calculate Vertical Angle (Pitch)
		var horizontal_dist = Vector2(dir_to_enemy.x, dir_to_enemy.z).length()
		var target_v_rot = atan2(dir_to_enemy.y, horizontal_dist)
		
		# 4. Smoothly update our rotation variables
		camrot_h = lerp_angle(camrot_h, target_h_rot, delta * 5.0)
		# Use -target_v_rot to look 'up' when the enemy is higher
		camrot_v = lerp_angle(camrot_v, -target_v_rot, delta * 5.0)

	# --- APPLY ---
	camrot_v = clamp(camrot_v, deg_to_rad(cam_v_min_deg), deg_to_rad(cam_v_max_deg))
	
	# Apply the rotation to the pivots
	# h_pivot turns left/right, v_spring_arm tilts up/down
	h_pivot.rotation.y = lerpf(h_pivot.rotation.y, camrot_h, delta * h_acceleration)
	v_spring_arm.rotation.x = lerpf(v_spring_arm.rotation.x, camrot_v, delta * v_acceleration)
	
	
	if locked_target:
		# 1. Get the direction from the camera mount to the enemy
		var look_pos = locked_target.global_position
		
		# 2. Horizontal Rotation (Yaw)
		# We want the 'h_pivot' to rotate toward the enemy
		var direction_to_enemy = look_pos - h_pivot.global_position
		var target_h_rot = atan2(-direction_to_enemy.x, -direction_to_enemy.z)
		
		# 3. Vertical Rotation (Pitch)
		# We find the height difference to look up/down
		var vertical_dist = look_pos.y - h_pivot.global_position.y
		var horizontal_dist = Vector2(direction_to_enemy.x, direction_to_enemy.z).length()
		var target_v_rot = atan2(vertical_dist, horizontal_dist)
		
		# 4. Smoothly interpolate the rotation values
		camrot_h = lerp_angle(camrot_h, target_h_rot, delta * 5.0)
		# We use -target_v_rot because typical camera 'X' rotation is inverted
		camrot_v = lerp_angle(camrot_v, -target_v_rot, delta * 5.0)
	
	# --- APPLY ROTATIONS ---
	# Clamp the vertical look so it doesn't flip over
	camrot_v = clamp(camrot_v, deg_to_rad(cam_v_min_deg), deg_to_rad(cam_v_max_deg))
	
	# Apply to the pivots
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
	var max_dist = 20.0 
	
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < max_dist:
			# Check if enemy is actually in front of the camera view
			if player_camera.is_position_in_frustum(enemy.global_position):
				closest = enemy
				max_dist = dist
	return closest
