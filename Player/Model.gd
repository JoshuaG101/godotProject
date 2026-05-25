extends Node
class_name StateMachine

@onready var player: CharacterBody3D = $".."
var current_state: Move
var states: Dictionary = {}

# --- NEW: INPUT BUFFER CONFIGURATION ---
@export var BUFFER_WINDOW := 0.25 # How long (in seconds) the game remembers an input
var buffered_action: String = ""
var buffer_timer := 0.0

# The priority actions we actually care about caching
const BUFFERABLE_ACTIONS = ["light_attack", "heavy_attack", "dodge", "jump"]

func _ready() -> void:
	await get_parent().ready
	
	for child in get_children():
		if child is Move:
			child.player = player
			states[child.name.to_lower()] = child
	
	current_state = states["idle"]
	current_state.on_enter_state()

func process_state(input_pkg: InputPackage, delta: float):
	# 1. Manage the input buffer lifetime
	update_buffer(input_pkg, delta)
	
	# 2. Inject the buffered action into the input package so states can see it
	if not buffered_action.is_empty():
		if not input_pkg.actions.has(buffered_action):
			input_pkg.actions.push_front(buffered_action) # Give it top priority
	
	# 3. Process normal state relevance
	var next_state_name = current_state.check_relevance(input_pkg)
	
	if next_state_name != "okay" and states.has(next_state_name.to_lower()):
		# If we successfully shifted states using a buffered action, clear it!
		if next_state_name.to_lower() == buffered_action:
			clear_buffer()
		elif buffered_action == "light_attack" or buffered_action == "heavy_attack":
			if next_state_name.to_lower() == "attack":
				clear_buffer()
				
		change_state(next_state_name.to_lower())
	
	current_state.update(input_pkg, delta)

func change_state(new_state_name: String):
	current_state.on_exit_state()
	current_state = states[new_state_name]
	current_state.on_enter_state()

# --- NEW: BUFFER MANAGEMENT UTILITIES ---
func update_buffer(input_pkg: InputPackage, delta: float) -> void:
	# Tick down existing buffer
	if buffer_timer > 0.0:
		buffer_timer -= delta
		if buffer_timer <= 0.0:
			buffered_action = ""
	
	# Listen for new high-priority button presses
	for action in input_pkg.actions:
		if action in BUFFERABLE_ACTIONS:
			buffered_action = action
			buffer_timer = BUFFER_WINDOW
			break # Capture the highest priority one and wait

func clear_buffer() -> void:
	buffered_action = ""
	buffer_timer = 0.0
