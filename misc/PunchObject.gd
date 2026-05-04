extends Area3D
class_name PunchObject

# The gun will automatically overwrite this value when it spawns
var punch_force: float = 40.0 

func _ready() -> void:
	# Tell the Area3D to listen for when bodies touch it
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	# Calculate direction FROM this erupting punch TO the body it hit
	var push_dir = (body.global_position - global_position).normalized()
	
	if body is CharacterBody3D and body.is_in_group("Enemy"):
		body.velocity += push_dir * punch_force
		
	elif body is PlayerMovement: # 'PlayerMovement' is your custom class name!
		# Put player in the air state
		if body.currentState != body.MOVESTATES.AIR:
			body.changeState(body.MOVESTATES.AIR)
		
		# Reset downward velocity for consistent jumps
		if push_dir.y < 0 and body.velocity.y < 0:
			body.velocity.y = 0
			
		# Apply the actual force!
		body.applyForce(push_dir * punch_force)
