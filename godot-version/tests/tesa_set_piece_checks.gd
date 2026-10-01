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
	var player = route.player
	var event = route.get_node("TesaSetPiece")
	var traffic = route.traffic_director
	route.set_physics_process(false)
	player.set_physics_process(false)
	var completed: Array[StringName] = [&"route_wave_01",&"route_wave_02",&"route_wave_03",&"route_micro_03",&"route_drone_01"]
	route.encounter_director.restore_completed_encounters(completed)
	player.position = Vector2(event.trigger_x,GameConfig.GROUND_Y)
	scene.camera.position = Vector2(event.trigger_x,225)
	scene.camera.reset_smoothing()
	scene.camera.force_update_scroll()
	event.advance(0.0,route)
	check(event.phase==event.Phase.WARNING and event.spawn_count==0,"Tesa trigger starts a one-second visual telegraph")
	event.advance(0.99,route)
	check(event.phase==event.Phase.WARNING and traffic.get_active_vehicle_count()==0,"Tesa does not spawn before telegraph completes")
	event.advance(0.02,route)
	var bus = event.vehicle
	check(is_instance_valid(bus) and event.spawn_count==1 and bus.asset_id==&"tesa","Exactly one Tesa spawns")
	if is_instance_valid(bus):
		bus.set_physics_process(false)
		check(bus.image_scale==0.922 and bus.base_speed==225.0 and bus.direction==-1,"Tesa keeps its configured scale, speed and readable sprite orientation")
		check(bus.position.x-180.0>scene.camera.get_screen_center_position().x+400.0,"Tesa begins entirely outside the right viewport")
		check(bus.roof_collision.one_way_collision and bus.collision_layer==GameConfig.PLAYER_PLATFORM_LAYER,"Tesa has a projectile-transparent one-way roof")
		var pickup = bus.get_node_or_null("pickup")
		check(pickup!=null and pickup.pickup_id==&"tesa_roof_sanguche" and pickup.kind=="sanguche" and pickup.position.y<bus.get_roof_world_y()-bus.global_position.y,"Attractive sandwich pickup is attached above the moving roof")
		for kind in [&"orange",&"stone",&"orange",&"stone"]:
			var shot = load("res://scenes/actors/projectile.tscn").instantiate()
			shot.kind = kind
			shot.team = &"player"
			route.get_node("Projectiles").add_child(shot)
			shot.set_physics_process(false)
			shot._resolve_collision(bus.projectile_target)
		check(is_equal_approx(bus.current_speed,123.75) and is_equal_approx(bus.get_speed_ratio(),0.55),"Orange and stone slowdown is bounded at 55 percent")
		if pickup != null:
			pickup._on_body_entered(player)
			check(pickup.used and route.collected_pickup_ids.has(&"tesa_roof_sanguche"),"Moving pickup is collectible once and records its stable id")
			pickup._on_body_entered(player)
			check(route.collected_pickup_ids.size()==1,"Moving pickup cannot be collected twice")
		bus.sync_to_physics = false
		bus.position.x = -1000.0
		scene.camera.position = Vector2(4400,225)
		scene.camera.reset_smoothing()
		scene.camera.force_update_scroll()
		event.advance(0.016,route)
		await process_frame
		check(event.phase==event.Phase.FINISHED and event.finish_reason in ["sector_exit","offscreen_exit"] and traffic.get_active_vehicle_count()==0,"Tesa exits cleanly with no active traffic reference (phase=%d reason=%s active=%d)" % [event.phase,event.finish_reason,traffic.get_active_vehicle_count()])
		player.position.x = event.trigger_x
		event.advance(2.0,route)
		check(event.spawn_count==1,"Tesa never duplicates after backtracking")
	var result := {"passed":failures.is_empty(),"checks":checks,"errors":failures,"trigger_x":event.trigger_x,"speed":event.travel_speed,"minimum_speed":event.travel_speed*0.55}
	var output := FileAccess.open("res://validation/tesa_set_piece_checks.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(result,"  ")+"\n")
	output.close()
	print(JSON.stringify(result))
	root.get_node("AudioManager").stop_all()
	await create_timer(0.3).timeout
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
