extends SceneTree
## Nine render-only 800x450 views for panorama seams and road-prop grounding.

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(800,450)
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
	scene.get_node("Interface").visible = false
	var camera: Camera2D = scene.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	for view in [
		{"name":"background_A","center":400.0},
		{"name":"background_AB","center":3394.0},
		{"name":"background_B","center":5091.0},
		{"name":"background_BC","center":6787.0},
		{"name":"background_C","center":7600.0},
		{"name":"ground_auto","center":700.0},
		{"name":"ground_camion_limones","center":4650.0},
		{"name":"ground_parada","center":2700.0}
	]:
		camera.position = Vector2(view.center,225.0)
		route.player.position = Vector2(view.center-300.0,GameConfig.GROUND_Y)
		camera.reset_smoothing()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://validation/%s.png" % view.name)
	var traffic = route.traffic_director
	traffic.enabled = true
	traffic.spawn_set_piece(&"capture_exprebus",&"exprebus",3200,-1,240,false)
	traffic.spawn_set_piece(&"capture_tesa",&"tesa",3650,-1,225,false)
	camera.position = Vector2(3425,225)
	route.player.position = Vector2(3425,GameConfig.GROUND_Y)
	camera.reset_smoothing()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://validation/ground_buses.png")
	var report := {"resolution":[800,450],"captures":["background_A.png","background_AB.png","background_B.png","background_BC.png","background_C.png","ground_auto.png","ground_camion_limones.png","ground_parada.png","ground_buses.png"]}
	var output := FileAccess.open("res://validation/background_grounding_captures.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"  ")+"\n")
	output.close()
	root.get_node("AudioManager").stop_all()
	scene.queue_free()
	await process_frame
	quit()
