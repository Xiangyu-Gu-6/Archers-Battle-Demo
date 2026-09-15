class_name EmeraldRangerRig
extends Node2D

const PART_ROOT := "res://assets/art/characters/emerald_ranger/rig_parts_v02/"
const GAME_SCALE := 0.0876

const FRONT_UPPER_LENGTH := 176.0
const FRONT_LOWER_LENGTH := 202.0
const REAR_UPPER_LENGTH := 190.0
const REAR_LOWER_LENGTH := 208.0
const FRONT_THIGH_LENGTH := 202.0
const FRONT_SHIN_LENGTH := 255.0
const REAR_THIGH_LENGTH := 232.0
const REAR_SHIN_LENGTH := 260.0

var skeleton: Skeleton2D
var bones: Dictionary = {}
var sprites: Dictionary = {}
var bow_string: Line2D

var combat_state := &"idle"
var aim_degrees := 45.0
var charge_amount := 0.0
var aim_weight := 0.0
var release_elapsed := -1.0
var hit_elapsed := -1.0
var motion_time := 0.0


func _ready() -> void:
	position = Vector2(0.0, -40.0)
	scale = Vector2.ONE * GAME_SCALE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_build_skeleton()
	_apply_pose()


func _process(delta: float) -> void:
	motion_time += delta
	var wants_aim := combat_state in [&"aim", &"charge"]
	aim_weight = move_toward(aim_weight, 1.0 if wants_aim else 0.0, delta * 5.5)
	if release_elapsed >= 0.0:
		release_elapsed += delta
		if release_elapsed >= 0.92:
			release_elapsed = -1.0
	if hit_elapsed >= 0.0:
		hit_elapsed += delta
		if hit_elapsed >= 0.42:
			hit_elapsed = -1.0
	_apply_pose()


func set_combat_state(next_state: StringName) -> void:
	combat_state = next_state
	if next_state != &"charge":
		charge_amount = 0.0


func set_aim_degrees(value: float) -> void:
	aim_degrees = clampf(value, 10.0, 85.0)


func set_charge(value: float) -> void:
	combat_state = &"charge"
	charge_amount = clampf(value, 0.0, 1.0)


func play_release() -> void:
	combat_state = &"release"
	release_elapsed = 0.0
	charge_amount = 0.0


func play_hit() -> void:
	hit_elapsed = 0.0


func is_nocked_arrow_visible() -> bool:
	return is_instance_valid(sprites.get("arrow")) and sprites.arrow.visible


func _build_skeleton() -> void:
	skeleton = Skeleton2D.new()
	skeleton.name = "EmeraldRangerSkeleton2D"
	add_child(skeleton)

	bones.pelvis = _bone("Pelvis", skeleton, Vector2.ZERO, 0.0, 80.0)
	bones.spine = _bone("Spine", bones.pelvis, Vector2.ZERO, 0.0, 205.0)
	bones.head = _bone("Head", bones.spine, Vector2(8, -218), 0.0, 90.0)
	bones.hat = _bone("Hat", bones.head, Vector2(-6, -172), 0.0, 70.0)
	bones.feather = _bone("Feather", bones.hat, Vector2(60, -18), 0.0, 95.0)
	bones.quiver = _bone("Quiver", bones.spine, Vector2(-82, -92), -0.20, 170.0)
	bones.pouch = _bone("BeltPouch", bones.pelvis, Vector2(74, -20), 0.08, 80.0)

	bones.rear_upper = _bone("RearUpperArm", bones.spine, Vector2(-45, -175), 0.0, REAR_UPPER_LENGTH)
	bones.rear_forearm = _bone("RearForearm", bones.rear_upper, Vector2(REAR_UPPER_LENGTH - 24.0, 0.0), 0.0, REAR_LOWER_LENGTH)
	bones.front_upper = _bone("FrontUpperArm", bones.spine, Vector2(38, -170), 0.0, FRONT_UPPER_LENGTH)
	bones.front_forearm = _bone("FrontForearm", bones.front_upper, Vector2(FRONT_UPPER_LENGTH - 22.0, 0.0), 0.0, FRONT_LOWER_LENGTH)
	bones.bow_grip = _bone("BowGrip", bones.front_forearm, Vector2(FRONT_LOWER_LENGTH - 18.0, 0.0), 0.0, 145.0)
	bones.arrow = _bone("NockedArrow", skeleton, Vector2(200, -155), 0.0, 300.0)

	bones.rear_thigh = _bone("RearThigh", bones.pelvis, Vector2(-32, 16), 0.0, REAR_THIGH_LENGTH)
	bones.rear_shin = _bone("RearShin", bones.rear_thigh, Vector2(REAR_THIGH_LENGTH - 28.0, 0.0), 0.0, REAR_SHIN_LENGTH)
	bones.front_thigh = _bone("FrontThigh", bones.pelvis, Vector2(32, 16), 0.0, FRONT_THIGH_LENGTH)
	bones.front_shin = _bone("FrontShin", bones.front_thigh, Vector2(FRONT_THIGH_LENGTH - 25.0, 0.0), 0.0, FRONT_SHIN_LENGTH)

	_attach_sprite("torso", bones.spine, "torso", Vector2(161, 240), 0.0, 0)
	_attach_sprite("head", bones.head, "head", Vector2(151, 258), 0.0, 5)
	_attach_sprite("hat", bones.hat, "hat", Vector2(162, 135), 0.0, 7)
	_attach_sprite("feather", bones.feather, "hat_feather", Vector2(286, 184), 0.0, 8, "v03")
	_attach_sprite("quiver", bones.quiver, "quiver", Vector2(116, 245), 0.0, -8)
	_attach_sprite("pouch", bones.pouch, "belt_pouch", Vector2(95, 80), 0.0, 4)
	_attach_sprite("rear_upper", bones.rear_upper, "rear_upper_arm", Vector2(72, 36), -PI / 2.0, -5)
	_attach_sprite("rear_forearm", bones.rear_forearm, "rear_forearm_hand", Vector2(27, 61), 0.0, -4)
	_attach_sprite("front_upper", bones.front_upper, "front_upper_arm", Vector2(106, 34), -PI / 2.0, 9)
	_attach_sprite("front_forearm", bones.front_forearm, "front_forearm_hand", Vector2(30, 145), 0.0, 10)
	_attach_sprite("bow", bones.bow_grip, "bow", Vector2(116, 158), 0.0, 12)
	_attach_sprite("arrow", bones.arrow, "nocked_arrow", Vector2(20, 40), 0.0, 14)
	_attach_sprite("rear_thigh", bones.rear_thigh, "rear_thigh", Vector2(66, 27), -PI / 2.0, -6)
	_attach_sprite("rear_shin", bones.rear_shin, "rear_lower_leg_boot", Vector2(76, 28), -PI / 2.0, -6)
	_attach_sprite("front_thigh", bones.front_thigh, "front_thigh", Vector2(60, 28), -PI / 2.0, 2)
	_attach_sprite("front_shin", bones.front_shin, "front_lower_leg_boot", Vector2(75, 28), -PI / 2.0, 2)

	bow_string = Line2D.new()
	bow_string.name = "DynamicBowString"
	bow_string.width = 3.0
	bow_string.default_color = Color("#f7e7bf")
	bow_string.z_index = 13
	bow_string.antialiased = true
	skeleton.add_child(bow_string)

	for bone_value in bones.values():
		if bone_value is Bone2D:
			bone_value.rest = bone_value.transform


func _bone(bone_name: String, parent: Node, position_value: Vector2, rotation_value: float, length_value: float) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = bone_name
	bone.position = position_value
	bone.rotation = rotation_value
	bone.set_autocalculate_length_and_angle(false)
	bone.set_length(length_value)
	parent.add_child(bone)
	return bone


func _attach_sprite(key: String, bone: Bone2D, file_stem: String, pivot: Vector2, sprite_rotation: float, z_value: int, version := "v02") -> void:
	var sprite := Sprite2D.new()
	sprite.name = file_stem.to_pascal_case() + "Skin"
	sprite.texture = load(PART_ROOT + "emerald_ranger_" + file_stem + "_" + version + ".png")
	sprite.centered = false
	sprite.position = -pivot
	sprite.rotation = sprite_rotation
	sprite.z_index = z_value
	bone.add_child(sprite)
	sprites[key] = sprite


func _apply_pose() -> void:
	if not is_instance_valid(skeleton):
		return
	var idle_wave := sin(motion_time * TAU / 1.35)
	var walk_wave := sin(motion_time * TAU * 2.2) if combat_state == &"move" else 0.0
	var recoil := _release_pulse()
	var hit := _hit_pulse()
	var draw_amount := maxf(charge_amount, aim_weight * 0.34)
	var pose_angle := lerpf(30.0, aim_degrees, aim_weight)
	var pose_radians := deg_to_rad(-pose_angle)

	var bounce := idle_wave * 3.0 + absf(walk_wave) * 5.0 - recoil * 9.0
	skeleton.position.y = bounce
	bones.spine.rotation = -0.035 * draw_amount + 0.11 * recoil - 0.10 * hit
	bones.head.rotation = -0.02 * draw_amount - 0.10 * recoil + 0.13 * hit + idle_wave * 0.008
	bones.hat.rotation = -0.045 * recoil + 0.08 * hit + idle_wave * 0.012
	bones.feather.rotation = idle_wave * 0.06 - recoil * 0.28 + hit * 0.18
	bones.quiver.rotation = -0.20 - recoil * 0.08 + walk_wave * 0.025
	bones.pouch.rotation = 0.08 + recoil * 0.09 - walk_wave * 0.035

	var bow_target := Vector2(278.0, -155.0)
	bow_target += Vector2(0.0, clampf((45.0 - pose_angle) * 2.6, -88.0, 66.0)) * aim_weight
	bow_target += Vector2(-16.0, 11.0) * recoil
	var relaxed_draw_target := Vector2(82.0, -52.0)
	var full_draw_target := Vector2(58.0, -178.0) + Vector2(0.0, clampf((45.0 - pose_angle) * 1.45, -48.0, 36.0))
	var draw_target := relaxed_draw_target.lerp(full_draw_target, draw_amount)
	draw_target += Vector2(-10.0, 12.0) * recoil

	_solve_two_bone(bones.front_upper, bones.front_forearm, bow_target, FRONT_UPPER_LENGTH - 22.0, FRONT_LOWER_LENGTH - 18.0, 1.0)
	_solve_two_bone(bones.rear_upper, bones.rear_forearm, draw_target, REAR_UPPER_LENGTH - 24.0, REAR_LOWER_LENGTH - 20.0, 1.0)

	var planted_y := 456.0 - bounce
	var stride := walk_wave * 30.0
	_solve_two_bone(bones.front_thigh, bones.front_shin, Vector2(48.0 + stride, planted_y), FRONT_THIGH_LENGTH - 25.0, FRONT_SHIN_LENGTH - 18.0, -1.0)
	_solve_two_bone(bones.rear_thigh, bones.rear_shin, Vector2(-44.0 - stride, planted_y - 3.0), REAR_THIGH_LENGTH - 28.0, REAR_SHIN_LENGTH - 20.0, 1.0)

	var bow_local := skeleton.to_local(bones.bow_grip.global_position)
	bones.bow_grip.global_rotation = skeleton.global_rotation + pose_radians * 0.12 + recoil * 0.12
	bones.arrow.position = draw_target
	bones.arrow.rotation = pose_radians * 0.18
	var released := release_elapsed >= 0.0 and release_elapsed < 0.84
	sprites.arrow.visible = not released
	var string_nock := bow_local + Vector2(-96.0, 0.0) if released else draw_target
	bow_string.points = PackedVector2Array([
		bow_local + Vector2(-92.0, -145.0),
		string_nock,
		bow_local + Vector2(-92.0, 145.0)
	])


func _solve_two_bone(upper: Bone2D, lower: Bone2D, target_local: Vector2, upper_length: float, lower_length: float, bend_sign: float) -> void:
	var origin_local := skeleton.to_local(upper.global_position)
	var delta := target_local - origin_local
	var distance := clampf(delta.length(), absf(upper_length - lower_length) + 1.0, upper_length + lower_length - 1.0)
	var target_angle := delta.angle()
	var cosine_shoulder := clampf((upper_length * upper_length + distance * distance - lower_length * lower_length) / (2.0 * upper_length * distance), -1.0, 1.0)
	var upper_angle := target_angle + acos(cosine_shoulder) * bend_sign
	upper.global_rotation = skeleton.global_rotation + upper_angle
	var elbow_local := origin_local + Vector2(upper_length, 0.0).rotated(upper_angle)
	lower.global_rotation = skeleton.global_rotation + (target_local - elbow_local).angle()


func _release_pulse() -> float:
	if release_elapsed < 0.0 or release_elapsed >= 0.68:
		return 0.0
	if release_elapsed <= 0.18:
		return smoothstep(0.0, 0.18, release_elapsed)
	return 1.0 - smoothstep(0.18, 0.68, release_elapsed)


func _hit_pulse() -> float:
	if hit_elapsed < 0.0 or hit_elapsed >= 0.42:
		return 0.0
	if hit_elapsed <= 0.10:
		return smoothstep(0.0, 0.10, hit_elapsed)
	return 1.0 - smoothstep(0.10, 0.42, hit_elapsed)
