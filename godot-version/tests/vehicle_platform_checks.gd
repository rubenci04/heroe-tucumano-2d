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
	var vehicles: Array[Node] = get_nodes_in_group("stationary_vehicles")
	var assets: Array[String] = []
	var positions: Array[int] = []
	for vehicle in vehicles:
		assets.append(vehicle.asset)
		positions.append(int(vehicle.position.x))
	check(vehicles.size()==9,"Ruta 38 contains nine deliberately spaced stationary vehicles")
	check(["auto1","auto2","auto3","camioneta1","camioneta2","camioneta3","camioneta4","camion_limones"].all(func(id): return assets.has(id)),"All approved car, pickup and lemon-truck assets are represented")
	check(vehicles.all(func(vehicle): return vehicle.collision_layer==GameConfig.PLAYER_PLATFORM_LAYER and vehicle.get_node("CollisionShape2D").one_way_collision and not vehicle.has_node("ImpactHitbox")),"Stationary vehicles are safe one-way Player platforms")
	check(vehicles.all(func(vehicle): return is_equal_approx(vehicle.get_ground_anchor_world_y(),GameConfig.GROUND_Y)),"Every stationary vehicle grounds its opaque wheel/base anchor on the gameplay surface")
	positions.sort()
	var gaps_ok := true
	for index in range(1,positions.size()):
		gaps_ok = gaps_ok and positions[index]-positions[index-1]>=700 and positions[index]-positions[index-1]<=800
	check(gaps_ok,"Vehicle spacing varies conservatively between 700 and 800 px")
	var bus_stop = route.get_node("Terrain/RoadsideBusStop")
	var roadside: float = preload("res://scripts/prototype/feel_config.gd").backdrop_ground_y(bus_stop.position.x)
	check(bus_stop.position.y==roadside and bus_stop.collision_layer==GameConfig.PLAYER_PLATFORM_LAYER and bus_stop.roof_collision.one_way_collision,"Bus stop stays roadside with a usable projectile-transparent roof")
	check(is_equal_approx(bus_stop.get_ground_anchor_world_y(),roadside),"Bus stop opaque base uses its configured roadside ground anchor")
	var objects = route.get_node("Objects").get_children()
	var roof_ids := [&"empanada_750_0",&"empanada_1350_0",&"empanada_2000_0",&"empanada_4100_0",&"empanada_4900_0",&"empanada_5600_0",&"empanada_7000_0",&"sanguche_bus_stop",&"sanguche_6200_0"]
	check(roof_ids.all(func(id): return objects.any(func(item): return item.pickup_id==id)),"Existing compatible rewards were moved onto vehicles and bus stop")
	check(not objects.any(func(item): return item.kind=="achilata"),"Ruta 38 still has zero active achilatas")
	var truck = vehicles.filter(func(vehicle): return vehicle.asset=="camion_limones")[0]
	var player = route.player
	player.position = Vector2(truck.position.x,100.0)
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	for frame in range(100):
		await physics_frame
	var truck_roof: float = route._platform_roof_y(truck)
	check(player.is_on_floor() and absf(player.position.y-truck_roof)<3.0,"Player lands on camion_limones roof")
	player.set_physics_process(false)
	var truck_reward = objects.filter(func(item): return item.pickup_id==&"empanada_4900_0")[0]
	check(truck_reward.position.y<truck_roof and absf(truck_reward.position.x-truck.position.x)<1.0,"Truck reward is visible above its roof before the jump")
	var result := {"passed":failures.is_empty(),"checks":checks,"errors":failures,"assets":assets,"positions":positions}
	var output := FileAccess.open("res://validation/vehicle_platform_checks.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(result,"  ")+"\n")
	output.close()
	print(JSON.stringify(result))
	root.get_node("AudioManager").stop_all()
	await create_timer(0.3).timeout
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
