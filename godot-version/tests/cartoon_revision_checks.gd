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
	root.get_node("AudioManager").stop_all()
	scene.queue_free()
	await process_frame
	print("CARTOON_POINT_%d %d/%d PASS %d FAIL" % [point, checks-failures.size(), checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
