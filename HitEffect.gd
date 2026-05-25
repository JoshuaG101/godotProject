# HitEffect.gd
extends Node3D

func _ready() -> void:
	# If using GPUParticles3D:
	if has_node("GPUParticles3D"):
		$GPUParticles3D.emitting = true
		
	# Automatically destroy this effect scene after 1 second
	await get_tree().create_timer(1.0).timeout
	queue_free()
