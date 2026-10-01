extends RefCounted
## Shared gameplay probe for smoke and each profile cycle.
static func run(tree: SceneTree,scene: Node,death_phase: String = "",profile_cycle: int = 0) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var route = scene.get_node("Route38")
	var player = route.player
	var event = route.get_node("ExpresbusSetPiece")
	var traffic = route.traffic_director
	route.set_physics_process(false)
	player.set_physics_process(false)
	player.position = Vector2(2850,370)
	player.velocity = Vector2.ZERO
	scene.camera.position = Vector2(2850,225)
	scene.camera.reset_smoothing()
	scene.camera.force_update_scroll()
	results.append({"ok":event.phase==event.Phase.READY,"message":"Expresbus begins each run ready"})
	var completed: Array[StringName] = route.encounter_director.get_completed_encounter_ids()
	var first_wave: Array[StringName] = [&"route_wave_01"]
	route.encounter_director.restore_completed_encounters(first_wave)
	event.advance(0.0,route)
	results.append({"ok":event.phase==event.Phase.READY,"message":"Trigger requires completion of the second wave"})
	route.encounter_director.restore_completed_encounters(completed)
	var after_third: Array[StringName] = [&"route_wave_01",&"route_wave_02",&"route_wave_03"]
	route.encounter_director.restore_completed_encounters(after_third)
	event.advance(0.0,route)
	results.append({"ok":event.phase==event.Phase.READY,"message":"Event cannot activate after the third wave"})
	route.encounter_director.restore_completed_encounters(completed)
	player.position.x = 2849.0
	event.advance(0.0,route)
	results.append({"ok":event.phase==event.Phase.READY and event.TRIGGER_X==2850.0,"message":"Trigger does not activate before X=2850"})
	var road = route.get_node("Environment/RoadLayers/BackLane")
	results.append({"ok":road.get_node("Road").texture.get_width()==330 and road.repeat_size.x==658.0,"message":"330px road mirrored pair repeats at 658px without gaps"})
	player.position.x = 2850.0
	event.advance(0.0,route)
	results.append({"ok":event.phase==event.Phase.WARNING and event.spawn_count==0 and traffic.get_active_vehicle_count()==0,"message":"Trigger reserves one event with a visible warning before spawn"})
	event.advance(0.99,route)
	results.append({"ok":event.phase==event.Phase.WARNING and event.spawn_count==0,"message":"Telegraph lasts one second without an early bus"})
	player.position.x = 3510.0
	route._physics_process(0.0)
	results.append({"ok":not route.encounter_director.is_encounter_activated(&"route_wave_03"),"message":"Warning also pauses the third wave"})
	player.position.x = 2850.0
	if death_phase in ["warning","final_life"]:
		if death_phase == "final_life":
			player.lives = 1
		await check_death(tree,scene,results)
		return results
	event.advance(0.02,route)
	var bus = event.vehicle
	results.append({"ok":is_instance_valid(bus) and event.spawn_count==1 and bus.asset_id==&"exprebus" and bus.image_scale==1.007 and bus.base_speed==240.0,"message":"Exactly one correctly scaled Expresbus spawns at designed speed"})
	if not is_instance_valid(bus):
		return results
	results.append({"ok":bus.position.x-180.0>scene.camera.get_screen_center_position().x+400.0,"message":"Bus starts entirely outside the right viewport edge"})
	bus.set_physics_process(false)
	if death_phase == "restart":
		scene.restart_game()
		await tree.frames(6)
		var fresh_route = tree.current_scene.get_node("Route38")
		var fresh_event = fresh_route.get_node("ExpresbusSetPiece")
		results.append({"ok":not is_instance_valid(bus) and fresh_event.phase==fresh_event.Phase.READY and fresh_event.spawn_count==0 and fresh_route.get_node("Vehicles").get_child_count()==0,"message":"Restart during entry destroys the old bus and creates one fresh event"})
		return results
	if profile_cycle > 0:
		tree.snapshot("expresbus_spawned",profile_cycle,scene)
	player.position.x = 3510.0
	route._physics_process(0.0)
	results.append({"ok":not route.encounter_director.is_encounter_activated(&"route_wave_03") and event.spawn_count==1,"message":"Crossing suppresses new waves and cannot duplicate its spawn"})
	player.position.x = 2850.0
	if death_phase in ["entry","crossing"]:
		if death_phase == "crossing":
			bus.set_physics_process(true)
			await tree.frames(60)
		await check_death(tree,scene,results)
		return results
	for kind in ["orange","stone","orange","stone"]:
		var shot = load("res://scenes/actors/projectile.tscn").instantiate()
		shot.kind = kind
		shot.team = &"player"
		route.get_node("Projectiles").add_child(shot)
		shot.set_physics_process(false)
		var before: float = bus.current_speed
		shot._resolve_collision(bus.projectile_target)
		results.append({"ok":shot.spent and is_equal_approx(bus.current_speed,maxf(132.0,before*0.8)),"message":"%s consumes one projectile and applies bounded slowdown" % kind})
	results.append({"ok":is_equal_approx(bus.current_speed,132.0),"message":"Three to four impacts reach the 55 percent speed floor"})
	var impact_shape = bus.impact_hitbox.collision_shape
	var danger_top: float = impact_shape.position.y-impact_shape.shape.size.y*0.5
	results.append({"ok":bus.roof_collision.one_way_collision and danger_top>bus.get_roof_world_y()-bus.position.y+40.0,"message":"One-way roof has over 40px clearance above the dangerous body"})
	# The existing car is the launch step for the 138px roof.
	bus.position = Vector2(3400,370)
	player.position = Vector2(3100,265)
	player.velocity = Vector2.ZERO
	player.health = player.max_health
	player.invulnerability = 0.0
	player.set_physics_process(true)
	await tree.frames(15)
	results.append({"ok":player.is_on_floor(),"message":"Player can stand on the existing stepping car beneath the one-way roof"})
	bus.set_physics_process(true)
	Input.action_press("move_right")
	Input.action_press("jump")
	await tree.frames(50)
	Input.action_release("move_right")
	Input.action_release("jump")
	await tree.frames(4)
	results.append({"ok":player.is_on_floor() and absf(player.position.y-bus.get_roof_world_y())<3.0,"message":"Player jumps through and lands on the actual Expresbus roof (player=%s bus=%s health=%d)" % [player.position,bus.position,player.health]})
	var health_before: int = player.health
	var player_start: float = player.position.x
	var bus_start: float = bus.position.x
	bus.set_physics_process(true)
	await tree.frames(24)
	var carried: float = player.position.x-player_start
	var bus_travel: float = bus.position.x-bus_start
	results.append({"ok":absf(carried-bus_travel)<8.0 and carried < -30.0 and player.is_on_floor(),"message":"Physics platform carries Player at the bus displacement (player=%.2f bus=%.2f)" % [carried,bus_travel]})
	results.append({"ok":player.health==health_before and health_before==player.max_health,"message":"Roof landing and riding do not inflict traffic damage"})
	if profile_cycle > 0:
		tree.snapshot("expresbus_riding",profile_cycle,scene)
		await tree.measure_window("expresbus_riding",profile_cycle,30,0)
	var relative_before: float = player.position.x-bus.position.x
	Input.action_press("move_right")
	await tree.frames(8)
	Input.action_release("move_right")
	results.append({"ok":player.position.x-bus.position.x>relative_before+15.0,"message":"Player can walk relative to the moving roof"})
	Input.action_press("jump")
	await tree.frames(8)
	Input.action_release("jump")
	results.append({"ok":not player.is_on_floor() and player.position.y<bus.get_roof_world_y()-20.0,"message":"Player can jump away from the moving bus without trapping"})
	player.set_physics_process(false)
	bus.set_physics_process(false)
	bus.recovery_delay_remaining = 0.0
	bus._update_slowdown(1.0)
	results.append({"ok":bus.current_speed>132.0 and bus.current_speed<240.0 and bus.active,"message":"Indestructible bus progressively recovers without stopping"})
	bus._update_slowdown(1.0)
	results.append({"ok":is_equal_approx(bus.current_speed,240.0),"message":"Bus recovers its base speed"})
	player.health_component.set_invulnerability(0.0)
	player.position = bus.position+Vector2(-120.0,0.0)
	var side_health: int = player.health
	await tree.frames(3)
	results.append({"ok":player.health<side_health,"message":"Actual lower front overlap still damages Player"})
	# Normal travel exits the sector; no timer or random respawn is involved.
	bus.set_physics_process(false)
	bus.sync_to_physics = false
	bus.position.x = event.EXIT_X-1.0
	scene.camera.position = Vector2(3000,225)
	scene.camera.reset_smoothing()
	scene.camera.force_update_scroll()
	event.advance(0.016,route)
	await tree.frames(2)
	results.append({"ok":event.phase==event.Phase.FINISHED and event.finish_reason=="sector_exit" and traffic.get_active_vehicle_count()==0 and route.get_node("Vehicles").get_child_count()==0,"message":"Sector exit removes bus and director references (%s phase=%d)" % [event.finish_reason,event.phase]})
	player.position = Vector2(2800,370)
	event.advance(1.0,route)
	player.position.x = 3000.0
	event.advance(1.0,route)
	results.append({"ok":event.spawn_count==1 and traffic.spawn_now(3000)==null,"message":"Backtracking never repeats Expresbus and random traffic remains off"})
	player.set_physics_process(true)
	return results

static func check_death(tree: SceneTree,scene: Node,results: Array[Dictionary]) -> void:
	var route = scene.get_node("Route38")
	var player = route.player
	var event = route.get_node("ExpresbusSetPiece")
	var count_before: int = event.spawn_count
	player.health = 1
	player.health_component.set_invulnerability(0.0)
	player.take_damage(1,"traffic")
	await tree.frames(3)
	results.append({"ok":event.phase==event.Phase.FINISHED and event.finish_reason=="player_death" and route.traffic_director.get_active_vehicle_count()==0 and route.get_node("Vehicles").get_child_count()==0,"message":"Death consumes warning/crossing and removes its vehicle without orphans"})
	var completed: Array[StringName] = [&"route_wave_01",&"route_wave_02"]
	var collected: Array[StringName] = []
	route.restore_checkpoint_state(completed,collected)
	route.set_physics_process(false)
	player.position.x = 3000.0
	event.advance(2.0,route)
	results.append({"ok":event.phase==event.Phase.FINISHED and event.spawn_count==count_before,"message":"Checkpoint restoration and backtracking cannot resurrect the consumed bus"})
	player.set_physics_process(true)
