# AttackDatabase.gd
extends Resource
class_name AttackDatabase

@export var attacks: Dictionary = {
	"jab": {
		"damage": 10.0,
		"kb_force": 3.0,
		"kb_dir": Vector3.ZERO,
		"float_time": 0.0,
		"start_frame": 2.0,
		"end_frame": 7.0,
		"is_directional": false,
		"hitbox_node": "LeftHandHitbox"
	},
	"jabCross": {
		"damage": 15.0,
		"kb_force": 5.0,
		"kb_dir": Vector3.ZERO,
		"float_time": 0.0,
		"start_frame": 4.0,
		"end_frame": 11.0,
		"is_directional": false,
		"hitbox_node": "RightHandHitbox"
	},
	"chargePunch": {
		"damage": 30.0,
		"kb_force": 15.0,
		"kb_dir": Vector3.ZERO,
		"float_time": 0.0,
		"start_frame": 12.0,
		"end_frame": 20.0,
		"is_directional": true,
		"hitbox_node": "RightHandHitbox"
	},
	"fastestHeadbutt": {
		"damage": 10.0,
		"kb_force": 4.0,
		"kb_dir": Vector3.ZERO,
		"float_time": 0.0,
		"start_frame": 3.0,
		"end_frame": 8.0,
		"is_directional": false,
		"hitbox_node": "HeadHitbox"
	},
	"heavy_attack_1": {
		"damage": 20.0,
		"kb_force": 10.0,
		"kb_dir": Vector3.ZERO,
		"float_time": 0.0,
		"start_frame": 8.0,
		"end_frame": 16.0,
		"is_directional": false,
		"hitbox_node": "RightHandHitbox"
	},
	"fastestLeftHook": {
		"damage": 15.0,
		"kb_force": 5.0,
		"kb_dir": Vector3.ZERO,
		"float_time": 0.0,
		"start_frame": 4.0,
		"end_frame": 10.0,
		"is_directional": false,
		"hitbox_node": "LeftHandHitbox"
	},
	"fastestRightHook": {
		"damage": 15.0,
		"kb_force": 5.0,
		"kb_dir": Vector3.ZERO,
		"float_time": 0.0,
		"start_frame": 4.0,
		"end_frame": 10.0,
		"is_directional": false,
		"hitbox_node": "RightHandHitbox"
	},
	"uppercut": {
		"damage": 25.0,
		"kb_force": 6.0,
		"kb_dir": Vector3.ZERO,
		"float_time": 0.5,
		"start_frame": 6.0,
		"end_frame": 12.0,
		"is_directional": true,
		"hitbox_node": "RightHandHitbox"
	},
	"chargeAttacke2": {
		"damage": 35.0,
		"kb_force": 22.0,
		"kb_dir": Vector3.ZERO,
		"float_time": 0.0,
		"start_frame": 14.0,
		"end_frame": 22.0,
		"is_directional": true,
		"hitbox_node": "RightHandHitbox",
		"forward_dash_speed": 14.0,
		"dash_start_frame": 6.0,
		"dash_end_frame": 15.0
	}
}
