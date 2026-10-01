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
	var director = route.encounter_director
	route.set_physics_process(false)
	director.reset_runtime_state(true)
	director.update_safety(1000.0,1000.0,800.0)
	director.activate_encounter(&"route_wave_01",540.0,false)
	var actors: Array[Node] = director.get_active_enemies(&"route_wave_01")
	for actor in actors:
		actor.set_physics_process(false)
	var hipster = actors[0]
	hipster.position.x = 1100.0
	var shots: Array[String] = []
	hipster.shot_requested.connect(func(_origin,_lane,_direction,kind,_team): shots.append(kind))
	# Projectile-only probes complete the mandatory first reading lifecycle.
	hipster._advance_ranged_lifecycle(hipster.definition.entry_duration,-300.0)
	hipster._advance_ranged_lifecycle(hipster._state_remaining,-300.0)
	hipster._begin_attack()
	hipster._advance_attack_state(hipster.definition.telegraph_duration)
	var first = route.get_node("Projectiles").get_child(-1)
	check(shots==["hipster_coffee"],"Hipster emits café, never bottle")
	check(first.speed==115.0 and first.visual.scale==Vector2(0.15,0.15),"Hipster café keeps scale 0.15 at 115 px/s")
	check(first.definition.rotation_speed_degrees==0.0 and is_equal_approx(first.visual.rotation,deg_to_rad(-22.0)),"Coffee remains visually upright with fixed orientation and no flight rotation")
	hipster._advance_attack_state(0.84)
	check(shots.size()==1,"Second coffee waits at least 0.85 seconds")
	hipster._advance_attack_state(0.02)
	check(shots==["hipster_coffee","hipster_coffee"],"Valid visible Hipster emits exactly two coffees")
	hipster._advance_attack_state(0.1)
	hipster._advance_attack_state(hipster.definition.recovery_duration+0.1)
	check(is_equal_approx(hipster.attack_cooldown,4.5),"Post-burst cooldown is 4.5 seconds")
	clear_projectiles(route)
	await process_frame

	var offscreen = actors[1]
	offscreen.position.x = 1100.0
	var offscreen_shots: Array[String] = []
	offscreen.shot_requested.connect(func(_origin,_lane,_direction,kind,_team): offscreen_shots.append(kind))
	director.advance_spawns(1.0)
	offscreen._advance_ranged_lifecycle(offscreen.definition.entry_duration,-300.0)
	offscreen._advance_ranged_lifecycle(offscreen._state_remaining,-300.0)
	offscreen._begin_attack()
	offscreen._advance_attack_state(offscreen.definition.telegraph_duration)
	offscreen.position.x = 1450.0
	director.update_safety(1000.0,1000.0,800.0)
	offscreen._advance_attack_state(1.0)
	check(offscreen_shots.size()==1 and offscreen._burst_shots_remaining==0,"Leaving camera cancels the second coffee")
	check(director.get_attack_token_count()==0,"Offscreen cancellation releases attack token")
	clear_projectiles(route)
	await process_frame

	var defeated = actors[2]
	defeated.position.x = 1100.0
	var defeated_shots: Array[String] = []
	defeated.shot_requested.connect(func(_origin,_lane,_direction,kind,_team): defeated_shots.append(kind))
	director.advance_spawns(1.0)
	defeated._advance_ranged_lifecycle(defeated.definition.entry_duration,-300.0)
	defeated._advance_ranged_lifecycle(defeated._state_remaining,-300.0)
	defeated._begin_attack()
	defeated._advance_attack_state(defeated.definition.telegraph_duration)
	defeated.take_damage(999,&"player")
	defeated._advance_attack_state(1.0)
	check(defeated_shots.size()==1,"Defeated Hipster cannot emit its second coffee")
	check(load("res://data/projectiles/coffee.tres").speed==300.0,"Palermitano keeps its independent current coffee resource")
	var result := {"passed":failures.is_empty(),"checks":checks,"errors":failures}
	var output := FileAccess.open("res://validation/hipster_coffee_checks.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(result,"  ")+"\n")
	output.close()
	print(JSON.stringify(result))
	root.get_node("AudioManager").stop_all()
	await create_timer(0.3).timeout
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func clear_projectiles(route: Node) -> void:
	for projectile in route.get_node("Projectiles").get_children():
		projectile.queue_free()
