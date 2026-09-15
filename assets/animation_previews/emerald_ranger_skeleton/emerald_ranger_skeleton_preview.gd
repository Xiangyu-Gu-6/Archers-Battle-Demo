extends Node2D

const PART_ROOT := "res://assets/art/characters/emerald_ranger/rig_parts_v02/"
const SAMPLE_STEP := 1.0 / 12.0
const CYCLE_SECONDS := 3.2

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
var fixed_phase := -1.0
var capture_path := ""


func _ready() -> void:
	_parse_preview_arguments()
	_build_skeleton()
	queue_redraw()
	if fixed_phase >= 0.0:
		_apply_pose(fixed_phase)
	if not capture_path.is_empty():
		_capture_deferred.call_deferred()


func _process(_delta: float) -> void:
	if fixed_phase < 0.0:
		var sampled_time: float = floor(Time.get_ticks_msec() / 1000.0 / SAMPLE_STEP) * SAMPLE_STEP
		_apply_pose(fmod(sampled_time, CYCLE_SECONDS))


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("#8edcf0"))
	draw_circle(Vector2(1070, 105), 62.0, Color("#ffe089"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 475), Vector2(150, 385), Vector2(300, 470), Vector2(475, 355),
		Vector2(690, 475), Vector2(890, 370), Vector2(1100, 475), Vector2(1280, 395),
		Vector2(1280, 720), Vector2(0, 720)
	]), Color("#7eb38a"))
	draw_rect(Rect2(0, 565, 1280, 155), Color("#d79a5a"))
	draw_rect(Rect2(0, 555, 1280, 22), Color("#65a93f"))
	for x in range(0, 1280, 54):
		draw_circle(Vector2(x + 16, 555), 13.0, Color("#79c64b"))


func _parse_preview_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--phase="):
			fixed_phase = clampf(float(argument.trim_prefix("--phase=")), 0.0, CYCLE_SECONDS)
		elif argument.begins_with("--capture="):
			capture_path = argument.trim_prefix("--capture=")


func _build_skeleton() -> void:
	skeleton = Skeleton2D.new()
	skeleton.name = "EmeraldRangerSkeleton2D"
	skeleton.position = Vector2(500, 382)
	skeleton.scale = Vector2.ONE * 0.38
	add_child(skeleton)

	bones.pelvis = _bone("Pelvis", skeleton, Vector2.ZERO, 0.0, 80.0)
	bones.spine = _bone("Spine", bones.pelvis, Vector2.ZERO, 0.0, 205.0)
	bones.head = _bone("Head", bones.spine, Vector2(8, -218), 0.0, 90.0)
	bones.hat = _bone("Hat", bones.head, Vector2(-6, -172), 0.0, 70.0)
	bones.feather = _bone("Feather", bones.hat, Vector2(60, -18), 0.0, 95.0)
	bones.quiver = _bone("Quiver", bones.spine, Vector2(-82, -92), -0.20, 170.0)
	bones.pouch = _bone("BeltPouch", bones.pelvis, Vector2(74, -20), 0.08, 80.0)

	bones.rear_upper = _bone("RearUpperArm", bones.spine, Vector2(-45, -175), 0.0, REAR_UPPER_LENGTH)
	bones.rear_forearm = _bone("RearForearm", bones.rear_upper, Vector2(REAR_UPPER_LENGTH - 24.0, 0), 0.0, REAR_LOWER_LENGTH)
	bones.front_upper = _bone("FrontUpperArm", bones.spine, Vector2(38, -170), 0.0, FRONT_UPPER_LENGTH)
	bones.front_forearm = _bone("FrontForearm", bones.front_upper, Vector2(FRONT_UPPER_LENGTH - 22.0, 0), 0.0, FRONT_LOWER_LENGTH)
	bones.bow_grip = _bone("BowGrip", bones.front_forearm, Vector2(FRONT_LOWER_LENGTH - 18.0, 0), 0.0, 145.0)
	bones.arrow = _bone("NockedArrow", skeleton, Vector2(200, -155), 0.0, 300.0)

	bones.rear_thigh = _bone("RearThigh", bones.pelvis, Vector2(-32, 16), 0.0, REAR_THIGH_LENGTH)
	bones.rear_shin = _bone("RearShin", bones.rear_thigh, Vector2(REAR_THIGH_LENGTH - 28.0, 0), 0.0, REAR_SHIN_LENGTH)
	bones.front_thigh = _bone("FrontThigh", bones.pelvis, Vector2(32, 16), 0.0, FRONT_THIGH_LENGTH)
	bones.front_shin = _bone("FrontShin", bones.front_thigh, Vector2(FRONT_THIGH_LENGTH - 25.0, 0), 0.0, FRONT_SHIN_LENGTH)

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


func _apply_pose(time_value: float) -> void:
	var idle_wave := sin(time_value * TAU / 1.2)
	var aim := _ramp(time_value, 0.42, 0.82)
	var draw_amount := _ramp(time_value, 0.82, 1.62)
	var release := _ramp(time_value, 1.62, 1.74)
	var recoil := _pulse(time_value, 1.68, 1.91, 2.18)
	var recover := _ramp(time_value, 2.14, 3.12)
	var action_weight := clampf(max(aim, draw_amount) - recover, 0.0, 1.0)

	var bounce := idle_wave * 3.0 - recoil * 6.0
	skeleton.position.y = 382.0 + bounce
	bones.spine.rotation = -0.025 * draw_amount + 0.075 * recoil
	bones.head.rotation = -0.025 * draw_amount - 0.085 * recoil + idle_wave * 0.008
	bones.hat.rotation = -0.035 * recoil + idle_wave * 0.012
	bones.feather.rotation = idle_wave * 0.055 - recoil * 0.22
	bones.quiver.rotation = -0.20 - recoil * 0.06
	bones.pouch.rotation = 0.08 + recoil * 0.07

	var bow_target := Vector2(196, -58).lerp(Vector2(278, -156), aim)
	bow_target += Vector2(-12, 8) * recoil
	var draw_target := Vector2(82, -52).lerp(Vector2(62, -176), max(aim * 0.58, draw_amount))
	draw_target += Vector2(-8, 10) * recoil

	_solve_two_bone(bones.front_upper, bones.front_forearm, bow_target, FRONT_UPPER_LENGTH - 22.0, FRONT_LOWER_LENGTH - 18.0, 1.0)
	_solve_two_bone(bones.rear_upper, bones.rear_forearm, draw_target, REAR_UPPER_LENGTH - 24.0, REAR_LOWER_LENGTH - 20.0, 1.0)

	var planted_y := 456.0 - bounce / 0.38
	var front_foot := Vector2(48 + action_weight * 14.0, planted_y)
	var rear_foot := Vector2(-44 - action_weight * 9.0, planted_y - 3.0)
	_solve_two_bone(bones.front_thigh, bones.front_shin, front_foot, FRONT_THIGH_LENGTH - 25.0, FRONT_SHIN_LENGTH - 18.0, -1.0)
	_solve_two_bone(bones.rear_thigh, bones.rear_shin, rear_foot, REAR_THIGH_LENGTH - 28.0, REAR_SHIN_LENGTH - 20.0, 1.0)

	bones.bow_grip.global_rotation = skeleton.global_rotation + 0.02 + recoil * 0.10
	var bow_local := skeleton.to_local(bones.bow_grip.global_position)
	var nock_local := draw_target
	if release > 0.0:
		nock_local = draw_target.lerp(Vector2(650, -156), release)
	bones.arrow.position = nock_local
	bones.arrow.rotation = -0.01 * draw_amount
	sprites.arrow.visible = time_value < 1.79

	var string_nock := draw_target if release <= 0.0 else bow_local + Vector2(-96, 0)
	bow_string.points = PackedVector2Array([
		bow_local + Vector2(-92, -145),
		string_nock,
		bow_local + Vector2(-92, 145)
	])


func _solve_two_bone(upper: Bone2D, lower: Bone2D, target_local: Vector2, upper_length: float, lower_length: float, bend_sign: float) -> void:
	var origin_local := skeleton.to_local(upper.global_position)
	var delta := target_local - origin_local
	var distance := clampf(delta.length(), absf(upper_length - lower_length) + 1.0, upper_length + lower_length - 1.0)
	var target_angle := delta.angle()
	var cosine_shoulder := clampf((upper_length * upper_length + distance * distance - lower_length * lower_length) / (2.0 * upper_length * distance), -1.0, 1.0)
	var shoulder_offset := acos(cosine_shoulder) * bend_sign
	var upper_angle := target_angle + shoulder_offset
	upper.global_rotation = skeleton.global_rotation + upper_angle

	var elbow_local := origin_local + Vector2(upper_length, 0).rotated(upper_angle)
	var lower_angle := (target_local - elbow_local).angle()
	lower.global_rotation = skeleton.global_rotation + lower_angle


func _ramp(value: float, start: float, finish: float) -> float:
	return smoothstep(start, finish, value)


func _pulse(value: float, start: float, peak: float, finish: float) -> float:
	if value <= start or value >= finish:
		return 0.0
	if value <= peak:
		return smoothstep(start, peak, value)
	return 1.0 - smoothstep(peak, finish, value)


func _capture_deferred() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var absolute_path := ProjectSettings.globalize_path(capture_path)
	var error := image.save_png(absolute_path)
	if error != OK:
		push_error("Could not save skeleton preview capture: " + absolute_path)
	get_tree().quit(error)

