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
	game._start_selected_match()
	while game.rebuilding_match:
		await process_frame
	game.turn_token += 1
	game.current_side = 0
	game.phase = game.Phase.SELECT
	game._update_ui()

	var player = game.archers[0]
	var rig = player.rig_visual
	check(is_instance_valid(rig), "player must use the emerald ranger rig")
	check(is_instance_valid(rig.skeleton), "rig must contain Skeleton2D")
	check(rig.bones.size() == 17, "rig must build all 17 named bones")
	check(rig.sprites.size() == 16, "rig must attach all 16 art parts")
	check(is_instance_valid(rig.bow_string), "rig must include a dynamic bow string")
	check(player.art_sprite == null, "player static composite must be replaced by the rig")
	check(is_instance_valid(game.archers[1].character_rig), "CPU shark or architect must use its character rig")

	game.shoot_button.pressed.emit()
	check(rig.combat_state == &"aim", "shoot choice must enter the aim pose")
	player.aim_angle = 67.0
	player.set_charge_visual(0.72)
	await process_frame
	check(is_equal_approx(rig.aim_degrees, 67.0), "aim angle must reach the visual rig")
	check(is_equal_approx(rig.charge_amount, 0.72), "charge power must reach the visual rig")
	check(rig.is_nocked_arrow_visible(), "nocked arrow must remain visible before release")

	player.play_release_visual()
	await process_frame
	check(not rig.is_nocked_arrow_visible(), "nocked arrow must hide on release")
	check(rig.release_elapsed >= 0.0, "release must start the recoil timeline")

	var origin_before: Vector2 = player.muzzle_position()
	player.apply_damage(10)
	await process_frame
	check(rig.hit_elapsed >= 0.0, "damage must trigger hit secondary motion")
	check(origin_before.distance_to(player.muzzle_position()) < 0.001, "visual animation must not change projectile origin")
	check(player.segment_hit(player.global_position + Vector2(-30, -86), player.global_position + Vector2(30, -86)).hit, "visual rig must not replace gameplay hit zones")

	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("V3_ACCEPTANCE_OK skeleton=17 parts=16 combat_states=true gameplay_isolated=true")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
