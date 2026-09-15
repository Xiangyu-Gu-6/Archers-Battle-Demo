class_name BattleTerrain
extends Node2D

const STEP := 40.0
const SOIL_TEXTURE := preload("res://assets/art/environments/terrain_soil_tile_512_v01.png")
const GRASS_TEXTURE := preload("res://assets/art/environments/terrain_grass_edge_strip_1024x64_v01.png")
var world_width := 2400.0
var world_bottom := 760.0
var heights: PackedFloat32Array
var seed_value := 0
var template_type := 0
var primary_feature_x := 1200.0
var left_zone := Vector2(190.0, 670.0)
var right_zone := Vector2(1730.0, 2210.0)
var grass_line: Line2D

func generate(seed_to_use: int, previous_signature := {}) -> Dictionary:
	seed_value = seed_to_use
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var attempts := 0
	while attempts < 20:
		template_type = posmod(seed_value + attempts, 3)
		_build_candidate(rng, template_type)
		if _basic_valid() and not _too_similar(previous_signature):
			_refresh_art()
			return {"seed": seed_value, "attempts": attempts + 1, "fallback": false, "template": template_name(), "signature": signature()}
		attempts += 1
	var previous_template := int(previous_signature.get("template", -1))
	template_type = posmod(previous_template + 1 + int(seed_value % 2), 3)
	_build_fallback(template_type)
	_refresh_art()
	return {"seed": seed_value, "attempts": 20, "fallback": true, "template": template_name(), "signature": signature()}

func _build_candidate(rng: RandomNumberGenerator, which_template: int) -> void:
	var count := int(world_width / STEP) + 1
	heights = PackedFloat32Array()
	heights.resize(count)
	var base := rng.randf_range(515.0, 585.0)
	var phase := rng.randf_range(0.0, TAU)
	primary_feature_x = rng.randf_range(900.0, 1500.0)
	var hill_h := rng.randf_range(38.0, 105.0)
	var hill_w := rng.randf_range(210.0, 390.0)
	var left_dip_x := rng.randf_range(390.0, 570.0)
	var right_dip_x := rng.randf_range(1830.0, 2010.0)
	for i in count:
		var x := i * STEP
		var side_detail := sin(x / 118.0 + phase) * 22.0 + sin(x / 245.0 + phase * 0.6) * 15.0
		var shape := 0.0
		match which_template:
			0: # 低中央丘陵
				shape = sin(x / 430.0 + phase) * 18.0 - hill_h * 0.72 * exp(-pow((x - primary_feature_x) / hill_w, 2.0))
			1: # 左右不等高坡地
				shape = lerpf(-58.0, 58.0, x / world_width) + sin(x / 360.0 + phase) * 23.0 - hill_h * 0.45 * exp(-pow((x - primary_feature_x) / hill_w, 2.0))
			2: # 浅凹位错落坡地
				var left_dip := 42.0 * exp(-pow((x - left_dip_x) / 175.0, 2.0))
				var right_dip := 42.0 * exp(-pow((x - right_dip_x) / 175.0, 2.0))
				shape = left_dip + right_dip - hill_h * 0.6 * exp(-pow((x - primary_feature_x) / hill_w, 2.0))
		heights[i] = clampf(base + side_detail + shape, 390.0, 625.0)
	_limit_slopes(13.0)
	_soften_spawn_pad((left_zone.x + left_zone.y) * 0.5)
	_soften_spawn_pad((right_zone.x + right_zone.y) * 0.5)
	_limit_slopes(13.0)

func _build_fallback(which_template: int) -> void:
	var count := int(world_width / STEP) + 1
	heights = PackedFloat32Array()
	heights.resize(count)
	for i in count:
		var x := i * STEP
		match which_template:
			0: heights[i] = 550.0 + sin(x / 330.0) * 24.0 - 48.0 * exp(-pow((x - 1150.0) / 320.0, 2.0))
			1: heights[i] = 500.0 + x / world_width * 92.0 + sin(x / 270.0) * 20.0
			_: heights[i] = 535.0 + sin(x / 250.0) * 18.0 + 34.0 * exp(-pow((x - 480.0) / 180.0, 2.0)) + 34.0 * exp(-pow((x - 1920.0) / 180.0, 2.0)) - 42.0 * exp(-pow((x - 1260.0) / 300.0, 2.0))
	primary_feature_x = 1150.0 if which_template == 0 else 1200.0 if which_template == 1 else 1260.0
	_soften_spawn_pad((left_zone.x + left_zone.y) * 0.5)
	_soften_spawn_pad((right_zone.x + right_zone.y) * 0.5)
	_limit_slopes(13.0)

func _soften_spawn_pad(mid: float) -> void:
	var target := surface_y(mid)
	for i in heights.size():
		var x := i * STEP
		var distance := absf(x - mid)
		if distance <= 65.0:
			heights[i] = lerpf(heights[i], target, 0.82 * (1.0 - distance / 65.0))

func template_name() -> String:
	return ["Central Hill", "Split Slopes", "Shallow Basin"][template_type]

func signature() -> Dictionary:
	var samples := PackedFloat32Array()
	for i in 25: samples.append(surface_y(world_width * float(i) / 24.0))
	return {"template": template_type, "feature_x": primary_feature_x, "samples": samples}

func _too_similar(previous: Dictionary) -> bool:
	if previous.is_empty(): return false
	var old_samples: PackedFloat32Array = previous.get("samples", PackedFloat32Array())
	if old_samples.size() != 25: return false
	var difference := 0.0
	var current_signature: Dictionary = signature()
	var current: PackedFloat32Array = current_signature.samples
	for i in 25: difference += absf(current[i] - old_samples[i])
	var average := difference / 25.0
	return average < 15.0 and absf(primary_feature_x - float(previous.get("feature_x", -9999.0))) < 120.0

func _limit_slopes(max_delta: float) -> void:
	for i in range(1, heights.size()):
		heights[i] = clampf(heights[i], heights[i - 1] - max_delta, heights[i - 1] + max_delta)
	for i in range(heights.size() - 2, -1, -1):
		heights[i] = clampf(heights[i], heights[i + 1] - max_delta, heights[i + 1] + max_delta)

func _basic_valid() -> bool:
	if heights.size() <= 2 or absf(surface_y(430.0) - surface_y(1970.0)) >= 190.0:
		return false
	var left_samples := [left_zone.x + 90.0, (left_zone.x + left_zone.y) * 0.5, left_zone.y - 90.0]
	var right_samples := [right_zone.x + 90.0, (right_zone.x + right_zone.y) * 0.5, right_zone.y - 90.0]
	for x in left_samples:
		if not _has_ballistic_route(x, right_samples[1], 1.0): return false
	for x in right_samples:
		if not _has_ballistic_route(x, left_samples[1], -1.0): return false
	return true

func _has_ballistic_route(from_x: float, to_x: float, direction: float) -> bool:
	var target := Vector2(to_x, surface_y(to_x) - 52.0)
	for angle in range(20, 81, 5):
		for power_step in range(2, 11):
			var power := power_step / 10.0
			var launch_dir := Vector2(cos(deg_to_rad(angle)) * direction, -sin(deg_to_rad(angle)))
			var pos := Vector2(from_x, surface_y(from_x) - 58.0) + launch_dir * 34.0
			var vel := launch_dir * lerpf(250.0, 1450.0, power)
			var dt := 1.0 / 30.0
			for step in 210:
				var next := pos + vel * dt + Vector2(0.0, 700.0) * 0.5 * dt * dt
				if next.distance_to(target) < 64.0: return true
				if segment_hit(pos, next).hit: break
				if next.x < -80.0 or next.x > world_width + 80.0 or next.y > world_bottom + 80.0: break
				pos = next
				vel.y += 700.0 * dt
	return false


func surface_y(x: float) -> float:
	if heights.is_empty(): return 560.0
	var cx := clampf(x, 0.0, world_width)
	var idx := mini(int(cx / STEP), heights.size() - 2)
	var t := (cx - idx * STEP) / STEP
	return lerpf(heights[idx], heights[idx + 1], t)

func segment_hit(a: Vector2, b: Vector2) -> Dictionary:
	var distance := a.distance_to(b)
	var steps := maxi(2, int(ceil(distance / 6.0)))
	for i in range(1, steps + 1):
		var t := float(i) / steps
		var p := a.lerp(b, t)
		if p.x >= 0.0 and p.x <= world_width and p.y >= surface_y(p.x):
			return {"hit": true, "t": t, "point": p}
	return {"hit": false}

func random_spawn(side: int, rng: RandomNumberGenerator) -> float:
	var zone := left_zone if side == 0 else right_zone
	return rng.randf_range(zone.x + 60.0, zone.y - 60.0)

func surface_distance(from_x: float, to_x: float) -> float:
	if is_equal_approx(from_x, to_x): return 0.0
	var direction := signf(to_x - from_x)
	var x := from_x
	var distance := 0.0
	while (to_x - x) * direction > 0.001:
		var next_x := x + direction * minf(STEP * 0.25, absf(to_x - x))
		distance += Vector2(x, surface_y(x)).distance_to(Vector2(next_x, surface_y(next_x)))
		x = next_x
	return distance

func advance_along_surface(from_x: float, direction: float, distance: float, zone: Vector2) -> float:
	var candidate := clampf(from_x + direction * distance, zone.x + 20.0, zone.y - 20.0)
	if surface_distance(from_x, candidate) <= distance: return candidate
	var low := minf(from_x, candidate)
	var high := maxf(from_x, candidate)
	for iteration in 12:
		var middle := (low + high) * 0.5
		if surface_distance(from_x, middle) <= distance:
			if direction > 0.0: low = middle
			else: high = middle
		else:
			if direction > 0.0: high = middle
			else: low = middle
	return low if direction > 0.0 else high

func reachable_interval(start_x: float, budget: float, side: int) -> Vector2:
	var zone := left_zone if side == 0 else right_zone
	return Vector2(advance_along_surface(start_x, -1.0, budget, zone), advance_along_surface(start_x, 1.0, budget, zone))

func _draw() -> void:
	if heights.is_empty(): return
	var poly := PackedVector2Array([Vector2(0.0, world_bottom)])
	var uvs := PackedVector2Array([Vector2(0.0, world_bottom / 512.0)])
	var ridge := PackedVector2Array()
	for i in heights.size():
		var p := Vector2(i * STEP, heights[i])
		poly.append(p)
		uvs.append(p / 512.0)
		ridge.append(p)
	poly.append(Vector2(world_width, world_bottom))
	uvs.append(Vector2(world_width / 512.0, world_bottom / 512.0))
	draw_colored_polygon(poly, Color.WHITE, uvs, SOIL_TEXTURE)
	draw_line(Vector2(left_zone.x, surface_y(left_zone.x) - 5.0), Vector2(left_zone.x, world_bottom), Color("#55a8ff55"), 2.0)
	draw_line(Vector2(left_zone.y, surface_y(left_zone.y) - 5.0), Vector2(left_zone.y, world_bottom), Color("#55a8ff55"), 2.0)
	draw_line(Vector2(right_zone.x, surface_y(right_zone.x) - 5.0), Vector2(right_zone.x, world_bottom), Color("#ff766c55"), 2.0)
	draw_line(Vector2(right_zone.y, surface_y(right_zone.y) - 5.0), Vector2(right_zone.y, world_bottom), Color("#ff766c55"), 2.0)

func _refresh_art() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	if not is_instance_valid(grass_line):
		grass_line = Line2D.new()
		grass_line.name = "GrassEdge"
		grass_line.width = 56.0
		grass_line.texture = GRASS_TEXTURE
		grass_line.texture_mode = Line2D.LINE_TEXTURE_TILE
		grass_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		grass_line.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		grass_line.joint_mode = Line2D.LINE_JOINT_ROUND
		grass_line.begin_cap_mode = Line2D.LINE_CAP_BOX
		grass_line.end_cap_mode = Line2D.LINE_CAP_BOX
		grass_line.z_index = 1
		add_child(grass_line)
	var points := PackedVector2Array()
	for i in heights.size(): points.append(Vector2(i * STEP, heights[i] + 22.0))
	grass_line.points = points
	queue_redraw()
