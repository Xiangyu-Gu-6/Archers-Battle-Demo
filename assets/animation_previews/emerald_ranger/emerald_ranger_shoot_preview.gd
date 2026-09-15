extends Node2D

const PART_ROOT := "res://assets/art/characters/emerald_ranger/rig_parts_v02/"
const TAU_12FPS := 1.0 / 12.0
const CYCLE_SECONDS := 3.2

var rig: Node2D
var parts: Dictionary = {}
var bow_string: Line2D
var fixed_phase := -1.0
var capture_path := ""


func _ready() -> void:
	_parse_preview_arguments()
	_build_rig()
	queue_redraw()
	if fixed_phase >= 0.0:
		_apply_pose(fixed_phase)
	if not capture_path.is_empty():
		_capture_deferred.call_deferred()


func _process(_delta: float) -> void:
	if fixed_phase < 0.0:
		var sampled_time: float = floor(Time.get_ticks_msec() / 1000.0 / TAU_12FPS) * TAU_12FPS
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


func _build_rig() -> void:
	rig = Node2D.new()
	rig.name = "EmeraldRangerRig"
	rig.position = Vector2(500, 384)
	rig.scale = Vector2.ONE * 0.38
	add_child(rig)

	parts.quiver = _part("quiver", rig, Vector2(-82, -92), Vector2(116, 245), -0.20, -8)
	parts.rear_thigh = _part("rear_thigh", rig, Vector2(-35, 18), Vector2(66, 27), 0.10, -6)
	parts.rear_shin = _part("rear_lower_leg_boot", parts.rear_thigh, Vector2(44, 230), Vector2(76, 28), -0.10, -6)
	parts.rear_upper = _part("rear_upper_arm", rig, Vector2(-45, -175), Vector2(72, 36), 1.35, -5)
	parts.rear_forearm = _part("rear_forearm_hand", parts.rear_upper, Vector2(52, 218), Vector2(27, 61), -1.22, -4)

	parts.torso = _part("torso", rig, Vector2(0, 0), Vector2(161, 240), 0.0, 0)
	parts.front_thigh = _part("front_thigh", rig, Vector2(34, 18), Vector2(60, 28), -0.06, 2)
	parts.front_shin = _part("front_lower_leg_boot", parts.front_thigh, Vector2(-8, 190), Vector2(75, 28), 0.06, 2)
	parts.pouch = _part("belt_pouch", rig, Vector2(74, -20), Vector2(95, 80), 0.08, 3)
	parts.head = _part("head", rig, Vector2(8, -218), Vector2(151, 258), 0.0, 4)
	parts.hat = _part("hat", rig, Vector2(2, -390), Vector2(162, 135), -0.03, 6)
	parts.feather = _part("hat_feather", rig, Vector2(62, -408), Vector2(286, 184), -0.04, 7)

	parts.front_upper = _part("front_upper_arm", rig, Vector2(38, -170), Vector2(106, 34), -0.68, 8)
	parts.front_forearm = _part("front_forearm_hand", parts.front_upper, Vector2(-42, 166), Vector2(30, 145), 0.70, 9)
	parts.bow = _part("bow", rig, Vector2(278, -155), Vector2(116, 158), -0.06, 10)
	parts.arrow = _part("nocked_arrow", rig, Vector2(245, -155), Vector2(20, 40), 0.0, 12)

	bow_string = Line2D.new()
	bow_string.name = "BowStringVFX"
	bow_string.width = 3.0
	bow_string.default_color = Color("#f7e7bf")
	bow_string.z_index = 11
	bow_string.antialiased = true
	rig.add_child(bow_string)


func _part(file_stem: String, parent: Node2D, position_value: Vector2, pivot: Vector2, rotation_value: float, z_value: int) -> Node2D:
	var joint := Node2D.new()
	joint.name = file_stem.to_pascal_case()
	joint.position = position_value
	joint.rotation = rotation_value
	parent.add_child(joint)

	var sprite := Sprite2D.new()
	var asset_version := "v03" if file_stem == "hat_feather" else "v02"
	sprite.texture = load(PART_ROOT + "emerald_ranger_" + file_stem + "_" + asset_version + ".png")
	sprite.centered = false
	sprite.position = -pivot
	sprite.z_index = z_value
	joint.add_child(sprite)
	return joint


func _apply_pose(time_value: float) -> void:
	var idle_wave := sin(time_value * TAU / 1.15)
	var aim := _ramp(time_value, 0.45, 0.82)
	var draw := _ramp(time_value, 0.82, 1.62)
	var release := _ramp(time_value, 1.62, 1.74)
	var recoil := _pulse(time_value, 1.68, 1.92, 2.18)
	var recover := _ramp(time_value, 2.15, 3.12)
	var action_weight := clampf(max(aim, draw) - recover, 0.0, 1.0)

	rig.position.y = 384.0 + idle_wave * 2.8 - recoil * 5.0
	parts.torso.rotation = -0.025 * draw + 0.08 * recoil
	parts.head.rotation = -0.035 * draw - 0.10 * recoil + idle_wave * 0.008
	parts.hat.rotation = -0.03 - 0.05 * recoil + idle_wave * 0.01
	parts.feather.rotation = -0.04 - 0.16 * recoil + idle_wave * 0.025

	parts.front_upper.rotation = lerpf(-0.68, -1.30, aim) + 0.10 * recoil
	parts.front_forearm.rotation = lerpf(0.70, 1.28, aim) - 0.08 * recoil
	parts.rear_upper.rotation = lerpf(1.35, 2.18, max(aim, draw)) - 0.14 * recoil
	parts.rear_forearm.rotation = lerpf(-1.22, -2.13, draw) + 0.20 * recoil

	parts.front_thigh.rotation = -0.06 - 0.06 * action_weight
	parts.front_shin.rotation = 0.06 + 0.08 * action_weight
	parts.rear_thigh.rotation = 0.10 + 0.05 * action_weight
	parts.rear_shin.rotation = -0.10 - 0.06 * action_weight

	parts.bow.rotation = -0.06 + 0.035 * draw + 0.13 * recoil
	var nock_x := lerpf(245.0, 78.0, draw)
	if release > 0.0:
		nock_x = lerpf(78.0, 615.0, release)
	parts.arrow.position = Vector2(nock_x, -155.0 - 4.0 * draw)
	parts.arrow.visible = time_value < 1.79

	var string_nock_x := lerpf(262.0, 78.0, draw)
	if release > 0.0:
		string_nock_x = 262.0
	bow_string.points = PackedVector2Array([
		Vector2(255, -299),
		Vector2(string_nock_x, -155),
		Vector2(258, -15)
	])
	bow_string.visible = time_value < 2.9


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
		push_error("Could not save preview capture: " + absolute_path)
	get_tree().quit(error)
