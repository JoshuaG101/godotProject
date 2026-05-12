extends Node3D
class_name SoulsCamera

@export var mouse_sensitivity: float = 0.15
@export var follow_speed: float = 10.0 
@export var min_pitch: float = -45.0 # Max look down
@export var max_pitch: float = 60.0  # Max look up

@onready var player_camera = $PlayerCamera
@onready var focus_point = $FocusPoint
@onready var target_focus_node = $"../CameraFocus" 
@onready var ray_cast = $RayCast3D # Our new collision helper

var offset_vector = Vector3(0, 2, 5) 
var vertical_angle: float = 0.0 

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Make sure the raycast doesn't hit Steve himself
	ray_cast.add_exception(get_parent())

func _input(event):
	if event is InputEventMouseMotion:
		# 1. HORIZONTAL (Left/Right)
		var angle_y = -event.relative.x * (mouse_sensitivity / 100.0)
		offset_vector = offset_vector.rotated(Vector3.UP, angle_y)
		
		# 2. VERTICAL (Up/Down)
		var side_axis = offset_vector.cross(Vector3.UP).normalized()
		
		# Inverting vertical input so Mouse Up = Look Up
		var angle_x = event.relative.y * (mouse_sensitivity / 100.0)
		
		# Clamp logic so the camera doesn't flip over Steve's head
		var change = rad_to_deg(angle_x)
		if vertical_angle + change > min_pitch and vertical_angle + change < max_pitch:
			vertical_angle += change
			offset_vector = offset_vector.rotated(side_axis, angle_x)

func _physics_process(delta):
	if not target_focus_node: return

	# Smooth follow the player
	focus_point.global_position = focus_point.global_position.lerp(
		target_focus_node.global_position, 
		follow_speed * delta
	)
	
	# Update RayCast to point from Focus Point to the desired camera spot
	ray_cast.global_position = focus_point.global_position
	ray_cast.target_position = ray_cast.to_local(focus_point.global_position + offset_vector)
	
	# COLLISION CHECK
	if ray_cast.is_colliding():
		# Move camera to the wall, but push it out slightly (0.2) so it doesn't clip
		var hit_point = ray_cast.get_collision_point()
		var hit_normal = ray_cast.get_collision_normal()
		player_camera.global_position = hit_point + (hit_normal * 0.2)
	else:
		# No wall? Go to the preferred spot
		player_camera.global_position = focus_point.global_position + offset_vector
	
	player_camera.look_at(focus_point.global_position)
