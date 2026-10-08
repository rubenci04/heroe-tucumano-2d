extends SceneTree
## Deterministic Mission 1 lifecycle: start, route, set pieces, boss, result and restart.

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
	var route = scene.get_node("Route38")
	var player = route.player
	var director = route.encounter_director
	var expresbus = route.get_node("ExpresbusSetPiece")
	var tesa = route.get_node("TesaSetPiece")
	var game_session = scene.game_session
	expect(scene.current_state==GameSession.DemoState.CHARACTER_SELECT and player.position==Vector2(80,GameConfig.GROUND_Y),"Mission 1 starts at clean character selection",snapshot(route))
	expect(route.get_node("Enemies").get_child_count()==0 and route.get_node("Vehicles").get_child_count()==0 and route.get_node("Projectiles").get_child_count()==0,"Initial route has no transient gameplay nodes",snapshot(route))
	scene.get_node("Interface/CharacterSelect").confirm_selected()
	scene.get_node("IntroFamailla").skip()
	await process_frame
	expect(scene.current_state==GameSession.DemoState.GAMEPLAY and player.controls_enabled,"Character selection and intro enter gameplay once",snapshot(route))
	player.health_component.set_invulnerability(10000.0)
	var registered: Array[StringName] = director.get_registered_encounter_ids()
	var started: Array[StringName] = []
	var completed: Array[StringName] = []
	director.encounter_started.connect(func(id: StringName): started.append(id))
	director.encounter_completed.connect(func(id: StringName): completed.append(id))
	var seen_frames: Dictionary = {}
	var seen_instances: Dictionary = {}
	var encounter_spawn_counts: Dictionary = {}
	var reached_preboss := false
	var preboss_frame := -1
	for frame in range(14000):
		# READY may still await an earlier encounter. Continue moving to finish it;
		# wait only for a bus that has actually started its warning/crossing.
		var waiting_for_expresbus: bool = expresbus.phase in [expresbus.Phase.WARNING, expresbus.Phase.CROSSING]
		var waiting_for_tesa: bool = tesa.phase in [tesa.Phase.WARNING, tesa.Phase.CROSSING]
		if player.position.x < 7400.0 and not waiting_for_expresbus and not waiting_for_tesa:
			player.position.x = minf(7400.0,player.position.x+160.0/60.0)
		player.position.y = GameConfig.GROUND_Y
		await physics_frame
		for encounter_id: StringName in director._active_enemies.keys():
			for actor in director.get_active_enemies(encounter_id):
				# This traversal uses 10,000s invulnerability to isolate progression.
				# It is not a respawn and must not hold newly spawned ranged actors.
				if actor.get("_waiting_respawn_read") == true and player.invulnerability > 9000.0:
					actor._waiting_respawn_read = false
				var instance_id: int = actor.get_instance_id()
				if not seen_instances.has(instance_id):
					seen_instances[instance_id] = true
					encounter_spawn_counts[encounter_id] = int(encounter_spawn_counts.get(encounter_id,0))+1
				if director.is_attack_visible(actor):
					if not seen_frames.has(instance_id):
						seen_frames[instance_id] = frame
					elif frame-int(seen_frames[instance_id]) >= 45:
						actor.take_damage(999,&"player")
		if player.position.x>=7400.0 and completed.size()==registered.size() \
				and director._pending.is_empty() and director._active_enemies.is_empty() \
				and director.get_attack_token_count()==0 and expresbus.phase==expresbus.Phase.FINISHED \
				and tesa.phase==tesa.Phase.FINISHED and route.traffic_director.get_active_vehicle_count()==0:
			reached_preboss = true
			preboss_frame = frame
			break
		if frame%1200==0:
			print("MISSION1_PROGRESS ",snapshot(route))
	var preboss := snapshot(route)
	expect(reached_preboss,"Mission reaches the clean preboss sector",preboss)
	var started_sorted := started.duplicate()
	var completed_sorted := completed.duplicate()
	var registered_sorted := registered.duplicate()
	started_sorted.sort()
	completed_sorted.sort()
	registered_sorted.sort()
	expect(started_sorted==registered_sorted and completed_sorted==registered_sorted and started.size()==registered.size() and completed.size()==registered.size(),"Every registered encounter starts and completes exactly once",{"started":started,"completed":completed,"registered":registered})
	expect(expresbus.spawn_count==1 and expresbus.phase==expresbus.Phase.FINISHED,"Expresbus appears and finishes exactly once",preboss)
	expect(tesa.spawn_count==1 and tesa.phase==tesa.Phase.FINISHED,"Tesa appears and finishes exactly once",preboss)
	expect(int(encounter_spawn_counts.get(&"route_drone_01",0))==1,"Drone tutorial contains exactly one Drone",encounter_spawn_counts)
	expect(int(encounter_spawn_counts.get(&"route_drone_02",0))==5,"Later Drone wave contains exactly five Drones",encounter_spawn_counts)
	expect(director._active_enemies.is_empty() and director._pending.is_empty(),"No invisible enemy or pending entry blocks preboss progression",preboss)
	expect(director.get_attack_token_count()==0,"No attack token remains before Palermitano",preboss)
	expect(game_session.active_checkpoint==&"route_after_heavy" and game_session.respawn_position.x==5600.0,"Both safe checkpoints advance monotonically during normal traversal",{"checkpoint":game_session.active_checkpoint,"respawn":game_session.respawn_position})

	# Exercise the live respawn contract after the route has been cleared.
	var lives_before: int = player.lives
	var completed_before_respawn: Array[StringName] = director.get_completed_encounter_ids()
	player.health_component.set_invulnerability(0.0)
	player.health = 1
	player.take_damage(1,&"enemy")
	await process_frame
	expect(player.lives==lives_before-1 and player.position.x>=route.LOCAL_RESPAWN_EDGE_PADDING,"A non-final death respawns locally without restarting Mission 1",snapshot(route))
	expect(director.get_completed_encounter_ids()==completed_before_respawn and expresbus.spawn_count==1 and tesa.spawn_count==1,"Respawn preserves completed encounters and consumed set pieces",snapshot(route))
	player.health_component.set_invulnerability(10000.0)

	# Enter the final sector only after route state is clean and the final rest expires.
	player.position = Vector2(7425.0,GameConfig.GROUND_Y)
	var boss_spawn_count := 0
	var boss_instance_id := 0
	for frame in range(600):
		await physics_frame
		if is_instance_valid(route.boss):
			if route.boss.get_instance_id()!=boss_instance_id:
				boss_instance_id = route.boss.get_instance_id()
				boss_spawn_count += 1
			break
	expect(is_instance_valid(route.boss) and boss_spawn_count==1,"Palermitano activates exactly once after the final route rest",snapshot(route))
	var boss: PalermitanoBoss = route.boss
	route.boss_director.skip_intro() # la intro de 2 s queda terminada: este test cubre el ciclo de vida del jefe
	var closing_started := [0]
	var closing_finished := [0]
	scene.demo_closing_started.connect(func(): closing_started[0] += 1)
	scene.demo_closing_finished.connect(func(): closing_finished[0] += 1)
	if is_instance_valid(boss):
		boss.set_physics_process(false)
		boss.boss_state = boss.BossState.DECIDE
		boss.current_pattern = boss.Pattern.NONE
		boss.last_pattern = boss.Pattern.CHAIN
		boss._summon_cooldown_remaining = 0.0
		player.position.x = boss.position.x-300.0
		if boss.begin_pattern(boss.Pattern.SUMMON_AGENTS):
			boss._process_telegraph(boss.summon_telegraph)
		scene._spawn_projectile(Vector2(7450,300),0,Vector2.LEFT,"coffee","enemy")
		var score_before: int = player.score
		boss.health_component.set_invulnerability(0.0)
		boss.take_damage(999,&"player")
		boss.take_damage(999,&"player")
		expect(not boss.active and boss.boss_state==boss.BossState.DEFEATED,"Boss death immediately stops its state machine",snapshot(route))
		expect(player.score==score_before+boss.reward_points and closing_started[0]==1,"Boss reward and Mission 1 victory trigger exactly once",snapshot(route))
	await process_frame
	expect(route.get_node("Enemies").get_child_count()==0 and route.get_node("Projectiles").get_child_count()==0,"Summons and pending projectiles cannot block victory",snapshot(route))
	expect(director._pending.is_empty() and director.get_attack_token_count()==0,"Victory leaves no pending encounter work or attack token",snapshot(route))
	expect(route.traffic_director.get_active_vehicle_count()==0 and expresbus.spawn_count==1 and tesa.spawn_count==1,"Victory cannot duplicate either designed vehicle",snapshot(route))
	while scene.get_node("Interface/DialogueBox").active:
		scene.get_node("Interface/DialogueBox").advance()
	await process_frame
	expect(scene.current_state==GameSession.DemoState.RESULT and scene.get_node("Interface/HUD/Results").visible and closing_finished[0]==1,"Existing mission-complete result appears exactly once",snapshot(route))
	expect(scene.exit_demo(false),"Existing result input accepts mission exit/continue action",snapshot(route))

	# Full restart must rebuild a pristine Mission 1 without duplicated nodes or state.
	scene.restart_game()
	await process_frame
	await process_frame
	await process_frame
	var fresh_scene = current_scene
	var fresh_route = fresh_scene.get_node("Route38")
	var fresh_director = fresh_route.encounter_director
	var fresh_exp = fresh_route.get_node("ExpresbusSetPiece")
	var fresh_tesa = fresh_route.get_node("TesaSetPiece")
	var restart_state := snapshot(fresh_route)
	expect(fresh_scene.current_state==GameSession.DemoState.CHARACTER_SELECT and fresh_route.player.position==Vector2(80,GameConfig.GROUND_Y),"Restart returns Player and flow to the initial state",restart_state)
	expect(fresh_director.get_completed_encounter_ids().is_empty() and fresh_director._pending.is_empty() and fresh_director.get_attack_token_count()==0,"Restart resets every encounter, pending entry and token",restart_state)
	expect(fresh_exp.phase==fresh_exp.Phase.READY and fresh_exp.spawn_count==0 and fresh_tesa.phase==fresh_tesa.Phase.READY and fresh_tesa.spawn_count==0,"Restart makes Expresbus and Tesa available exactly once for the new run",restart_state)
	expect(not fresh_route.boss_started and not fresh_route.boss_active and not is_instance_valid(fresh_route.boss),"Restart makes Palermitano available without retaining an old instance",restart_state)
	expect(fresh_route.get_node("Enemies").get_child_count()==0 and fresh_route.get_node("Vehicles").get_child_count()==0 and fresh_route.get_node("Projectiles").get_child_count()==0,"Restart leaves zero enemies, vehicles and projectiles",restart_state)
	expect(fresh_route.get_collected_pickup_ids().is_empty() and fresh_route.get_node("Objects").get_child_count()>0,"Restart restores the Mission 1 pickup contract",restart_state)
	expect(fresh_route.get_node("ExpresbusSetPiece").get_parent()==fresh_route and fresh_route.get_node("TesaSetPiece").get_parent()==fresh_route,"Restart creates no duplicate set-piece nodes",restart_state)

	var result := {"passed":failures.is_empty(),"checks":checks,"errors":failures,"preboss_frame":preboss_frame,"started":started,"completed":completed,"spawn_counts":encounter_spawn_counts,"victory_count":closing_started[0],"result_count":closing_finished[0],"restart":restart_state}
	var output := FileAccess.open("res://validation/route_38_end_to_end.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(result,"  ")+"\n")
	output.close()
	print(JSON.stringify(result))
	root.get_node("AudioManager").stop_all()
	fresh_scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func snapshot(route: Node) -> Dictionary:
	var director = route.encounter_director
	var boss_state: Variant = null
	if is_instance_valid(route.boss):
		boss_state = route.boss.boss_state
	return {
		"controls_enabled":route.player.controls_enabled,
		"player_health":route.player.health,
		"player_lives":route.player.lives,
		"player_state":route.player.state,
		"actors":route.get_node("Enemies").get_children().map(func(actor: Node): return {"type":actor.get("archetype"),"x":actor.position.x,"y":actor.position.y,"state":actor.get("ai_state"),"active":actor.get("active"),"velocity":actor.get("velocity"),"respawn_read":actor.get("_waiting_respawn_read")}),
		"player_x":snappedf(route.player.position.x,0.1),
		"active_enemies":route.get_node("Enemies").get_child_count(),
		"active_encounters":director._active_enemies.keys(),
		"pending":director._pending.size(),
		"tokens":director.get_attack_token_count(),
		"vehicles":route.traffic_director.get_active_vehicle_count(),
		"projectiles":route.get_node("Projectiles").get_child_count(),
		"hostile_projectiles":director.get_hostile_projectile_count(),
		"boss_state":boss_state,
		"completed":director.get_completed_encounter_ids(),
		"expresbus_spawns":route.get_node("ExpresbusSetPiece").spawn_count,
		"tesa_spawns":route.get_node("TesaSetPiece").spawn_count
	}
