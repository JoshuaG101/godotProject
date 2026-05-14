extends Node
class_name InputGatherer

func gather_input() -> InputPackage:
	var new_input = InputPackage.new()
	
	if Input.is_action_just_pressed("ui_accept"):
		new_input.actions.append("jump")
		
	if Input.is_action_just_pressed("punch"):
		new_input.actions.append("punch")
		
	if Input.is_action_just_pressed("dodge"):
		new_input.actions.append("dodge")
		
	if Input.is_action_just_pressed("sprint"):
		new_input.actions.append("sprint")
		
	new_input.input_direction = Input.get_vector("left", "right", "up", "down")
	
	if new_input.input_direction != Vector2.ZERO:
		new_input.actions.append("run")
		
	# FIXED: Changed .action to .actions
	if new_input.actions.is_empty():
		new_input.actions.append("idle")

	return new_input
