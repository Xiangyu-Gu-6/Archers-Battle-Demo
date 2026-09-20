class_name CarnivalCharacterRig
extends Node2D

const ROLE_FOLDERS := {
	&"shark": "shipwreck_shark",
	&"architect": "architect"
}
const PART_BONES := {
	"torso": "Spine", "head": "Head", "headband": "Hat", "hat": "Hat",
	"fin": "Feather", "cape": "Feather", "quiver": "Quiver",
	"tool_belt": "BeltPouch", "rear_upper_arm": "RearUpperArm",
	"rear_forearm": "RearForearm", "front_upper_arm": "FrontUpperArm",
	"front_forearm": "FrontForearm", "rear_thigh": "RearThigh",
	"rear_shin": "RearShin", "front_thigh": "FrontThigh",
	"front_shin": "FrontShin", "bow": "BowGrip", "arrow": "NockedArrow",
	"blueprint_hand": "FrontForearm", "folded_barrier": "FrontForearm"
}

var role_id: StringName = &"shark"
var side := 1
var skeleton: Skeleton2D
var bones: Dictionary = {}
var sprites: Dictionary = {}
var bone_source: Dictionary = {}
var part_bones: Dictionary = {}
var bow_string: Line2D
var rig_data: Dictionary = {}
var motion_data: Dictionary = {}
var combat_state: StringName = &"idle"
var shot_kind: StringName = &"normal"
var aim_degrees := 45.0
var charge_amount := 0.0
var motion_time := 0.0
var state_elapsed := 0.0
var action_name := ""
var action_elapsed := 0.0
var hit_elapsed := -1.0

func configure(role: StringName, which_side: int) -> void:
	role_id = role
	side = which_side

func _ready() -> void:
	var folder: String = ROLE_FOLDERS[role_id]
	var root := "res://assets/art/characters/%s/%s_" % [folder, folder]
	rig_data = JSON.parse_string(FileAccess.get_file_as_string(root + "rig_anchors_v06.json"))
	motion_data = JSON.parse_string(FileAccess.get_file_as_string(root + "animation_keys_v03.json"))
	var skeleton_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(root + "skeleton_v01.json"))
	var uniform_scale: float = float(rig_data["recommended_uniform_scale"])
	var native_right: bool = str(rig_data["facing"]) == "right"
	var mirror: bool = (side == 0) != native_right
	scale = Vector2(-uniform_scale if mirror else uniform_scale, uniform_scale)
	var canvas: Array = rig_data["source_canvas_px"]
	var root_pivot: Array = rig_data["root_pivot_source_px"]
	position.y = -(float(canvas[1]) - float(root_pivot[1])) * uniform_scale
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_build_skeleton(skeleton_data)
	_build_sprites()
	_build_string()
	_apply_frame()

func _build_skeleton(data: Dictionary) -> void:
	skeleton = Skeleton2D.new()
	skeleton.name = "CharacterSkeleton2D"
	add_child(skeleton)
	for raw_bone in data["bones"]:
		var spec: Dictionary = raw_bone
		var bone := Bone2D.new()
		var name_value: String = str(spec["name"])
		bone.name = name_value
		var local: Array = spec["rest_local_px"]
		bone.position = Vector2(float(local[0]), float(local[1]))
		bone.set_autocalculate_length_and_angle(false)
		bone.set_length(maxf(1.0, float(spec["suggested_length_px"])))
		var parent_name = spec["parent"]
		var parent: Node = skeleton if parent_name == null else bones[str(parent_name)]
		parent.add_child(bone)
		bones[name_value] = bone
		bone_source[name_value] = spec["rest_global_source_px"]
	for bone in bones.values(): bone.rest = bone.transform

func _build_sprites() -> void:
	var parts: Dictionary = rig_data["parts"]
	for raw_name in rig_data["z_order_back_to_front"]:
		var part_name: String = str(raw_name)
		if not parts.has(part_name): continue
		var spec: Dictionary = parts[part_name]
		var bone_name: String = PART_BONES.get(part_name, str(spec["parent_bone"]))
		if not bones.has(bone_name): bone_name = str(spec["parent_bone"])
		var bone: Bone2D = bones[bone_name]
		var rect: Array = spec["source_rect_px"]
		var source: Array = bone_source[bone_name]
		var sprite := Sprite2D.new()
		sprite.name = part_name.to_pascal_case() + "Skin"
		sprite.texture = load(str(spec["file"]))
		sprite.centered = false
		# v04 cutouts include 8 transparent pixels on every side.
		sprite.position = Vector2(float(rect[0]) - 8.0 - float(source[0]), float(rect[1]) - 8.0 - float(source[1]))
		sprite.z_index = int(spec["z_index"])
		sprite.visible = bool(spec.get("visibility_default", true))
		bone.add_child(sprite)
		sprites[part_name] = sprite
		part_bones[part_name] = bone_name

func _build_string() -> void:
	bow_string = Line2D.new()
	bow_string.name = "DynamicBowString"
	bow_string.width = 10.0
	bow_string.default_color = Color("#f8e5b9")
	bow_string.z_index = 13
	bow_string.antialiased = true
	skeleton.add_child(bow_string)

func _process(delta: float) -> void:
	motion_time += delta
	state_elapsed += delta
	if action_name != "":
		action_elapsed += delta
		var animation: Dictionary = motion_data["animations"][action_name]
		if action_elapsed >= float(animation["duration_s"]): action_name = ""
	if hit_elapsed >= 0.0:
		hit_elapsed += delta
		if hit_elapsed >= 0.42: hit_elapsed = -1.0
	_apply_frame()

func set_combat_state(next_state: StringName) -> void:
	if combat_state != next_state: state_elapsed = 0.0
	combat_state = next_state
	if next_state != &"charge": charge_amount = 0.0

func set_aim_degrees(value: float) -> void:
	aim_degrees = value

func set_skill_visual(kind: StringName) -> void:
	shot_kind = kind

func set_charge(value: float) -> void:
	combat_state = &"charge"
	charge_amount = clampf(value, 0.0, 1.0)

func play_release(kind: StringName = &"normal") -> void:
	shot_kind = kind
	action_name = "heavy_shot" if role_id == &"shark" and kind == &"heavy" else "normal_shoot"
	action_elapsed = _event_time(action_name, "nocked_arrow_hide", 0.6)
	charge_amount = 0.0
	_apply_frame()

func play_build() -> void:
	if role_id != &"architect": return
	action_name = "build_barrier"
	action_elapsed = 0.70
	_apply_frame()

func play_hit() -> void:
	hit_elapsed = 0.0
	_apply_frame()

func is_nocked_arrow_visible() -> bool:
	return is_instance_valid(sprites.get("arrow")) and sprites["arrow"].visible

func _event_time(animation_name: String, event_id: String, fallback: float) -> float:
	var animation: Dictionary = motion_data["animations"].get(animation_name, {})
	for raw_event in animation.get("events", []):
		var event: Dictionary = raw_event
		if str(event["id"]) == event_id: return float(event["at_s"])
	return fallback

func _sample_animation(animation_name: String, time_value: float) -> Dictionary:
	var animation: Dictionary = motion_data["animations"][animation_name]
	var duration: float = float(animation["duration_s"])
	var t: float = fmod(time_value, duration) if bool(animation.get("loop", false)) else minf(time_value, duration)
	var keys: Array = animation["keyframes"]
	var before: Array = keys[0]
	var after: Array = keys[keys.size() - 1]
	for i in keys.size():
		var item: Array = keys[i]
		if float(item[0]) <= t:
			before = item
			after = keys[mini(i + 1, keys.size() - 1)]
	var ratio := 0.0
	if float(after[0]) > float(before[0]): ratio = clampf((t - float(before[0])) / (float(after[0]) - float(before[0])), 0.0, 1.0)
	ratio = ratio * ratio * (3.0 - 2.0 * ratio)
	var poses: Dictionary = motion_data["poses_degrees"]
	return _blend_poses(poses[str(before[1])], poses[str(after[1])], ratio)

func _blend_poses(a: Dictionary, b: Dictionary, weight: float) -> Dictionary:
	var result := {}
	for key in a.keys(): result[key] = lerpf(float(a[key]), float(b.get(key, 0.0)), weight)
	for key in b.keys():
		if not result.has(key): result[key] = lerpf(0.0, float(b[key]), weight)
	return result

func _apply_frame() -> void:
	if not is_instance_valid(skeleton): return
	var pose: Dictionary
	var animation_name := "idle_loop"
	var elapsed := motion_time
	if combat_state in [&"defeat", &"victory"]:
		animation_name = str(combat_state)
		elapsed = state_elapsed
	elif hit_elapsed >= 0.0:
		animation_name = "hit_react"
		elapsed = hit_elapsed
	elif action_name != "":
		animation_name = action_name
		elapsed = action_elapsed
	elif combat_state == &"move":
		animation_name = "move_loop"
	elif combat_state == &"build_preview" and role_id == &"architect":
		animation_name = "build_barrier"
		elapsed = 0.45
	elif combat_state == &"aim":
		pose = motion_data["poses_degrees"]["anticipation"]
	elif combat_state == &"charge":
		var target_pose := "charge" if shot_kind == &"heavy" else "light_charge"
		if not motion_data["poses_degrees"].has(target_pose): target_pose = "charge"
		pose = _blend_poses(motion_data["poses_degrees"]["anticipation"], motion_data["poses_degrees"][target_pose], charge_amount)
	if pose.is_empty(): pose = _sample_animation(animation_name, elapsed)
	_apply_bone_rotations(pose)
	_apply_visibility(animation_name, elapsed)
	_update_string()

func _apply_bone_rotations(pose: Dictionary) -> void:
	var desired := {}
	for bone_name in bones.keys(): desired[bone_name] = 0.0
	for part_name in pose.keys():
		if not part_bones.has(part_name): continue
		var bone_name: String = part_bones[part_name]
		if part_name in ["torso", "head", "hat", "headband", "fin", "cape", "quiver", "tool_belt", "rear_upper_arm", "rear_forearm", "front_upper_arm", "front_forearm", "rear_thigh", "rear_shin", "front_thigh", "front_shin", "bow", "arrow"]:
			desired[bone_name] = float(pose[part_name])
	for bone_name in bones.keys():
		var bone: Bone2D = bones[bone_name]
		var parent: Node = bone.get_parent()
		var parent_angle: float = float(desired.get(parent.name, 0.0)) if parent is Bone2D else 0.0
		bone.rotation = deg_to_rad(float(desired[bone_name]) - parent_angle)
	for part_name in sprites.keys():
		var part_angle: float = float(pose.get(part_name, 0.0))
		var bone_angle: float = float(desired[part_bones[part_name]])
		sprites[part_name].rotation = deg_to_rad(part_angle - bone_angle)

func _apply_visibility(animation_name: String, time_value: float) -> void:
	var animation: Dictionary = motion_data["animations"][animation_name]
	var visibility: Dictionary = animation.get("visibility", {})
	for part_name in sprites.keys():
		var spec: Dictionary = rig_data["parts"][part_name]
		var visible_now: bool = bool(spec.get("visibility_default", true))
		if visibility.has(part_name):
			var rule: Dictionary = visibility[part_name]
			var show_time: float = float(rule.get("show_from_s", -1.0))
			var hide_time: float = float(rule.get("hide_from_s", -1.0))
			if show_time >= 0.0 and hide_time >= 0.0:
				visible_now = (time_value >= show_time and time_value < hide_time) if show_time < hide_time else (time_value < hide_time or time_value >= show_time)
			elif show_time >= 0.0: visible_now = time_value >= show_time
			elif hide_time >= 0.0: visible_now = time_value < hide_time
		if combat_state == &"build_preview":
			if part_name == "blueprint_hand": visible_now = true
			if part_name in ["bow", "arrow", "folded_barrier"]: visible_now = false
		sprites[part_name].visible = visible_now
	bow_string.visible = sprites.has("bow") and sprites["bow"].visible

func _update_string() -> void:
	if not bow_string.visible or not sprites.has("bow") or not bones.has("NockedArrow"): return
	var spec: Dictionary = rig_data["parts"]["bow"]
	var rect: Array = spec["source_rect_px"]
	var source: Array = bone_source["BowGrip"]
	var tip_x := float(rect[0]) + float(rect[2]) * 0.5 - float(source[0])
	var top_local := Vector2(tip_x, float(rect[1]) - float(source[1]))
	var bottom_local := Vector2(tip_x, float(rect[1]) + float(rect[3]) - float(source[1]))
	var bow_bone: Bone2D = bones["BowGrip"]
	var arrow_bone: Bone2D = bones["NockedArrow"]
	var top_point := skeleton.to_local(bow_bone.to_global(top_local))
	var bottom_point := skeleton.to_local(bow_bone.to_global(bottom_local))
	var nock_point := skeleton.to_local(arrow_bone.global_position) if is_nocked_arrow_visible() else top_point.lerp(bottom_point, 0.5)
	bow_string.points = PackedVector2Array([top_point, nock_point, bottom_point])
