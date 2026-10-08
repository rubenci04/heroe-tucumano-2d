extends SceneTree
## Full-route deterministic progression and ground-ranged safety probe.

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool,message: String,context: Dictionary = {}) -> void:
	checks += 1
	if condition:
		return
	var diagnostic := "%s | %s" % [message,JSON.stringify(context)]
	failures.append(diagnostic)
	push_error(diagnostic)

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
	var director = route.encounter_director
	var event = route.get_node("ExpresbusSetPiece")
	var tesa = route.get_node("TesaSetPiece")
	var camera: Camera2D = scene.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	player.health_component.set_invulnerability(10000.0)
	route.set_physics_process(false)
	await check_attack_visibility(scene,route)
	director.reset_runtime_state(true)
	await physics_frame
	player.position = Vector2(80.0,GameConfig.GROUND_Y)
	camera.position = Vector2(400.0,225.0)
	camera.reset_smoothing()
	var started: Array[StringName] = []
	var completed: Array[StringName] = []
	var started_during_bus: Array[StringName] = []
	director.encounter_started.connect(func(id: StringName):
		started.append(id)
		if event.is_running():
			started_during_bus.append(id)
	)
	director.encounter_completed.connect(func(id: StringName): completed.append(id))
	route.set_physics_process(true)
	var seen_frame: Dictionary = {}
	var ever_visible: Dictionary = {}
	var peak_visible := 0
	var bus_seen := false
	var reached_preboss := false
	for frame in range(20000):
		var waiting: bool = (event.phase != event.Phase.FINISHED and player.position.x >= event.trigger_x) or (tesa.phase != tesa.Phase.FINISHED and player.position.x >= tesa.trigger_x)
		if player.position.x < 7400.0 and not waiting:
			player.position.x = minf(7400.0,player.position.x+160.0/60.0)
		player.position.y = GameConfig.GROUND_Y
		await physics_frame
		bus_seen = bus_seen or event.phase in [event.Phase.WARNING,event.Phase.CROSSING,event.Phase.FINISHED]
		var visible_now := 0
		for encounter_id: StringName in director._active_enemies.keys():
			for actor in director.get_active_enemies(encounter_id):
				var instance_id: int = actor.get_instance_id()
				if director.is_attack_visible(actor):
					visible_now += 1
					ever_visible[instance_id] = true
					if not seen_frame.has(instance_id):
						seen_frame[instance_id] = frame
					elif frame-int(seen_frame[instance_id]) >= 150:
						actor.take_damage(999,&"player")
		peak_visible = maxi(peak_visible,visible_now)
		var registered: Array[StringName] = director.get_registered_encounter_ids()
		if player.position.x>=7400.0 and completed.size()==registered.size() \
				and director._pending.is_empty() and director._active_enemies.is_empty() \
				and director.get_attack_token_count()==0 and director.get_ground_projectile_count()==0 \
				and event.phase==event.Phase.FINISHED:
			reached_preboss = true
			break
		if frame%600==0:
			print("ROUTE_PROGRESS ",snapshot(route))
	var registered: Array[StringName] = director.get_registered_encounter_ids()
	var final_state := snapshot(route)
	expect(bus_seen and event.spawn_count==1,"Expresbus ran exactly once",final_state)
	expect(started_during_bus.is_empty(),"No encounter began during Expresbus",{"started_during_bus":started_during_bus})
	var registered_sorted := registered.duplicate()
	var started_sorted := started.duplicate()
	var completed_sorted := completed.duplicate()
	registered_sorted.sort()
	started_sorted.sort()
	completed_sorted.sort()
	expect(started_sorted==registered_sorted,"Every registered encounter activates exactly once",{"started":started,"registered":registered})
	expect(completed_sorted==registered_sorted,"Every registered encounter completes exactly once",{"completed":completed,"registered":registered})
	expect(reached_preboss and player.position.x>=7400.0,"Player reached the preboss zone",final_state)
	expect(director._pending.is_empty(),"No pending spawn remained",final_state)
	expect(director.get_attack_token_count()==0,"No attack token remained",final_state)
	expect(director._active_enemies.is_empty(),"No invisible enemy blocked progression",final_state)
	expect(peak_visible>=1 and peak_visible<=preload("res://scripts/prototype/feel_config.gd").WAVE_MAX_ADVANCED,"Visible population stays within the configured limit (spaced actors can be offscreen)",{"peak_visible":peak_visible})
	expect(ever_visible.size()>=registered.size(),"Actors entered the viewport before test defeat",{"visible_actor_count":ever_visible.size()})
	var output := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"peak_visible":peak_visible,"started":started,"completed":completed,"final":final_state}
	var result_file := FileAccess.open("res://validation/route_progression.json",FileAccess.WRITE)
	result_file.store_string(JSON.stringify(output,"  ")+"\n")
	result_file.close()
	print(JSON.stringify(output))
	root.get_node("AudioManager").stop_all()
	await create_timer(0.3).timeout
	scene.queue_free()
	for index in range(3):
		await process_frame
	quit(0 if failures.is_empty() else 1)

func check_attack_visibility(scene: Node,route: Node) -> void:
	var director = route.encounter_director
	var player = route.player
	player.set_physics_process(false)
	player.position.x = 1000
	scene.camera.position = Vector2(1000,225)
	scene.camera.reset_smoothing()
	scene.camera.force_update_scroll()
	director.reset_runtime_state(true)
	director.update_safety(1000.0,1000.0,800.0)
	director.activate_encounter(&"route_wave_01",1000.0,false)
	var actors: Array[Node] = director.get_active_enemies(&"route_wave_01")
	for actor in actors:
		actor.set_physics_process(false)
	var probe = actors[0]
	probe.position.x = 1500.0
	expect(not director.request_attack(probe),"Offscreen ground actor cannot obtain a token",snapshot(route))
	probe.position.x = 1200.0
	expect(director.request_attack(probe),"Visible ground actor can obtain the sole token",snapshot(route))
	probe._advance_ranged_lifecycle(probe.definition.entry_duration,-300.0)
	probe._advance_ranged_lifecycle(probe._state_remaining,-300.0)
	probe.ai_state = probe.AIState.REACT
	probe._state_remaining = 0
	probe.attack_cooldown = 0
	probe._begin_attack()
	probe._burst_shots_remaining = 1
	probe.position.x = 1450.0
	director.update_safety(1000.0,1000.0,800.0)
	expect(probe.ai_state==probe.AIState.ENTER and probe._burst_shots_remaining==0 and director.get_attack_token_count()==0,"Leaving camera cancels burst, restores entry and releases token",snapshot(route))
	probe.position.x = 500.0
	director.update_safety(1000.0,1000.0,800.0)
	expect(probe.is_queued_for_deletion() and director.get_active_enemy_count(&"route_wave_01")==actors.size()-1,"Actor wholly behind viewport is safely unregistered",snapshot(route))
	var hostile_kinds := ["hipster_coffee","agent_orb","drone_bolt"]
	for index in range(3):
		scene._spawn_projectile(Vector2(850.0+index*20.0,300.0),0,-1,hostile_kinds[index],"enemy")
	var second = actors[1]
	second.position.x = 1200.0
	expect(director.get_hostile_projectile_count()==3 and not director.request_attack(second),"Three hostile projectiles exhaust the global budget",snapshot(route))
	for projectile in route.get_node("Projectiles").get_children():
		projectile.queue_free()
	await physics_frame
	director.reset_runtime_state(true)
	player.set_physics_process(true)

func snapshot(route: Node) -> Dictionary:
	var director = route.encounter_director
	var actors: Array = []
	var offscreen := 0
	for id in director._active_enemies.keys():
		for actor in director.get_active_enemies(id):
			var hidden: bool = not director.is_attack_visible(actor)
			offscreen += 1 if hidden else 0
			actors.append({"id":String(id),"type":actor.archetype,"x":snappedf(actor.position.x,0.1),"state":actor.ai_state,"offscreen":hidden})
	return {"player_x":snappedf(route.player.position.x,0.1),"active":actors,"active_count":actors.size(),"offscreen":offscreen,"pending":director._pending.size(),"tokens":director.get_attack_token_count(),"ground_projectiles":director.get_ground_projectile_count(),"completed":director.get_completed_encounter_ids()}
