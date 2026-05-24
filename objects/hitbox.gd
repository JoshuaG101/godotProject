extends Area3D
class_name Hitbox

var damage := 10.0
var knockback_force := 0.0
var knockback_direction := Vector3.ZERO
var float_time := 0.0 # Added so Attack.gd line 166 doesn't crash

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	monitoring = false 

func _on_area_entered(hurtbox: Area3D) -> void:
	print("Hitbox overlapped something! Name: ", hurtbox.name)
	
	# Try checking both the hurtbox itself and its parent for the group/method
	var target = hurtbox.get_parent()
	
	if target and target.is_in_group("enemy") and target.has_method("take_damage"):
		var final_kb_dir = knockback_direction
		if final_kb_dir == Vector3.ZERO:
			final_kb_dir = -global_transform.basis.z.normalized()
			
		# Pass the damage, final knockback vector, and float time to the enemy
		var final_knockback = final_kb_dir * knockback_force
		target.take_damage(damage, final_knockback, float_time)
