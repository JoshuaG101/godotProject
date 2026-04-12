extends Node
class_name PunchGun

@export var ray : RayCast3D
@export var shooter : CharacterBody3D # The player or enemy holding the gun
@export var punch_force : float = 40.0
@export var punch_scene : PackedScene

var target_circle: MeshInstance3D

func _ready() -> void:
	# Tell the raycast to IGNORE the person shooting. 
	# This fixes the circle being stuck on the player!
	if shooter:
		ray.add_exception(shooter)
		
	# Create the visual targeting circle entirely in code
	target_circle = MeshInstance3D.new()
	var disc = CylinderMesh.new()
	disc.top_radius = 0.5
	disc.bottom_radius = 0.5
	disc.height = 0.05 # Make it super flat
	target_circle.mesh = disc
	
	# Give it a glowing, semi-transparent red material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.2, 0.2, 0.5) 
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	target_circle.material_override = mat
	
	add_child(target_circle)
	target_circle.top_level = true
	target_circle.visible = false

func _process(_delta: float) -> void:
	if ray.is_colliding():
		target_circle.visible = true
		var hit_point = ray.get_collision_point()
		var hit_normal = ray.get_collision_normal()
		
		target_circle.global_position = hit_point + (hit_normal * 0.02)
		
		if hit_normal.is_equal_approx(Vector3.DOWN):
			target_circle.quaternion = Quaternion(Vector3.RIGHT, PI)
		else:
			target_circle.quaternion = Quaternion(Vector3.UP, hit_normal)
	else:
		target_circle.visible = false

	if Input.is_action_just_released("shoot"):
		shoot()

func shoot() -> void:
	print("shoot")
	if not ray.is_colliding():
		return
	print("kapow")
		
	var hit_point = ray.get_collision_point()
	var hit_normal = ray.get_collision_normal() 
	
	# ONLY spawn the box. The box will handle the physics!
	spawn_punch_box(hit_point, hit_normal)


func spawn_punch_box(pos: Vector3, normal: Vector3) -> void:
	if not punch_scene:
		push_warning("Punch Scene is not assigned in the inspector!")
		return
		
	var punch_instance = punch_scene.instantiate()
	
	# Pass the gun's force over to the new object before adding it
	if "punch_force" in punch_instance:
		punch_instance.punch_force = punch_force
		
	get_tree().current_scene.add_child(punch_instance)
	
	if normal.is_equal_approx(Vector3.DOWN):
		punch_instance.quaternion = Quaternion(Vector3.RIGHT, PI)
	else:
		punch_instance.quaternion = Quaternion(Vector3.UP, normal)
	
	punch_instance.global_position = pos - (normal * 1.0)
	
	var tween = get_tree().create_tween()
	tween.tween_property(punch_instance, "global_position", pos + (normal * 0.5), 0.1).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_interval(0.2)
	tween.tween_property(punch_instance, "scale", Vector3.ZERO, 0.15)
	tween.tween_callback(punch_instance.queue_free)
