extends Move
class_name Idle

func on_enter_state():
	player.velocity.x = 0
	player.velocity.z = 0
	
	# Use the 'anim_player' shortcut from Move.gd
# Replace the old animation block with this:
	if anim_player:
		if anim_player.has_animation("idle"):
			anim_player.play("idle", 0.3)
		elif anim_player.has_animation("Armature|idle"):
			anim_player.play("Armature|idle", 0.3)

func check_relevance(input: InputPackage) -> String:
	input.actions.sort_custom(moves_priority_sort)
	
	if input.actions.size() > 0:
		var top_action = input.actions[0]
		
		# --- ADD THIS: Redirect attack actions to the attack state ---
		if top_action == "light_attack" or top_action == "heavy_attack":
			return "attack"
			
		if top_action != "idle":
			return top_action
			
	return "okay"
