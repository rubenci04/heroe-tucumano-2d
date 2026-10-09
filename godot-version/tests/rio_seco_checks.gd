extends SceneTree
## Río Seco completo: todos los encuentros terminan, ningún enemigo queda fuera de cuadro y
## ningún enemigo dispara desde fuera del encuadre (margen 40 px). También cubre los rescates del director.

var failures: Array[String] = []
var checks := 0
var scene: Node
var route: Node2D
var player: CharacterBody2D
var director: Node
var offscreen_shots: Array = []

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool,message: String,context: Dictionary = {}) -> void:
	checks += 1
	if condition:
		return
	var diagnostic := "%s | %s" % [message,JSON.stringify(context)]
	failures.append(diagnostic)
	push_error(diagnostic)

func camera_center() -> float:
	return scene.get_node("Camera2D").get_screen_center_position().x

func run() -> void:
	root.size = Vector2i(800,450)
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.get_node("Interface/CharacterSelect").confirm_selected()
	scene.get_node("IntroFamailla").skip()
	await process_frame
	route = scene.get_node("Route38")
	player = route.player
	director = route.encounter_director
	player.health_component.set_invulnerability(100000.0)
	route.get_node("Projectiles").child_entered_tree.connect(func(projectile: Node):
		if projectile.get("team") == &"enemy" and absf(projectile.global_position.x-camera_center()) > 400.0+40.0+90.0:
			offscreen_shots.append({"x":projectile.global_position.x,"cam":camera_center(),"kind":projectile.get("kind")}))
	# Todo lo anterior a Río Seco ya está resuelto: se empieza en el tramo final.
	var done: Array[StringName] = []
	for id in director.get_registered_encounter_ids():
		if float(director._encounters[id].activation.value) < 6700.0:
			done.append(id)
	director.restore_completed_encounters(done)
	player.position = Vector2(6700.0,GameConfig.GROUND_Y)
	var seen: Dictionary = {}
	var completed: Array[StringName] = []
	director.encounter_completed.connect(func(id: StringName): completed.append(id))
	var pending_ids: Array[StringName] = []
	for id in director.get_registered_encounter_ids():
		if not done.has(id):
			pending_ids.append(id)
	var worst_offscreen := 0.0
	var reached := false
	for frame in range(9000):
		if player.position.x < 7400.0:
			player.position.x = minf(7400.0,player.position.x+160.0/60.0)
		player.position.y = GameConfig.GROUND_Y
		await physics_frame
		for id in director._active_enemies.keys():
			for actor in director.get_active_enemies(id):
				if actor.get("_waiting_respawn_read") == true:
					actor._waiting_respawn_read = false
				var instance_id: int = actor.get_instance_id()
				if actor.archetype != "drone" and absf(actor.global_position.x-camera_center()) > 440.0:
					worst_offscreen = maxf(worst_offscreen,float(actor.get_meta("offscreen_time",0.0)))
				if director.is_attack_visible(actor):
					if not seen.has(instance_id):
						seen[instance_id] = frame
					elif frame-int(seen[instance_id]) >= 45:
						actor.take_damage(999,&"player")
		if player.position.x >= 7400.0 and pending_ids.all(func(id: StringName): return completed.has(id)) \
				and director._pending.is_empty() and director._active_enemies.is_empty():
			reached = true
			break
	expect(reached,"Todos los encuentros de Río Seco terminan",{"completed":completed,"pending":pending_ids,"active":director._active_enemies.size(),"queued":director._pending.size()})
	expect(worst_offscreen <= director.OFFSCREEN_LIMIT+0.1,"Ningún enemigo pasa más de 4 s fuera de cuadro",{"worst":worst_offscreen})
	expect(offscreen_shots.is_empty(),"No hay proyectiles enemigos nacidos fuera de cámara",{"shots":offscreen_shots})

	# Rescate: enemigo spawneado lejos, jugador en el tope de cámara, nadie lo mata.
	player.position = Vector2(7400.0,GameConfig.GROUND_Y)
	for i in 30:
		await physics_frame
	var stray = route.spawn_enemy("agente",camera_center()+1200.0,0)
	director._encounters[&"fixture_stray"] = {"id":"fixture_stray","activation":{},"completion":"all_enemies_defeated","enemies":[],"rest":0.0}
	director._active_enemies[&"fixture_stray"] = {}
	director._track_enemy(&"fixture_stray",stray)
	stray.set_physics_process(false) # inmóvil: solo el rescate puede traerlo
	for i in range(int(60.0*(director.OFFSCREEN_LIMIT+1.0))):
		await physics_frame
	expect(absf(stray.global_position.x-camera_center()) <= 400.0,"Un enemigo inalcanzable vuelve al borde visible en ≤ 4 s",{"x":stray.global_position.x,"cam":camera_center()})
	# Disparo desde fuera de cuadro: descartado.
	stray.global_position.x = camera_center()+700.0
	var before: int = route.get_node("Projectiles").get_child_count()
	route._relay_shot(stray,stray.global_position,0,Vector2.LEFT,"agent_orb","enemy")
	expect(route.get_node("Projectiles").get_child_count() == before,"Un tirador fuera de cuadro no dispara",{})
	# Caída al vacío: se descarta y libera el cupo.
	stray.global_position.y = 2000.0
	await physics_frame
	await physics_frame
	expect(not is_instance_valid(stray) or stray.is_queued_for_deletion(),"Un enemigo caído al vacío se descarta",{})
	scene.queue_free()
	await process_frame
	print("RIO_SECO_CHECKS %d/%d" % [checks-failures.size(),checks])
	quit(0 if failures.is_empty() else 1)
