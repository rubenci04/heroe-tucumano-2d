extends SceneTree

const PROJECTILE_SCENE = preload("res://scenes/actors/projectile.tscn")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool,message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func add_hostile(route: Node,kind: StringName) -> Node:
	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.kind = kind
	projectile.team = &"enemy"
	projectile.position = Vector2(3000,220)
	route.get_node("Projectiles").add_child(projectile)
	projectile.set_physics_process(false)
	return projectile

func clear_hostiles(route: Node) -> void:
	for projectile in route.get_node("Projectiles").get_children():
		projectile.queue_free()

func run() -> void:
	root.size = Vector2i(800,450)
	var orange = load("res://data/projectiles/orange.tres")
	var hipster = load("res://data/enemies/hipster.tres")
	var agent = load("res://data/enemies/agente.tres")
	var grandote = load("res://data/enemies/grandote.tres")
	var drone_definition = load("res://data/enemies/drone.tres")
	check(orange.speed==560.0 and orange.damage==1,"Player standard projectile remains clearly fast at 560 px/s")
	check([hipster.max_health,agent.max_health,grandote.max_health,drone_definition.max_health]==[2,3,6,3],"Enemy HP maps to 2/3/6/3 Naranjazos")
	check(ceili(float(hipster.max_health)/2.0)==1 and ceili(float(agent.max_health)/2.0)==2 and ceili(float(grandote.max_health)/2.0)==3,"Two-damage Punch keeps 1/2/3-hit melee hierarchy")
	check(load("res://data/projectiles/hipster_coffee.tres").speed==115.0 and hipster.attack_cooldown==4.5,"Hipster coffee uses 115 px/s and 4.5-second cooldown")
	check(load("res://data/projectiles/agent_orb.tres").speed==170.0 and agent.attack_cooldown==3.2 and agent.telegraph_duration==0.45,"Agent orb uses 170 px/s with readable telegraph and cooldown")
	check(load("res://data/projectiles/drone_bolt.tres").speed==175.0 and drone_definition.attack_cooldown==2.8,"Drone bolt uses 175 px/s with 2.8-second cooldown")

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
	route.player.set_physics_process(false)
	director.reset_runtime_state(true)
	director.camera_center_x = NAN
	director.activate_encounter(&"route_wave_03",3500.0,false)
	var ground: Array[Node] = director.get_active_enemies(&"route_wave_03")
	for actor in ground:
		actor.set_physics_process(false)
	check(director.request_attack(ground[0]) and not director.request_attack(ground[1]) and director.get_attack_token_count()==1,"Only one terrestrial ranged actor receives permission")
	ground[0].take_damage(999,&"player")
	check(director.get_attack_token_count()==0,"Ground token releases immediately on death")
	add_hostile(route,&"hipster_coffee")
	add_hostile(route,&"agent_orb")
	add_hostile(route,&"drone_bolt")
	director.advance_spawns(1.0)
	check(director.get_hostile_projectile_count()==3 and not director.request_attack(ground[2]),"Three live hostile projectiles block every new ranged permission")
	route.get_node("Projectiles").get_child(0).queue_free()
	await process_frame
	check(director.get_hostile_projectile_count()==2 and director.request_attack(ground[2]),"Permission resumes naturally after one projectile expires")

	director.reset_runtime_state(true)
	clear_hostiles(route)
	await process_frame
	director.activate_encounter(&"route_drone_02",6100.0,false)
	var drones: Array[Node] = director.get_active_enemies(&"route_drone_02")
	for actor in drones:
		actor.set_physics_process(false)
	check(drones.size()==5 and director.request_attack(drones[0]) and not director.request_attack(drones[1]) and director.get_drone_attack_token_count()==1,"Five-Drone wave keeps five actors but one offensive token")
	director.release_attack(drones[0])
	director.advance_spawns(0.64)
	check(not director.request_attack(drones[1]),"Drone handoff remains closed before 0.65 seconds")
	director.advance_spawns(0.12)
	check(director.request_attack(drones[1]),"Drone handoff opens after the configured 0.75-second gap")
	director.release_attack(drones[1])
	director.advance_spawns(0.8)
	add_hostile(route,&"drone_bolt")
	add_hostile(route,&"drone_bolt")
	check(director.get_projectile_cap_for(drones[2])==2 and not director.request_attack(drones[2]),"Five-Drone wave stops new attacks at two live hostile projectiles")
	clear_hostiles(route)
	await process_frame
	director.advance_spawns(0.8)
	check(director.request_attack(drones[2]),"Drone can receive a token again after projectiles clear")
	var retired_drone_id: int = drones[2].get_instance_id()
	drones[2].position.x = 5000.0
	director.update_safety(6100.0,6500.0,800.0)
	await process_frame
	check(not is_instance_id_valid(retired_drone_id) and director.get_drone_attack_token_count()==0,"Offscreen retirement releases Drone token and tracking")
	check(route.get_node("TesaSetPiece").post_rest_seconds==2.5,"Tesa is followed by 2.5 seconds without encounter activation")
	var protected = route.get_node("Objects").get_children().filter(func(item): return item.get_meta("reward_after",&"")==&"route_drone_02")
	check(protected.size()==1 and protected[0].kind=="sanguche","Existing sandwich remains gated until the demanding Drone wave ends")

	scene.restart_game()
	await process_frame
	await process_frame
	await process_frame
	var fresh_route = current_scene.get_node("Route38")
	check(fresh_route.encounter_director.get_attack_token_count()==0 and fresh_route.encounter_director.get_hostile_projectile_count()==0,"Restart clears tokens and hostile projectile budget")
	var result := {"passed":failures.is_empty(),"checks":checks,"errors":failures,"hp":{"hipster":2,"agent":3,"grandote":6,"drone":3},"hostile_cap":3,"drone_wave_cap":2,"drone_attack_cap":1}
	var output := FileAccess.open("res://validation/combat_readability_checks.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(result,"  ")+"\n")
	output.close()
	print(JSON.stringify(result))
	root.get_node("AudioManager").stop_all()
	await create_timer(0.3).timeout
	quit(0 if failures.is_empty() else 1)
