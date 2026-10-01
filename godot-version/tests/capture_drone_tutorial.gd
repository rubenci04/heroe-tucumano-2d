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
	var director = route.encounter_director
	route.set_physics_process(false)
	route.player.set_physics_process(false)
	route.player.position = Vector2(4100,GameConfig.GROUND_Y)
	director.reset_runtime_state(true)
	director.update_safety(4100.0,4100.0,800.0)
	director.activate_encounter(&"route_drone_01",4100.0,true)
	var drone = director.get_active_enemies(&"route_drone_01")[0]
	drone.set_physics_process(false)
	drone.position = Vector2(4280,205)
	drone.flight_anchor_y = drone.position.y
	drone.patrol_center_x = drone.position.x
	drone.ai_state = drone.AIState.IDLE
	drone.cooldown_remaining = 0.65
	var camera: Camera2D = scene.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	camera.position = Vector2(4100,225)
	camera.reset_smoothing()
	scene.set_process(false)
	scene.get_node("Interface").visible = false
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://validation/drone_tutorial.png")
	scene.queue_free()
	await process_frame
	quit()
