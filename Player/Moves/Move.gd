extends Node
class_name Move

var player: CharacterBody3D
# Shortcut to access the animation player directly through the player reference
var anim_player: AnimationPlayer:
	get:
		return player.anim_player if player else null
static var moves_priority := {"idle": 1, "run": 2, "jump": 10}

static func moves_priority_sort(a: String, b: String):
	return moves_priority.get(a, 0) > moves_priority.get(b, 0)

func check_relevance(_input: InputPackage) -> String:
	return "okay"

func update(_input: InputPackage, _delta: float):
	pass

func on_enter_state():
	pass

func on_exit_state():
	pass
