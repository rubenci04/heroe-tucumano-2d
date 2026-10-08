extends SceneTree
## Focused route regression and reproducible rendered evidence. -- --point=1 --capture
const CFG = preload("res://scripts/prototype/feel_config.gd")
var failures: Array[String] = []
var checks := 0
var point := 1
var scene: Node
var route: Node
var camera: Camera2D

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--point="):
			point = int(argument.trim_prefix("--point="))
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var directory := "res://tests/screenshots/cartoon_revision"
	DirAccess.make_dir_recursive_absolute(directory)
	check(root.get_texture().get_image().save_png(directory.path_join(name + ".png")) == OK, "Saved " + name)

func _run() -> void:
	root.size = Vector2i(800, 450)
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.get_node("Interface/CharacterSelect").confirm_selected()
	scene.get_node("IntroFamailla").skip()
	await process_frame
	route = scene.get_node("Route38")
	route.set_physics_process(false)
	route.encounter_director.reset_runtime_state(true)
	route.traffic_director.set_enabled(false, true)
	route.player.set_physics_process(false)
	scene.set_process(false)
	camera = scene.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	camera.position = Vector2(400, 225)
	route.player.position = Vector2(200, GameConfig.GROUND_Y)
	if point == 1:
		var sprite: AnimatedSprite2D = route.player.visual
		var idle: StringName = route.player.character_definition.idle_animation
		sprite.play(idle)
		check(sprite.sprite_frames.get_frame_count(idle) == 8, "Idle has eight frames")
		check(sprite.sprite_frames.get_animation_speed(idle) == 6 and sprite.sprite_frames.get_animation_loop(idle), "Idle loops at 6 fps")
		for index in 8:
			check("/ciruja/idle/" in sprite.sprite_frames.get_frame_texture(idle, index).resource_path, "Neutral idle source %d" % index)
		check(sprite.sprite_frames.has_animation(&"ajustar_gorra"), "Cap adjustment remains available")
		await capture("p1_idle")
	if point == 2:
		var player = route.player
		player.play_animation(player.character_definition.idle_animation)
		player.visual.pause()
		var base_height: float = CollisionFactory.opaque_bounds(player.visual.sprite_frames.get_frame_texture(player.visual.animation, 0)).size.y * player.character_visual_scale
		var heights: Array[float] = []
		for y in [370.0, 330.0, 290.0]:
			# Continuous travel to each throwing height, never rescale or teleport in gameplay.
			var start: float = player.position.y
			for frame in 30:
				player.position.y = lerpf(start, y, (frame + 1.0) / 30.0)
				route.anim._update_player(1.0 / 60.0)
				route._batch._anchor(player.visual)
				check(player.visual.scale.is_equal_approx(Vector2.ONE * player.character_visual_scale), "Fixed player scale while changing Y")
			player.oranges_unlocked = true
			player.shot_cooldown = 0
			player.throw_projectile("orange", Vector2.RIGHT)
			player.play_animation(player.action_animation)
			player.visual.pause()
			check("/ciruja/idle/" in player.visual.sprite_frames.get_frame_texture(player.visual.animation, 0).resource_path, "Throw preserves the new silhouette")
			var shot = route.get_node("Projectiles").get_child(-1)
			shot.set_physics_process(false)
			var height: float = CollisionFactory.opaque_bounds(player.visual.sprite_frames.get_frame_texture(player.visual.animation, player.visual.frame)).size.y * player.visual.scale.y
			heights.append(height)
			check(absf(height / base_height - 1.0) <= 0.03, "Throw height stays within 3% at Y=" + str(y))
			await capture("p2_orange_y_%d" % int(y))
			shot.queue_free()
		check(heights.max() / heights.min() <= 1.03, "Three visible throw heights differ by at most 3%")
		for character in ["agente", "hipster", "grandote"]:
			var enemy = route.spawn_enemy(character, 400, 0)
			enemy.set_physics_process(false)
			var fixed: Vector2 = enemy.visual.scale
			for y in [370.0, 330.0, 290.0]:
				enemy.position.y = y
				route.anim._update_enemy(enemy, route.anim._enemies[enemy])
				route._batch._anchor(enemy.visual)
				check(enemy.scale == Vector2.ONE and enemy.visual.scale.is_equal_approx(fixed), "Enemy scale independent of Y: " + character)
			enemy.queue_free()
	root.get_node("AudioManager").stop_all()
	scene.queue_free()
	await process_frame
	print("CARTOON_POINT_%d %d/%d PASS %d FAIL" % [point, checks-failures.size(), checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
