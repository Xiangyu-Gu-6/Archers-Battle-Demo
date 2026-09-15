extends SceneTree

const MainScene := preload("res://scenes/Main.tscn")
const TerrainScript := preload("res://scripts/terrain.gd")
const ArcherScript := preload("res://scripts/archer.gd")
const BallisticsScript := preload("res://scripts/ballistics.gd")
const BalanceScript := preload("res://scripts/game_balance.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _run() -> void:
	var balance = BalanceScript.new()
	check(is_equal_approx(balance.charge_half_cycle, 2.0), "charge half-cycle must be 2 seconds")
	check(is_equal_approx(balance.move_budget, 180.0), "move budget must be five 36-unit body widths")
	await _test_terrain_and_ballistics(balance)
	await _test_ui_and_match_lifecycle()
	if failures.is_empty():
		print("V2_ACCEPTANCE_OK seeds=100 templates=3 restarts=20 ui_chain=true ballistics_shared=true")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _test_terrain_and_ballistics(balance) -> void:
	var previous := {}
	var templates := {}
	for seed_value in range(2200, 2300):
		var terrain = TerrainScript.new()
		terrain.world_width = balance.world_width
		terrain.world_bottom = balance.world_bottom
		root.add_child(terrain)
		var generated: Dictionary = terrain.generate(seed_value, previous)
		check(generated.attempts <= 20, "seed %d exceeded retry budget" % seed_value)
		templates[generated.template] = true
		var interval: Vector2 = terrain.reachable_interval(430.0, balance.move_budget, 0)
		check(terrain.surface_distance(430.0, interval.x) <= balance.move_budget + 0.25, "left reachable range exceeds budget")
		check(terrain.surface_distance(430.0, interval.y) <= balance.move_budget + 0.25, "right reachable range exceeds budget")
		previous = generated.signature
		terrain.free()
	check(templates.size() == 3, "all three terrain templates must appear in 100 seeds")

	var terrain = TerrainScript.new()
	root.add_child(terrain)
	terrain.generate(987654)
	var shooter = ArcherScript.new()
	var target = ArcherScript.new()
	root.add_child(shooter)
	root.add_child(target)
	shooter.setup(0, "射手", Color.WHITE, 100)
	target.setup(1, "目标", Color.WHITE, 100)
	shooter.position = Vector2(430.0, terrain.surface_y(430.0))
	target.position = Vector2(1970.0, terrain.surface_y(1970.0))
	shooter.aim_angle = 47.0
	var origin: Vector2 = shooter.muzzle_position()
	var velocity: Vector2 = shooter.launch_direction() * balance.launch_speed(0.58)
	var trace: Dictionary = BallisticsScript.trace(origin, velocity, balance.gravity, balance.arrow_timeout, balance.world_width, balance.world_bottom, terrain, target)
	var position := origin
	var current_velocity := velocity
	for i in range(1, trace.points.size()):
		var frame: Dictionary = BallisticsScript.advance(position, current_velocity, BallisticsScript.DEFAULT_STEP, balance.gravity, terrain, target)
		check(frame.position.distance_to(trace.points[i]) < 0.01, "preview and real step diverged at %d" % i)
		position = frame.position
		current_velocity = frame.velocity
		if frame.collision.hit: break
	var half: PackedVector2Array = BallisticsScript.first_fraction_by_arc(trace.points, 0.5)
	var full_length := _arc_length(trace.points)
	var half_length := _arc_length(half)
	check(absf(half_length - full_length * 0.5) < 0.25, "displayed prediction must be half of full arc length")
	shooter.free()
	target.free()
	terrain.free()
	await process_frame

func _test_ui_and_match_lifecycle() -> void:
	var game = MainScene.instantiate()
	root.add_child(game)
	while game.rebuilding_match: await process_frame
	game.turn_token += 1
	game.current_side = 0
	game.phase = game.Phase.SELECT
	game._update_ui()
	game.move_button.pressed.emit()
	check(game.phase == game.Phase.MOVE, "move button must enter move preview")
	check(not game.move_committed and game.cancel_button.visible, "unmoved action must be cancellable")
	game.cancel_button.pressed.emit()
	check(game.phase == game.Phase.SELECT, "cancel button must return to action choice")
	game.shoot_button.pressed.emit()
	check(game.phase == game.Phase.AIM, "shoot button must enter aim")
	game.cancel_button.pressed.emit()
	check(game.phase == game.Phase.SELECT, "uncommitted aim must be cancellable")
	game.shoot_button.pressed.emit()
	game._fire_arrow(0, 0.5)
	check(game.pending_player_shot.has("trajectory"), "player shot must retain its previous trajectory")
	check(game.pending_player_shot.trajectory.size() > 1, "retained player trajectory must contain drawable points")

	var seeds := {}
	for iteration in 20:
		var old_root = game.match_root
		game.phase = game.Phase.GAME_OVER
		game.again_button.disabled = false
		game.again_button.pressed.emit()
		while game.rebuilding_match: await process_frame
		check(game.match_root != old_root, "restart %d must replace MatchRoot" % iteration)
		check(game.archers[0].health == 100 and game.archers[1].health == 100, "restart %d must restore health" % iteration)
		check(game.landed_arrows.is_empty() and game.last_player_shot.is_empty(), "restart %d must clear shot state" % iteration)
		check(not seeds.has(game.current_seed), "restart %d repeated a seed" % iteration)
		seeds[game.current_seed] = true
	game.queue_free()
	await process_frame

func _arc_length(points: PackedVector2Array) -> float:
	var length := 0.0
	for i in range(points.size() - 1): length += points[i].distance_to(points[i + 1])
	return length
