class_name BattleTerrain
extends Node2D

const STEP := 40.0
var world_width := 2400.0
var world_bottom := 760.0
var heights: PackedFloat32Array
var seed_value := 0
var left_zone := Vector2(190.0, 670.0)
var right_zone := Vector2(1730.0, 2210.0)

func generate(seed_to_use: int) -> Dictionary:
	seed_value = seed_to_use
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var attempts := 0
	while attempts < 20:
		_build_candidate(rng)
		if _basic_valid():
			queue_redraw()
			return {"seed": seed_value, "attempts": attempts + 1, "fallback": false}
		attempts += 1
	_build_fallback()
	queue_redraw()
	return {"seed": seed_value, "attempts": 20, "fallback": true}

func _build_candidate(rng: RandomNumberGenerator) -> void:
	var count := int(world_width / STEP) + 1
	heights = PackedFloat32Array()
	heights.resize(count)
	var base := rng.randf_range(525.0, 585.0)
	var phase := rng.randf_range(0.0, TAU)
	var hill_x := rng.randf_range(1020.0, 1380.0)
	var hill_h := rng.randf_range(45.0, 125.0)
	var hill_w := rng.randf_range(190.0, 360.0)
	for i in count:
		var x := i * STEP
		var rolling := sin(x / 310.0 + phase) * 48.0 + sin(x / 137.0 + phase * 0.7) * 17.0
		var mound := hill_h * exp(-pow((x - hill_x) / hill_w, 2.0))
		heights[i] = clampf(base + rolling - mound, 390.0, 620.0)
	_limit_slopes(17.0)
	_flatten_zone(left_zone.x, left_zone.y)
	_flatten_zone(right_zone.x, right_zone.y)
	_limit_slopes(16.0)

func _build_fallback() -> void:
	var count := int(world_width / STEP) + 1
	heights = PackedFloat32Array()
	heights.resize(count)
	for i in count:
		var x := i * STEP
		heights[i] = 555.0 + sin(x / 340.0) * 30.0 - 55.0 * exp(-pow((x - 1200.0) / 290.0, 2.0))
	_flatten_zone(left_zone.x, left_zone.y)
	_flatten_zone(right_zone.x, right_zone.y)

func _flatten_zone(from_x: float, to_x: float) -> void:
	var mid := (from_x + to_x) * 0.5
	var target := surface_y(mid)
	for i in heights.size():
		var x := i * STEP
		if x >= from_x and x <= to_x:
			var edge := minf((x - from_x) / 90.0, (to_x - x) / 90.0)
			var blend := clampf(edge, 0.0, 1.0) * 0.72
			heights[i] = lerpf(heights[i], target, blend)

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

func _draw() -> void:
	if heights.is_empty(): return
	var poly := PackedVector2Array([Vector2(0.0, world_bottom)])
	var ridge := PackedVector2Array()
	for i in heights.size():
		var p := Vector2(i * STEP, heights[i])
		poly.append(p)
		ridge.append(p)
	poly.append(Vector2(world_width, world_bottom))
	draw_colored_polygon(poly, Color("#263f35"))
	draw_polyline(ridge, Color("#8fc57f"), 5.0, true)
	draw_line(Vector2(left_zone.x, surface_y(left_zone.x) - 5.0), Vector2(left_zone.x, world_bottom), Color("#55a8ff55"), 2.0)
	draw_line(Vector2(left_zone.y, surface_y(left_zone.y) - 5.0), Vector2(left_zone.y, world_bottom), Color("#55a8ff55"), 2.0)
	draw_line(Vector2(right_zone.x, surface_y(right_zone.x) - 5.0), Vector2(right_zone.x, world_bottom), Color("#ff766c55"), 2.0)
	draw_line(Vector2(right_zone.y, surface_y(right_zone.y) - 5.0), Vector2(right_zone.y, world_bottom), Color("#ff766c55"), 2.0)

