# Hitbox.gd
extends Area3D
class_name Hitbox

var damage := 10.0
var knockback_force := 0.0
var knockback_direction := Vector3.ZERO

func _ready() -> void:
	# Connect Godot's built-in area collision signal to our custom function
	area_entered.connect(_on_area_entered)
	# Start disabled so we don't accidentally hit things by just walking into them
	monitoring = false 

func _on_area_entered(hurtbox: Area3D) -> void:
	# Verify the hurtbox belongs to an enemy parent object
	var enemy = hurtbox.get_parent()
	if enemy and enemy.is_in_group("enemy") and enemy.has_method("take_damage"):
		# Calculate dynamic global knockback direction from the player's facing angle if not preset
		var final_kb_dir = knockback_direction
		if final_kb_dir == Vector3.ZERO:
			# Default to pushing directly away from Steve's global forward orientation
			final_kb_dir = -global_transform.basis.z.normalized()
			
		enemy.take_damage(damage, final_kb_dir * knockback_force)
