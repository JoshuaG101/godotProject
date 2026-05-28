extends EnemyState
class_name Chase

@export var CHASE_SPEED := 4.5
@export var ATTACK_RANGE := 1.8

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func on_enter_state(msg: Dictionary = {}) -> void:
	if enemy and enemy.anim_player:
		enemy.anim_player.play("Armature|run")

func update(delta: float) -> void:
	if not enemy or not enemy.target:
		state_machine.change_state("patrol")
		return
		
	var player_pos = enemy.target.global_position
	var current_pos = enemy.global_position
	
	var dir_to_player = (player_pos - current_pos)
	dir_to_player.y = 0 
	
	var distance = dir_to_player.length()
	
	if distance > 0.01:
		dir_to_player = dir_to_player.normalized()
	else:
		dir_to_player = Vector3.ZERO
	
	# If in range, stop running animation
	if distance <= ATTACK_RANGE:
		enemy.velocity.x = 0
		enemy.velocity.z = 0
		if enemy.anim_player and enemy.anim_player.current_animation == "Armature|run":
			enemy.anim_player.play("Armature|idle") # Stand still to strike
		print("Enemy is in range! Attacking!") 
		return

	# Otherwise ensure running animation is playing while closing distance
	if enemy.anim_player and enemy.anim_player.current_animation != "Armature|run":
		enemy.anim_player.play("Armature|run")

	enemy.velocity.x = dir_to_player.x * CHASE_SPEED
	enemy.velocity.z = dir_to_player.z * CHASE_SPEED
	
	if not enemy.is_on_floor():
		enemy.velocity.y -= gravity * delta
		
	if enemy.has_node("Armature") and dir_to_player.length_squared() > 0.01:
		var visuals = enemy.get_node("Armature")
		var look_target = current_pos + dir_to_player
		
		var target_transform = visuals.global_transform.looking_at(look_target, Vector3.UP).orthonormalized()
		var current_basis = visuals.global_transform.basis.orthonormalized()
		visuals.global_transform.basis = current_basis.slerp(target_transform.basis, 10.0 * delta)
