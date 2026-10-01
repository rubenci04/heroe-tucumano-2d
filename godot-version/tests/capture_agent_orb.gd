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
	var camera: Camera2D = scene.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	camera.position = Vector2(4000,225)
	route.player.position = Vector2(3850,GameConfig.GROUND_Y)
	route.player.set_physics_process(false)
	var agent = route.spawn_enemy("agente",4120.0,0)
	agent.set_physics_process(false)
	agent.contact.monitoring = false
	agent.facing = -1
	scene.set_process(false)
	camera.reset_smoothing()
	await process_frame
	agent._advance_ranged_lifecycle(agent.definition.entry_duration,-270.0)
	agent._advance_ranged_lifecycle(agent._state_remaining,-270.0)
	agent._begin_attack()
	agent.visual.frame = 2
	agent._refresh_visual_frame_offset()
	agent._advance_attack_state(agent.definition.telegraph_duration)
	var orb = route.get_node("Projectiles").get_child(-1)
	orb.set_physics_process(false)
	camera.reset_smoothing()
	scene.get_node("Interface").visible = false
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://validation/agent_orb.png")
	scene.queue_free()
	await process_frame
	quit()
