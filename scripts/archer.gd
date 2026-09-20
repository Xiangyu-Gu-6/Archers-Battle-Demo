class_name Archer
extends Node2D

const EmeraldRangerRigScript := preload("res://scripts/emerald_ranger_rig.gd")
const CarnivalCharacterRigScript := preload("res://scripts/carnival_character_rig.gd")

var display_name := "Archer"
var side := 0
var role_id: StringName = &"ranger"
var skill_uses := 1
var health := 100
var max_health := 100
var aim_angle := 45.0:
	set(value):
		aim_angle = value
		if is_instance_valid(rig_visual):
			rig_visual.set_aim_degrees(value)
		if is_instance_valid(character_rig): character_rig.set_aim_degrees(value)
var body_color := Color("#52a7ff")
var art_sprite: Sprite2D
var rig_visual: EmeraldRangerRig
var character_rig: CarnivalCharacterRig

func setup(which_side: int, label_text: String, color: Color, hp: int, role: StringName = &"") -> void:
	side = which_side
	role_id = role if role != &"" else (&"ranger" if side == 0 else &"shark")
	display_name = label_text
	body_color = color
	max_health = hp
	health = hp
	_build_art_sprite()
	queue_redraw()

func _build_art_sprite() -> void:
	if is_instance_valid(art_sprite): art_sprite.queue_free()
	if is_instance_valid(rig_visual): rig_visual.queue_free()
	if is_instance_valid(character_rig): character_rig.queue_free()
	if role_id == &"ranger":
		rig_visual = EmeraldRangerRigScript.new()
		rig_visual.name = "AnimatedCharacterRig"
		add_child(rig_visual)
		rig_visual.set_aim_degrees(aim_angle)
		if side == 1: rig_visual.scale.x = -1.0
		return
	character_rig = CarnivalCharacterRigScript.new()
	character_rig.name = "AnimatedCharacterRig"
	character_rig.configure(role_id, side)
	add_child(character_rig)
	character_rig.set_aim_degrees(aim_angle)

func facing_sign() -> float:
	return 1.0 if side == 0 else -1.0

func muzzle_position() -> Vector2:
	var direction := Vector2(cos(deg_to_rad(aim_angle)) * facing_sign(), -sin(deg_to_rad(aim_angle)))
	return global_position + Vector2(0.0, -58.0) + direction * 34.0

func launch_direction() -> Vector2:
	return Vector2(cos(deg_to_rad(aim_angle)) * facing_sign(), -sin(deg_to_rad(aim_angle))).normalized()

func apply_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	if is_instance_valid(rig_visual):
		rig_visual.play_hit()
	if is_instance_valid(character_rig): character_rig.play_hit()
	queue_redraw()

func set_visual_state(state: StringName) -> void:
	if is_instance_valid(rig_visual):
		rig_visual.set_combat_state(state)
	if is_instance_valid(character_rig): character_rig.set_combat_state(state)

func set_charge_visual(value: float) -> void:
	if is_instance_valid(rig_visual):
		rig_visual.set_charge(value)
	if is_instance_valid(character_rig): character_rig.set_charge(value)

func play_release_visual(kind: StringName = &"normal") -> void:
	if is_instance_valid(rig_visual):
		rig_visual.play_release()
	if is_instance_valid(character_rig): character_rig.play_release(kind)

func set_skill_visual(kind: StringName) -> void:
	if is_instance_valid(character_rig): character_rig.set_skill_visual(kind)

func play_build_visual() -> void:
	if is_instance_valid(character_rig): character_rig.play_build()

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
	var aim := launch_direction()
	draw_line(Vector2(0.0, -58.0), Vector2(0.0, -58.0) + aim * 42.0, Color("#fff0a8dd"), 2.5)

