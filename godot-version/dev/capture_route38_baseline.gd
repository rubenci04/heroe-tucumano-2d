extends SceneTree
## Reproducible render-only baseline. It does not mutate gameplay resources or PNG assets.

const OUTPUT_DIR := "res://docs/baseline"


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	root.size = Vector2i(800,450)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.get_node("Interface/CharacterSelect").confirm_selected()
	scene.get_node("IntroFamailla").skip()
	await process_frame
	var route = scene.get_node("Route38")
	route.set_physics_process(false)
	route.encounter_director.reset_runtime_state(true)
	route.player.set_physics_process(false)
	route.player.play_animation(&"Idle")
	scene.get_node("Interface").visible = false
	var camera: Camera2D = scene.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	for view in [
		{"name":"01_start","center":400.0},
		{"name":"02_expresbus_sector","center":2850.0},
		{"name":"03_tesa_midpoint","center":4400.0},
		{"name":"04_drone_sector","center":6200.0},
		{"name":"05_preboss","center":7600.0}
	]:
		camera.position = Vector2(view.center,225.0)
		route.player.position = Vector2(view.center-260.0,GameConfig.GROUND_Y)
		camera.reset_smoothing()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/%s.png" % [OUTPUT_DIR,view.name])
	# Runtime scale lineup, still inside this disposable fixture.
	camera.position = Vector2(4400,225)
	route.player.position = Vector2(4100,GameConfig.GROUND_Y)
	for pair in [["agente",4260.0],["hipster",4420.0],["grandote",4590.0]]:
		var actor = route.spawn_enemy(pair[0],pair[1],0)
		actor.set_physics_process(false)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/06_runtime_scale_lineup.png" % OUTPUT_DIR)
	root.get_node("AudioManager").stop_all()
	scene.queue_free()
	await process_frame
	quit()
