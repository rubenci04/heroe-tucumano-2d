extends SceneTree
## Visual validation only: three 800x450 route zones, no gameplay mutation.

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
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	scene.get_node("Interface").visible = false
	var camera: Camera2D = scene.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	var route = scene.get_node("Route38")
	var player = route.get_node("Player")
	var director = route.get_node("EncounterDirector")
	var captures: Array[Dictionary] = []
	for entry: Dictionary in [
		{"name":"early","id":&"route_wave_01","center":1450.0,"activation":900.0},
		{"name":"middle","id":&"route_wave_03","center":4150.0,"activation":3500.0},
		{"name":"late","id":&"route_wave_06","center":7410.0,"activation":6800.0}
	]:
		for projectile in route.get_node("Projectiles").get_children():
			projectile.queue_free()
		director.reset_runtime_state(true)
		await process_frame
		director.camera_center_x = NAN
		director.activate_encounter(entry.id,entry.activation,false)
		var actors: Array[Node] = director.get_active_enemies(entry.id)
		for actor in actors:
			actor.set_physics_process(false)
		if entry.name == "middle":
			scene._spawn_projectile(Vector2(entry.center+40.0,300.0),0,-1,"hipster_coffee","enemy")
			var coffee = route.get_node("Projectiles").get_child(-1)
			coffee.set_physics_process(false)
		camera.position = Vector2(entry.center,225.0)
		player.position = Vector2(entry.center-300.0,GameConfig.GROUND_Y)
		player.play_animation(&"Idle")
		camera.reset_smoothing()
		await process_frame
		await RenderingServer.frame_post_draw
		var visible_count := actors.filter(func(actor: Node): return absf(actor.position.x-float(entry.center))<=400.0).size()
		var output_path := "res://validation/route_pacing_%s.png" % entry.name
		root.get_texture().get_image().save_png(output_path)
		captures.append({"zone":entry.name,"encounter":String(entry.id),"camera_x":entry.center,"active":actors.size(),"visible_800x450":visible_count,"image":output_path})
	var audit := {
		"captures": captures,
		"achilata_runtime_count": route.get_node("Objects").get_children().filter(func(item: Node): return item.get("kind")=="achilata").size(),
		"asphalt_decorative_platforms": get_nodes_in_group("generic_platforms").size()
	}
	var audit_file := FileAccess.open("res://validation/route_pacing_capture.json",FileAccess.WRITE)
	audit_file.store_string(JSON.stringify(audit,"  ")+"\n")
	audit_file.close()
	scene.queue_free()
	await process_frame
	quit()
