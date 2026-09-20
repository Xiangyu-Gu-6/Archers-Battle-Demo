extends SceneTree

const MainScene := preload("res://scenes/Main.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var game = MainScene.instantiate()
	root.add_child(game)
	for role in [&"shark", &"architect"]:
		game._show_hero_select()
		game._select_hero(role)
		game._start_selected_match()
		while game.rebuilding_match:
			await process_frame
		game.turn_token += 1
		game.current_side = 0
		game.phase = game.Phase.SELECT
		game._update_ui()
		var actor = game.archers[0]
		var rig = actor.character_rig
		check(is_instance_valid(rig), "%s must use an animated rig" % role)
		if not is_instance_valid(rig):
			continue
		check(is_instance_valid(rig.skeleton), "%s must have Skeleton2D" % role)
		check(rig.bones.size() == 17, "%s must have 17 bones" % role)
		check(rig.sprites.size() == (15 if role == &"shark" else 17), "%s must have its final v04 art parts" % role)
		check(is_instance_valid(rig.bow_string), "%s must have a dynamic bow string" % role)
		check(game.skill_button.get_theme_font_size("font_size") == game.move_button.get_theme_font_size("font_size"), "skill and move type sizes must match")
		check(game.skill_button.get_theme_stylebox("normal") is StyleBoxTexture, "skill art must remain installed")
		check(game.skill_button.text.length() <= 4, "skill label must fit the shared text safe area")
		var origin_before: Vector2 = actor.muzzle_position()
		actor.set_visual_state(&"move")
		await process_frame
		check(rig.combat_state == &"move", "%s movement must reach its rig" % role)
		actor.set_visual_state(&"aim")
		actor.set_charge_visual(0.8)
		await process_frame
		check(is_equal_approx(rig.charge_amount, 0.8), "%s charge must reach its rig" % role)
		actor.play_release_visual(&"heavy" if role == &"shark" else &"normal")
		await process_frame
		check(not rig.is_nocked_arrow_visible(), "%s nocked arrow must hide on release" % role)
		check(rig.action_name == ("heavy_shot" if role == &"shark" else "normal_shoot"), "%s must select the right animation" % role)
		actor.apply_damage(1)
		await process_frame
		check(rig.hit_elapsed >= 0.0, "%s hit reaction must play" % role)
		check(origin_before.distance_to(actor.muzzle_position()) < 0.001, "%s animation must not move the gameplay muzzle" % role)
		if role == &"architect":
			actor.set_visual_state(&"build_preview")
			await process_frame
			check(rig.sprites["blueprint_hand"].visible, "architect must show blueprint while placing")
			check(not rig.sprites["bow"].visible, "architect must stow bow while placing")
			actor.play_build_visual()
			await process_frame
			check(rig.action_name == "build_barrier", "architect must play build animation")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("V4_ACCEPTANCE_OK shark=15 architect=17 bones=17 skill_type=true animations=true")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
