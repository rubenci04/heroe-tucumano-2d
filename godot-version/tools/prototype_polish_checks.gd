extends SceneTree
## Focused prototype validation, separate from production test suites.
const CFG = preload("res://scripts/prototype/feel_config.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var arena = load("res://scenes/prototype/pixel_arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await process_frame
	await process_frame
	var viewport: SubViewport = arena.get_node("ViewportContainer/SubViewport")
	check(viewport.size == Vector2i(400, 225), "Viewport stays 400x225")
	arena.anim.set_process(false)
	arena.player.set_physics_process(false)
	check(is_equal_approx(arena.player.character_visual_scale, 0.42) and arena.player.scale == Vector2.ONE, "Ciruja physical and visual reference unchanged")
	var boss: Node
	var hipster: Node
	for enemy in arena.enemies.get_children():
		enemy.set_physics_process(false)
		if enemy.get("boss_state") != null:
			boss = enemy
		if enemy.get("archetype") == "hipster":
			hipster = enemy
		var body: CollisionShape2D = enemy.get_node("CollisionShape2D")
		check(absf(body.position.y + body.shape.size.y * 0.5) < 0.01, "Scaled collision rests at feet: " + enemy.name)
		check(body.shape.size == enemy.hurtbox.collision_shape.shape.size, "Hurtbox matches body: " + enemy.name)
	for sprite: AnimatedSprite2D in arena.batch_visuals:
		sprite.stop()
		sprite.set_meta("pose_multiplier", Vector2.ONE)
		var character: String = sprite.get_meta("batch_character", "campeona")
		var original := sprite.animation
		sprite.animation = &"avanzar_idle" if character == "hipster" else (&"idle" if character == "campeona" else &"correr")
		sprite.frame = 0
		arena._anchor_batch_visual(sprite)
		var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
		var height: float = CollisionFactory.opaque_bounds(texture).size.y * sprite.get_global_transform_with_canvas().get_scale().y
		print("SCALE %s: visible=%.2f target=%.2f" % [character, height, CFG.target_height(character)])
		check(absf(height - CFG.target_height(character)) < (3.0 if character == "ciruja" else 1.5), "Opaque height matches target (Ciruja fixed): " + character)
		for animation in sprite.sprite_frames.get_animation_names():
			for index in sprite.sprite_frames.get_frame_count(animation):
				sprite.animation = animation
				sprite.frame = index
				arena._anchor_batch_visual(sprite)
				var frame := sprite.sprite_frames.get_frame_texture(animation, index)
				var batch := frame.resource_path.begins_with("res://characters/")
				var feet := 240.0 if batch else CollisionFactory.opaque_bounds(frame).end.y
				check(absf(feet - frame.get_height() * 0.5 + sprite.offset.y) < 0.01, "%s/%s/%d feet anchored" % [character, animation, index])
			sprite.animation = original
			sprite.frame = 0
			arena._anchor_batch_visual(sprite)
	var shadow_count := 0
	for child in arena.world.get_children():
		if child.name.ends_with("ContactShadow"):
			shadow_count += 1
	check(shadow_count == 6, "Six proportional contact shadows")
	check(boss != null and hipster != null, "Boss and scooter connected")
	for name in [&"avanzar_idle", &"tirar_botella", &"tirar_cafe", &"caida"]:
		check(hipster.visual.sprite_frames.has_animation(name), "Hipster animation: " + String(name))
	hipster.ai_state = hipster.AIState.TELEGRAPH
	arena._update_hipster_attack(hipster)
	check(hipster.definition.projectile_definition.projectile_id == &"hipster_coffee", "First throw uses coffee")
	hipster.ai_state = hipster.AIState.RECOVERY
	arena._update_hipster_attack(hipster)
	hipster.ai_state = hipster.AIState.TELEGRAPH
	arena._update_hipster_attack(hipster)
	check(hipster.definition.projectile_definition.projectile_id == &"bottle", "Next throw uses bottle")
	check(load("res://data/enemies/hipster.tres").projectile_definition.projectile_id == &"hipster_coffee", "Production Hipster definition remains untouched")
	for kind in ["bottle", "hipster_coffee"]:
		arena._spawn_projectile(hipster.global_position + Vector2(-24, -42), 0, -1, kind, "enemy", hipster)
		var projectile: Node = arena.projectiles.get_child(-1)
		check(projectile.kind == StringName(kind), "Projectile created by code: " + kind)
		var hand: Vector2 = CFG.BATCH_MUZZLE_SOURCE.hipster - Vector2(160, 240)
		if hipster.facing < 0:
			hand.x = -hand.x
		check(projectile.position.is_equal_approx(hipster.visual.to_global(hand)), "Scaled throwing-hand socket: " + kind)
		projectile.queue_free()
	var agent: Node = arena.enemies.get_children().filter(func(actor): return actor.get("archetype") == "agente")[0]
	for facing in [-1, 1]:
		agent.facing = facing
		arena._spawn_projectile(agent.global_position + Vector2(facing * 22, -58), 0, facing, "agent_orb", "enemy", agent)
		var shot: Node = arena.projectiles.get_child(-1)
		var tip: Vector2 = CFG.BATCH_MUZZLE_SOURCE.agente - Vector2(160, 240)
		if facing > 0:
			tip.x = -tip.x
		check(shot.position.is_equal_approx(agent.visual.to_global(tip)) and shot.direction == facing, "Agent gun-tip socket follows facing and visual scale")
		shot.queue_free()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://scenes/levels/route_38_data.json"))
	for id in ["route_wave_01", "route_wave_02"]:
		var wave: Dictionary = data.encounters.filter(func(item): return item.id == id)[0]
		check(wave.enemies.size() == 6 and is_equal_approx(wave.enemies[-1].delay, 2.25), "Early presence with stagger intact: " + id)
	var ending = load("res://data/dialogues/demo_ending.tres")
	check(ending.entries.any(func(entry): return "Ingenio La Providencia" in entry.text and "Campeona" in entry.text), "Ending keeps rescue unfinished")
	var environment = load("res://scenes/levels/route_38_environment.tscn").instantiate()
	check(not environment.get_node("DistantBackground/MountainsB").flip_h, "Sky not mirrored")
	environment.free()
	if "--capture" in OS.get_cmdline_user_args() and not DisplayServer.get_name() == "headless":
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("user://prototype_cartoon_polish.png")
		print("CAPTURE ", ProjectSettings.globalize_path("user://prototype_cartoon_polish.png"))
	arena.queue_free()
	await process_frame
	print("PROTOTYPE_POLISH %d/%d PASS, %d FAIL" % [checks-failures, checks, failures])
	quit(0 if failures == 0 else 1)
