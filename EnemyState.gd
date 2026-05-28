extends Node
class_name EnemyState

var enemy: CharacterBody3D
var state_machine: EnemyStateMachine

func on_enter_state(msg: Dictionary = {}) -> void:
	pass

func on_exit_state() -> void:
	pass

func update(delta: float) -> void:
	pass
