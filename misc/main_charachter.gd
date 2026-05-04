extends CharacterBody3D

# --- Movement Constants ---
const MOUSE_SENSITIVITY = 0.002
const WALK_SPEED = 12.0
const CROUCH_SPEED = 2.5
const SLIDE_SPEED = 16.0
const SLIDE_STEER_CONTROL = 0.05
const SLIDE_MAX_TIME = 1.0
const JUMP_VELOCITY = 6.0
const FRICTION = 0.15

# --- Air & Wall Mechanics ---
const AIR_ACCEL = 100.0
const MAX_AIR_SPEED = 1.0 
const AIR_BRAKE_STRENGTH = 0.08 
const WALL_BOUNCE_FORCE = 12.0
const WALL_BOUNCE_HEIGHT = 8.0
const MAX_WALL_JUMPS = 1
const LEDGE_CLIMB_BOOST = 6.0

# --- Dash & Momentum ---
const DASH_SPEED = 28.0
const DASH_DURATION = 0.25
const DASH_MOMENTUM_RETAIN = 0.7
const DASH_JUMP_WINDOW = 0.08 # Only allow jumping when dash_timer is below this
const DASH_JUMP_BOOST = 1.4   # Multiplier for horizontal speed on success

# --- State Variables ---
@export var slide_curve: Curve 
var dash_count = 0
var jump_count = 0
var wall_jump_count = 0 
var is_dashing = false
var dash_timer = 0.0
var dash_direction_vector = Vector3.ZERO
var is_crouching = false
var is_sliding = false
var slide_timer = 0.0
var coyote_timer = 0.0
const COYOTE_TIME_WINDOW = 0.15

# --- Nodes ---
@onready var camera_controller = get_node_or_null("Camera_Controller")
@onready var camera = get_node_or_null("Camera_Controller/Camera3D")
@onready var ledge_ray = get_node_or_null("LedgeRay") 
@onready var armature = get_node_or_null("Armature") 
@onready var wall_detector = get_node_or_null("ShapeCast3D")

var base_fov = 75.0
var dash_fov = 95.0
var camera_tilt = 0.0 
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var xform : Transform3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if camera_controller:
			camera_controller.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		if camera:
			camera_tilt -= event.relative.y * MOUSE_SENSITIVITY
			camera_tilt = clamp(camera_tilt, deg_to_rad(-80), deg_to_rad(80))
			camera.rotation.x = camera_tilt

func _process(_delta: float) -> void:
	if camera_controller:
		camera_controller.global_position = camera_controller.global_position.lerp(global_position, 0.2)
	
	if camera:
		var target_fov = dash_fov if is_dashing else base_fov
		# Subtle FOV push when the dash jump window is active
		if is_dashing and dash_timer <= DASH_JUMP_WINDOW:
			target_fov += 5.0
		camera.fov = lerp(camera.fov, target_fov, 0.1)

func _physics_process(delta: float) -> void:
	# Gravity & Ground Reset
	if not is_on_floor():
		velocity.y -= gravity * delta
		coyote_timer -= delta
		if not is_dashing: handle_ledge_climb()
	else:
		dash_count = 0
		jump_count = 0
		wall_jump_count = 0
		coyote_timer = COYOTE_TIME_WINDOW

	# Character Rotation
	if armature and camera_controller:
		var target_rotation_y = camera_controller.rotation.y
		armature.rotation.y = lerp_angle(armature.rotation.y, target_rotation_y, 0.2)

	# DASH STATE HANDLING
	if is_dashing:
		dash_timer -= delta
		velocity.x = dash_direction_vector.x * DASH_SPEED
		velocity.z = dash_direction_vector.z * DASH_SPEED
		velocity.y = 0 
		
		# Ground Dash -> Slide transition
		if is_on_floor() and Input.is_action_pressed("crouch"):
			end_dash_transfer_momentum()
			start_slide()
		
		if dash_timer <= 0:
			end_dash_transfer_momentum()
		
		move_and_slide()
		
		# Check for Dash Jump while in dash state
		if Input.is_action_just_pressed("jump"):
			if dash_timer <= DASH_JUMP_WINDOW:
				# SUCCESSFUL TIMED JUMP
				handle_dash_jump()
				return # Exit dash state early via handle_dash_jump
			else:
				# TOO EARLY: You can add a "thud" sound or visual here
				pass

		return 

	# Normal Input Handlers
	if Input.is_action_just_pressed("dash") and dash_count < 2:
		start_dash()

	handle_crouch_logic(delta)

	if Input.is_action_just_pressed("jump"):
		if not is_on_floor() and check_near_wall() and wall_jump_count < MAX_WALL_JUMPS:
			handle_wall_bounce()
		elif coyote_timer > 0 or jump_count < 1:
			velocity.y = JUMP_VELOCITY
			jump_count += 1
			coyote_timer = 0
			is_sliding = false

	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (camera_controller.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	apply_physics_movement(direction, delta)
	move_and_slide()

	# Visual Alignment
	var floor_norm = $RayCast3D.get_collision_normal() if has_node("RayCast3D") and is_on_floor() else Vector3.UP
	align_with_floor(floor_norm)
	global_transform = global_transform.interpolate_with(xform, 0.3)
	
	handle_animations(input_dir)

# --- Sub-Mechanics ---

func handle_dash_jump():
	is_dashing = false
	# Carry over massive momentum
	velocity.x *= DASH_JUMP_BOOST
	velocity.z *= DASH_JUMP_BOOST
	velocity.y = JUMP_VELOCITY
	jump_count = 1
	apply_camera_shake(0.4)

func check_near_wall() -> bool:
	if wall_detector:
		wall_detector.force_shapecast_update()
		return wall_detector.is_colliding()
	return false

func start_dash():
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	if input_dir.length() < 0.1: return
	
	is_dashing = true
	dash_count += 1
	dash_timer = DASH_DURATION
	apply_camera_shake(0.2)
	dash_direction_vector = (camera_controller.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

func end_dash_transfer_momentum():
	is_dashing = false
	velocity.x *= DASH_MOMENTUM_RETAIN
	velocity.z *= DASH_MOMENTUM_RETAIN

func start_slide():
	is_sliding = true
	slide_timer = SLIDE_MAX_TIME
	is_crouching = true
	update_capsule_height(1.5)

func apply_physics_movement(direction: Vector3, delta: float):
	var horizontal_vel = Vector3(velocity.x, 0, velocity.z)
	
	if is_sliding and is_on_floor():
		slide_timer -= delta
		var slide_progress = clamp(1.0 - (slide_timer / SLIDE_MAX_TIME), 0.0, 1.0)
		var curve_mult = slide_curve.sample(slide_progress) if slide_curve else 0.94
		
		if slide_timer > 0:
			var slide_dir = horizontal_vel.normalized()
			if direction != Vector3.ZERO:
				slide_dir = (slide_dir + (direction * SLIDE_STEER_CONTROL)).normalized()
			var final_vel = slide_dir * (SLIDE_SPEED * curve_mult)
			velocity.x = final_vel.x
			velocity.z = final_vel.z
		else:
			is_sliding = false
		return

	if is_on_floor():
		var target_speed = WALK_SPEED
		if is_crouching: target_speed = CROUCH_SPEED

		if direction != Vector3.ZERO:
			velocity.x = lerp(velocity.x, direction.x * target_speed, FRICTION)
			velocity.z = lerp(velocity.z, direction.z * target_speed, FRICTION)
		else:
			velocity.x = lerp(velocity.x, 0.0, FRICTION)
			velocity.z = lerp(velocity.z, 0.0, FRICTION)
	else:
		if direction != Vector3.ZERO:
			air_accelerate(direction, delta)

func air_accelerate(wish_dir: Vector3, delta: float):
	var horizontal_vel = Vector3(velocity.x, 0, velocity.z)
	var movement_dot = horizontal_vel.dot(wish_dir)
	
	if movement_dot < 0 and horizontal_vel.length() > 0.5:
		velocity.x = lerp(velocity.x, 0.0, AIR_BRAKE_STRENGTH)
		velocity.z = lerp(velocity.z, 0.0, AIR_BRAKE_STRENGTH)
	else:
		var current_speed = movement_dot
		var add_speed = MAX_AIR_SPEED - current_speed
		if add_speed <= 0: return
		var accel_speed = AIR_ACCEL * MAX_AIR_SPEED * delta
		if accel_speed > add_speed: accel_speed = add_speed
		velocity.x += accel_speed * wish_dir.x
		velocity.z += accel_speed * wish_dir.z

func handle_wall_bounce():
	var wall_normal = Vector3.ZERO
	if wall_detector and wall_detector.get_collision_count() > 0:
		wall_normal = wall_detector.get_collision_normal(0)
	else:
		wall_normal = get_wall_normal()
	
	velocity.y = WALL_BOUNCE_HEIGHT
	velocity.x = wall_normal.x * WALL_BOUNCE_FORCE
	velocity.z = wall_normal.z * WALL_BOUNCE_FORCE
	
	wall_jump_count += 1
	jump_count = 1 
	apply_camera_shake(0.3)

func handle_ledge_climb():
	if ledge_ray and ledge_ray.is_colliding() and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY + LEDGE_CLIMB_BOOST
		var forward = -camera_controller.global_transform.basis.z
		velocity += forward * 3.0

func handle_crouch_logic(_delta):
	if Input.is_action_pressed("crouch") and is_on_floor():
		if not is_crouching and Vector3(velocity.x, 0, velocity.z).length() > WALK_SPEED - 1.0:
			start_slide()
		is_crouching = true
		update_capsule_height(1.5)
	else:
		is_crouching = false
		is_sliding = false
		update_capsule_height(2.0)

func update_capsule_height(h):
	if has_node("CollisionShape3D") and $CollisionShape3D.shape is CapsuleShape3D:
		$CollisionShape3D.shape.height = lerp($CollisionShape3D.shape.height, h, 0.2)

func align_with_floor(floor_normal):
	xform = global_transform
	xform.basis.y = floor_normal
	xform.basis.x = -xform.basis.z.cross(floor_normal)
	xform.basis = xform.basis.orthonormalized()

func apply_camera_shake(intensity: float):
	if not camera: return
	camera.h_offset = randf_range(-1, 1) * intensity
	camera.v_offset = randf_range(-1, 1) * intensity
	get_tree().create_timer(0.1).timeout.connect(func():
		if camera: camera.h_offset = 0; camera.v_offset = 0
	)

func handle_animations(input_dir):
	if not has_node("AnimationPlayer"): return
	var anim = $AnimationPlayer
	if is_on_floor():
		if is_sliding: anim.play("slide")
		elif input_dir != Vector2.ZERO: anim.play("run")
		else: anim.play("idle")
	else:
		if velocity.y > 0: anim.play("jump")


func _on_fall_zone_body_entered(body: Node3D) -> void:
	get_tree().change_scene_to_file("res://first_world.tscn")

func bounce(force: float = 15.0):
	velocity.y = force
	# Reset jump counts so the player can still double-jump/dash after hitting the pad
	jump_count = 0
	dash_count = 0
	is_sliding = false
	is_dashing = false
	apply_camera_shake(0.5) # Optional: adds impact feel
