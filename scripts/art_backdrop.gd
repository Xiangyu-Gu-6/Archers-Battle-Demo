class_name ArtBackdrop
extends Node2D

const SKY := preload("res://assets/art/environments/carnival_sky_base_v01.png")
const FAR := preload("res://assets/art/environments/carnival_far_parallax_v01.png")
const MID := preload("res://assets/art/environments/carnival_midground_parallax_v01.png")
const TENT := preload("res://assets/art/props/carnival_tent_v01.png")
const WAGON := preload("res://assets/art/props/carnival_wagon_v01.png")
const TARGET := preload("res://assets/art/props/carnival_target_v01.png")

var battle_camera: Camera2D
var world_width := 2400.0
var sky: Sprite2D
var far_layer: Sprite2D
var mid_layer: Sprite2D

func setup(camera_node: Camera2D, width: float) -> void:
	battle_camera = camera_node
	world_width = width
	z_index = -100
	sky = _make_layer(SKY, Vector2(1.60, 1.60), -30)
	far_layer = _make_layer(FAR, Vector2(1.25, 1.25), -20)
	mid_layer = _make_layer(MID, Vector2(1.25, 1.25), -10)
	far_layer.modulate = Color(1.0, 1.0, 1.0, 0.78)
	mid_layer.modulate = Color(1.0, 1.0, 1.0, 0.58)
	sky.position = Vector2(world_width * 0.5, 360.0)
	far_layer.position = Vector2(world_width * 0.5, 365.0)
	mid_layer.position = Vector2(world_width * 0.5, 365.0)

func _make_layer(texture: Texture2D, layer_scale: Vector2, layer_z: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = layer_scale
	sprite.z_index = layer_z
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(sprite)
	return sprite

func _process(_delta: float) -> void:
	if not is_instance_valid(battle_camera) or not is_instance_valid(sky): return
	var offset := battle_camera.position.x - world_width * 0.5
	sky.position.x = battle_camera.position.x
	far_layer.position.x = world_width * 0.5 + offset * 0.15
	mid_layer.position.x = world_width * 0.5 + offset * 0.34

func add_match_props(parent: Node2D, terrain, seed_value: int) -> Node2D:
	var props := Node2D.new()
	props.name = "DecorativeProps"
	props.z_index = -2
	parent.add_child(props)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0xA471
	var entries := [
		{"texture": TENT, "x": rng.randf_range(820.0, 990.0), "scale": 0.15},
		{"texture": WAGON, "x": rng.randf_range(1110.0, 1290.0), "scale": 0.15},
		{"texture": TARGET, "x": rng.randf_range(1430.0, 1600.0), "scale": 0.11}
	]
	for entry in entries:
		var sprite := Sprite2D.new()
		sprite.texture = entry.texture
		sprite.scale = Vector2.ONE * float(entry.scale)
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.68)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var x := float(entry.x)
		var half_height: float = entry.texture.get_height() * float(entry.scale) * 0.5
		sprite.position = Vector2(x, terrain.surface_y(x) - half_height + 12.0)
		props.add_child(sprite)
	return props
