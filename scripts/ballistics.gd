class_name Ballistics
extends RefCounted

const DEFAULT_STEP := 1.0 / 60.0

static func advance(position: Vector2, velocity: Vector2, delta: float, gravity: float, terrain, target = null) -> Dictionary:
	var next_position := position + velocity * delta + Vector2(0.0, gravity) * 0.5 * delta * delta
	var next_velocity := velocity + Vector2(0.0, gravity) * delta
	var ground_hit: Dictionary = terrain.segment_hit(position, next_position)
	var actor_hit := {"hit": false}
	if is_instance_valid(target): actor_hit = target.segment_hit(position, next_position)
	var collision := {"hit": false}
	if ground_hit.hit:
		collision = {"hit": true, "kind": &"terrain", "t": ground_hit.t, "point": ground_hit.point}
	if actor_hit.hit and (not collision.hit or actor_hit.t < collision.t):
		collision = {"hit": true, "kind": &"actor", "part": actor_hit.part, "t": actor_hit.t, "point": actor_hit.point}
	if collision.hit: next_position = collision.point
	return {"position": next_position, "velocity": next_velocity, "collision": collision}

static func trace(origin: Vector2, initial_velocity: Vector2, gravity: float, timeout: float, world_width: float, world_bottom: float, terrain, target = null, step_delta := DEFAULT_STEP) -> Dictionary:
	var points := PackedVector2Array([origin])
	var position := origin
	var velocity := initial_velocity
	var elapsed := 0.0
	var closest := INF
	var target_center := Vector2.ZERO
	if is_instance_valid(target): target_center = target.global_position + Vector2(0.0, -50.0)
	var max_steps := mini(720, int(ceil(timeout / step_delta)) + 1)
	for step in max_steps:
		var frame := advance(position, velocity, step_delta, gravity, terrain, target)
		position = frame.position
		velocity = frame.velocity
		elapsed += step_delta
		points.append(position)
		if is_instance_valid(target): closest = minf(closest, position.distance_to(target_center))
		if frame.collision.hit:
			return {"points": points, "result": frame.collision, "closest": closest, "elapsed": elapsed}
		if position.x < -120.0 or position.x > world_width + 120.0 or position.y > world_bottom + 180.0:
			return {"points": points, "result": {"hit": false, "kind": &"out_of_bounds", "point": position}, "closest": closest, "elapsed": elapsed}
	return {"points": points, "result": {"hit": false, "kind": &"timeout", "point": position}, "closest": closest, "elapsed": elapsed}

static func first_fraction_by_arc(points: PackedVector2Array, fraction: float) -> PackedVector2Array:
	if points.size() < 2: return points
	var total := 0.0
	for i in range(points.size() - 1): total += points[i].distance_to(points[i + 1])
	var target_length := total * clampf(fraction, 0.0, 1.0)
	var result := PackedVector2Array([points[0]])
	var traversed := 0.0
	for i in range(points.size() - 1):
		var segment := points[i].distance_to(points[i + 1])
		if traversed + segment >= target_length:
			var remaining := target_length - traversed
			result.append(points[i].lerp(points[i + 1], remaining / segment if segment > 0.0001 else 0.0))
			break
		result.append(points[i + 1])
		traversed += segment
	return result


