class_name GameBalance
extends Resource

@export var max_health := 100
@export var world_width := 2400.0
@export var world_bottom := 760.0
@export var gravity := 700.0
@export var min_speed := 250.0
@export var max_speed := 1450.0
@export var charge_half_cycle := 2.0
@export var gameplay_body_width := 36.0
@export var move_budget := 180.0
@export var move_speed := 125.0
@export var min_angle := 5.0
@export var max_angle := 85.0
@export var angle_tap_step := 0.5
@export var angle_hold_delay := 0.25
@export var angle_hold_speed := 15.0
@export var fine_angle_tap_step := 0.1
@export var fine_angle_hold_speed := 3.0
@export var arrow_timeout := 8.0
@export var head_damage := 50
@export var torso_damage := 30
@export var legs_damage := 20

func launch_speed(power: float) -> float:
	return lerpf(min_speed, max_speed, clampf(power, 0.0, 1.0))

func damage_for(part: StringName) -> int:
	match part:
		&"head": return head_damage
		&"torso": return torso_damage
		&"legs": return legs_damage
	return 0


