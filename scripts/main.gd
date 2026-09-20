extends Node2D

enum Phase { HERO_SELECT, GENERATING, INTRO, SELECT, MOVE, AIM, CHARGE, BUILD, ARROW, RESOLVE, GAME_OVER }

const TerrainScript := preload("res://scripts/terrain.gd")
const ArcherScript := preload("res://scripts/archer.gd")
const ArrowScript := preload("res://scripts/arrow.gd")
const BalanceScript := preload("res://scripts/game_balance.gd")
const BallisticsScript := preload("res://scripts/ballistics.gd")
const ArtBackdropScript := preload("res://scripts/art_backdrop.gd")
const BarrierScript := preload("res://scripts/architect_barrier.gd")
const ROLES := {
	&"ranger": {"name": "翡翠游侠", "skill": "翠羽三连", "detail": "3支散射箭，每支造成普通箭80%伤害。每局1次。", "texture": preload("res://assets/art/characters/emerald_ranger_static_right_v01.png")},
	&"shark": {"name": "船骸鲨客", "skill": "鲨牙重击", "detail": "1支强化箭，造成普通箭150%伤害。每局1次。", "texture": preload("res://assets/art/characters/shipwreck_shark/shipwreck_shark_skill_portrait_v01.png")},
	&"architect": {"name": "建筑师", "skill": "搭建壁垒", "detail": "己方区域建造120×150壁垒，高约1.5个角色身高，挡住2次箭矢。占用一回合，每局1次。", "texture": preload("res://assets/art/characters/architect/architect_skill_portrait_v01.png")}
}

var balance = BalanceScript.new()
var match_root: Node2D
var terrain
var archers: Array = []
var landed_arrows: Array = []
var barriers: Array = []
var active_arrows: Array = []
var remaining_arrows := 0
var shot_results: Array = []
var active_shot_kind: StringName = &"normal"
var selected_role: StringName = &"ranger"
var cpu_role: StringName = &"shark"
var barrier_preview
var preview_trails: Array = []
var match_id := 0
var rebuilding_match := false
var current_side := 0
var phase := Phase.GENERATING
var turn_token := 0
var move_remaining := 0.0
var charge_elapsed := 0.0
var charge_power := 0.0
var charging := false
var move_committed := false
var shot_committed := false
var move_start_position := Vector2.ZERO
var aim_up_held := false
var aim_down_held := false
var aim_hold_elapsed := 0.0
var preview_update_elapsed := 0.0
var active_arrow
var rng := RandomNumberGenerator.new()
var current_seed := 0
var intro_skipped := false
var camera_goal := Vector2.ZERO
var zoom_goal := Vector2.ONE
var dragging := false
var last_mouse := Vector2.ZERO
var drag_hint_shown := false
var temporary_full_view := false
var saved_camera_goal := Vector2.ZERO
var saved_zoom_goal := Vector2.ONE
var trajectory := PackedVector2Array()
var pending_player_shot := {}
var last_player_shot := {}
var previous_terrain_signature := {}
var move_reachable_interval := Vector2.ZERO
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
var skill_button: Button
var place_button: Button
var end_move_button: Button
var return_button: Button
var cancel_button: Button
var skip_button: Button
var enemy_button: Button
var result_panel: PanelContainer
var result_label: Label
var again_button: Button
var change_hero_button: Button
var hero_panel: PanelContainer
var hero_buttons: Array[Button] = []
var hero_detail: Label
var hero_start_button: Button
var battle_widgets: Array[Control] = []
var hit_label: Label
var seed_label: Label
var last_shot_label: Label
var power_direction_label: Label
var art_backdrop

func _ready() -> void:
	rng.randomize()
	_build_world()
	_build_ui()
	_show_hero_select()

func _build_world() -> void:
	RenderingServer.set_default_clear_color(Color("#101824"))
	var camera := Camera2D.new()
	camera.name = "BattleCamera"
	camera.position = Vector2(640.0, 360.0)
	camera.position_smoothing_enabled = false
	add_child(camera)
	camera.make_current()
	art_backdrop = ArtBackdropScript.new()
	art_backdrop.name = "ArtBackdrop"
	add_child(art_backdrop)
	art_backdrop.setup(camera, balance.world_width)

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
	battle_widgets.append(top)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 18)
	top.add_child(top_row)
	var player_box := VBoxContainer.new()
	player_box.custom_minimum_size = Vector2(310, 0)
	player_hp_text = _make_label("PLAYER 100 / 100", 17)
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
	ai_hp_text = _make_label("CPU 100 / 100", 17)
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
	battle_widgets.append(bottom)
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 12)
	bottom.add_child(bottom_row)
	move_button = Button.new(); move_button.text = "移动"
	move_button.theme = load("res://assets/ui/themes/move_action_button_theme_v01.tres")
	shoot_button = Button.new(); shoot_button.text = "射击"
	shoot_button.theme = load("res://assets/ui/themes/shoot_action_button_theme_v01.tres")
	skill_button = Button.new(); skill_button.text = "技能×1"
	skill_button.theme = load("res://assets/ui/themes/move_action_button_theme_v01.tres")
	end_move_button = Button.new(); end_move_button.text = "END MOVE"
	cancel_button = Button.new(); cancel_button.text = "CANCEL"
	return_button = Button.new(); return_button.text = "MY ARCHER"
	place_button = Button.new(); place_button.text = "放置壁垒"
	for button in [move_button, shoot_button, skill_button, end_move_button, place_button, cancel_button, return_button]:
		button.custom_minimum_size = Vector2(142, 62) if button in [move_button, shoot_button, skill_button] else Vector2(82, 62)
		button.focus_mode = Control.FOCUS_NONE
		bottom_row.add_child(button)
	move_button.pressed.connect(_choose_move)
	shoot_button.pressed.connect(_choose_shoot)
	skill_button.pressed.connect(_choose_skill)
	place_button.pressed.connect(_place_barrier)
	end_move_button.pressed.connect(_end_move)
	cancel_button.pressed.connect(_cancel_action)
	return_button.pressed.connect(_return_to_actor)
	var meter_box := VBoxContainer.new()
	meter_box.custom_minimum_size = Vector2(240, 0)
	angle_label = _make_label("ANGLE 45°", 17)
	power_bar = ProgressBar.new()
	power_bar.max_value = 100
	power_bar.custom_minimum_size = Vector2(230, 28)
	power_bar.show_percentage = true
	power_direction_label = _make_label("MARKS 25 · 50 · 75", 13)
	power_direction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meter_box.add_child(angle_label)
	meter_box.add_child(power_bar)
	meter_box.add_child(power_direction_label)
	bottom_row.add_child(meter_box)
	var info_box := VBoxContainer.new()
	info_box.custom_minimum_size = Vector2(160, 0)
	move_label = _make_label("MOVE 180 / 180", 16)
	var help := _make_label("A/D 移动 · W/S 瞄准\n空格蓄力 · 点击放置", 13)
	help.add_theme_color_override("font_color", Color("#c4cbd6"))
	info_box.add_child(move_label)
	info_box.add_child(help)
	bottom_row.add_child(info_box)

	skip_button = Button.new()
	skip_button.text = "SKIP MAP INTRO"
	skip_button.position = Vector2(1080, 122)
	skip_button.size = Vector2(180, 44)
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.pressed.connect(func(): intro_skipped = true)
	root.add_child(skip_button)
	battle_widgets.append(skip_button)
	enemy_button = Button.new()
	enemy_button.text = "VIEW ENEMY"
	enemy_button.position = Vector2(735, 122)
	enemy_button.size = Vector2(145, 44)
	enemy_button.focus_mode = Control.FOCUS_NONE
	enemy_button.pressed.connect(_view_enemy)
	root.add_child(enemy_button)
	battle_widgets.append(enemy_button)
	seed_label = _make_label("", 13)
	seed_label.position = Vector2(22, 112)
	seed_label.add_theme_color_override("font_color", Color("#9ba6b7"))
	seed_label.visible = OS.is_debug_build()
	root.add_child(seed_label)
	battle_widgets.append(seed_label)
	last_shot_label = _make_label("LAST SHOT: NONE", 14)
	last_shot_label.position = Vector2(905, 118)
	last_shot_label.size = Vector2(350, 72)
	last_shot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	last_shot_label.add_theme_color_override("font_color", Color("#26384a"))
	last_shot_label.add_theme_color_override("font_outline_color", Color("#fff7dfcc"))
	last_shot_label.add_theme_constant_override("outline_size", 3)
	root.add_child(last_shot_label)
	battle_widgets.append(last_shot_label)
	hit_label = _make_label("", 28)
	hit_label.position = Vector2(460, 126)
	hit_label.size = Vector2(360, 54)
	hit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hit_label)
	battle_widgets.append(hit_label)
	result_panel = PanelContainer.new()
	result_panel.position = Vector2(390, 210)
	result_panel.size = Vector2(500, 260)
	var result_box := VBoxContainer.new()
	result_box.alignment = BoxContainer.ALIGNMENT_CENTER
	result_label = _make_label("", 30)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	again_button = Button.new(); again_button.text = "PLAY AGAIN"; again_button.custom_minimum_size = Vector2(220, 60); again_button.focus_mode = Control.FOCUS_NONE
	again_button.pressed.connect(new_match)
	change_hero_button = Button.new(); change_hero_button.text = "更换英雄"; change_hero_button.custom_minimum_size = Vector2(220, 48)
	change_hero_button.pressed.connect(_show_hero_select)
	result_box.add_child(result_label)
	result_box.add_child(again_button)
	result_box.add_child(change_hero_button)
	result_panel.add_child(result_box)
	root.add_child(result_panel)
	result_panel.visible = false
	_build_hero_select(root)

func _build_hero_select(root: Control) -> void:
	hero_panel = PanelContainer.new()
	hero_panel.position = Vector2(92, 55)
	hero_panel.size = Vector2(1096, 610)
	root.add_child(hero_panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	hero_panel.add_child(layout)
	var title := _make_label("选择你的弓箭手", 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)
	var subtitle := _make_label("三位英雄各有一次专属行动 · 玩家 VS 电脑", 17)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(subtitle)
	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 24)
	layout.add_child(cards)
	for role in [&"ranger", &"shark", &"architect"]:
		var card := Button.new()
		card.custom_minimum_size = Vector2(310, 338)
		card.icon = ROLES[role].texture
		card.expand_icon = true
		card.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		card.text = ROLES[role].name
		card.pressed.connect(_select_hero.bind(role))
		cards.add_child(card)
		hero_buttons.append(card)
	hero_detail = _make_label("", 17)
	hero_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(hero_detail)
	var rules := _make_label("生命100 · 普通箭头/躯干/腿伤害50/30/20 · 电脑随机选择另外两位英雄之一", 14)
	rules.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(rules)
	hero_start_button = Button.new()
	hero_start_button.custom_minimum_size = Vector2(280, 56)
	hero_start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hero_start_button.pressed.connect(_start_selected_match)
	layout.add_child(hero_start_button)
	_select_hero(selected_role)

func _select_hero(role: StringName) -> void:
	selected_role = role
	if not is_instance_valid(hero_panel): return
	var roles := [&"ranger", &"shark", &"architect"]
	for i in hero_buttons.size():
		hero_buttons[i].text = ROLES[roles[i]].name + ("  ✓ 已选择" if roles[i] == role else "  选择")
		hero_buttons[i].modulate = Color.WHITE if roles[i] == role else Color("#a5afb6")
	hero_detail.text = "%s · %s\n%s" % [ROLES[role].name, ROLES[role].skill, ROLES[role].detail]
	hero_start_button.text = "以%s开始对战" % ROLES[role].name

func _apply_skill_button_art(role: StringName) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxTexture.new()
		style.texture = load("res://assets/ui/skills/%s_skill_button_%s_v01.png" % [role, state])
		style.content_margin_left = 50.0
		style.content_margin_top = 8.0 if state == "pressed" else 5.0
		style.content_margin_right = 8.0
		style.content_margin_bottom = 2.0 if state == "pressed" else 5.0
		skill_button.add_theme_stylebox_override(state, style)
	skill_button.add_theme_stylebox_override("focus", skill_button.get_theme_stylebox("hover"))

func _show_hero_select() -> void:
	turn_token += 1
	phase = Phase.HERO_SELECT
	if is_instance_valid(match_root):
		match_root.queue_free()
		match_root = null
	archers.clear()
	barriers.clear()
	active_arrows.clear()
	landed_arrows.clear()
	barrier_preview = null
	trajectory = PackedVector2Array()
	preview_trails.clear()
	last_player_shot.clear()
	pending_player_shot.clear()
	hero_panel.visible = true
	result_panel.visible = false
	for widget in battle_widgets: widget.visible = false
	_select_hero(selected_role)
	queue_redraw()

func _start_selected_match() -> void:
	if phase != Phase.HERO_SELECT or rebuilding_match: return
	hero_start_button.disabled = true
	hero_start_button.text = "准备战场…"
	hero_panel.visible = false
	for widget in battle_widgets: widget.visible = true
	new_match()
	hero_start_button.disabled = false
	_select_hero(selected_role)

func new_match(use_same_seed := false) -> void:
	if rebuilding_match: return
	var other_roles := [&"ranger", &"shark", &"architect"]
	other_roles.erase(selected_role)
	cpu_role = other_roles[rng.randi_range(0, other_roles.size() - 1)]
	rebuilding_match = true
	turn_token += 1
	match_id += 1
	phase = Phase.GENERATING
	charging = false
	move_committed = false
	shot_committed = false
	aim_up_held = false
	aim_down_held = false
	aim_hold_elapsed = 0.0
	preview_update_elapsed = 0.0
	dragging = false
	temporary_full_view = false
	intro_skipped = false
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("aim_up")
	Input.action_release("aim_down")
	Input.action_release("charge")
	trajectory = PackedVector2Array()
	preview_trails.clear()
	active_shot_kind = &"normal"
	pending_player_shot.clear()
	last_player_shot.clear()
	last_shot_label.text = "LAST SHOT: NONE"
	queue_redraw()
	hit_label.text = ""
	result_panel.visible = false
	again_button.disabled = true
	var old_seed := current_seed
	var old_signature := previous_terrain_signature.duplicate(true)
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
	barriers.clear()
	active_arrows.clear()
	remaining_arrows = 0
	shot_results.clear()
	barrier_preview = null
	active_arrow = null
	for i in 2:
		var archer = ArcherScript.new()
		var role: StringName = selected_role if i == 0 else cpu_role
		archer.setup(i, ROLES[role].name, Color("#55aaff") if i == 0 else Color("#ff736a"), balance.max_health, role)
		archer.skill_uses = balance.skill_uses_per_match
		archers.append(archer)
		match_root.add_child(archer)
	_apply_skill_button_art(selected_role)
	if use_same_seed and current_seed != 0 and OS.is_debug_build():
		current_seed = old_seed
	else:
		current_seed = rng.randi()
		while current_seed == old_seed: current_seed = rng.randi()
	var generated: Dictionary = terrain.generate(current_seed, {} if use_same_seed else old_signature)
	art_backdrop.add_match_props(match_root, terrain, current_seed)
	previous_terrain_signature = generated.signature
	seed_label.text = "SEED %s · ATTEMPTS %s%s" % [current_seed, generated.attempts, " · FALLBACK" if generated.fallback else ""]
	for archer in archers:
		archer.health = balance.max_health
		archer.aim_angle = 45.0
	var spawn_rng := RandomNumberGenerator.new(); spawn_rng.seed = current_seed ^ 0x5A17
	archers[0].position = Vector2(terrain.random_spawn(0, spawn_rng), 0)
	archers[1].position = Vector2(terrain.random_spawn(1, spawn_rng), 0)
	_snap_archers()
	current_side = spawn_rng.randi_range(0, 1)
	print("MATCH_READY id=%d seed=%d template=%s attempts=%d fallback=%s terrain=%s" % [match_id, current_seed, generated.template, generated.attempts, generated.fallback, _terrain_summary()])
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
	turn_label.text = "MAP READY"
	status_label.text = "SCOUTING THE FIELD..."
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
	move_committed = false
	shot_committed = false
	aim_up_held = false
	aim_down_held = false
	aim_hold_elapsed = 0.0
	phase = Phase.SELECT
	for actor in archers:
		actor.set_visual_state(&"idle")
	hit_label.text = ""
	_focus_actor(current_side)
	status_label.text = "CHOOSE AN ACTION" if current_side == 0 else "CPU IS SCOUTING..."
	_update_ui()
	if current_side == 1:
		_ai_turn(turn_token)

func _choose_move() -> void:
	if phase != Phase.SELECT or current_side != 0: return
	phase = Phase.MOVE
	archers[0].set_visual_state(&"move")
	move_committed = false
	move_start_position = archers[0].global_position
	move_reachable_interval = terrain.reachable_interval(archers[0].position.x, move_remaining, 0)
	status_label.text = "MOVE RANGE %.0f—%.0f · CANCEL BEFORE MOVING" % [move_reachable_interval.x, move_reachable_interval.y]
	queue_redraw()
	_update_ui()

func _choose_shoot() -> void:
	if phase != Phase.SELECT or current_side != 0: return
	active_shot_kind = &"normal"
	_enter_aim()

func _choose_skill() -> void:
	if phase != Phase.SELECT or current_side != 0 or archers[0].skill_uses <= 0: return
	if archers[0].role_id == &"architect":
		_begin_build(0)
		return
	active_shot_kind = &"scatter" if archers[0].role_id == &"ranger" else &"heavy"
	_enter_aim()

func _enter_aim() -> void:
	phase = Phase.AIM
	archers[current_side].set_visual_state(&"aim")
	archers[current_side].set_skill_visual(active_shot_kind)
	shot_committed = false
	var preview_power := float(last_player_shot.get("power", 0.5))
	status_label.text = "%s · 预览 %d%% · 按住空格蓄力" % [active_shot_kind, roundi(preview_power * 100.0)]
	_update_trajectory(preview_power)
	_update_ui()

func _begin_build(side: int) -> void:
	phase = Phase.BUILD
	archers[side].set_visual_state(&"build_preview")
	barrier_preview = BarrierScript.new()
	match_root.add_child(barrier_preview)
	barrier_preview.setup(Vector2(balance.barrier_width, balance.barrier_height), balance.barrier_hit_points, true)
	var actor = archers[side]
	var offset: float = 170.0 * actor.facing_sign()
	_update_barrier_preview(actor.position.x + offset)
	status_label.text = "移动鼠标选位置，点击或按放置壁垒 · 每局一次"
	_update_ui()

func _update_barrier_preview(x: float) -> void:
	if not is_instance_valid(barrier_preview): return
	barrier_preview.position = Vector2(x, terrain.surface_y(x))
	barrier_preview.set_placement_valid(_barrier_placement_valid(current_side, x))
	if current_side == 0 and is_instance_valid(place_button): place_button.disabled = not barrier_preview.valid_placement

func _barrier_placement_valid(side: int, x: float) -> bool:
	var zone: Vector2 = terrain.left_zone if side == 0 else terrain.right_zone
	if x - balance.barrier_width * 0.5 < zone.x or x + balance.barrier_width * 0.5 > zone.y: return false
	for actor in archers:
		if absf(actor.position.x - x) < balance.barrier_width * 0.5 + 30.0: return false
	for barrier in barriers:
		if is_instance_valid(barrier) and barrier.hit_points > 0 and absf(barrier.position.x - x) < balance.barrier_width: return false
	return true

func _place_barrier() -> void:
	if phase != Phase.BUILD or not is_instance_valid(barrier_preview): return
	if not barrier_preview.valid_placement: return
	var placed = BarrierScript.new()
	match_root.add_child(placed)
	placed.position = barrier_preview.position
	placed.setup(Vector2(balance.barrier_width, balance.barrier_height), balance.barrier_hit_points)
	barriers.append(placed)
	barrier_preview.queue_free()
	barrier_preview = null
	archers[current_side].skill_uses -= 1
	archers[current_side].play_build_visual()
	status_label.text = "%s 搭建了壁垒" % archers[current_side].display_name
	_finish_action()

func _end_move() -> void:
	if phase != Phase.MOVE or current_side != 0: return
	_finish_action()

func _cancel_action() -> void:
	if current_side != 0: return
	if phase == Phase.MOVE and not move_committed:
		phase = Phase.SELECT
	elif phase == Phase.AIM and not shot_committed:
		active_shot_kind = &"normal"
		phase = Phase.SELECT
	elif phase == Phase.BUILD:
		if is_instance_valid(barrier_preview): barrier_preview.queue_free()
		barrier_preview = null
		phase = Phase.SELECT
	else:
		return
	archers[0].set_visual_state(&"idle")
	trajectory = PackedVector2Array()
	preview_trails.clear()
	queue_redraw()
	status_label.text = "CHOOSE AN ACTION"
	_update_ui()

func _return_to_actor() -> void:
	if phase in [Phase.SELECT, Phase.MOVE, Phase.AIM]:
		temporary_full_view = false
		_focus_actor(current_side)

func _view_enemy() -> void:
	if current_side != 0 or phase not in [Phase.SELECT, Phase.MOVE, Phase.AIM]: return
	temporary_full_view = false
	_focus_actor(1)

func _begin_full_view() -> void:
	if current_side != 0 or phase not in [Phase.SELECT, Phase.MOVE, Phase.AIM] or temporary_full_view: return
	temporary_full_view = true
	saved_camera_goal = camera_goal
	saved_zoom_goal = zoom_goal
	camera_goal = Vector2(balance.world_width * 0.5, 385.0)
	zoom_goal = Vector2(0.5, 0.5)

func _end_full_view() -> void:
	if not temporary_full_view: return
	temporary_full_view = false
	camera_goal = saved_camera_goal
	zoom_goal = saved_zoom_goal

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
			var aim_axis := float(int(aim_up_held) - int(aim_down_held))
			if absf(aim_axis) > 0.01:
				aim_hold_elapsed += delta
				if aim_hold_elapsed >= balance.angle_hold_delay:
					var hold_speed: float = balance.fine_angle_hold_speed if Input.is_key_pressed(KEY_SHIFT) else balance.angle_hold_speed
					archers[0].aim_angle = clampf(archers[0].aim_angle + aim_axis * hold_speed * delta, balance.min_angle, balance.max_angle)
					archers[0].queue_redraw()
					_update_trajectory(float(last_player_shot.get("power", 0.5)))
			else:
				aim_hold_elapsed = 0.0
		if phase == Phase.CHARGE:
			charge_elapsed += delta
			charge_power = _triangle_power(charge_elapsed)
			archers[0].set_charge_visual(charge_power)
			preview_update_elapsed += delta
			if preview_update_elapsed >= 1.0 / 30.0:
				preview_update_elapsed = 0.0
				_update_trajectory(charge_power)
		_update_ui()
	if phase == Phase.ARROW and is_instance_valid(active_arrow):
		camera_goal = active_arrow.global_position
		zoom_goal = Vector2(0.88, 0.88)

func _input(event: InputEvent) -> void:
	if phase != Phase.HERO_SELECT or not (event is InputEventKey) or not event.pressed or event.echo: return
	var roles := [&"ranger", &"shark", &"architect"]
	var index := roles.find(selected_role)
	if event.keycode == KEY_LEFT:
		_select_hero(roles[posmod(index - 1, roles.size())])
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_RIGHT:
		_select_hero(roles[posmod(index + 1, roles.size())])
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and phase == Phase.BUILD and current_side == 0 and event.position.y < 590.0:
		_update_barrier_preview(get_global_mouse_position().x)
	if event is InputEventKey and current_side == 0:
		if event.keycode == KEY_TAB and not event.echo:
			if event.pressed: _begin_full_view()
			else: _end_full_view()
		if event.is_action("aim_up") or event.is_action("aim_down"):
			var is_up := event.is_action("aim_up")
			if event.pressed and not event.echo and phase == Phase.AIM:
				if is_up: aim_up_held = true
				else: aim_down_held = true
				aim_hold_elapsed = 0.0
				var tap: float = balance.fine_angle_tap_step if event.shift_pressed else balance.angle_tap_step
				archers[0].aim_angle = clampf(archers[0].aim_angle + (tap if is_up else -tap), balance.min_angle, balance.max_angle)
				archers[0].queue_redraw()
				_update_trajectory(float(last_player_shot.get("power", 0.5)))
			elif not event.pressed:
				if is_up: aim_up_held = false
				else: aim_down_held = false
		if event.is_action_pressed("charge") and phase == Phase.AIM and not event.echo:
			phase = Phase.CHARGE
			charging = true
			shot_committed = true
			charge_elapsed = 0.0
			archers[0].set_charge_visual(0.0)
			preview_update_elapsed = 0.0
			_focus_actor(0)
			status_label.text = "ACTION LOCKED: CHARGING"
		elif event.is_action_released("charge") and phase == Phase.CHARGE and charging:
			charging = false
			_fire_arrow(current_side, charge_power)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and phase == Phase.BUILD and current_side == 0:
		_place_barrier()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and phase in [Phase.SELECT, Phase.MOVE, Phase.AIM]:
		dragging = event.pressed
		last_mouse = event.position
		if event.pressed and not drag_hint_shown:
			drag_hint_shown = true
			status_label.text = "DRAG TO SCOUT · HOLD TAB FOR FULL MAP"
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
		archers[0].set_visual_state(&"aim")
		aim_up_held = false
		aim_down_held = false
		dragging = false
		_end_full_view()
		status_label.text = "FOCUS RESTORED · PRESS SPACE AGAIN"
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		aim_up_held = false
		aim_down_held = false
		dragging = false
		_end_full_view()

func _move_actor(actor, direction: float, delta: float) -> void:
	var requested_distance := minf(balance.move_speed * delta, move_remaining)
	var zone: Vector2 = terrain.left_zone if actor.side == 0 else terrain.right_zone
	var previous_x: float = actor.position.x
	var next_x: float = terrain.advance_along_surface(previous_x, signf(direction), requested_distance, zone)
	var actual: float = terrain.surface_distance(previous_x, next_x)
	actor.set_visual_state(&"move" if actual > 0.05 else &"idle")
	actor.position.x = next_x
	actor.position.y = terrain.surface_y(next_x)
	move_remaining = maxf(0.0, move_remaining - actual)
	if actual > 0.05 and not move_committed:
		move_committed = true
		status_label.text = "ACTION LOCKED: MOVING"
	_focus_actor(actor.side)
	if actor.side == 0:
		move_reachable_interval = terrain.reachable_interval(actor.position.x, move_remaining, 0)
		_update_last_shot_ui()
		queue_redraw()
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
	preview_trails.clear()
	queue_redraw()
	var shooter = archers[side]
	var target = archers[1 - side]
	shooter.play_release_visual(active_shot_kind)
	var angles: Array[float] = [shooter.aim_angle]
	var multiplier := 1.0
	if active_shot_kind == &"scatter":
		angles = [clampf(shooter.aim_angle - balance.scatter_angle_degrees, balance.min_angle, balance.max_angle), shooter.aim_angle, clampf(shooter.aim_angle + balance.scatter_angle_degrees, balance.min_angle, balance.max_angle)]
		multiplier = balance.scatter_damage_multiplier
	elif active_shot_kind == &"heavy":
		multiplier = balance.heavy_damage_multiplier
	if active_shot_kind != &"normal": shooter.skill_uses -= 1
	remaining_arrows = angles.size()
	shot_results.clear()
	active_arrows.clear()
	if side == 0:
		var paths: Array = []
		for angle in angles:
			var direction := _shot_direction(shooter, angle)
			var shot_trace: Dictionary = BallisticsScript.trace(shooter.muzzle_position(), direction * balance.launch_speed(power), balance.gravity, balance.arrow_timeout, balance.world_width, balance.world_bottom, terrain, target, BallisticsScript.DEFAULT_STEP, barriers)
			paths.append(shot_trace.points)
		pending_player_shot = {
			"angle": shooter.aim_angle,
			"power": power,
			"skill": active_shot_kind,
			"shooter_position": shooter.global_position,
			"target_position": target.global_position,
			"trajectory": paths[roundi((angles.size() - 1) * 0.5)],
			"trajectories": paths
		}
	for angle in angles:
		var arrow = ArrowScript.new()
		match_root.add_child(arrow)
		arrow.launch(shooter.muzzle_position(), _shot_direction(shooter, angle) * balance.launch_speed(power), shooter, target, terrain, balance.gravity, balance.arrow_timeout, barriers, multiplier)
		arrow.stopped.connect(_on_arrow_stopped.bind(turn_token, arrow))
		active_arrows.append(arrow)
	active_arrow = active_arrows[0]
	status_label.text = "%s 发射%s · %.1f° · %d%%" % [shooter.display_name, ROLES[shooter.role_id].skill if active_shot_kind != &"normal" else "普通箭", shooter.aim_angle, roundi(power * 100.0)]
	_update_ui()

func _shot_direction(shooter, angle: float) -> Vector2:
	return Vector2(cos(deg_to_rad(angle)) * shooter.facing_sign(), -sin(deg_to_rad(angle))).normalized()

func _on_arrow_stopped(result: Dictionary, token: int, arrow) -> void:
	if token != turn_token or phase != Phase.ARROW: return
	shot_results.append(result)
	remaining_arrows -= 1
	if is_instance_valid(arrow):
		if result.kind in [&"out_of_bounds", &"timeout"]:
			arrow.queue_free()
		else:
			landed_arrows.append(arrow)
			while landed_arrows.size() > 12:
				var oldest = landed_arrows.pop_front()
				if is_instance_valid(oldest): oldest.queue_free()
	if result.kind == &"actor":
		var damage: int = roundi(balance.damage_for(result.part) * arrow.damage_multiplier)
		var target = archers[1 - current_side]
		target.apply_damage(damage)
		var part_name: String = {&"head": "HEAD", &"torso": "TORSO", &"legs": "LEGS"}[result.part]
		hit_label.text = "%s −%d" % [part_name, damage]
		status_label.text = "%s HITS %s!" % [archers[current_side].display_name, target.display_name]
	elif result.kind == &"barrier":
		result.barrier.take_arrow_hit()
		hit_label.text = "壁垒命中 · 剩余%d次" % result.barrier.hit_points
	else:
		match result.kind:
			&"terrain": hit_label.text = "GROUND HIT"
			&"timeout": hit_label.text = "FLIGHT TIMEOUT"
			_: hit_label.text = "OUT OF BOUNDS"
	if remaining_arrows > 0:
		active_arrow = null
		for flying in active_arrows:
			if is_instance_valid(flying) and flying.active:
				active_arrow = flying
				break
		return
	phase = Phase.RESOLVE
	if current_side == 0:
		last_player_shot = pending_player_shot.duplicate()
		var best_result: Dictionary = result
		for shot_result in shot_results:
			if shot_result.kind == &"actor": best_result = shot_result
		last_player_shot["kind"] = best_result.kind
		last_player_shot["point"] = best_result.point
		if best_result.has("part"): last_player_shot["part"] = best_result.part
		pending_player_shot.clear()
		_update_last_shot_ui()
		queue_redraw()
	_update_ui()
	await get_tree().create_timer(1.0).timeout
	if token != turn_token: return
	if archers[0].health <= 0 or archers[1].health <= 0:
		_end_game()
	else:
		_finish_action()

func _finish_action() -> void:
	if phase == Phase.GAME_OVER: return
	archers[current_side].set_visual_state(&"idle")
	current_side = 1 - current_side
	_begin_turn()

func _end_game() -> void:
	phase = Phase.GAME_OVER
	turn_token += 1
	var player_won: bool = archers[1].health <= 0
	archers[0].set_visual_state(&"victory" if player_won else &"defeat")
	archers[1].set_visual_state(&"defeat" if player_won else &"victory")
	result_label.text = ("VICTORY!" if player_won else "DEFEAT") + "\n\nPLAYER %d / CPU %d" % [archers[0].health, archers[1].health]
	result_panel.visible = true
	turn_label.text = "MATCH OVER"
	status_label.text = "SELECT PLAY AGAIN FOR A NEW MAP"
	_update_ui()

func _ai_turn(token: int) -> void:
	phase = Phase.SELECT
	_update_ui()
	status_label.text = "CPU IS SCOUTING..."
	await get_tree().create_timer(0.45).timeout
	if token != turn_token: return
	if archers[1].role_id == &"architect" and archers[1].skill_uses > 0 and rng.randf() < 0.35:
		_begin_build(1)
		var candidate: float = archers[1].position.x - 170.0
		for attempt in 5:
			if _barrier_placement_valid(1, candidate): break
			candidate += 55.0
		_update_barrier_preview(candidate)
		await get_tree().create_timer(0.3).timeout
		if token != turn_token: return
		if barrier_preview.valid_placement:
			_place_barrier()
			return
		barrier_preview.queue_free()
		barrier_preview = null
		phase = Phase.SELECT
	var solution: Dictionary = await _find_ai_shot(token)
	if token != turn_token: return
	if solution.is_empty():
		await _ai_move(token)
		return
	archers[1].aim_angle = clampf(solution.angle + rng.randf_range(-2.0, 2.0), balance.min_angle, balance.max_angle)
	active_shot_kind = &"normal"
	if archers[1].skill_uses > 0:
		if archers[1].role_id == &"shark": active_shot_kind = &"heavy"
		elif archers[1].role_id == &"ranger": active_shot_kind = &"scatter"
	archers[1].set_skill_visual(active_shot_kind)
	archers[1].set_visual_state(&"aim")
	archers[1].queue_redraw()
	phase = Phase.AIM
	status_label.text = "CPU IS AIMING..."
	_focus_actor(1)
	_update_trajectory(solution.power)
	await get_tree().create_timer(0.55).timeout
	if token != turn_token: return
	phase = Phase.CHARGE
	archers[1].set_charge_visual(0.0)
	var target_power: float = clampf(solution.power + rng.randf_range(-0.03, 0.03), 0.0, 1.0)
	var elapsed := 0.0
	while elapsed < target_power * balance.charge_half_cycle:
		await get_tree().physics_frame
		if token != turn_token: return
		elapsed += get_physics_process_delta_time()
		charge_power = _triangle_power(elapsed)
		archers[1].set_charge_visual(charge_power)
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
	var origin: Vector2 = shooter.global_position + Vector2(0.0, -58.0) + dir * 34.0
	var traced: Dictionary = BallisticsScript.trace(origin, dir * balance.launch_speed(power), balance.gravity, balance.arrow_timeout, balance.world_width, balance.world_bottom, terrain, target, BallisticsScript.DEFAULT_STEP, barriers)
	return {"hit_actor": traced.result.kind == &"actor", "score": traced.closest}

func _ai_move(token: int) -> void:
	phase = Phase.MOVE
	status_label.text = "CPU MOVES AND ENDS ITS TURN"
	var actor = archers[1]
	var direction := -1.0 if rng.randf() < 0.75 else 1.0
	var distance := rng.randf_range(35.0, balance.move_budget)
	while distance > 0.0 and token == turn_token:
		await get_tree().physics_frame
		var step := minf(balance.move_speed * get_physics_process_delta_time(), distance)
		var before: float = actor.position.x
		var zone: Vector2 = terrain.right_zone
		actor.position.x = terrain.advance_along_surface(actor.position.x, direction, step, zone)
		actor.position.y = terrain.surface_y(actor.position.x)
		distance -= terrain.surface_distance(before, actor.position.x)
		if is_equal_approx(before, actor.position.x): break
		_focus_actor(1)
	if token == turn_token: _finish_action()

func _update_trajectory(power: float) -> void:
	var shooter = archers[current_side]
	var target = archers[1 - current_side]
	var angles: Array[float] = [shooter.aim_angle]
	if active_shot_kind == &"scatter": angles = [clampf(shooter.aim_angle - balance.scatter_angle_degrees, balance.min_angle, balance.max_angle), shooter.aim_angle, clampf(shooter.aim_angle + balance.scatter_angle_degrees, balance.min_angle, balance.max_angle)]
	preview_trails.clear()
	for angle in angles:
		var traced: Dictionary = BallisticsScript.trace(shooter.muzzle_position(), _shot_direction(shooter, angle) * balance.launch_speed(power), balance.gravity, balance.arrow_timeout, balance.world_width, balance.world_bottom, terrain, target, BallisticsScript.DEFAULT_STEP, barriers)
		preview_trails.append(BallisticsScript.first_fraction_by_arc(traced.points, 0.5))
	trajectory = preview_trails[roundi((preview_trails.size() - 1) * 0.5)]
	queue_redraw()

func _draw() -> void:
	if not last_player_shot.is_empty() and last_player_shot.has("trajectory"):
		for previous_path in last_player_shot.get("trajectories", [last_player_shot.trajectory]):
			if previous_path.size() > 1:
				for i in range(previous_path.size() - 1):
					if i % 2 == 0:
						draw_line(previous_path[i], previous_path[i + 1], Color("#76b9d844"), 2.0)
	for trail in preview_trails:
		if trail.size() > 1:
			for i in range(trail.size() - 1):
				var progress := float(i) / maxf(1.0, trail.size() - 2.0)
				var alpha := 0.72
				if progress > 0.8: alpha *= (1.0 - progress) / 0.2
				draw_line(trail[i], trail[i + 1], Color(1.0, 0.84, 0.40, alpha), 3.0)
	if not last_player_shot.is_empty() and last_player_shot.kind in [&"terrain", &"actor", &"barrier"]:
		var marker: Vector2 = last_player_shot.point
		var marker_color := Color("#b8c4d255")
		draw_circle(marker, 10.0, marker_color, false, 2.0)
		draw_line(marker + Vector2(-7, -7), marker + Vector2(7, 7), marker_color, 2.0)
		draw_line(marker + Vector2(-7, 7), marker + Vector2(7, -7), marker_color, 2.0)
	if phase == Phase.MOVE and current_side == 0 and move_reachable_interval.x < move_reachable_interval.y:
		var range_points := PackedVector2Array()
		var x := move_reachable_interval.x
		while x < move_reachable_interval.y:
			range_points.append(Vector2(x, terrain.surface_y(x) - 7.0))
			x += 12.0
		range_points.append(Vector2(move_reachable_interval.y, terrain.surface_y(move_reachable_interval.y) - 7.0))
		if range_points.size() > 1: draw_polyline(range_points, Color("#64b5ff99"), 5.0, true)

func _update_last_shot_ui() -> void:
	if last_player_shot.is_empty():
		last_shot_label.text = "LAST SHOT: NONE"
		return
	var outcome := ""
	match last_player_shot.kind:
		&"actor": outcome = {&"head": "HEAD HIT", &"torso": "TORSO HIT", &"legs": "LEG HIT"}.get(last_player_shot.get("part", &""), "HIT")
		&"terrain": outcome = "GROUND"
		&"barrier": outcome = "BARRIER"
		&"timeout": outcome = "TIMEOUT"
		_: outcome = "OUT"
	var changed: bool = archers.size() == 2 and (archers[0].global_position.distance_to(last_player_shot.shooter_position) > 0.5 or archers[1].global_position.distance_to(last_player_shot.target_position) > 0.5)
	last_shot_label.text = "LAST SHOT: %.1f° · %d%% · %s%s" % [last_player_shot.angle, roundi(last_player_shot.power * 100.0), outcome, "\nPOSITION CHANGED · REFERENCE ONLY" if changed else ""]

func _focus_actor(side: int) -> void:
	camera_goal = archers[side].global_position + Vector2(0.0, -130.0)
	camera_goal.x = clampf(camera_goal.x, 640.0, balance.world_width - 640.0)
	camera_goal.y = clampf(archers[side].global_position.y - 180.0, 260.0, 420.0)
	zoom_goal = Vector2(1.0, 1.0)

func _update_ui() -> void:
	if not is_instance_valid(player_hp) or archers.size() < 2: return
	last_shot_label.visible = phase != Phase.INTRO
	player_hp.value = archers[0].health
	ai_hp.value = archers[1].health
	player_hp_text.text = "玩家·%s %d / %d" % [archers[0].display_name, archers[0].health, archers[0].max_health]
	ai_hp_text.text = "电脑·%s %d / %d" % [archers[1].display_name, archers[1].health, archers[1].max_health]
	angle_label.text = "ANGLE %.1f°" % archers[current_side].aim_angle
	power_bar.value = charge_power * 100.0
	var descending: bool = fmod(charge_elapsed, balance.charge_half_cycle * 2.0) > balance.charge_half_cycle
	power_direction_label.text = "MARKS 25 · 50 · 75    %s" % ("-" if descending and phase == Phase.CHARGE else "+" if phase == Phase.CHARGE else "")
	move_label.text = "MOVE %d / %d" % [roundi(move_remaining), roundi(balance.move_budget)]
	if phase not in [Phase.INTRO, Phase.GAME_OVER]:
		turn_label.text = "%s TURN" % archers[current_side].display_name.to_upper()
	var player_can_choose := current_side == 0 and phase == Phase.SELECT
	move_button.disabled = not player_can_choose
	shoot_button.disabled = not player_can_choose
	skill_button.disabled = not player_can_choose or archers[0].skill_uses <= 0
	var skill_labels := {&"ranger": "三连", &"shark": "重击", &"architect": "建造"}
	skill_button.text = "%s×%d" % [skill_labels[archers[0].role_id], archers[0].skill_uses]
	skill_button.tooltip_text = "%s：%s" % [ROLES[archers[0].role_id].skill, ROLES[archers[0].role_id].detail]
	end_move_button.visible = current_side == 0 and phase == Phase.MOVE
	place_button.visible = current_side == 0 and phase == Phase.BUILD
	place_button.disabled = not is_instance_valid(barrier_preview) or not barrier_preview.valid_placement
	cancel_button.visible = current_side == 0 and ((phase == Phase.MOVE and not move_committed) or (phase == Phase.AIM and not shot_committed) or phase == Phase.BUILD)
	return_button.disabled = current_side != 0 or phase not in [Phase.SELECT, Phase.MOVE, Phase.AIM]
	enemy_button.visible = current_side == 0 and phase in [Phase.SELECT, Phase.MOVE, Phase.AIM]
