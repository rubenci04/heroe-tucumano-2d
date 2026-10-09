extends SceneTree
## Capturas finales con el encuadre nuevo: Famaillá, Acheral (vehículo de agentes), Monteros (escuadrón de drones),
## Villa Quinteros y el jefe. Con ventana, --fixed-fps 60.
const OUT := "res://tests/screenshots/final_views/"
var scene: Node
var route: Node2D
var player: CharacterBody2D
var director: Node

func _initialize() -> void:
	call_deferred("run")

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func place(x: float) -> void:
	player.position = Vector2(x, GameConfig.GROUND_Y)
	scene._update_route_camera(0.0, true)
	scene.camera.reset_smoothing()
	await frames(4)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size = Vector2i(800, 450)
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
	player.oranges_unlocked = true
	player.stones = 20
	var all_ids: Array[StringName] = director.get_registered_encounter_ids()
	var keep := [&"route_vehicle_acheral", &"route_squad_monteros", &"route_wave_04"]
	var done: Array[StringName] = []
	for id in all_ids:
		if not keep.has(id):
			done.append(id)
	director.restore_completed_encounters(done)
	# Famaillá
	await place(350.0)
	director._rest_remaining = 1000000.0
	await frames(20)
	await shot("1_famailla")
	director._rest_remaining = 0.0
	# Acheral: vehículo de agentes con los agentes ya abajo
	await place(2300.0)
	await frames(10)
	var vehicle: Node = null
	for actor in director.get_active_enemies(&"route_vehicle_acheral"):
		vehicle = actor
	var guard := 0
	while vehicle != null and vehicle.agents_released < 2 and guard < 900:
		await physics_frame
		guard += 1
	await frames(20)
	await shot("2_acheral_vehiculo_agentes")
	player.health_component.set_invulnerability(100000.0)
	# Monteros: escuadrón de drones
	for enemy in route.get_node("Enemies").get_children():
		enemy.queue_free()
	var done_plus: Array[StringName] = done.duplicate()
	done_plus.append(&"route_vehicle_acheral")
	director.restore_completed_encounters(done_plus)
	await place(3350.0)
	director._rest_remaining = 0.0
	await frames(240)
	await shot("3_monteros_escuadron_drones")
	# Villa Quinteros
	for enemy in route.get_node("Enemies").get_children():
		enemy.queue_free()
	director.restore_completed_encounters(all_ids)
	await place(5650.0)
	route.spawn_enemy("hipster", scene.camera.position.x + 260.0, 0)
	route.spawn_enemy("agente", scene.camera.position.x + 330.0, 0)
	await frames(30)
	await shot("4_villa_quinteros")
	# Jefe
	director.restore_completed_encounters(all_ids)
	for enemy in route.get_node("Enemies").get_children():
		enemy.queue_free()
	player.position = Vector2(7430.0, GameConfig.GROUND_Y)
	director._rest_remaining = 0.0
	var wait := 0
	while not is_instance_valid(route.boss) and wait < 900:
		await physics_frame
		wait += 1
	if is_instance_valid(route.boss):
		route.boss_director.skip_intro()
		await frames(90)
	await shot("5_jefe")
	quit()
