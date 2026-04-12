extends Control

# This variable tracks which action we are currently trying to rebind
var action_to_remap : String = ""
var is_listening : bool = false

@onready var left_button = $LeftKeyButton # Drag your button here

func _ready() -> void:
	# Optional: Update the button text to show the current key when the menu opens
	update_button_text("move_left", left_button)

# 1. The player clicks the button to change the "move_left" key
func _on_left_key_button_pressed() -> void:
	action_to_remap = "move_left"
	is_listening = true
	left_button.text = "Press any key..."

# 2. We listen for their keyboard input
func _input(event: InputEvent) -> void:
	if is_listening:
		# Check if the input is a keyboard key (you can add mouse buttons here too if you want)
		if event is InputEventKey and event.is_pressed():
			
			# Change the keybind in Godot's system
			change_keybind(action_to_remap, event)
			
			# Stop listening and update the text
			is_listening = false
			update_button_text(action_to_remap, left_button)
			
			# Stop the input from doing anything else right now
			get_viewport().set_input_as_handled()

func change_keybind(action_name: String, new_key: InputEvent) -> void:
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, new_key)

# Helper function to make the button display the name of the key (like "W" or "Space")
func update_button_text(action_name: String, button: Button) -> void:
	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		# Get the first event tied to this action and get its text representation
		button.text = events[0].as_text().trim_suffix(" (Physical)")
