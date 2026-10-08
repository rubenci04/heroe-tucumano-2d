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
	var player = route.player
	route.set_physics_process(false)
	player.set_physics_process(false)
	player.position = Vector2(4100,GameConfig.GROUND_Y)
	director.reset_runtime_state(true)
	director.update_safety(player.position.x,player.position.x,800.0)
	check(director.activate_encounter(&"route_drone_01",4100.0,true),"Tutorial encounter activates at X=4100")
	var tutorial: Array[Node] = director.get_active_enemies(&"route_drone_01")
	check(tutorial.size()==1 and tutorial[0].get_script().resource_path=="res://scripts/actors/drone.gd","Tutorial contains exactly one Drone and no ground companion")
	var drone = tutorial[0]
	drone.set_physics_process(false)
	var side := -1.0 if drone.position.x>player.position.x else 1.0
	drone.position.x = player.position.x-side*drone.definition.preferred_distance
	drone._process_entry(0.01)
	check(drone.ai_state==drone.AIState.IDLE and is_equal_approx(drone.cooldown_remaining,1.0),"Tutorial grants one second of reading after entry")
	drone._process_idle(0.79)
	check(drone.ai_state==drone.AIState.IDLE and drone.shots_emitted==0,"Drone cannot aim or fire during the initial reading period")
	var x_before: float = drone.position.x
	var y_before: float = drone.position.y
	drone._physics_process(0.22)
	drone._physics_process(0.22)
	check(absf(drone.position.x-x_before)>0.1,"Tutorial Drone patrols horizontally")
	check(absf(drone.position.y-y_before)>0.1 and drone.bob_amplitude<=5.0,"Tutorial Drone has a soft vertical oscillation")

	var completed_before_wave: Array[StringName] = [
		&"route_wave_01",&"route_micro_01",&"route_micro_02",&"route_wave_02",
		&"route_wave_03",&"route_micro_03",&"route_drone_01",&"route_micro_04",
		&"route_wave_04",&"route_micro_05"
	]
	director.restore_completed_encounters(completed_before_wave)
	await process_frame
	player.position.x = 6100.0
	director.update_safety(player.position.x,6500.0,800.0)
	check(director.activate_encounter(&"route_drone_02",6100.0,true),"Later aerial wave activates at X=6100")
	var spawn_counts: Array[int] = [director.get_active_enemy_count(&"route_drone_02")]
	for step in range(6):
		director.advance_spawns(0.55,player.position.x)
		spawn_counts.append(director.get_active_enemy_count(&"route_drone_02"))
	var wave: Array[Node] = director.get_active_enemies(&"route_drone_02")
	print("DRONE_GROUP_COUNTS ", spawn_counts)
	check(spawn_counts==[1,2,2,4,4,4,5] and wave.size()==5,"Five Drones arrive in groups of at most two separated by the configured delay")
	check(wave.all(func(actor): return actor.get_script().resource_path=="res://scripts/actors/drone.gd" and actor.wave_formation and actor.formation_size==5),"Wave contains five phase-coordinated Drones")
	var phases: Array[float] = []
	for index in range(wave.size()):
		var member = wave[index]
		member.set_physics_process(false)
		member.position = Vector2(6420.0+index*40.0,205.0)
		member.flight_anchor_y = member.position.y
		member.patrol_center_x = member.position.x
		member.ai_state = member.AIState.IDLE
		member.cooldown_remaining = 0.0
		phases.append(member.formation_phase)
	check(phases.duplicate().all(func(phase): return phases.count(phase)==1),"Formation phases are distinct, avoiding identical trajectories")

	director.update_safety(player.position.x,6500.0,800.0)
	var first = wave[0]
	var second = wave[1]
	check(first._begin_aim(),"First Drone receives an aerial attack token")
	first._process_aim(0.23)
	director.advance_spawns(0.8,player.position.x)
	check(not second._begin_aim(),"Only one Drone may hold attack permission")
	var extra_grants := 0
	for index in range(2,wave.size()):
		extra_grants += 1 if wave[index]._begin_aim() else 0
	check(director.get_drone_attack_token_count()==1 and extra_grants==0,"Aerial attack pool is capped at one simultaneous Drone")
	director.release_attack(first)
	director.advance_spawns(0.64,player.position.x)
	check(not second._begin_aim(),"Global aerial handoff waits at least 0.65 seconds")
	director.advance_spawns(0.12,player.position.x)
	check(second._begin_aim() and director.get_drone_attack_token_count()==1,"Next Drone receives permission after the 0.75-second global gap")
	check(is_equal_approx(second.definition.projectile_definition.speed,175.0) and is_equal_approx(second.definition.attack_cooldown,2.8),"Drone bolt and offensive cooldown use the lower-pressure values")

	for member in wave:
		member.position.x = 5000.0
	director.update_safety(player.position.x,6500.0,800.0)
	await process_frame
	check(director.get_active_enemy_count(&"route_drone_02")==0 and director.get_drone_attack_token_count()==0,"Offscreen Drones retire and release tracking/tokens")
	check(director.is_encounter_completed(&"route_drone_02"),"Invisible retired Drones cannot block encounter completion")
	director.advance_spawns(2.1,6450.0)
	director.update_activation(6450.0)
	check(director.is_encounter_activated(&"route_micro_06"),"Next encounter can activate after the aerial wave retires")

	scene.restart_game()
	await process_frame
	await process_frame
	await process_frame
	var fresh_route = current_scene.get_node("Route38")
	check(fresh_route.get_node("Enemies").get_child_count()==0 and fresh_route.encounter_director.get_attack_token_count()==0,"Restart clears Drone actors and every attack token")
	var result := {"passed":failures.is_empty(),"checks":checks,"errors":failures,"tutorial_x":4100,"wave_x":6100,"entry_interval":0.55,"read_delay":1.0,"attack_cap":1}
	var output := FileAccess.open("res://validation/drone_encounter_checks.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(result,"  ")+"\n")
	output.close()
	print(JSON.stringify(result))
	root.get_node("AudioManager").stop_all()
	await create_timer(0.3).timeout
	quit(0 if failures.is_empty() else 1)
