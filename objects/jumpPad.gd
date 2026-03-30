extends Area3D

@export var launch_force: float = 20.0

func _on_body_entered(body: Node3D) -> void:
	print("Something entered!") # Debugging line: check your Output console
	if body.has_method("bounce"):
		print("Body has bounce method! Launching...")
		body.bounce(launch_force)
		
		# Optional: Play a sound or animation here
		# $AnimationPlayer.play("boing")
