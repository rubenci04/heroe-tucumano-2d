extends SceneTree

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool,message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func run() -> void:
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
	var agent = route.spawn_enemy("agente",1200.0,0)
	agent.set_physics_process(false)
	agent.contact.monitoring = false
	route.player.position.x = 900.0
	agent.facing = -1
	var shots: Array[String] = []
	agent.shot_requested.connect(func(_origin,_lane,_direction,kind,_team): shots.append(kind))
	scene.set_process(false)
	scene.camera.position_smoothing_enabled = false
	scene.camera.position = Vector2(1000,225)
	scene.camera.reset_smoothing()
	await process_frame
	# Legacy fixture now completes ENTER/REACT before testing projectile presentation.
	agent._advance_ranged_lifecycle(agent.definition.entry_duration,-300.0)
	agent._advance_ranged_lifecycle(agent._state_remaining,-300.0)
	agent._begin_attack()
	agent.visual.frame = 2
	agent._refresh_visual_frame_offset()
	agent._advance_attack_state(agent.definition.telegraph_duration)
	var orb = route.get_node("Projectiles").get_child(-1)
	check(shots==["agent_orb"] and orb.kind==&"agent_orb","Agent emits one independent orb, not legacy bullet")
	check(orb.definition!=load("res://data/projectiles/drone_bolt.tres") and orb.definition.resource_path=="res://data/projectiles/agent_orb.tres","Agent orb is independent from Drone resource")
	check(orb.speed==170.0 and orb.damage==1 and orb.visual.scale==Vector2(0.85,0.85) and orb.collision_shape.shape.size==Vector2(10,10),"Agent orb has approved independent size, slower speed, damage and collider")
	# Punto de lanzamiento medido sobre el cuadro nuevo (BATCH_MUZZLE_SOURCE del agente, mirando a la izquierda).
	check(orb.position.is_equal_approx(agent.visual.to_global(Vector2(110.0-160.0,101.0-240.0))),"Left-facing muzzle is aligned to the batch barrel socket")
	var start: Vector2 = orb.position
	var rotation: float = orb.visual.rotation
	orb._physics_process(0.1)
	check(orb.position.is_equal_approx(start+Vector2(-17.0,0.0)),"Agent orb follows a straight 170 px/s trajectory")
	check(is_equal_approx(orb.visual.rotation,rotation) and orb.definition.rotation_speed_degrees==0.0,"Agent orb has no continuous rotation")
	agent._advance_attack_state(0.5)
	check(shots.size()==1 and agent._burst_shots_remaining==0 and is_equal_approx(agent.definition.attack_cooldown,3.2) and is_equal_approx(agent.definition.telegraph_duration,0.45),"Agent fires once with readable telegraph and 3.2-second cooldown")
	orb.queue_free()
	agent.queue_free()
	await process_frame
	var result := {"passed":failures.is_empty(),"checks":checks,"errors":failures}
	var output := FileAccess.open("res://validation/agent_orb_checks.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(result,"  ")+"\n")
	output.close()
	print(JSON.stringify(result))
	root.get_node("AudioManager").stop_all()
	await create_timer(0.3).timeout
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
