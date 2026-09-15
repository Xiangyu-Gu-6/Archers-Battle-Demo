class_name FlyingArrow
extends Node2D

const BallisticsScript := preload("res://scripts/ballistics.gd")

signal stopped(result: Dictionary)
var velocity := Vector2.ZERO
var gravity := 700.0
var age := 0.0
var timeout := 8.0
var shooter
var target
var terrain
var world_width := 2400.0
var active := true

func launch(origin: Vector2, initial_velocity: Vector2, owner_archer, target_archer, ground, gravity_value: float, timeout_value: float) -> void:
	global_position = origin
	velocity = initial_velocity
	shooter = owner_archer
	target = target_archer
	terrain = ground
	gravity = gravity_value
	timeout = timeout_value
	world_width = ground.world_width
	rotation = velocity.angle()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not active: return
	var frame: Dictionary = BallisticsScript.advance(global_position, velocity, delta, gravity, terrain, target)
	global_position = frame.position
	velocity = frame.velocity
	if frame.collision.hit:
		_finish(frame.collision)
		return
	rotation = velocity.angle()
	age += delta
	if age >= timeout:
		_finish({"hit": false, "kind": &"timeout", "point": global_position})
	elif global_position.x < -120.0 or global_position.x > world_width + 120.0 or global_position.y > terrain.world_bottom + 180.0:
		_finish({"hit": false, "kind": &"out_of_bounds", "point": global_position})

func _finish(result: Dictionary) -> void:
	if not active: return
	active = false
	set_physics_process(false)
	stopped.emit(result)

func _draw() -> void:
	draw_line(Vector2(-20.0, 0.0), Vector2(8.0, 0.0), Color("#f7efe0"), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(8.0, 0.0), Vector2(1.0, -4.0), Vector2(1.0, 4.0)]), Color("#ffce57"))
	draw_line(Vector2(-18.0, 0.0), Vector2(-24.0, -5.0), Color("#f06d62"), 2.0)
	draw_line(Vector2(-18.0, 0.0), Vector2(-24.0, 5.0), Color("#f06d62"), 2.0)

