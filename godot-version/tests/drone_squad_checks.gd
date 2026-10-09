extends SceneTree
## Escuadrones de drones (Monteros, Villa Quinteros, Río Seco): entran escalonados a distintas alturas, mueren con 1–2
## golpes, solo disparan dentro del encuadre (margen 40 px) y el encuentro termina sin dejar objetos huérfanos.

var failures: Array[String] = []
var checks := 0
var scene: Node
var route: Node2D
var player: CharacterBody2D
var director: Node
var shots_outside: Array = []
var shots_total := 0

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool,message: String,context: Dictionary = {}) -> void:
	checks += 1
	if condition:
		return
	var diagnostic := "%s | %s" % [message,JSON.stringify(context)]
	failures.append(diagnostic)
	push_error(diagnostic)

func camera_edges() -> Vector2:
	var camera: Camera2D = scene.get_node("Camera2D")
	var half := 400.0/camera.zoom.x
	var center := camera.get_screen_center_position().x
	return Vector2(center-half-40.0,center+half+40.0)

func drones_of(id: StringName) -> Array:
	return director.get_active_enemies(id).filter(func(actor: Node): return actor.get("archetype") == "drone")

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
	player.health_component.set_invulnerability(1000000.0)
	var registered: Array[StringName] = director.get_registered_encounter_ids()
	var squads: Dictionary = {&"route_squad_monteros":Vector2(2800.0,4200.0),&"route_squad_quinteros":Vector2(5400.0,6600.0),&"route_squad_rio_seco":Vector2(6600.0,8000.0)}
	for id: StringName in squads:
		var x := float(director._encounters[id].activation.value) if registered.has(id) else -1.0
		expect(x >= squads[id].x and x < squads[id].y,"%s está en su tramo (%d)" % [id,x],{})
	var others: Array[StringName] = []
	for other in registered:
		if not squads.has(other):
			others.append(other)
	director.restore_completed_encounters(others)
	route.get_node("Projectiles").child_entered_tree.connect(func(projectile: Node):
		if projectile.get("team") == &"enemy":
			shots_total += 1
			var edges := camera_edges()
			if projectile.global_position.x < edges.x or projectile.global_position.x > edges.y:
				shots_outside.append({"x":projectile.global_position.x,"edges":edges}))
	for id: StringName in squads:
		var activation_x := float(director._encounters[id].activation.value)
		player.position = Vector2(activation_x,GameConfig.GROUND_Y)
		await physics_frame
		director._rest_remaining = 0.0
		if not director.is_encounter_activated(id):
			director.activate_encounter(id,activation_x,true)
		# Entrada escalonada: no aparecen todos juntos y vuelan a distintas alturas.
		var spawn_frames: Array[int] = []
		var expected: int = director._encounters[id].enemies.size()
		var frame := 0
		while spawn_frames.size() < expected and frame < 600:
			await physics_frame
			frame += 1
			while spawn_frames.size() < drones_of(id).size():
				spawn_frames.append(frame)
		expect(spawn_frames.size() == expected,"%s: entran los %d drones" % [id,expected],{"seen":spawn_frames.size()})
		expect(spawn_frames.size() < 2 or spawn_frames[-1]-spawn_frames[0] >= 30,"%s: entran escalonados" % id,{"frames":spawn_frames})
		var heights: Array[float] = []
		for drone in drones_of(id):
			heights.append(snappedf(drone.flight_anchor_y,1.0))
			expect(drone.max_health <= 2,"%s: muere con 1–2 golpes (vida %d)" % [id,drone.max_health],{})
		heights.sort()
		var distinct := 0
		for i in heights.size():
			if i == 0 or heights[i] != heights[i-1]:
				distinct += 1
		expect(distinct == heights.size(),"%s: cada dron vuela a otra altura" % id,{"heights":heights})
		# Fuera de cuadro no dispara: ni toma turno de ataque ni emite proyectil.
		var probe: Node = drones_of(id)[0]
		var saved_x: float = probe.position.x
		probe.position.x = scene.get_node("Camera2D").get_screen_center_position().x+900.0
		director.update_safety(player.position.x,scene.get_node("Camera2D").get_screen_center_position().x,800.0/scene.get_node("Camera2D").zoom.x)
		var projectiles_before: int = route.get_node("Projectiles").get_child_count()
		var began: bool = probe._begin_aim()
		probe._shot_emitted_this_attack = false
		probe.ai_state = probe.AIState.FIRE
		probe._emit_locked_shot()
		expect(not began and route.get_node("Projectiles").get_child_count() == projectiles_before,"%s: un dron fuera de cuadro no dispara" % id,{})
		probe.position.x = saved_x
		# Dejar volar el escuadrón 8 s: todo disparo nace dentro del encuadre.
		for i in 480:
			await physics_frame
		# Matar a cada dron con 1–2 golpes.
		for drone in drones_of(id):
			var hits := 0
			while is_instance_valid(drone) and drone.active and hits < 2:
				drone.health_component.invulnerability_remaining = 0.0
				drone.health_component.take_damage(1,player)
				hits += 1
			expect(not drone.active and hits <= 2,"%s: cae con %d golpe(s)" % [id,hits],{})
		for i in 200:
			if director.is_encounter_completed(id):
				break
			await physics_frame
		expect(director.is_encounter_completed(id),"%s: el encuentro termina" % id,{})
		for child in route.get_node("Projectiles").get_children():
			child.queue_free()
	expect(shots_outside.is_empty(),"Ningún disparo enemigo nació fuera del encuadre (%d disparos)" % shots_total,{"fuera":shots_outside})
	for child in route.get_node("Enemies").get_children():
		child.queue_free()
	director.reset_runtime_state(true)
	director.restore_completed_encounters(registered)
	await process_frame
	await process_frame
	expect(route.get_node("Enemies").get_child_count() == 0,"No quedan drones sueltos",{})
	scene.queue_free()
	await process_frame
	await process_frame
	expect(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) == 0,"Sin nodos huérfanos",{"orphans":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)})
	print("DRONE_SQUAD_CHECKS %d/%d (disparos observados: %d)" % [checks-failures.size(),checks,shots_total])
	quit(0 if failures.is_empty() else 1)
