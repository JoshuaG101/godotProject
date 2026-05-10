extends Node
class_name SoulsCamera

@export var mouse_sensitivity: float = 0.15
@export var follow_speed: float = 10.0 

@onready var player_camera = $PlayerCamera
@onready var focus_point = $FocusPoint
@onready var camera_nest = $CameraNest

# We use the sibling path because they share the same parent (Steve)
@onready var target_focus_node = $"../CameraFocus" 

var offset_vector = Vector3(0, 2, 5) # Adjust this for your preferred distance
var root_player: CharacterBody3D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	root_player = get_parent() as CharacterBody3D
	
	# This 'if' check prevents the Nil error if the node isn't found
	if target_focus_node:
		focus_point.top_level = true 
		focus_point.global_position = target_focus_node.global_position
	else:
		push_error("CameraFocus node not found! Check your hierarchy.")

func _input(event):
	if event is InputEventMouseMotion:
		# Horizontal rotation
		var angle_y = -event.relative.x * (mouse_sensitivity / 100.0)
		offset_vector = offset_vector.rotated(Vector3.UP, angle_y)
		
		# Vertical rotation
		var side_axis = offset_vector.cross(Vector3.UP).normalized()
		var angle_x = -event.relative.y * (mouse_sensitivity / 100.0)
		
		var new_offset = offset_vector.rotated(side_axis, angle_x)
		# Clamp vertical look so it doesn't flip over the top
		if abs(new_offset.normalized().dot(Vector3.UP)) < 0.92:
			offset_vector = new_offset

func _physics_process(delta):
	if not target_focus_node: return

	# Smoothly move the internal FocusPoint toward Steve's CameraFocus node
	focus_point.global_position = focus_point.global_position.lerp(
		target_focus_node.global_position, 
		follow_speed * delta
	)
	
	# Position the camera relative to that smooth point
	camera_nest.global_position = focus_point.global_position + offset_vector
	player_camera.global_position = camera_nest.global_position
	player_camera.look_at(focus_point.global_position)
