class_name Archer
extends Node2D

var display_name := "Archer"
var side := 0
var health := 100
var max_health := 100
var aim_angle := 45.0
var body_color := Color("#52a7ff")

func setup(which_side: int, label_text: String, color: Color, hp: int) -> void:
	side = which_side
	display_name = label_text
	body_color = color
	max_health = hp
	health = hp
	queue_redraw()

func facing_sign() -> float:
	return 1.0 if side == 0 else -1.0

func muzzle_position() -> Vector2:
	var direction := Vector2(cos(deg_to_rad(aim_angle)) * facing_sign(), -sin(deg_to_rad(aim_angle)))
	return global_position + Vector2(0.0, -58.0) + direction * 34.0

func launch_direction() -> Vector2:
	return Vector2(cos(deg_to_rad(aim_angle)) * facing_sign(), -sin(deg_to_rad(aim_angle))).normalized()

func apply_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	queue_redraw()

func segment_hit(a: Vector2, b: Vector2) -> Dictionary:
	var la := a - global_position
	var lb := b - global_position
	var hits: Array[Dictionary] = []
	var head_t := _segment_circle(la, lb, Vector2(0.0, -86.0), 13.0)
	if head_t >= 0.0: hits.append({"part": &"head", "t": head_t})
	var torso_t := _segment_rect(la, lb, Rect2(-18.0, -72.0, 36.0, 45.0))
	if torso_t >= 0.0: hits.append({"part": &"torso", "t": torso_t})
	var legs_t := _segment_rect(la, lb, Rect2(-15.0, -27.0, 30.0, 27.0))
	if legs_t >= 0.0: hits.append({"part": &"legs", "t": legs_t})
	if hits.is_empty(): return {"hit": false}
	hits.sort_custom(func(x, y): return x.t < y.t)
	return {"hit": true, "part": hits[0].part, "t": hits[0].t, "point": a.lerp(b, hits[0].t)}

func _segment_circle(a: Vector2, b: Vector2, center: Vector2, radius: float) -> float:
	var d := b - a
	var f := a - center
	var aa := d.dot(d)
	if aa <= 0.00001: return -1.0
	var bb := 2.0 * f.dot(d)
	var cc := f.dot(f) - radius * radius
	var disc := bb * bb - 4.0 * aa * cc
	if disc < 0.0: return -1.0
	var root := sqrt(disc)
	var t1 := (-bb - root) / (2.0 * aa)
	var t2 := (-bb + root) / (2.0 * aa)
	if t1 >= 0.0 and t1 <= 1.0: return t1
	if t2 >= 0.0 and t2 <= 1.0: return t2
	return -1.0

func _segment_rect(a: Vector2, b: Vector2, rect: Rect2) -> float:
	var d := b - a
	var near := 0.0
	var far := 1.0
	for axis in 2:
		var origin := a[axis]
		var delta := d[axis]
		var lo := rect.position[axis]
		var hi := rect.end[axis]
		if absf(delta) < 0.00001:
			if origin < lo or origin > hi: return -1.0
		else:
			var t1 := (lo - origin) / delta
			var t2 := (hi - origin) / delta
			if t1 > t2:
				var swap := t1; t1 = t2; t2 = swap
			near = maxf(near, t1)
			far = minf(far, t2)
			if near > far: return -1.0
	return near

func _draw() -> void:
	var sign_dir := facing_sign()
	draw_circle(Vector2(0.0, -86.0), 13.0, body_color)
	draw_rect(Rect2(-18.0, -72.0, 36.0, 45.0), body_color)
	draw_rect(Rect2(-14.0, -27.0, 10.0, 27.0), body_color.darkened(0.18))
	draw_rect(Rect2(4.0, -27.0, 10.0, 27.0), body_color.darkened(0.18))
	draw_line(Vector2(sign_dir * 13.0, -63.0), Vector2(sign_dir * 31.0, -50.0), body_color.lightened(0.15), 7.0)
	draw_arc(Vector2(sign_dir * 29.0, -58.0), 24.0, -PI * 0.5, PI * 0.5, 18, Color("#e7c98d"), 3.0)
	var aim := launch_direction()
	draw_line(Vector2(0.0, -58.0), Vector2(0.0, -58.0) + aim * 42.0, Color("#f1eadb"), 2.0)

