extends EnemyState
class_name Patrol

# 1. Set SPEED to 0.0 so the enemy is completely stationary until triggered
@export var SPEED := 0.0
@export var direction := Vector3(-1, 0, 0)

var turning := false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func on_enter_state(msg: Dictionary = {}) -> void:
	turning = false
	# 2. Play the idle animation while standing still
	if enemy and enemy.anim_player:
		enemy.anim_player.play("Armature|idle")

func update(delta: float) -> void:
	if turning:
		return

	if enemy.is_on_wall():
		turn_around()
		return

	# This will be zeroed out by default now, keeping him rooted to the floor
	enemy.velocity.x = direction.x * SPEED
	enemy.velocity.z = direction.z * SPEED

	if not enemy.is_on_floor():
		enemy.velocity.y -= gravity * delta
	else:
		enemy.velocity.y = -0.1 

func turn_around() -> void:
	if turning: 
		return
		
	turning = true
	
	enemy.velocity.x = 0
	enemy.velocity.z = 0
	if enemy.anim_player:
		enemy.anim_player.play("Armature|idle")
	
	var turn_tween = create_tween()
	turn_tween.tween_property(enemy, "rotation_degrees:y", enemy.rotation_degrees.y + 180.0, 0.6)
	
	await turn_tween.finished
			
	direction = -direction
	turning = false
	
	if enemy.anim_player:
		enemy.anim_player.play("Armature|idle")
