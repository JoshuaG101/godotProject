extends Node
class_name a

@onready var player: CharacterBody3D = $".."
@onready var states = {
	"idle": $Idle,
	"run": $Run,
	"jump": $Jump
}

var current_state: Move

func _ready() -> void:
	for child in get_children():
		if child is Move:
			child.player = player
	current_state = $Idle
	current_state.on_enter_state()

func process_state(input_package: InputPackage, delta: float):
	var next_state_name = current_state.check_relevance(input_package)
	
	if next_state_name != "okay" and states.has(next_state_name):
		change_state(next_state_name)
	
	current_state.update(input_package, delta)

func change_state(new_state_name: String):
	current_state.on_exit_state()
	current_state = states[new_state_name]
	current_state.on_enter_state()
