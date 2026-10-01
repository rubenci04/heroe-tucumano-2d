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
	route.player.position = Vector2(6100,GameConfig.GROUND_Y)
	var completed: Array[StringName] = [&"route_drone_01",&"route_wave_04",&"route_micro_05"]
	director.restore_completed_encounters(completed)
	director.update_safety(6100.0,6100.0,800.0)
	director.activate_encounter(&"route_drone_02",6100.0,false)
	var wave: Array[Node] = director.get_active_enemies(&"route_drone_02")
	var positions := [Vector2(5800,190),Vector2(5945,160),Vector2(6100,185),Vector2(6255,155),Vector2(6400,195)]
	for index in range(wave.size()):
		var drone = wave[index]
		drone.set_physics_process(false)
		drone.position = positions[index]
		drone.flight_anchor_y = drone.position.y
		drone.patrol_center_x = drone.position.x
		drone.ai_state = drone.AIState.IDLE
		drone.cooldown_remaining = 0.0
	director.update_safety(6100.0,6100.0,800.0)
	wave[0]._begin_aim()
	director.advance_spawns(0.23,6100.0)
	wave[3]._begin_aim()
	var camera: Camera2D = scene.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	camera.position = Vector2(6100,225)
	camera.reset_smoothing()
	scene.set_process(false)
	scene.get_node("Interface").visible = false
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://validation/drone_wave.png")
	scene.queue_free()
	await process_frame
	quit()
