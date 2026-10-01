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
	route.player.position = Vector2(4400,GameConfig.GROUND_Y)
	route.player.set_physics_process(false)
	var camera: Camera2D = scene.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	camera.position = Vector2(4650,225)
	camera.reset_smoothing()
	scene.set_process(false)
	scene.get_node("Interface").visible = false
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://validation/vehicle_pickup.png")
	scene.queue_free()
	await process_frame
	quit()
