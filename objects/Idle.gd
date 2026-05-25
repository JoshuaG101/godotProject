extends Move
class_name Idle

func on_enter_state():
	player.velocity.x = 0
	player.velocity.z = 0
	
	if anim_player:
		if anim_player.has_animation("idle"):
			anim_player.play("idle", 0.3)
		elif anim_player.has_animation("Armature|idle"):
			anim_player.play("Armature|idle", 0.3)

# Inside Idle.gd
func check_relevance(input: InputPackage) -> String:
	if input.actions.has("light_attack") or input.actions.has("heavy_attack"):
		return "attack"
	if input.actions.has("dodge"):
		return "dodge"
	if input.actions.has("jump") and player.is_on_floor():
		return "jump"
	if input.input_direction != Vector2.ZERO:
		return "run"
		
	return "okay"
