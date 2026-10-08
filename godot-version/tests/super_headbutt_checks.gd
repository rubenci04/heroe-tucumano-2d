extends SceneTree

var checks := 0
var failures: Array[String] = []
var scene
var route
var player

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool,message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func frames(count: int = 3) -> void:
	for index in range(count):
		await physics_frame

func ready_player(x: float = 1000.0) -> void:
	player.cancel_tucumanazo()
	player.position = Vector2(x,370)
	player.velocity = Vector2.ZERO
	player.health = player.max_health
	player.hit_time = 0.0
	player.fury_time = 0.0
	player.shot_cooldown = 0.0
	player.invulnerability = 0.0
	player.controls_enabled = true
	player.cancel_collection()
	player.facing = 1
	player.tucumanazo_counter.reset_full()
	await frames(4)

func wait_phase(phase: int) -> void:
	for index in range(180):
		if player.special_phase == phase:
			return
		await physics_frame
	check(false,"Requested Super phase reached within bounded time")

func run() -> void:
	root.size = Vector2i(800,450)
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.character_select.confirm_selected()
	scene.intro.skip()
	route = scene.route
	player = route.player
	route.set_physics_process(false)
	route.encounter_director.set_physics_process(false)
	# Isolate ability input from automatic roadside collection during this fixture.
	for pickup in route.get_node("Objects").get_children():
		pickup.queue_free()
	await ready_player()
	var definition = player.tucumanazo_definition
	check(definition.is_valid() and definition.damage == 5 and definition.rush_attack.damage == 2,"Existing final damage retained; contact damage lower")
	check(definition.startup_duration >= 0.10 and definition.startup_duration <= 0.18,"Startup stays in approved interval")
	Input.action_press("tucumanazo")
	await frames(2)
	Input.action_release("tucumanazo")
	check(player.special_active and player.state == player.State.SUPER_STARTUP,"Semantic input starts grounded Super startup")
	check(player.tucumanazo_counter.current_uses == 4 and not player.start_tucumanazo(),"Exactly one charge, overlapping activation rejected")
	check(not player.super_rush_hitbox.active and not player.tucumanazo_hitbox.active,"Startup has no offensive hitbox")
	await wait_phase(player.SpecialPhase.RUSH)
	var start_x: float = player.position.x-player.special_rush_distance
	check(is_equal_approx(player.special_rush_speed,player.walk_speed*2.2),"Rush speed derives from base walk speed")
	var enemy = route.spawn_enemy("grandote",player.position.x+45,0)
	enemy.set_physics_process(false)
	await frames(2)
	player._poll_super_hitbox(player.super_rush_hitbox,player.global_position,player.global_position+Vector2(50,0))
	check(enemy.health == 4,"Rush contact damages a six-HP enemy by two")
	check(enemy._super_stagger_remaining > 0 and enemy._super_knockback_speed > 0,"Rush applies short directional stagger/knockback")
	var pushed_from: float = enemy.position.x
	enemy.set_physics_process(true)
	Input.action_press("move_left")
	Input.action_press("jump")
	var projectiles_before: int = route.get_node("Projectiles").get_child_count()
	player.throw_projectile("orange")
	player.start_punch()
	check(not player.punch_active and route.get_node("Projectiles").get_child_count()==projectiles_before,"Normal attacks blocked during Rush")
	var hp_before: int = player.health
	enemy._process_contact_damage()
	player.take_damage(1,"enemy")
	check(player.health == hp_before and player.special_active,"Weak body contact cannot interrupt Rush")
	await frames(12)
	check(enemy.position.x > pushed_from and enemy.health == 4,"Knockback moves enemy without repeated Rush damage")
	check(player.facing == 1 and player.position.x > start_x and player.is_on_floor(),"Opposite movement and jump cannot steer Rush")
	Input.action_release("move_left")
	Input.action_release("jump")
	enemy.queue_free()
	await wait_phase(player.SpecialPhase.FINISH)
	check(absf(player.position.x-start_x-240.0)<1.0,"Unobstructed Rush covers exactly 240 pixels")
	check(not player.super_rush_hitbox.active and not player.tucumanazo_hitbox.active,"Finish windup separates Rush from strong impact")
	var final_enemy = route.spawn_enemy("grandote",player.position.x+70,0)
	final_enemy.set_physics_process(false)
	await frames(2)
	await wait_phase(player.SpecialPhase.ACTIVE)
	await frames(2)
	check(final_enemy.health == 1 and player.tucumanazo_hitbox.active,"Final applies original five damage during active window")
	check(player._special_hit_stop_used and player.visual.frame == 2,"Strong impact uses existing Headbutt impact frame and hit-stop")
	await wait_phase(player.SpecialPhase.RECOVERY)
	check(not player.tucumanazo_hitbox.active and player.special_active,"Recovery disables damage but retains control lock")
	await wait_phase(player.SpecialPhase.READY)
	check(not player.special_active and final_enemy.health==1,"Recovery returns control without final multihit")
	Input.action_press("move_right")
	var recovered_x: float = player.position.x
	await frames(4)
	Input.action_release("move_right")
	check(player.position.x > recovered_x,"Manual movement resumes after recovery")
	final_enemy.queue_free()
	await ready_player()
	player.facing = -1
	check(player.start_tucumanazo(),"Left-facing Super starts")
	await wait_phase(player.SpecialPhase.RUSH)
	await frames(4)
	check(player.position.x < 1000 and player.special_direction == -1,"Left Rush moves and hits towards locked initial facing")
	scene.pause_game()
	var paused_position: Vector2 = player.position
	var paused_time: float = player.special_phase_remaining
	await create_timer(0.12,true,false,true).timeout
	check(player.position == paused_position and is_equal_approx(player.special_phase_remaining,paused_time),"Pause freezes Rush motion and timing")
	scene.resume_game()
	await frames(4)
	check(player.position.x < paused_position.x,"Resume continues same Rush")
	player.health_component.take_damage(1,&"enemy_projectile")
	check(not player.special_active and not player.super_rush_hitbox.active,"Dangerous hostile damage interrupts and cleans Rush")
	await ready_player()
	player.start_tucumanazo()
	await wait_phase(player.SpecialPhase.RUSH)
	player.health = 1
	player.health_component.take_damage(1,&"enemy_projectile")
	await frames(4)
	check(not player.special_active and not player.super_rush_hitbox.active and not player.tucumanazo_hitbox.active,"Life loss/respawn clears both hitboxes and Super state")
	await ready_player()
	player.position.y -= 100
	await frames(2)
	check(not player.start_tucumanazo() and player.tucumanazo_counter.current_uses == 5,"Air activation rejected without charge consumption")
	await ready_player()
	var wall := StaticBody2D.new()
	wall.position = Vector2(1100,330)
	wall.collision_layer = GameConfig.WORLD_LAYER
	var wall_shape := CollisionShape2D.new()
	wall_shape.shape = RectangleShape2D.new()
	wall_shape.shape.size = Vector2(20,100)
	wall.add_child(wall_shape)
	route.add_child(wall)
	await frames(2)
	player.start_tucumanazo()
	await wait_phase(player.SpecialPhase.FINISH)
	check(player.position.x < 1090 and player.special_rush_distance < 240,"Solid wall stops Rush early without tunnelling")
	wall.queue_free()
	await ready_player()
	var vehicle = get_nodes_in_group("stationary_vehicles")[0]
	player.position = Vector2(vehicle.position.x,route._platform_roof_y(vehicle)-1)
	player.velocity = Vector2.ZERO
	await frames(4)
	check(player.is_on_floor() and player.start_tucumanazo(),"Grounded vehicle roof allows Super")
	await wait_phase(player.SpecialPhase.FINISH)
	check(player.position.x > vehicle.position.x and player.position.y >= route._platform_roof_y(vehicle)-2,"Rush clears one-way roof without wedging or teleporting")
	await ready_player(7350)
	var boss = route.spawn_palermitano(7470,0)
	route.boss_director.skip_intro() # la intro de 2 s bloquea controles: este test mide la pelea
	boss.set_physics_process(false)
	await frames(2)
	var boss_hp: int = boss.health
	player.start_tucumanazo()
	await wait_phase(player.SpecialPhase.RUSH)
	player._poll_super_hitbox(player.super_rush_hitbox,player.global_position,boss.global_position)
	check(boss.health == boss_hp-2 and boss.position.x == 7470,"Boss receives Rush damage without displacement")
	player._begin_super_finish()
	await wait_phase(player.SpecialPhase.ACTIVE)
	await frames(2)
	check(boss.health == boss_hp-7,"Boss can receive independent strong final after Rush invulnerability expires")
	boss.queue_free()
	await ready_player(7930)
	route.boss_active = true
	player.start_tucumanazo()
	await wait_phase(player.SpecialPhase.FINISH)
	check(player.position.x <= route.BOSS_ARENA_BOUNDS.y,"Boss arena clamp remains respected")
	route.boss_active = false
	await ready_player()
	player.health = 1
	player.tucumanazo_counter.set_uses(1)
	player.collect("sanguche")
	check(player.health == player.max_health and player.tucumanazo_counter.current_uses == 5,"Milanesa restores full HP and full existing Super stock")
	check(player.fury_time == 10.0 and scene.hud.special_status.text == "TUCUMANAZO x5","Milanesa preserves fury and synchronizes HUD counter")
	player.fury_time = 0.0
	var collection = route.add_pickup("orange_tree","arbol_naranjas",player.position.x,0,0.85,370.0,&"super_collection_probe")
	collection._on_body_entered(player)
	player.set_physics_process(false)
	var collection_origin: Vector2 = player.position
	var player_shots: Array = []
	var fire_probe := func(_origin,_lane,_direction,kind,_team): player_shots.append(kind)
	player.shot_requested.connect(fire_probe)
	Input.action_press("move_right")
	Input.action_press("jump")
	var hostile_count_before: int = route.get_node("Projectiles").get_child_count()
	scene._spawn_projectile(Vector2(2200,250),0,1,"agent_orb","enemy")
	await frames(3)
	Input.action_release("move_right")
	Input.action_release("jump")
	player.throw_projectile("orange")
	player.begin_lane_change(1)
	check(player.collection_active and player.position == collection_origin and not player.changing_lane and not player.start_tucumanazo() and player_shots.is_empty(),"Collection blocks Player movement/attacks/Super even when enemy projectile count changes")
	check(route.get_node("Projectiles").get_child_count() > hostile_count_before,"Hostile shots can legitimately alter scene total during collection")
	player.shot_requested.disconnect(fire_probe)
	player.cancel_collection()
	collection.queue_free()
	player.set_physics_process(true)
	await ready_player()
	player.start_tucumanazo()
	await frames(10)
	player.health = 1
	player.lives = 1
	player.invulnerability = 0.0
	player.health_component.take_damage(1,&"enemy_projectile")
	check(player.state == player.State.DEATH and not player.special_active and not player.super_rush_hitbox.active,"Final-life death cancels Rush without leaving damage areas")
	scene.restart_from_checkpoint()
	await frames(4)
	scene = current_scene
	check(not scene.route.player.special_active and not scene.route.player.super_rush_hitbox.active and is_equal_approx(Engine.time_scale,1.0),"Checkpoint restart has no residual Rush or hit-stop")
	scene.queue_free()
	await frames(3)
	print("Super Headbutt checks: %d/%d PASS" % [checks-failures.size(),checks])
	quit(0 if failures.is_empty() else 1)
