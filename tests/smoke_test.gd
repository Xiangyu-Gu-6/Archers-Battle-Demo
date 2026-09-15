extends SceneTree

const TerrainScript := preload("res://scripts/terrain.gd")
const ArcherScript := preload("res://scripts/archer.gd")
const BalanceScript := preload("res://scripts/game_balance.gd")

var failures: Array[String] = []

func _init() -> void:
	var balance = BalanceScript.new()
	for seed_value in range(1000, 1100):
		var terrain = TerrainScript.new()
		terrain.world_width = balance.world_width
		terrain.world_bottom = balance.world_bottom
		root.add_child(terrain)
		var result: Dictionary = terrain.generate(seed_value)
		if result.attempts > 20: failures.append("seed %d exceeded retry limit" % seed_value)
		for x in [250.0, 430.0, 610.0, 1790.0, 1970.0, 2150.0]:
			var y: float = terrain.surface_y(x)
			if y < 350.0 or y > 650.0: failures.append("seed %d invalid surface" % seed_value)
		terrain.free()
	var actor = ArcherScript.new()
	root.add_child(actor)
	actor.setup(0, "测试", Color.WHITE, balance.max_health)
	actor.position = Vector2(400, 550)
	var head_hit: Dictionary = actor.segment_hit(Vector2(350, 464), Vector2(450, 464))
	if not head_hit.hit or head_hit.part != &"head": failures.append("head swept collision failed")
	actor.apply_damage(balance.damage_for(&"head"))
	actor.apply_damage(balance.damage_for(&"head"))
	if actor.health != 0: failures.append("two headshots must reduce health to zero")
	actor.free()
	if failures.is_empty():
		print("SMOKE_TEST_OK seeds=100 collision=head damage=two_headshots")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

