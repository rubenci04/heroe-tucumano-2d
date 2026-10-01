extends SceneTree
## Render-only review fixture: run with a graphics driver, not --headless.
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
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	scene.get_node("Route38/EncounterDirector").reset_runtime_state(true)
	await process_frame
	scene.get_node("Interface").visible = false
	var camera: Camera2D = scene.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	var route = scene.get_node("Route38")
	route.set_physics_process(false)
	var player = route.get_node("Player")
	player.set_physics_process(false)
	player.play_animation(&"Idle")
	for center: float in [400.0,2200.0,4000.0,5800.0,7600.0]:
		camera.position = Vector2(center,225)
		player.position = Vector2(center-80,370)
		camera.reset_smoothing()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://validation/rebalance_%d.png" % int(center))
	camera.position = Vector2(4400,225)
	player.position = Vector2(4100,370)
	for pair in [["agente",4260.0],["hipster",4420.0],["grandote",4590.0]]:
		route.spawn_enemy(pair[0],pair[1],0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://validation/rebalance_actors.png")
	root.get_texture().get_image().save_png("res://validation/phase_scale_actors.png")
	for enemy in route.get_node("Enemies").get_children():
		enemy.queue_free()
	await process_frame
	var coffee_hipster = route.spawn_enemy("hipster",4660,0)
	coffee_hipster.facing = -1
	coffee_hipster._begin_attack()
	coffee_hipster._advance_attack_state(coffee_hipster.definition.telegraph_duration)
	var first_cup = route.get_node("Projectiles").get_child(-1)
	first_cup._physics_process(0.24)
	coffee_hipster._advance_attack_state(0.24)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://validation/rebalance_coffee.png")
	coffee_hipster.queue_free()
	for cup in route.get_node("Projectiles").get_children():
		cup.queue_free()
	await process_frame
	var traffic = route.get_node("TrafficDirector")
	traffic.enabled = true
	traffic.spawn_set_piece(&"scale_exprebus",&"exprebus",4250,-1)
	traffic.spawn_set_piece(&"scale_tesa",&"tesa",4630,1)
	player.position = Vector2(4440,370)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://validation/rebalance_buses.png")
	var audit: Array[Dictionary] = []
	for entry in [["ciruja_idle",0.42],["hipster_scooter_idle",0.34],["agente_idle",0.36],["grandote_idle",0.44],["final_boss_idle",0.42],["drone_1",0.55],["auto1",0.90],["auto2",0.90],["auto3",0.95],["camion_limones",0.80],["exprebus",1.20],["tesa",1.10],["kiosco_coca",0.72],["parada_colectivo",0.62],["arbol_naranjas",0.85],["montaña_cascote",0.32],["empanada",0.14],["sanguche",0.25],["achilata",0.18]]:
		var bounds := CollisionFactory.opaque_bounds(load("res://assets/%s.png" % entry[0]))
		audit.append({"asset":entry[0],"scale":entry[1],"width":bounds.size.x*entry[1],"height":bounds.size.y*entry[1],"ciruja_ratio":bounds.size.y*entry[1]/82.74})
	var audit_file := FileAccess.open("res://validation/rebalance_scale_audit.json",FileAccess.WRITE)
	audit_file.store_string(JSON.stringify(audit,"  ")+"\n")
	audit_file.close()
	scene.queue_free()
	await process_frame
	quit()
