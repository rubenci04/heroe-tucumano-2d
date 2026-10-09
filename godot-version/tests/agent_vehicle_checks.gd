extends SceneTree
## Ciclo de vida del vehículo de agentes: llega con aviso, frena, baja 2 agentes y se va; se destruye antes o después
## de bajarlos (monedas, explosión, restos ≤ 2 s); respeta el cupo de enemigos; sin objetos huérfanos.

var failures: Array[String] = []
var checks := 0
var scene: Node
var route: Node2D
var player: CharacterBody2D
var director: Node

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool,message: String,context: Dictionary = {}) -> void:
	checks += 1
	if condition:
		return
	var diagnostic := "%s | %s" % [message,JSON.stringify(context)]
	failures.append(diagnostic)
	push_error(diagnostic)

func wait_until(condition: Callable,max_frames: int) -> int:
	for frame in max_frames:
		if condition.call():
			return frame
		await physics_frame
	return -1

func vehicle_of(id: StringName) -> Node:
	for actor in director.get_active_enemies(id):
		if actor.get("archetype") == "agent_vehicle":
			return actor
	return null

func agents_of(id: StringName) -> Array:
	return director.get_active_enemies(id).filter(func(actor: Node): return actor.get("archetype") == "agente")

func coin_count() -> int:
	var count := 0
	for pickup in route.get_node("Objects").get_children():
		if str(pickup.get("pickup_id")).begins_with("agentveh_"):
			count += 1
	return count

func clear_coins() -> void:
	for pickup in route.get_node("Objects").get_children():
		if str(pickup.get("pickup_id")).begins_with("agentveh_"):
			pickup.queue_free()

func start(id: StringName,x: float) -> void:
	player.position = Vector2(x,GameConfig.GROUND_Y)
	await physics_frame
	director._rest_remaining = 0.0
	if not director.is_encounter_activated(id): # al teletransportar al jugador la ruta puede activarlo sola
		director.activate_encounter(id,x,false)
	expect(director.is_encounter_activated(id),"El encuentro %s se activa" % id,{})

func destroy(vehicle: Node) -> void:
	while is_instance_valid(vehicle) and vehicle.health > 0:
		vehicle.health_component.invulnerability_remaining = 0.0
		vehicle.take_damage(1,&"player")

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
	var others: Array[StringName] = [] # el resto de la ruta ya está resuelto: solo actúan los vehículos
	for other in registered:
		if not String(other).begins_with("route_vehicle"):
			others.append(other)
	director.restore_completed_encounters(others)
	for id: StringName in [&"route_vehicle_acheral",&"route_vehicle_monteros",&"route_vehicle_quinteros"]:
		expect(registered.has(id),"%s está en la tabla de encuentros" % id,{})
	expect(not registered.any(func(id): return String(id).begins_with("route_vehicle") and float(director._encounters[id].activation.value) < 1400.0),"Ningún vehículo de agentes en Famaillá",{})

	# 1) Ciclo completo: aviso → llega → frena → baja 2 agentes → se va; el encuentro cierra al caer los agentes.
	var id := &"route_vehicle_acheral"
	await start(id,2300.0)
	var vehicle := vehicle_of(id)
	expect(vehicle != null and vehicle.phase == vehicle.Phase.WARNING,"Aparece con aviso antes de moverse",{})
	var x_spawn: float = vehicle.position.x
	await wait_until(func(): return vehicle.phase == vehicle.Phase.ARRIVING,200)
	expect(vehicle.phase == vehicle.Phase.ARRIVING and absf(vehicle.position.x-x_spawn) < 1.0,"El aviso dura ~1 s sin avanzar",{"phase":vehicle.phase})
	await wait_until(func(): return vehicle.phase == vehicle.Phase.UNLOADING,600)
	var camera: Camera2D = scene.get_node("Camera2D")
	var center := camera.get_screen_center_position().x
	var half := 400.0/camera.zoom.x
	expect(vehicle.phase == vehicle.Phase.UNLOADING and vehicle.position.x < center+half and vehicle.position.x > center,"Frena dentro del encuadre",{"x":vehicle.position.x,"cam":center,"half":half})
	await wait_until(func(): return agents_of(id).size() >= 2,300)
	expect(agents_of(id).size() == 2 and vehicle.agents_released == 2,"Baja exactamente 2 agentes",{"n":agents_of(id).size()})
	expect(director.get_active_enemy_count(id) == 3,"El vehículo y sus agentes cuentan para el cupo",{"n":director.get_active_enemy_count(id)})
	for agent in agents_of(id):
		expect(absf(agent.position.x-vehicle.position.x) < 120.0,"Los agentes bajan junto al vehículo",{})
		agent.set_physics_process(false)
	var ref: WeakRef = weakref(vehicle)
	await wait_until(func(): return ref.get_ref() == null or ref.get_ref().phase == 3,400)
	expect(is_instance_valid(vehicle) and vehicle.phase == vehicle.Phase.LEAVING,"Termina de bajar y se va",{})
	await wait_until(func(): return ref.get_ref() == null,600)
	expect(not is_instance_valid(vehicle),"El vehículo sale y se libera",{})
	expect(not director.is_encounter_completed(id),"El encuentro sigue abierto mientras viven los agentes",{})
	for agent in agents_of(id):
		agent.take_damage(999,&"player")
	await wait_until(func(): return director.is_encounter_completed(id),200)
	expect(director.is_encounter_completed(id),"Al caer los agentes el encuentro termina",{})
	expect(coin_count() == 0,"Sin destruirlo no suelta monedas",{})

	# 2) Destruido ANTES de que bajen: los agentes de adentro mueren con él; monedas, humo, explosión, restos ≤ 2 s.
	id = &"route_vehicle_monteros"
	await start(id,3200.0)
	vehicle = vehicle_of(id)
	await wait_until(func(): return vehicle.phase == vehicle.Phase.ARRIVING,200)
	var defeated_points := [0]
	vehicle.defeated.connect(func(points: int): defeated_points[0] = points)
	var health_max: int = vehicle.max_health
	vehicle.take_damage(1,&"player")
	expect(vehicle.health == health_max-1 and vehicle.visual.modulate != Color.WHITE,"Un golpe baja la vida y hace destello",{"hp":vehicle.health})
	while vehicle.health > health_max*0.5:
		vehicle.health_component.invulnerability_remaining = 0.0
		vehicle.take_damage(1,&"player")
	expect(vehicle.smoke_puffs == 0,"Con más del 50 % de vida no hay humo",{})
	await wait_until(func(): return vehicle.smoke_puffs > 0,60)
	expect(vehicle.smoke_puffs > 0,"Al 50 % de vida suelta humo",{})
	var particles_before_blast: int = route.feel.fx._particles.size()
	destroy(vehicle)
	expect(vehicle.phase == vehicle.Phase.DESTROYED and agents_of(id).is_empty(),"Destruido antes de que bajen: ningún agente aparece",{})
	expect(route.feel.fx._particles.size() > particles_before_blast,"Explota con el FX existente",{})
	expect(defeated_points[0] == 150+2*100,"Los agentes de adentro mueren con el vehículo (puntos)",{"points":defeated_points[0]})
	var coins := coin_count()
	expect(coins >= 1 and coins <= 3,"Suelta 1–3 empanadas",{"coins":coins})
	var wreck_frames := 0
	while is_instance_valid(vehicle) and wreck_frames < 300:
		await physics_frame
		wreck_frames += 1
	expect(not is_instance_valid(vehicle) and wreck_frames/60.0 <= 2.0,"Los restos se desvanecen en ≤ 2 s",{"s":wreck_frames/60.0})
	await wait_until(func(): return director.is_encounter_completed(id),120)
	expect(director.is_encounter_completed(id),"Sin agentes ni vehículo el encuentro termina",{})
	clear_coins()

	# 3) Destruido DESPUÉS de bajar los agentes: los agentes siguen; el encuentro cierra cuando caen.
	id = &"route_vehicle_quinteros"
	await start(id,6000.0)
	vehicle = vehicle_of(id)
	await wait_until(func(): return vehicle.agents_released >= 2,900)
	expect(vehicle.agents_released == 2 and agents_of(id).size() == 2,"El tercer vehículo baja sus agentes",{})
	for agent in agents_of(id):
		agent.set_physics_process(false)
	destroy(vehicle)
	expect(agents_of(id).size() == 2,"Destruirlo después no mata a los agentes que ya bajaron",{})
	ref = weakref(vehicle)
	await wait_until(func(): return ref.get_ref() == null,200)
	expect(not director.is_encounter_completed(id),"El encuentro sigue abierto con agentes vivos",{})
	for agent in agents_of(id):
		agent.take_damage(999,&"player")
	await wait_until(func(): return director.is_encounter_completed(id),200)
	expect(director.is_encounter_completed(id),"Cierra al caer los agentes",{})
	clear_coins()

	# 4) Daño por proyectil del jugador (naranja).
	director.reset_runtime_state(true)
	director.restore_completed_encounters(others)
	await start(&"route_vehicle_acheral",2300.0)
	vehicle = vehicle_of(&"route_vehicle_acheral")
	await wait_until(func(): return vehicle.phase == vehicle.Phase.UNLOADING,800)
	var hp: int = vehicle.health
	var projectile = load("res://scenes/actors/projectile.tscn").instantiate()
	projectile.position = Vector2(vehicle.position.x+160.0,vehicle.get_roof_position().y+10.0)
	projectile.direction = -1
	projectile.travel_direction = Vector2.LEFT
	projectile.kind = &"orange"
	projectile.team = &"player"
	route.get_node("Projectiles").add_child(projectile)
	await wait_until(func(): return vehicle.health < hp,90)
	expect(vehicle.health < hp,"Una naranja del jugador daña al vehículo",{"hp":vehicle.health})

	# 5) Cupo máximo: sin cupo libre los agentes no bajan hasta que se libera.
	for agent in agents_of(&"route_vehicle_acheral"):
		agent.queue_free()
	await physics_frame
	var fixture := &"fixture_cupo"
	director._encounters[fixture] = {"id":"fixture_cupo","activation":{},"completion":"all_enemies_defeated","enemies":[],"rest":0.0}
	director._active_enemies[fixture] = {}
	var dummies: Array[Node] = []
	while director._population() < director.population_limit(player.position.x):
		var dummy = route.spawn_enemy("hipster",vehicle.position.x+300.0,0)
		dummy.set_physics_process(false)
		director._track_enemy(fixture,dummy)
		dummies.append(dummy)
	var released_before: int = vehicle.agents_released
	for i in 150:
		await physics_frame
	expect(director.free_slots(player.position.x) == 0 and vehicle.agents_released == released_before,"Sin cupo libre no bajan más agentes",{"released":vehicle.agents_released,"before":released_before})
	expect(director._population() <= director.population_limit(player.position.x),"Nunca se supera el máximo simultáneo",{"pop":director._population()})
	for dummy in dummies:
		dummy.take_damage(999,&"player")
	await wait_until(func(): return vehicle.agents_released > released_before,300)
	expect(vehicle.agents_released > released_before,"Al liberarse cupo bajan los agentes pendientes",{})

	# 6) Sin huérfanos tras limpiar.
	for child in route.get_node("Enemies").get_children():
		child.queue_free()
	director.reset_runtime_state(true)
	director.restore_completed_encounters(registered)
	await process_frame
	await process_frame
	expect(route.get_node("Enemies").get_child_count() == 0,"No quedan actores sueltos",{"n":route.get_node("Enemies").get_child_count()})
	scene.queue_free()
	await process_frame
	await process_frame
	expect(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) == 0,"Sin nodos huérfanos al terminar",{"orphans":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)})
	print("AGENT_VEHICLE_CHECKS %d/%d" % [checks-failures.size(),checks])
	quit(0 if failures.is_empty() else 1)
