extends SceneTree

var checks := 0
var failures: Array[String] = []
var clock := 0.0
var route
var player
const STEP := 1.0/60.0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool,message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func tick(actors: Array,count: int = 1) -> void:
	for index in range(count):
		clock += STEP
		for actor in actors:
			actor._physics_process(STEP)

func make_actor(kind: String,x: float = 4300.0):
	var actor = route.spawn_enemy(kind,x,0)
	actor.set_physics_process(false)
	actor.contact.collision_mask = 0
	return actor

func run() -> void:
	root.size = Vector2i(800,450)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.character_select.confirm_selected()
	scene.intro.skip()
	scene.set_process(false)
	route = scene.route
	route.set_physics_process(false)
	player = route.player
	player.set_physics_process(false)
	player.position = Vector2(4000,370)
	player.controls_enabled = true
	player.invulnerability = 0.0
	scene.camera.position_smoothing_enabled = false
	scene.camera.position = Vector2(4000,225)
	scene.camera.reset_smoothing()
	await process_frame
	for kind in ["agente","hipster"]:
		clock = 0.0
		var actor = make_actor(kind,4500)
		await physics_frame
		await process_frame
		var shots: Array = []
		actor.shot_requested.connect(func(origin,_lane,direction,projectile,_team): shots.append({"time":clock,"origin":origin,"direction":direction,"kind":projectile}))
		actor._begin_attack()
		actor.execute_attack()
		check(actor.ai_state==actor.AIState.ENTER and shots.is_empty(),kind+": spawn cannot start or execute attack")
		tick([actor],60)
		check(shots.is_empty() and actor.ai_state==actor.AIState.ENTER and actor.position.x<4500,kind+": offscreen ENTER moves without preparing or firing")
		actor.position.x = 4300
		await physics_frame
		await process_frame
		var visible_at := clock
		var seen_react := false
		var seen_prepare := false
		for index in range(100):
			tick([actor])
			if actor.ai_state==actor.AIState.REACT:
				seen_react = true
				check(shots.is_empty(),kind+": REACT has no projectile")
			if actor.ai_state==actor.AIState.TELEGRAPH:
				seen_prepare = true
				check(shots.is_empty() and actor.visual.animation==actor.definition.attack_animation,kind+": existing preparation precedes shot")
			if not shots.is_empty():
				break
		var minimum: float = actor.definition.entry_duration+actor.definition.reaction_time+actor.definition.telegraph_duration
		check(seen_react and seen_prepare,kind+": ENTER → REACT → TELEGRAPH traversed")
		check(not shots.is_empty() and shots[0].time-visible_at>=minimum-0.001 and shots[0].time-visible_at<=1.1,kind+": first useful-view shot occurs between minimum and 1.1 s")
		check(shots[0].kind==("agent_orb" if kind=="agente" else "hipster_coffee"),kind+": projectile identity unchanged")
		check(actor.definition.projectile_definition.damage==1 and actor.definition.projectile_definition.speed==(170.0 if kind=="agente" else 115.0),kind+": projectile damage/speed preserved")
		check(shots[0].origin.is_equal_approx(actor.global_position+Vector2(-22,-58) if kind=="agente" else actor.global_position+Vector2(-24,-42)),kind+": muzzle unchanged")
		for index in range(100):
			if actor.ai_state==actor.AIState.RECOVERY:
				break
			tick([actor])
		var recovery_shots := shots.size()
		tick([actor],int(actor.definition.recovery_duration/STEP)-1)
		check(actor.ai_state==actor.AIState.RECOVERY and shots.size()==recovery_shots,kind+": recovery prevents consecutive attack")
		tick([actor],2)
		check(actor.ai_state==actor.AIState.REPOSITION,kind+": recovery enters reposition decision")
		actor.position.x = 4050
		await physics_frame
		await process_frame
		var before_retreat: float = actor.position.x
		tick([actor],5)
		check(actor.position.x>before_retreat,kind+": too-close ranged enemy retreats towards preferred distance")
		tick([actor],20)
		check(actor.ai_state==actor.AIState.REACT,kind+": reposition returns to reaction/decision")
		actor.position.x = 4300
		actor.attack_cooldown = 0.0
		actor._state_remaining = 0.0
		actor._begin_attack()
		player.lives -= 1
		player.invulnerability = 1.4
		var before_respawn := shots.size()
		tick([actor],100)
		check(actor.ai_state==actor.AIState.ENTER and shots.size()==before_respawn and player.invulnerability==1.4,kind+": life loss cancels pending attack and preserves respawn protection duration")
		player.invulnerability = 0.0
		tick([actor],10)
		check(shots.size()==before_respawn,kind+": respawn restarts reading window")
		actor.queue_free()
		for projectile in route.get_node("Projectiles").get_children():
			projectile.queue_free()
		await process_frame
	# Simultaneous standalone spawns verify deterministic staggering independent of token grants.
	clock = 0.0
	var first = make_actor("agente")
	var second = make_actor("agente")
	await physics_frame
	await process_frame
	var first_times: Array = []
	var second_times: Array = []
	first.shot_requested.connect(func(_a,_b,_c,_d,_e): first_times.append(clock))
	second.shot_requested.connect(func(_a,_b,_c,_d,_e): second_times.append(clock))
	tick([first,second],100)
	check(first_times.size()==1 and second_times.size()==1 and second_times[0]-first_times[0]>=0.08 and second_times[0]-first_times[0]<=0.20,"Simultaneous first actions stagger deterministically by about 0.12 s")
	var grandote = make_actor("grandote")
	check(grandote.ai_state==grandote.AIState.CHASE and not grandote.uses_ranged_lifecycle(),"Grandote retains existing AI without ranged lifecycle")
	# Diagnose the smoke's collection block independently of live enemy cadence.
	player.health = player.max_health
	player.hit_time = 0.0
	player.invulnerability = 0.0
	player.oranges_unlocked = false
	player.stones = 0
	var orange = route.add_pickup("orange_tree","arbol_naranjas",4000,0,0.85,370.0,&"lifecycle_collection_orange")
	orange._on_body_entered(player)
	player._update_collection(0.399)
	var collection_time: float = player.collection_remaining
	scene.pause_game()
	await create_timer(0.1,true,false,true).timeout
	check(player.collection_active and player.collection_remaining==collection_time and not player.oranges_unlocked,"Isolated collection/pause retains timing and pending reward")
	scene.resume_game()
	player._update_collection(0.002)
	check(player.oranges_unlocked and orange.used,"Isolated orange reward occurs exactly once at 0.4 s")
	player._update_collection(0.2)
	check(not player.collection_active and player.controls_enabled and player.state==player.State.IDLE,"Isolated orange collection returns controls")
	var stones = route.add_pickup("stone_pile","montaña_cascote",4000,0,0.65,370.0,&"lifecycle_collection_stones")
	stones._on_body_entered(player)
	player._update_collection(0.401)
	check(stones.used and player.stones==20,"Isolated stone collection grants twenty once")
	player._update_collection(0.2)
	check(not player.collection_active and player.controls_enabled,"Isolated stone collection returns controls")
	var interrupted = route.add_pickup("stone_pile","montaña_cascote",4000,0,0.65,370.0,&"lifecycle_collection_interrupted")
	interrupted._on_body_entered(player)
	var incoming = load("res://data/attacks/super_rush.tres").duplicate()
	incoming.damage = 1
	var accepted: bool = player.hurtbox.receive_attack(first,&"enemy",0,incoming)
	check(accepted and not player.collection_active and not interrupted.used and player.stones==20,"A legitimate hostile hit cancels collection; smoke must isolate unrelated live attacks")
	var result := {"passed":failures.is_empty(),"checks":checks,"errors":failures,"minimum_first_shot":0.95,"stagger":0.12}
	print(JSON.stringify(result))
	scene.queue_free()
	for index in range(3):
		await physics_frame
		await process_frame
	quit(0 if failures.is_empty() else 1)
