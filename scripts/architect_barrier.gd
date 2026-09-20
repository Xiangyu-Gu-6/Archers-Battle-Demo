class_name ArchitectBarrier
extends Node2D

const INTACT := preload("res://assets/art/barriers/architect_barrier_intact_v01.png")
const DAMAGED := preload("res://assets/art/barriers/architect_barrier_damaged_v02.png")
const VALID := preload("res://assets/art/barriers/architect_placement_valid_v01.png")
const INVALID := preload("res://assets/art/barriers/architect_placement_invalid_v01.png")
const DESTROYED := preload("res://assets/art/barriers/architect_barrier_destroyed_v01.png")

var width := 120.0
var height := 150.0
var hit_points := 2
var preview := false
var valid_placement := true
var broken_frame := -1
var sprite: Sprite2D

func setup(size: Vector2, durability: int, is_preview := false) -> void:
	width = size.x
	height = size.y
	hit_points = durability
	preview = is_preview
	_build_sprite()

func _build_sprite() -> void:
	sprite = Sprite2D.new()
	sprite.name = "BarrierArt"
	sprite.centered = false
	sprite.position = Vector2(-width * 0.5, -height)
	sprite.scale = Vector2(width / float(INTACT.get_width()), height / float(INTACT.get_height()))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	_refresh_art()

func set_placement_valid(value: bool) -> void:
	valid_placement = value
	_refresh_art()

func _refresh_art() -> void:
	if not is_instance_valid(sprite): return
	if preview:
		sprite.texture = VALID if valid_placement else INVALID
		sprite.modulate.a = 0.75
	else:
		sprite.texture = INTACT if hit_points >= 2 else DAMAGED
		sprite.modulate.a = 1.0

func take_arrow_hit() -> void:
	if hit_points <= 0: return
	hit_points -= 1
	if hit_points == 0:
		broken_frame = Engine.get_physics_frames()
		sprite.texture = DESTROYED
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
		tween.tween_callback(queue_free)
	else:
		_refresh_art()

func segment_hit(a: Vector2, b: Vector2) -> Dictionary:
	if preview or (hit_points <= 0 and Engine.get_physics_frames() != broken_frame):
		return {"hit": false}
	var rect := Rect2(global_position + Vector2(-width * 0.5, -height), Vector2(width, height))
	var direction := b - a
	var near := 0.0
	var far := 1.0
	for axis in 2:
		if absf(direction[axis]) < 0.00001:
			if a[axis] < rect.position[axis] or a[axis] > rect.end[axis]: return {"hit": false}
		else:
			var t1 := (rect.position[axis] - a[axis]) / direction[axis]
			var t2 := (rect.end[axis] - a[axis]) / direction[axis]
			if t1 > t2:
				var swap := t1
				t1 = t2
				t2 = swap
			near = maxf(near, t1)
			far = minf(far, t2)
			if near > far: return {"hit": false}
	return {"hit": true, "t": near, "point": a.lerp(b, near)}
