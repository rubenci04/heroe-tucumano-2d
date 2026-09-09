extends SceneTree

const GAME_SESSION = preload("res://scripts/core/game_session.gd")

var snapshots: Array[Dictionary] = []
var frame_windows: Array[Dictionary] = []
var errors: Array[String] = []
var cycle_summaries: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("run_profile")


func frames(count: int) -> void:
	for _index in range(count):
		await physics_frame
	await process_frame


func expect(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
		push_error(message)


func snapshot(stage: String, cycle: int, scene: Node = null) -> void:
	var route: Node = scene.get_node("Route38") if is_instance_valid(scene) else null
	var audio_manager: Node = root.get_node("AudioManager")
	var game_session: Node = root.get_node("GameSession")
	snapshots.append({
		"cycle": cycle,
		"stage": stage,
		"fps": Performance.get_monitor(Performance.TIME_FPS),
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,
		"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0,
		"static_memory_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
		"static_memory_peak_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC_MAX)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"resources": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"orphan_nodes": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"node_timers": root.find_children("*","Timer",true,false).size(),
		"active_tweens": get_processed_tweens().size(),
		"audio_players": root.find_children("*","AudioStreamPlayer",true,false).size(),
		"enemies": route.get_node("Enemies").get_child_count() if route else 0,
		"projectiles": route.get_node("Projectiles").get_child_count() if route else 0,
		"vehicles": route.get_node("Vehicles").get_child_count() if route else 0,
		"audio_voice_pool": audio_manager.voices.size(),
		"session_progress_connections": game_session.progress_changed.get_connections().size(),
		"session_checkpoint_connections": game_session.checkpoint_changed.get_connections().size(),
		"route_boss_defeat_connections": route.boss_defeated.get_connections().size() if route else 0
	})


func measure_window(stage: String, cycle: int, frame_count: int = 90, warmup_frames: int = 110) -> void:
	for _index in range(warmup_frames):
		await process_frame
	var started_usec := Time.get_ticks_usec()
	var fps_total := 0.0
	var fps_min := INF
	var process_total_ms := 0.0
	var process_max_ms := 0.0
	var physics_total_ms := 0.0
	var physics_max_ms := 0.0
	for _index in range(frame_count):
		await process_frame
		var fps := Performance.get_monitor(Performance.TIME_FPS)
		var process_ms := Performance.get_monitor(Performance.TIME_PROCESS)*1000.0
		var physics_ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0
		fps_total += fps
		fps_min = minf(fps_min,fps)
		process_total_ms += process_ms
		process_max_ms = maxf(process_max_ms,process_ms)
		physics_total_ms += physics_ms
		physics_max_ms = maxf(physics_max_ms,physics_ms)
	var elapsed_seconds := float(Time.get_ticks_usec()-started_usec)/1000000.0
	frame_windows.append({
		"cycle": cycle,
		"stage": stage,
		"sampled_frames": frame_count,
		"warmup_frames": warmup_frames,
		"observed_fps_average": fps_total/frame_count,
		"observed_fps_minimum": fps_min,
		"wall_fps": frame_count/elapsed_seconds,
		"process_ms_average": process_total_ms/frame_count,
		"process_ms_maximum": process_max_ms,
		"physics_ms_average": physics_total_ms/frame_count,
		"physics_ms_maximum": physics_max_ms
	})


func run_profile() -> void:
	var started_usec := Time.get_ticks_usec()
	var game_session: Node = root.get_node("GameSession")
	var audio_manager: Node = root.get_node("AudioManager")
	var scene: Node
	for cycle in range(1,4):
		if cycle == 1:
			scene = load("res://scenes/main.tscn").instantiate()
			root.add_child(scene)
			current_scene = scene
		await frames(5)
		snapshot("character_select",cycle,scene)
		await measure_window("character_select",cycle,60)
		expect(scene.current_state==GAME_SESSION.DemoState.CHARACTER_SELECT,"Cycle %d did not start at CHARACTER_SELECT" % cycle)
		var character_select: Control = scene.get_node("Interface/CharacterSelect")
		var intro: Node = scene.get_node("IntroFamailla")
		var dialogue: Control = scene.get_node("Interface/DialogueBox")
		expect(character_select.confirm_selected(),"Cycle %d could not select San Martin" % cycle)
		if cycle == 1:
			while dialogue.active:
				dialogue.advance()
		else:
			expect(intro.skip(),"Cycle %d could not skip INTRO" % cycle)
		await frames(3)
		expect(scene.current_state==GAME_SESSION.DemoState.GAMEPLAY,"Cycle %d did not enter GAMEPLAY" % cycle)
		var route: Node = scene.get_node("Route38")
		var player: CharacterBody2D = route.get_node("Player")
		var encounters: Node = route.get_node("EncounterDirector")
		var traffic: Node = route.get_node("TrafficDirector")
		route.set_physics_process(false)
		scene._spawn_projectile(player.position,player.lane_index,1,"orange","player")
		player.combo_component.register_hit(StringName("profile_combo_%d" % cycle))
		expect(player.tucumanazo_counter.current_uses==5 and player.start_tucumanazo(),"Cycle %d could not consume its first Tucumanazo" % cycle)
		player.cancel_tucumanazo()
		for pre_checkpoint_id: StringName in [&"route_wave_01",&"route_wave_02",&"route_wave_03"]:
			expect(encounters.activate_encounter(pre_checkpoint_id),"Cycle %d could not activate %s" % [cycle,pre_checkpoint_id])
			for enemy in encounters.get_active_enemies(pre_checkpoint_id):
				enemy.set_physics_process(false)
				enemy.health_component.set_invulnerability(0.0)
				enemy.take_damage(999,&"player")
			await frames(1)
		var checkpoint: Area2D = route.get_node("Checkpoint")
		expect(checkpoint.activate_for(player),"Cycle %d could not activate checkpoint" % cycle)
		route.set_physics_process(false)
		snapshot("checkpoint_active",cycle,scene)
		if cycle == 1:
			expect(encounters.activate_encounter(&"route_drone_01"),"Cycle 1 could not activate the Drone respawn scenario")
			var drone_before_respawn: Array[Node] = encounters.get_active_enemies(&"route_drone_01")
			player.position = Vector2(4300.0,GameConfig.LANES[1])
			player.lane_index = 1
			player.hurtbox.lane_index = 1
			player.collision_mask = 1 << 1
			player.health_component.set_invulnerability(0.0)
			player.health = 1
			player.take_damage(1,"enemy")
			await frames(2)
			expect(player.position==Vector2(4140.0,GameConfig.LANES[1]) and encounters.get_active_enemy_count(&"route_drone_01")==drone_before_respawn.size() and drone_before_respawn.all(func(drone: Node): return is_instance_valid(drone) and drone.is_inside_tree()),"Cycle 1 Drone death did not preserve the aerial encounter with local respawn")
			snapshot("drone_local_respawn",cycle,scene)
		for encounter_id: StringName in encounters.get_registered_encounter_ids():
			if encounters.is_encounter_completed(encounter_id) or encounters.is_encounter_activated(encounter_id):
				continue
			expect(encounters.activate_encounter(encounter_id),"Cycle %d could not activate %s" % [cycle,encounter_id])
		var first_vehicle = traffic.spawn_now(4700.0)
		var second_vehicle = traffic.spawn_now(4700.0)
		expect(first_vehicle != null and second_vehicle != null,"Cycle %d could not exercise the traffic budget" % cycle)
		await frames(3)
		snapshot("active_encounters",cycle,scene)
		player.hurtbox.set_receiving_enabled(false)
		await measure_window("active_encounters",cycle,90)
		player.hurtbox.set_receiving_enabled(true)
		if cycle == 1:
			var enemies_before_wave_respawn: int = route.get_node("Enemies").get_child_count()
			player.position = Vector2(5000.0,GameConfig.LANES[1])
			player.lane_index = 1
			player.hurtbox.lane_index = 1
			player.collision_mask = 1 << 1
			player.health_component.set_invulnerability(0.0)
			player.health = 1
			player.take_damage(1,"enemy")
			await frames(2)
			expect(player.position.x>=4780.0 and player.position.x<=4880.0 and route.get_node("Enemies").get_child_count()==enemies_before_wave_respawn,"Cycle 1 wave death reset or duplicated active enemies")
			snapshot("wave_local_respawn",cycle,scene)
		elif cycle == 2:
			var traffic_before_respawn: int = traffic.get_active_vehicle_count()
			var roof_vehicle: Node = traffic.get_active_vehicles()[1]
			roof_vehicle.position = Vector2(4840.0,GameConfig.LANES[1])
			roof_vehicle.lane_index = 1
			player.position = Vector2(5000.0,GameConfig.LANES[1])
			player.lane_index = 1
			player.hurtbox.lane_index = 1
			player.collision_mask = 1 << 1
			player.health_component.set_invulnerability(0.0)
			player.health = 1
			player.take_damage(1,"traffic")
			await frames(2)
			expect(traffic.get_active_vehicle_count()==traffic_before_respawn and not (player.lane_index==roof_vehicle.lane_index and absf(player.position.x-roof_vehicle.position.x)<=route.LOCAL_RESPAWN_VEHICLE_CLEARANCE),"Cycle 2 traffic death respawned on a moving vehicle or reset traffic")
			snapshot("traffic_local_respawn",cycle,scene)
		for encounter_id: StringName in encounters.get_registered_encounter_ids():
			if encounters.is_encounter_completed(encounter_id):
				continue
			for enemy in encounters.get_active_enemies(encounter_id):
				enemy.set_physics_process(false)
				enemy.health_component.set_invulnerability(0.0)
				enemy.take_damage(999,&"player")
			await frames(1)
		traffic.clear_traffic()
		player.position = Vector2(7425.0,GameConfig.LANES[1])
		player.lane_index = 1
		player.hurtbox.lane_index = 1
		route._physics_process(0.0)
		var final_boss = route.boss
		expect(is_instance_valid(final_boss) and final_boss is PalermitanoBoss,"Cycle %d could not activate Palermitano" % cycle)
		if is_instance_valid(final_boss):
			final_boss.set_physics_process(false)
			final_boss.boss_state = final_boss.BossState.DECIDE
			final_boss.begin_pattern(final_boss.Pattern.TRIPLE_COFFEE)
			final_boss._process_telegraph(final_boss.coffee_telegraph)
			final_boss._process_attack(final_boss.coffee_shot_interval)
			final_boss._process_attack(final_boss.coffee_shot_interval)
			final_boss.boss_state = final_boss.BossState.DECIDE
			final_boss._summon_cooldown_remaining = 0.0
			final_boss.begin_pattern(final_boss.Pattern.SUMMON_AGENTS)
			final_boss._process_telegraph(final_boss.summon_telegraph)
			if cycle == 3:
				var boss_health_before_respawn: int = final_boss.health
				var summons_before_respawn: int = final_boss.get_live_summon_count()
				player.position = Vector2(7350.0,GameConfig.LANES[final_boss.lane_index])
				player.lane_index = final_boss.lane_index
				player.hurtbox.lane_index = final_boss.lane_index
				player.collision_mask = 1 << final_boss.lane_index
				player.health_component.set_invulnerability(0.0)
				player.health = 1
				player.take_damage(1,"boss")
				await frames(2)
				expect(route.boss==final_boss and final_boss.health==boss_health_before_respawn and final_boss.get_live_summon_count()==summons_before_respawn and route.boss_active,"Cycle 3 boss death reset HP, arena or summons")
				expect(player.position.x>=route.BOSS_ARENA_BOUNDS.x+route.LOCAL_RESPAWN_ARENA_PADDING and player.position.x<=route.BOSS_ARENA_BOUNDS.y-route.LOCAL_RESPAWN_ARENA_PADDING,"Cycle 3 boss respawn escaped arena bounds")
				snapshot("boss_local_respawn",cycle,scene)
		player.hurtbox.set_receiving_enabled(false)
		snapshot("final_boss_active",cycle,scene)
		await measure_window("final_boss_active",cycle,90)
		if is_instance_valid(final_boss):
			final_boss.health_component.set_invulnerability(0.0)
			final_boss.take_damage(999,&"player")
		await frames(4)
		expect(dialogue.active and scene.demo_closing,"Cycle %d did not enter demo closing" % cycle)
		while dialogue.active:
			dialogue.advance()
		await frames(2)
		expect(scene.current_state==GAME_SESSION.DemoState.RESULT,"Cycle %d did not reach RESULT" % cycle)
		expect(route.get_node("Enemies").get_child_count()==0 and route.get_node("Projectiles").get_child_count()==0 and route.get_node("Vehicles").get_child_count()==0,"Cycle %d left gameplay actors at RESULT" % cycle)
		snapshot("result",cycle,scene)
		await measure_window("result",cycle,60)
		cycle_summaries.append({
			"cycle": cycle,
			"completed_encounters": encounters.get_completed_encounter_ids().size(),
			"checkpoint": String(game_session.active_checkpoint),
			"result_music_state": String(audio_manager.current_music_state)
		})
		scene.restart_game()
		await frames(6)
		scene = current_scene
		expect(scene.current_state==GAME_SESSION.DemoState.CHARACTER_SELECT,"Cycle %d restart did not return to CHARACTER_SELECT" % cycle)
		expect(game_session.active_checkpoint.is_empty() and game_session.score==0 and game_session.coins==0,"Cycle %d restart left GameSession progress" % cycle)
		expect(scene.get_node("Route38/Enemies").get_child_count()==0 and scene.get_node("Route38/Projectiles").get_child_count()==0 and scene.get_node("Route38/Vehicles").get_child_count()==0,"Cycle %d restart left actor nodes" % cycle)
		expect(audio_manager.voices.size()==8 and audio_manager.get_children().filter(func(child: Node): return child is AudioStreamPlayer).size()==9,"Cycle %d duplicated audio players" % cycle)
		snapshot("after_restart",cycle,scene)
	var elapsed_seconds := float(Time.get_ticks_usec()-started_usec)/1000000.0
	var restart_snapshots: Array = snapshots.filter(func(item: Dictionary): return item.stage=="after_restart")
	var result := {
		"passed": errors.is_empty(),
		"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(),
		"elapsed_seconds": elapsed_seconds,
		"cycles": 3,
		"snapshots": snapshots,
		"frame_windows": frame_windows,
		"cycle_summaries": cycle_summaries,
		"restart_node_delta": int(restart_snapshots[-1].nodes)-int(restart_snapshots[0].nodes),
		"restart_memory_delta_bytes": int(restart_snapshots[-1].static_memory_bytes)-int(restart_snapshots[0].static_memory_bytes),
		"restart_resource_delta": int(restart_snapshots[-1].resources)-int(restart_snapshots[0].resources),
		"errors": errors
	}
	var output := FileAccess.open("res://validation/vertical_slice_profile.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(result,"  ")+"\n")
	output.close()
	print(JSON.stringify(result))
	quit(0 if errors.is_empty() else 1)
