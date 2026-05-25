extends Area3D
class_name Hitbox

# --- NEW: Drag and drop your HitEffect.tscn into this slot in the Inspector ---
@export var hit_effect_scene: PackedScene

var damage := 10.0
var knockback_force := 0.0
var knockback_direction := Vector3.ZERO
var float_time := 0.0 

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	monitoring = false 

func _on_area_entered(hurtbox: Area3D) -> void:
	print("Hitbox overlapped something! Name: ", hurtbox.name)
	
	var target = hurtbox.get_parent()
	
	if target and target.is_in_group("enemy") and target.has_method("take_damage"):
		var final_kb_dir = knockback_direction
		if final_kb_dir == Vector3.ZERO:
			final_kb_dir = -global_transform.basis.z.normalized()
			
		var final_knockback = final_kb_dir * knockback_force
		target.take_damage(damage, final_knockback, float_time)
		
		# --- NEW: Spawn the hit effect ---
		spawn_hit_effect()

# --- NEW: Function to handle the instantiation ---
func spawn_hit_effect() -> void:
	if hit_effect_scene:
		# 1. Create an instance of the effect scene
		var effect_instance = hit_effect_scene.instantiate() as Node3D
		
		# 2. Add it to the main tree root so it doesn't move around with the player's hand
		get_tree().current_scene.add_child(effect_instance)
		
		# 3. Place it at the global position of this hand hitbox
		effect_instance.global_position = global_position
	else:
		print_rich("[color=yellow]Hitbox Warning:[/color] No hit_effect_scene assigned in the Inspector.")
