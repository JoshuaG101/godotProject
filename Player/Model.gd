extends Node
class_name StateMachine

@onready var player: CharacterBody3D = $".."
var current_state: Move
var states: Dictionary = {}

func _ready() -> void:
	# Wait for Player to initialize its @onready nodes
	await get_parent().ready
	
	# Map all child nodes as states
	for child in get_children():
		if child is Move:
			child.player = player
			states[child.name.to_lower()] = child
	
	current_state = states["idle"]
	current_state.on_enter_state()

func process_state(input_pkg: InputPackage, delta: float):
	var next_state_name = current_state.check_relevance(input_pkg)
	
	if next_state_name != "okay" and states.has(next_state_name.to_lower()):
		change_state(next_state_name.to_lower())
	
	current_state.update(input_pkg, delta)

func change_state(new_state_name: String):
	current_state.on_exit_state()
	current_state = states[new_state_name]
	current_state.on_enter_state()
