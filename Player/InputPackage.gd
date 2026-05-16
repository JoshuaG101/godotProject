# InputPackage.gd
extends RefCounted
class_name InputPackage

var actions: Array[String] = []
var input_direction := Vector2.ZERO
var dodge_direction := Vector2.ZERO # Stores the direction at the exact frame of dodging
