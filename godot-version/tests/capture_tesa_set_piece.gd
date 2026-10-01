extends SceneTree

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
	var event = route.get_node("TesaSetPiece")
	var completed: Array[StringName] = [&"route_wave_01",&"route_wave_02",&"route_wave_03",&"route_micro_03",&"route_drone_01"]
	route.encounter_director.restore_completed_encounters(completed)
	route.player.position = Vector2(event.trigger_x,GameConfig.GROUND_Y)
	event.advance(0.0,route)
	event.advance(1.01,route)
	var bus = event.vehicle
	bus.set_physics_process(false)
	bus.position.x = 4400.0
	for platform in get_nodes_in_group("stationary_vehicles"):
		if absf(platform.position.x-bus.position.x)<600.0:
			platform.visible = false
	route.player.position = Vector2(4330.0,bus.get_roof_world_y())
	route.player.set_physics_process(false)
	var camera: Camera2D = scene.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	camera.position = Vector2(4400,225)
	camera.reset_smoothing()
	scene.set_process(false)
	scene.get_node("Interface").visible = false
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://validation/tesa_set_piece.png")
	scene.queue_free()
	await process_frame
	quit()
