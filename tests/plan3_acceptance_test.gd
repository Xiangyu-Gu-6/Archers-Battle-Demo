extends SceneTree

const MainScene := preload("res://scenes/Main.tscn")
const BarrierScript := preload("res://scripts/architect_barrier.gd")
const BallisticsScript := preload("res://scripts/ballistics.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _run() -> void:
	var game = MainScene.instantiate()
	root.add_child(game)
	check(game.phase == game.Phase.HERO_SELECT, "startup must show hero selection")
	check(game.hero_panel.visible and game.selected_role == &"ranger", "ranger must be preselected")
	for role in [&"ranger", &"shark", &"architect"]:
		game._select_hero(role)
		game._start_selected_match()
		while game.rebuilding_match: await process_frame
		game.turn_token += 1
		game.current_side = 0
		game.phase = game.Phase.SELECT
		check(game.archers[0].role_id == role, "player role does not match selection: %s" % role)
		check(game.archers[1].role_id != role, "CPU must use one of the other two heroes")
		check(game.archers[0].skill_uses == 1 and game.archers[1].skill_uses == 1, "both skill counters must reset")
		if role == &"ranger":
			game._choose_skill()
			check(game.phase == game.Phase.AIM and game.preview_trails.size() == 3, "scatter needs three preview trails")
			game._fire_arrow(0, 0.5)
			check(game.active_arrows.size() == 3 and game.remaining_arrows == 3, "scatter needs three real arrows")
			check(game.archers[0].skill_uses == 0, "scatter skill must be consumed once")
			var hp_before: int = game.archers[1].health
			for arrow in game.active_arrows.duplicate():
				game._on_arrow_stopped({"hit": true, "kind": &"actor", "part": &"torso", "point": game.archers[1].position}, game.turn_token, arrow)
			check(game.archers[1].health == hp_before - 72, "three torso arrows must each deal 24")
			check(game.phase == game.Phase.RESOLVE, "turn cannot resolve until all three arrows stop")
		elif role == &"shark":
			game._choose_skill()
			game._fire_arrow(0, 0.5)
			check(game.active_arrows.size() == 1, "heavy attack is one arrow")
			check(is_equal_approx(game.active_arrows[0].damage_multiplier, 1.5), "heavy multiplier must be 150 percent")
			game._on_arrow_stopped({"hit": true, "kind": &"actor", "part": &"torso", "point": game.archers[1].position}, game.turn_token, game.active_arrows[0])
			check(game.archers[1].health == 55, "heavy torso hit must deal 45")
		else:
			game._choose_skill()
			check(game.phase == game.Phase.BUILD, "architect skill must enter placement")
			var candidate: float = game.terrain.left_zone.x + game.balance.barrier_width
			while candidate < game.terrain.left_zone.y - game.balance.barrier_width and not game._barrier_placement_valid(0, candidate):
				candidate += 20.0
			game._update_barrier_preview(candidate)
			check(game.barrier_preview.valid_placement, "own-zone candidate must be valid")
			game._place_barrier()
			check(game.barriers.size() == 1 and game.archers[0].skill_uses == 0, "placement consumes action and skill")
			if game.barriers.is_empty():
				game._show_hero_select()
				continue
			var barrier = game.barriers[0]
			var y: float = barrier.position.y - 40.0
			var start := Vector2(barrier.position.x - 100.0, y)
			var frame: Dictionary = BallisticsScript.advance(start, Vector2(200.0, 0.0), 1.0, 0.0, game.terrain, null, game.barriers)
			check(frame.collision.kind == &"barrier", "shared ballistics must stop at barrier")
			barrier.take_arrow_hit()
			check(barrier.hit_points == 1 and barrier.segment_hit(start, start + Vector2(200, 0)).hit, "first hit must crack but still block")
			barrier.take_arrow_hit()
			check(barrier.hit_points == 0, "second hit must break barrier")
			await physics_frame
			check(not barrier.segment_hit(start, start + Vector2(200, 0)).hit, "broken barrier must lose collision")
		game._show_hero_select()
		check(game.phase == game.Phase.HERO_SELECT and game.barriers.is_empty() and game.active_arrows.is_empty(), "change hero must clear match objects")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("PLAN3_ACCEPTANCE_OK roles=3 scatter=3x80 heavy=150 barrier=2 selection=true")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)
