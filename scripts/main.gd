extends Node2D

enum Phase { GENERATING, INTRO, SELECT, MOVE, AIM, CHARGE, ARROW, RESOLVE, GAME_OVER }

const TerrainScript := preload("res://scripts/terrain.gd")
const ArcherScript := preload("res://scripts/archer.gd")
const ArrowScript := preload("res://scripts/arrow.gd")
const BalanceScript := preload("res://scripts/game_balance.gd")

var balance = BalanceScript.new()
var match_root: Node2D
var terrain
var archers: Array = []
var landed_arrows: Array = []
var match_id := 0
var rebuilding_match := false
var current_side := 0
var phase := Phase.GENERATING
var turn_token := 0
var move_remaining := 0.0
var charge_elapsed := 0.0
var charge_power := 0.0
var charging := false
var active_arrow
var rng := RandomNumberGenerator.new()
var current_seed := 0
var intro_skipped := false
var camera_goal := Vector2.ZERO
var zoom_goal := Vector2.ONE
var dragging := false
var last_mouse := Vector2.ZERO
var trajectory := PackedVector2Array()
var ui: CanvasLayer
var turn_label: Label
var status_label: Label
var angle_label: Label
var move_label: Label
var power_bar: ProgressBar
var player_hp: ProgressBar
var ai_hp: ProgressBar
var player_hp_text: Label
var ai_hp_text: Label
var move_button: Button
var shoot_button: Button
var end_move_button: Button
var return_button: Button
var skip_button: Button
var result_panel: PanelContainer
var result_label: Label
var again_button: Button
var hit_label: Label
var seed_label: Label

func _ready() -> void:
	rng.randomize()
	_build_world()
	_build_ui()
	new_match()

func _build_world() -> void:
	RenderingServer.set_default_clear_color(Color("#101824"))
	var camera := Camera2D.new()
	camera.name = "BattleCamera"
	camera.position = Vector2(640.0, 360.0)
	camera.position_smoothing_enabled = false
	add_child(camera)
	camera.make_current()

func _make_label(text_value: String, size := 18) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#f2f3f5"))
	return label

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)

	var top := PanelContainer.new()
	top.position = Vector2(20, 16)
	top.size = Vector2(1240, 92)
	root.add_child(top)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 18)
	top.add_child(top_row)
	var player_box := VBoxContainer.new()
	player_box.custom_minimum_size = Vector2(310, 0)
	player_hp_text = _make_label("玩家 100 / 100", 17)
	player_hp = ProgressBar.new()
	player_hp.custom_minimum_size = Vector2(300, 24)
	player_hp.max_value = balance.max_health
	player_hp.show_percentage = false
	player_box.add_child(player_hp_text)
	player_box.add_child(player_hp)
	top_row.add_child(player_box)
	var center_box := VBoxContainer.new()
	center_box.custom_minimum_size = Vector2(560, 0)
	turn_label = _make_label("", 22)
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label = _make_label("", 16)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_box.add_child(turn_label)
	center_box.add_child(status_label)
	top_row.add_child(center_box)
	var ai_box := VBoxContainer.new()
	ai_box.custom_minimum_size = Vector2(310, 0)
	ai_hp_text = _make_label("电脑 100 / 100", 17)
	ai_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ai_hp = ProgressBar.new()
	ai_hp.custom_minimum_size = Vector2(300, 24)
	ai_hp.max_value = balance.max_health
	ai_hp.show_percentage = false
	ai_box.add_child(ai_hp_text)
	ai_box.add_child(ai_hp)
	top_row.add_child(ai_box)

	var bottom := PanelContainer.new()
	bottom.position = Vector2(20, 596)
	bottom.size = Vector2(1240, 106)
	root.add_child(bottom)
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 12)
	bottom.add_child(bottom_row)
	move_button = Button.new(); move_button.text = "移动"
	shoot_button = Button.new(); shoot_button.text = "射击"
	end_move_button = Button.new(); end_move_button.text = "结束移动"
	return_button = Button.new(); return_button.text = "回到角色"
	for button in [move_button, shoot_button, end_move_button, return_button]:
		button.custom_minimum_size = Vector2(118, 62)
		button.focus_mode = Control.FOCUS_NONE
		bottom_row.add_child(button)
	move_button.pressed.connect(_choose_move)
	shoot_button.pressed.connect(_choose_shoot)
	end_move_button.pressed.connect(_end_move)
	return_button.pressed.connect(_return_to_actor)
	var meter_box := VBoxContainer.new()
	meter_box.custom_minimum_size = Vector2(310, 0)
	angle_label = _make_label("角度 45°", 17)
	power_bar = ProgressBar.new()
	power_bar.max_value = 100
	power_bar.custom_minimum_size = Vector2(300, 28)
	power_bar.show_percentage = true
	meter_box.add_child(angle_label)
	meter_box.add_child(power_bar)
	bottom_row.add_child(meter_box)
	var info_box := VBoxContainer.new()
	info_box.custom_minimum_size = Vector2(240, 0)
	move_label = _make_label("移动额度：80", 16)
	var help := _make_label("A/D 移动 · W/S 调角\n按住空格蓄力，松开发射", 14)
	help.add_theme_color_override("font_color", Color("#c4cbd6"))
	info_box.add_child(move_label)
	info_box.add_child(help)
	bottom_row.add_child(info_box)

	skip_button = Button.new()
	skip_button.text = "跳过地图展示"
	skip_button.position = Vector2(1080, 122)
	skip_button.size = Vector2(180, 44)
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.pressed.connect(func(): intro_skipped = true)
	root.add_child(skip_button)
	seed_label = _make_label("", 13)
	seed_label.position = Vector2(22, 112)
	seed_label.add_theme_color_override("font_color", Color("#9ba6b7"))
	root.add_child(seed_label)
	hit_label = _make_label("", 28)
	hit_label.position = Vector2(460, 126)
	hit_label.size = Vector2(360, 54)
	hit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hit_label)
	result_panel = PanelContainer.new()
	result_panel.position = Vector2(390, 210)
	result_panel.size = Vector2(500, 260)
	var result_box := VBoxContainer.new()
	result_box.alignment = BoxContainer.ALIGNMENT_CENTER
	result_label = _make_label("", 30)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	again_button = Button.new(); again_button.text = "再来一局"; again_button.custom_minimum_size = Vector2(220, 60); again_button.focus_mode = Control.FOCUS_NONE
	again_button.pressed.connect(new_match)
	result_box.add_child(result_label)
	result_box.add_child(again_button)
	result_panel.add_child(result_box)
	root.add_child(result_panel)
	result_panel.visible = false

func new_match(use_same_seed := false) -> void:
	if rebuilding_match: return
	rebuilding_match = true
	turn_token += 1
	match_id += 1
	phase = Phase.GENERATING
	charging = false
	dragging = false
	intro_skipped = false
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("aim_up")
	Input.action_release("aim_down")
	Input.action_release("charge")
	trajectory = PackedVector2Array()
	queue_redraw()
	hit_label.text = ""
	result_panel.visible = false
	again_button.disabled = true
	var old_seed := current_seed
	var old_arrow_count := landed_arrows.size() + (1 if is_instance_valid(active_arrow) and active_arrow.active else 0)
	if is_instance_valid(match_root):
		print("MATCH_RESET id=%d seed=%d arrows=%d children=%d" % [match_id - 1, old_seed, old_arrow_count, match_root.get_child_count()])
		match_root.queue_free()
		await get_tree().process_frame
	match_root = Node2D.new()
	match_root.name = "MatchRoot_%d" % match_id
	add_child(match_root)
	terrain = TerrainScript.new()
	terrain.world_width = balance.world_width
	terrain.world_bottom = balance.world_bottom
	match_root.add_child(terrain)
	archers.clear()
	landed_arrows.clear()
	active_arrow = null
	for i in 2:
		var archer = ArcherScript.new()
		archer.setup(i, "玩家" if i == 0 else "电脑", Color("#55aaff") if i == 0 else Color("#ff736a"), balance.max_health)
		archers.append(archer)
		match_root.add_child(archer)
	if use_same_seed and current_seed != 0 and OS.is_debug_build():
		current_seed = old_seed
	else:
		current_seed = rng.randi()
		while current_seed == old_seed: current_seed = rng.randi()
	var generated: Dictionary = terrain.generate(current_seed)
	seed_label.text = "种子：%s · 生成尝试：%s%s" % [current_seed, generated.attempts, " · 备用地形" if generated.fallback else ""]
	for archer in archers:
		archer.health = balance.max_health
		archer.aim_angle = 45.0
	var spawn_rng := RandomNumberGenerator.new(); spawn_rng.seed = current_seed ^ 0x5A17
	archers[0].position = Vector2(terrain.random_spawn(0, spawn_rng), 0)
	archers[1].position = Vector2(terrain.random_spawn(1, spawn_rng), 0)
	_snap_archers()
	current_side = spawn_rng.randi_range(0, 1)
	print("MATCH_READY id=%d seed=%d attempts=%d fallback=%s terrain=%s" % [match_id, current_seed, generated.attempts, generated.fallback, _terrain_summary()])
	rebuilding_match = false
	again_button.disabled = false
	_update_ui()
	_start_intro(turn_token)

func _terrain_summary() -> String:
	if not is_instance_valid(terrain) or terrain.heights.is_empty(): return "empty"
	var samples: Array[String] = []
	for i in range(0, terrain.heights.size(), maxi(1, terrain.heights.size() / 8)):
		samples.append(str(roundi(terrain.heights[i])))
	return ",".join(samples)

func _start_intro(token: int) -> void:
	phase = Phase.INTRO
	skip_button.visible = true
	turn_label.text = "地图生成完毕"
	status_label.text = "正在观察战场……"
	camera_goal = Vector2(balance.world_width * 0.5, 385.0)
	zoom_goal = Vector2(0.50, 0.50)
	var elapsed := 0.0
	while elapsed < 1.8 and not intro_skipped and token == turn_token:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if token != turn_token: return
	skip_button.visible = false
	_begin_turn()

func _begin_turn() -> void:
	turn_token += 1
	charge_elapsed = 0.0
	charge_power = 0.0
	move_remaining = balance.move_budget
	phase = Phase.SELECT
	hit_label.text = ""
	_focus_actor(current_side)
	_update_ui()
	if current_side == 1:
		_ai_turn(turn_token)

func _choose_move() -> void:
	if phase != Phase.SELECT or current_side != 0: return
	phase = Phase.MOVE
	status_label.text = "移动会消耗本回合射击机会"
	_update_ui()

func _choose_shoot() -> void:
	if phase != Phase.SELECT or current_side != 0: return
	phase = Phase.AIM
	status_label.text = "W/S 调整角度；按住空格蓄力"
	_update_trajectory(0.0)
	_update_ui()

func _end_move() -> void:
	if phase != Phase.MOVE or current_side != 0: return
	_finish_action()

func _return_to_actor() -> void:
	if phase in [Phase.SELECT, Phase.MOVE, Phase.AIM, Phase.CHARGE]: _focus_actor(current_side)

func _physics_process(delta: float) -> void:
	var camera := get_node("BattleCamera") as Camera2D
	camera.position = camera.position.lerp(camera_goal, 1.0 - exp(-delta * 6.0))
	camera.zoom = camera.zoom.lerp(zoom_goal, 1.0 - exp(-delta * 6.0))
	if phase == Phase.MOVE and current_side == 0:
		var axis := Input.get_axis("move_left", "move_right")
		if absf(axis) > 0.01 and move_remaining > 0.0:
			_move_actor(archers[0], axis, delta)
	if phase in [Phase.AIM, Phase.CHARGE] and current_side == 0:
		if phase == Phase.AIM:
			var aim_axis := Input.get_axis("aim_down", "aim_up")
			if absf(aim_axis) > 0.01:
				archers[0].aim_angle = clampf(archers[0].aim_angle + aim_axis * balance.angle_speed * delta, balance.min_angle, balance.max_angle)
				archers[0].queue_redraw()
		if phase == Phase.CHARGE:
			charge_elapsed += delta
			charge_power = _triangle_power(charge_elapsed)
		_update_trajectory(charge_power)
		_update_ui()
	if phase == Phase.ARROW and is_instance_valid(active_arrow):
		camera_goal = active_arrow.global_position
		zoom_goal = Vector2(0.88, 0.88)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and current_side == 0:
		if event.is_action_pressed("charge") and phase == Phase.AIM and not event.echo:
			phase = Phase.CHARGE
			charging = true
			charge_elapsed = 0.0
		elif event.is_action_released("charge") and phase == Phase.CHARGE and charging:
			charging = false
			_fire_arrow(current_side, charge_power)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and phase in [Phase.SELECT, Phase.MOVE, Phase.AIM, Phase.CHARGE]:
		dragging = event.pressed
		last_mouse = event.position
	if event is InputEventMouseMotion and dragging and current_side == 0:
		camera_goal -= event.relative / get_node("BattleCamera").zoom
		camera_goal.x = clampf(camera_goal.x, 640.0, balance.world_width - 640.0)
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_F6:
		new_match(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and phase == Phase.CHARGE:
		charging = false
		charge_elapsed = 0.0
		charge_power = 0.0
		phase = Phase.AIM
		status_label.text = "窗口焦点已恢复；请重新按空格蓄力"

func _move_actor(actor, direction: float, delta: float) -> void:
	var requested := minf(balance.move_speed * delta, move_remaining) * signf(direction)
	var zone: Vector2 = terrain.left_zone if actor.side == 0 else terrain.right_zone
	var next_x := clampf(actor.position.x + requested, zone.x + 20.0, zone.y - 20.0)
	var actual := absf(next_x - actor.position.x)
	actor.position.x = next_x
	actor.position.y = terrain.surface_y(next_x)
	move_remaining = maxf(0.0, move_remaining - actual)
	_focus_actor(actor.side)
	if move_remaining <= 0.01: _finish_action()

func _snap_archers() -> void:
	for actor in archers:
		actor.position.y = terrain.surface_y(actor.position.x)

func _triangle_power(elapsed: float) -> float:
	var cycle := fmod(elapsed, balance.charge_half_cycle * 2.0)
	return cycle / balance.charge_half_cycle if cycle <= balance.charge_half_cycle else 2.0 - cycle / balance.charge_half_cycle

func _fire_arrow(side: int, power: float) -> void:
	if phase not in [Phase.AIM, Phase.CHARGE, Phase.SELECT]: return
	phase = Phase.ARROW
	trajectory = PackedVector2Array()
	queue_redraw()
	var shooter = archers[side]
	var target = archers[1 - side]
	active_arrow = ArrowScript.new()
	match_root.add_child(active_arrow)
	active_arrow.launch(shooter.muzzle_position(), shooter.launch_direction() * balance.launch_speed(power), shooter, target, terrain, balance.gravity, balance.arrow_timeout)
	active_arrow.stopped.connect(_on_arrow_stopped.bind(turn_token))
	status_label.text = "%s发射：角度 %.1f°，力度 %d%%" % [shooter.display_name, shooter.aim_angle, roundi(power * 100.0)]
	_update_ui()

func _on_arrow_stopped(result: Dictionary, token: int) -> void:
	if token != turn_token or phase != Phase.ARROW: return
	phase = Phase.RESOLVE
	if is_instance_valid(active_arrow):
		if result.kind == &"miss":
			active_arrow.queue_free()
		else:
			landed_arrows.append(active_arrow)
			while landed_arrows.size() > 12:
				var oldest = landed_arrows.pop_front()
				if is_instance_valid(oldest): oldest.queue_free()
	if result.kind == &"actor":
		var damage: int = balance.damage_for(result.part)
		var target = archers[1 - current_side]
		target.apply_damage(damage)
		var part_name: String = {&"head": "头部", &"torso": "躯干", &"legs": "腿脚"}[result.part]
		hit_label.text = "%s −%d" % [part_name, damage]
		status_label.text = "%s命中%s！" % [archers[current_side].display_name, target.display_name]
	else:
		hit_label.text = "未命中" if result.kind == &"miss" else "命中地形"
	_update_ui()
	await get_tree().create_timer(0.6).timeout
	if token != turn_token: return
	if archers[0].health <= 0 or archers[1].health <= 0:
		_end_game()
	else:
		_finish_action()

func _finish_action() -> void:
	if phase == Phase.GAME_OVER: return
	current_side = 1 - current_side
	_begin_turn()

func _end_game() -> void:
	phase = Phase.GAME_OVER
	turn_token += 1
	var player_won: bool = archers[1].health <= 0
	result_label.text = ("胜利！" if player_won else "惜败") + "\n\n玩家 %d / 电脑 %d" % [archers[0].health, archers[1].health]
	result_panel.visible = true
	turn_label.text = "对局结束"
	status_label.text = "点击“再来一局”生成新地图"
	_update_ui()

func _ai_turn(token: int) -> void:
	phase = Phase.SELECT
	_update_ui()
	status_label.text = "电脑正在观察地形……"
	await get_tree().create_timer(0.45).timeout
	if token != turn_token: return
	var solution: Dictionary = await _find_ai_shot(token)
	if token != turn_token: return
	if solution.is_empty():
		await _ai_move(token)
		return
	archers[1].aim_angle = clampf(solution.angle + rng.randf_range(-2.0, 2.0), balance.min_angle, balance.max_angle)
	archers[1].queue_redraw()
	phase = Phase.AIM
	status_label.text = "电脑正在瞄准……"
	_focus_actor(1)
	_update_trajectory(solution.power)
	await get_tree().create_timer(0.55).timeout
	if token != turn_token: return
	phase = Phase.CHARGE
	var target_power: float = clampf(solution.power + rng.randf_range(-0.03, 0.03), 0.0, 1.0)
	var elapsed := 0.0
	while elapsed < target_power * balance.charge_half_cycle:
		await get_tree().physics_frame
		if token != turn_token: return
		elapsed += get_physics_process_delta_time()
		charge_power = _triangle_power(elapsed)
		_update_trajectory(charge_power)
		_update_ui()
	_fire_arrow(1, charge_power)

func _find_ai_shot(token: int) -> Dictionary:
	var shooter = archers[1]
	var target = archers[0]
	var best := {}
	var best_score := INF
	var checked := 0
	for angle in range(15, 81, 3):
		for power_step in range(2, 21):
			if token != turn_token: return {}
			var power := power_step / 20.0
			var result: Dictionary = _simulate_shot(shooter, target, float(angle), power)
			if result.hit_actor:
				return {"angle": float(angle), "power": power}
			if result.score < best_score:
				best_score = result.score
				best = {"angle": float(angle), "power": power}
			checked += 1
			if checked % 80 == 0: await get_tree().process_frame
	return best if best_score < 330.0 else {}

func _simulate_shot(shooter, target, angle: float, power: float) -> Dictionary:
	var sign_dir: float = shooter.facing_sign()
	var dir := Vector2(cos(deg_to_rad(angle)) * sign_dir, -sin(deg_to_rad(angle)))
	var pos: Vector2 = shooter.global_position + Vector2(0.0, -58.0) + dir * 34.0
	var vel: Vector2 = dir * balance.launch_speed(power)
	var closest := INF
	var dt := 1.0 / 60.0
	for step in 360:
		var next := pos + vel * dt + Vector2(0.0, balance.gravity) * 0.5 * dt * dt
		var ground_hit: Dictionary = terrain.segment_hit(pos, next)
		var actor_hit: Dictionary = target.segment_hit(pos, next)
		if actor_hit.hit and (not ground_hit.hit or actor_hit.t < ground_hit.t): return {"hit_actor": true, "score": 0.0}
		closest = minf(closest, next.distance_to(target.global_position + Vector2(0, -50)))
		if ground_hit.hit or next.x < -100 or next.x > balance.world_width + 100 or next.y > balance.world_bottom + 100: break
		pos = next
		vel.y += balance.gravity * dt
	return {"hit_actor": false, "score": closest}

func _ai_move(token: int) -> void:
	phase = Phase.MOVE
	status_label.text = "电脑选择移动，本回合不射击"
	var actor = archers[1]
	var direction := -1.0 if rng.randf() < 0.75 else 1.0
	var distance := rng.randf_range(35.0, balance.move_budget)
	while distance > 0.0 and token == turn_token:
		await get_tree().physics_frame
		var step := minf(balance.move_speed * get_physics_process_delta_time(), distance)
		var before: float = actor.position.x
		var zone: Vector2 = terrain.right_zone
		actor.position.x = clampf(actor.position.x + direction * step, zone.x + 20.0, zone.y - 20.0)
		actor.position.y = terrain.surface_y(actor.position.x)
		distance -= absf(actor.position.x - before)
		if is_equal_approx(before, actor.position.x): break
		_focus_actor(1)
	if token == turn_token: _finish_action()

func _update_trajectory(power: float) -> void:
	trajectory = PackedVector2Array()
	var shooter = archers[current_side]
	var pos: Vector2 = shooter.muzzle_position()
	var vel: Vector2 = shooter.launch_direction() * balance.launch_speed(power)
	trajectory.append(pos)
	var traveled := 0.0
	var dt := 1.0 / 60.0
	for step in 12:
		var next := pos + vel * dt + Vector2(0.0, balance.gravity) * 0.5 * dt * dt
		var hit: Dictionary = terrain.segment_hit(pos, next)
		if hit.hit:
			trajectory.append(hit.point)
			break
		traveled += pos.distance_to(next)
		if traveled > 180.0: break
		trajectory.append(next)
		pos = next
		vel.y += balance.gravity * dt
	queue_redraw()

func _draw() -> void:
	if trajectory.size() > 1:
		for i in range(trajectory.size() - 1):
			draw_line(trajectory[i], trajectory[i + 1], Color("#ffd667aa"), 3.0 if i % 2 == 0 else 1.0)

func _focus_actor(side: int) -> void:
	camera_goal = archers[side].global_position + Vector2(0.0, -130.0)
	camera_goal.x = clampf(camera_goal.x, 640.0, balance.world_width - 640.0)
	camera_goal.y = 340.0
	zoom_goal = Vector2(1.0, 1.0)

func _update_ui() -> void:
	if not is_instance_valid(player_hp) or archers.size() < 2: return
	player_hp.value = archers[0].health
	ai_hp.value = archers[1].health
	player_hp_text.text = "玩家 %d / %d" % [archers[0].health, archers[0].max_health]
	ai_hp_text.text = "电脑 %d / %d" % [archers[1].health, archers[1].max_health]
	angle_label.text = "角度 %.1f°" % archers[current_side].aim_angle
	power_bar.value = charge_power * 100.0
	move_label.text = "移动额度：%d / %d" % [roundi(move_remaining), roundi(balance.move_budget)]
	if phase not in [Phase.INTRO, Phase.GAME_OVER]:
		turn_label.text = "%s行动" % archers[current_side].display_name
	var player_can_choose := current_side == 0 and phase == Phase.SELECT
	move_button.disabled = not player_can_choose
	shoot_button.disabled = not player_can_choose
	end_move_button.visible = current_side == 0 and phase == Phase.MOVE
	return_button.disabled = current_side != 0 or phase not in [Phase.SELECT, Phase.MOVE, Phase.AIM, Phase.CHARGE]

