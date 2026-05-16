# Input.gd
extends Node
class_name InputGatherer

func gather_input() -> InputPackage:
	var new_input = InputPackage.new()
	new_input.input_direction = Input.get_vector("left", "right", "up", "down")
	
	# --- Attacks ---
	var is_blocking = Input.is_action_pressed("block") # Hold block modifier
	
	if Input.is_action_just_pressed("punch"):
		if is_blocking:
			new_input.actions.append("heavy_attack")
		else:
			new_input.actions.append("light_attack")
			
	# --- Dodge ---
	if Input.is_action_just_pressed("dodge"):
		new_input.actions.append("dodge")
		# Snap the direction vector at the frame the button was hit
		if new_input.input_direction != Vector2.ZERO:
			new_input.dodge_direction = new_input.input_direction
		else:
			new_input.dodge_direction = Vector2.UP # Default to forward dodge if neutral
			
	# --- Jump & Movement ---
	if Input.is_action_just_pressed("ui_accept"):
		new_input.actions.append("jump")
		
	if new_input.input_direction != Vector2.ZERO:
		new_input.actions.append("run")
	elif new_input.actions.is_empty():
		new_input.actions.append("idle")

	return new_input
