extends SceneTree
## Capturas del vehículo de agentes en F5 (con ventana, --fixed-fps 60): aviso, agentes bajando, humo y explosión.
const OUT := "res://tests/screenshots/agent_vehicle/"

func _initialize() -> void:
	call_deferred("run")

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size = Vector2i(800, 450)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.get_node("Interface/CharacterSelect").confirm_selected()
	scene.get_node("IntroFamailla").skip()
	await process_frame
	var route = scene.get_node("Route38")
	var director = route.encounter_director
	var player = route.player
	var others: Array[StringName] = []
	for id in director.get_registered_encounter_ids():
		if not String(id).begins_with("route_vehicle"):
			others.append(id)
	director.restore_completed_encounters(others)
	player.position = Vector2(2300.0, GameConfig.GROUND_Y)
	player.oranges_unlocked = true
	player.health_component.set_invulnerability(0.0)
	for i in 5:
		await physics_frame
	director._rest_remaining = 0.0
	if not director.is_encounter_activated(&"route_vehicle_acheral"):
		director.activate_encounter(&"route_vehicle_acheral", 2300.0, false)
	var vehicle: Node = null
	for actor in director.get_active_enemies(&"route_vehicle_acheral"):
		vehicle = actor
	for i in 30:
		await process_frame
	await shot("1_aviso")
	while vehicle.phase != vehicle.Phase.UNLOADING:
		await process_frame
	for i in 70:
		await process_frame
	await shot("2_agentes_bajan")
	while vehicle.health > 2:
		vehicle.health_component.invulnerability_remaining = 0.0
		vehicle.take_damage(1, &"player")
	for i in 40:
		await process_frame
	await shot("3_humo")
	vehicle.health_component.invulnerability_remaining = 0.0
	vehicle.take_damage(99, &"player")
	for i in 6:
		await process_frame
	await shot("4_explosion")
	for i in 40:
		await process_frame
	await shot("5_restos_y_empanadas")
	quit()
