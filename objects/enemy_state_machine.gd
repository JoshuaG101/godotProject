extends Node
class_name EnemyStateMachine

var enemy: CharacterBody3D
var current_state: EnemyState
var states: Dictionary = {}

func init(parent_enemy: CharacterBody3D) -> void:
	enemy = parent_enemy
	
	# Gather all child state nodes
	for child in get_children():
		if child is EnemyState:
			child.enemy = enemy
			child.state_machine = self
			states[child.name.to_lower()] = child
			
	# Default starting state
	if states.has("patrol"):
		change_state("patrol")

func process_state(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func change_state(new_state_name: String, msg: Dictionary = {}) -> void:
	var lower_name = new_state_name.to_lower()
	if not states.has(lower_name):
		return
		
	if current_state:
		current_state.on_exit_state()
		
	current_state = states[lower_name]
	
	# Clean slate: Reset horizontal velocity when changing states
	if enemy:
		enemy.velocity.x = 0
		enemy.velocity.z = 0
		
	current_state.on_enter_state(msg)
