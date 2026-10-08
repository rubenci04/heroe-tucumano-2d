extends SceneTree

var checks := 0
var failures: Array[String] = []

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

func run() -> void:
	root.size = Vector2i(800,450)
	var game_session = root.get_node("GameSession")
	var audio_manager = root.get_node("AudioManager")
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.character_select.confirm_selected()
	scene.intro.skip()
	var route = scene.route
	var player = route.player
	route.set_physics_process(false)
	player.set_physics_process(false)
	for hp in [1,2,3]:
		player.health = hp
		var food = route.add_pickup("sanguche","sanguche",100,0,0.25,-1.0,StringName("qol_food_%d" % hp))
		food._on_body_entered(player)
		check(player.health == player.max_health and food.used,"Milanesa fully heals and consumes at HP %d" % hp)
	check(player.fury_time == 10.0,"Existing milanesa fury remains unchanged")
	player.fury_time = 0.0
	player.position = Vector2(3300,GameConfig.GROUND_Y)
	player.set_physics_process(true)
	await frames()
	route.update_last_safe_position()
	player.set_physics_process(false)
	check(route.last_safe_position.distance_to(player.position)<1.0,"Grounded living Player continuously records a real safe position")
	var checkpoint = route.get_node("Checkpoint")
	check(route.checkpoint_records.size()==2,"Two data-driven checkpoints exist in addition to the start")
	check(not route._checkpoint_is_safe(route.checkpoint_records[0]),"Automatic checkpoint waits for prerequisites and a safe break")
	var completed: Array[StringName] = [&"route_wave_01",&"route_micro_01",&"route_micro_02",&"route_wave_02"]
	route.encounter_director.restore_completed_encounters(completed)
	route.get_node("ExpresbusSetPiece").phase = ExpresbusSetPiece.Phase.FINISHED
	route.get_node("ExpresbusSetPiece").spawn_count = 1
	player.position = Vector2(3650,GameConfig.GROUND_Y)
	player.set_physics_process(true)
	await frames()
	check(route._checkpoint_is_safe(route.checkpoint_records[0]),"Checkpoint accepts a safe grounded break after Expresbus")
	route._update_checkpoints()
	player.set_physics_process(false)
	check(game_session.active_checkpoint==&"route_midpoint" and game_session.respawn_position==Vector2(3600,370),"First checkpoint activates and records its position")
	check(game_session.checkpoint_completed_encounters==completed and game_session.checkpoint_sector=="Monteros","Checkpoint snapshots progress and sector")
	player.position = Vector2(4300,370)
	route.last_safe_position = Vector2(4280,370)
	player.health = 1
	player.invulnerability = 0.0
	var lives_before: int = player.lives
	player.take_damage(1,"enemy")
	check(player.lives==lives_before-1 and player.health==player.max_health,"A death consumes exactly one life and restores HP")
	check(player.position==Vector2(4280,370) and player.position!=game_session.respawn_position,"One-life respawn uses the nearby last safe point, never the checkpoint")
	check(player.invulnerability>1.2 and route.encounter_director.get_completed_encounter_ids()==completed,"Respawn preserves progress and the existing 1.25-second immunity")
	check(not route.is_local_respawn_safe(Vector2(4650,370),0),"Stationary truck cannot contain a respawn")
	var near_truck: Dictionary = route.find_local_respawn(Vector2(4650,370),0)
	check(near_truck.found and absf(near_truck.position.x-4650.0)<=256 and route.is_local_respawn_safe(near_truck.position,0),"Vehicle-adjacent respawn finds a nearby safe ground point")
	var enemy = route.spawn_enemy("agente",4280,0)
	enemy.set_physics_process(false)
	check(not route.is_local_respawn_safe(Vector2(4280,370),0),"Enemy body excludes an unsafe last-safe point")
	var near_enemy: Dictionary = route.find_local_respawn(Vector2(4300,370),0)
	check(near_enemy.found and route.is_local_respawn_safe(near_enemy.position,0),"Search replaces a stale unsafe position without checkpoint rollback")
	enemy.queue_free()
	await frames()
	var melee_enemy = route.spawn_enemy("grandote",4500,0)
	melee_enemy.set_physics_process(false)
	melee_enemy.melee_hitbox.activate(1.0)
	check(not route.is_local_respawn_safe(Vector2(4450,370),0),"Active melee volume excludes an otherwise body-clear respawn point")
	melee_enemy.queue_free()
	scene._spawn_projectile(Vector2(4300,330),0,Vector2.LEFT,"coffee","enemy")
	var dangerous_shot = route.get_node("Projectiles").get_child(-1)
	dangerous_shot.set_physics_process(false)
	check(not route.is_local_respawn_safe(Vector2(4300,370),0),"A nearby hostile projectile excludes a respawn")
	route.prepare_local_respawn_safety(Vector2(4300,370),0)
	await frames()
	check(route.is_local_respawn_safe(Vector2(4300,370),0),"Local threat cleanup removes the unsafe projectile without rewinding progress")
	# Coffee orientation is visual-only and remains fixed for both directions/spread.
	for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2(-1,-0.15).normalized()]:
		scene._spawn_projectile(Vector2(4300,100),0,direction,"coffee","enemy")
		var coffee = route.get_node("Projectiles").get_child(-1)
		coffee.set_physics_process(false)
		check(is_equal_approx(coffee.visual.rotation,deg_to_rad(-22)) and not coffee.visual.flip_v,"Boss coffee stays upright regardless of travel direction")
		# Desde el paso del prototipo el café va en arco: velocidad y colisión las fija ArcShot (10 px visibles).
		check(coffee.damage==1 and coffee.get_node_or_null("ArcShot") != null,"Coffee keeps damage and takes the prototype arc toward the player")
		coffee._physics_process(0.01)
		check(coffee.get_node_or_null("ArcShot") != null and coffee.travel_direction.is_finite(),"Coffee keeps its arc after one physics step")
		coffee.queue_free()
	await frames()
	# Use the real Esc path, not only direct state setters.
	var esc := InputEventAction.new()
	esc.action = &"pause"
	esc.pressed = true
	scene._unhandled_input(esc)
	check(paused and scene.pause_menu.visible and scene.pause_menu.can_process(),"Esc pauses gameplay while the menu continues processing")
	var position_before: Vector2 = player.position
	player.set_physics_process(true)
	enemy = route.spawn_enemy("agente",4500,0)
	scene._spawn_projectile(Vector2(4300,100),0,Vector2.LEFT,"coffee","enemy")
	# Spawning through Main is intentionally blocked while paused; add a real fixture shot.
	var shot = load("res://scenes/actors/projectile.tscn").instantiate()
	shot.kind = &"coffee"
	shot.position = Vector2(4400,100)
	route.get_node("Projectiles").add_child(shot)
	var enemy_before: Vector2 = enemy.position
	var shot_before: Vector2 = shot.position
	await create_timer(0.1,true).timeout
	check(player.position==position_before and enemy.position==enemy_before and shot.position==shot_before and not route.can_process(),"Pause freezes Player, enemies and projectiles")
	check(audio_manager.sfx_paused and not audio_manager.music_player.stream_paused,"Pause preserves the existing audio policy")
	scene._unhandled_input(esc)
	await frames()
	check(not paused and not scene.pause_menu.visible and player.controls_enabled,"Esc resumes and expires the UI input edge")
	player.set_physics_process(false)
	enemy.queue_free()
	shot.queue_free()
	await frames()
	# Second checkpoint activates only after the first heavy encounter/Tesa; no content edits.
	completed.append(&"route_wave_04")
	route.encounter_director.restore_completed_encounters(completed)
	route.get_node("TesaSetPiece").phase = ExpresbusSetPiece.Phase.FINISHED
	route.get_node("TesaSetPiece").spawn_count = 1
	player.position = Vector2(5650,370)
	player.set_physics_process(true)
	await frames()
	route._update_checkpoints()
	player.set_physics_process(false)
	check(game_session.active_checkpoint==&"route_after_heavy" and game_session.respawn_position.x==5600,"Second checkpoint activates during a safe break")
	check(not game_session.checkpoint_completed_encounters.has(&"route_wave_06"),"Checkpoint cannot skip the later final escalation")
	player.health = 1
	player.lives = 1
	player.invulnerability = 0.0
	player.take_damage(1,"enemy")
	await create_timer(0.65,true).timeout
	check(player.lives==0 and scene.game_over and scene.current_state==game_session.DemoState.RESULT,"Final life produces Game Over exactly once")
	var restart := InputEventAction.new()
	restart.action = &"restart"
	restart.pressed = true
	scene._unhandled_input(restart)
	await frames(5)
	scene = current_scene
	route = scene.route
	player = route.player
	route.set_physics_process(false)
	player.set_physics_process(false)
	check(scene.current_state==game_session.DemoState.GAMEPLAY and player.position.x==5600 and player.health==player.max_health and player.lives==player.character_definition.starting_lives,"Game Over restart restores checkpoint, full HP and starting lives")
	check(route.encounter_director.is_encounter_completed(&"route_wave_04") and route.encounter_director.get_attack_token_count()==0,"Restored progress and tokens cannot block or duplicate encounters")
	check(route.get_node("Enemies").get_children().all(func(actor): return actor.get_meta("encounter_id",&"") not in completed and actor.position.x>player.position.x+400) and route.get_node("Projectiles").get_child_count()==0 and route.get_node("Vehicles").get_child_count()==0,"Restart removes transient threats; only safe new entries from unfinished encounters may appear")
	check(route.get_node("ExpresbusSetPiece").phase==ExpresbusSetPiece.Phase.FINISHED and route.get_node("TesaSetPiece").phase==ExpresbusSetPiece.Phase.FINISHED,"Already consumed buses never duplicate after checkpoint restart")
	check(route.get_collected_pickup_ids().has(&"qol_food_1") and route.get_node("Terrain").get_children().filter(func(item): return item.is_in_group("stationary_vehicles")).size()==9,"Critical pickup consumption and stationary vehicle instances remain coherent")
	route.encounter_director.add_rest(0.0)
	route.encounter_director.update_activation(5600)
	check(route.encounter_director.is_encounter_activated(&"route_wave_03"),"Unfinished encounters can activate after restoration")
	scene.pause_game()
	scene.pause_menu.get_node("Options/RestartCheckpoint").pressed.emit()
	check(scene.pause_menu.get_node("ConfirmRestart").visible,"Pause restart asks for confirmation")
	scene.pause_menu.get_node("ConfirmRestart").confirmed.emit()
	await frames(5)
	scene = current_scene
	check(not paused and scene.current_state==game_session.DemoState.GAMEPLAY and scene.player.position.x==5600,"Pause restart uses the same checkpoint restore path")
	scene.route.set_physics_process(false)
	scene.player.set_physics_process(false)
	# A new run still resets everything; checkpoint persistence is only within this run.
	scene.restart_game()
	await frames(4)
	check(game_session.active_checkpoint.is_empty() and current_scene.current_state==game_session.DemoState.CHARACTER_SELECT,"Explicit new-run restart still clears checkpoint state")
	print(JSON.stringify({"checks":checks,"passed":failures.is_empty(),"errors":failures}))
	current_scene.queue_free()
	paused = false
	await process_frame
	quit(0 if failures.is_empty() else 1)
