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

func clear_projectiles(route: Node) -> void:
	for projectile in route.get_node("Projectiles").get_children():
		projectile.queue_free()
	await process_frame

func set_decide(boss: PalermitanoBoss) -> void:
	boss.boss_state = boss.BossState.DECIDE
	boss.current_pattern = boss.Pattern.NONE
	boss.chain_hitbox.deactivate()

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
	route.set_physics_process(false)
	player.set_physics_process(false)
	player.position = Vector2(7200,GameConfig.GROUND_Y)
	var boss: PalermitanoBoss = route.spawn_palermitano(7600,0)
	route.boss_director.skip_intro() # estos tests miden el combate; la intro de 2 s tiene su propio flujo
	boss.set_physics_process(false)
	var patterns: Array[int] = []
	boss.pattern_started.connect(func(pattern: int): patterns.append(pattern))

	# 1. A full 1.25 seconds passes before the first telegraph begins.
	boss._physics_process(0.99)
	check(boss.boss_state==boss.BossState.INTRO and patterns.is_empty(),"Boss remains readable and inert throughout its one-second entrance")
	boss._physics_process(0.02)
	boss._physics_process(0.24)
	check(boss.boss_state==boss.BossState.DECIDE and patterns.is_empty(),"Decision window keeps the boss non-offensive until 1.25 seconds")
	boss._physics_process(0.02)
	check(boss.boss_state==boss.BossState.TELEGRAPH and patterns.size()==1 and route.get_node("Projectiles").get_child_count()==0 and boss.get_live_summon_count()==0,"First action begins as a telegraph without projectile, summon or hitbox")

	# 2/4/5. Triple coffee has a readable tell, three spaced shots and recovery.
	set_decide(boss)
	boss.last_pattern = boss.Pattern.SUMMON_AGENTS
	boss._coffee_cooldown_remaining = 0.0
	check(boss.begin_pattern(boss.Pattern.TRIPLE_COFFEE),"Triple coffee can begin from a clean decision state")
	boss._process_telegraph(0.54)
	check(boss.coffee_projectiles_emitted==0 and route.get_node("Projectiles").get_child_count()==0,"Coffee telegraph emits nothing before 0.55 seconds")
	boss._process_telegraph(0.02)
	check(boss.coffee_projectiles_emitted==1,"First coffee appears only after the telegraph")
	boss._process_attack(0.27)
	check(boss.coffee_projectiles_emitted==1,"Second coffee respects the 0.28-second interval")
	boss._process_attack(0.02)
	boss._process_attack(0.28)
	check(boss.coffee_projectiles_emitted==3 and route.get_node("Projectiles").get_child_count()==3,"Triple coffee emits exactly three independently spaced cups")
	boss._process_attack(0.02)
	check(boss.boss_state==boss.BossState.RECOVERY and is_equal_approx(boss._state_remaining,boss.coffee_recovery),"Triple coffee enters its explicit recovery window")
	await clear_projectiles(route)

	# 3/4/5. Chain remains short range and cannot hit during anticipation.
	set_decide(boss)
	boss.last_pattern = boss.Pattern.TRIPLE_COFFEE
	boss._chain_cooldown_remaining = 0.0
	player.position.x = boss.position.x-100.0
	check(boss.begin_pattern(boss.Pattern.CHAIN) and not boss.chain_hitbox.active,"Chain begins at short range with an inactive hitbox")
	boss._process_telegraph(0.47)
	check(not boss.chain_hitbox.active,"Chain cannot hit before its 0.48-second anticipation completes")
	boss._process_telegraph(0.02)
	check(boss.chain_hitbox.active and boss.chain_hitbox.damage==2,"Chain activates once after its communicated startup")
	boss._process_attack(0.14)
	check(not boss.chain_hitbox.active and boss.boss_state==boss.BossState.RECOVERY and is_equal_approx(boss._state_remaining,0.75),"Chain closes before its 0.75-second punishable recovery")

	# 6/7. Summons enter one at a time and never exceed two live Agents.
	set_decide(boss)
	boss.last_pattern = boss.Pattern.CHAIN
	boss._summon_cooldown_remaining = 0.0
	player.position.x = boss.position.x-300.0
	check(boss.begin_pattern(boss.Pattern.SUMMON_AGENTS),"A clean summon pattern can begin")
	boss._process_telegraph(boss.summon_telegraph)
	check(boss.get_live_summon_count()==1 and boss.summon_requests_emitted==1,"First summon introduces exactly one Agent")
	set_decide(boss)
	boss.last_pattern = boss.Pattern.TRIPLE_COFFEE
	boss._summon_cooldown_remaining = 0.0
	check(boss.begin_pattern(boss.Pattern.SUMMON_AGENTS),"A later summon can introduce the second Agent")
	boss._process_telegraph(boss.summon_telegraph)
	check(boss.get_live_summon_count()==2,"Second telegraphed summon reaches the absolute two-Agent cap")
	set_decide(boss)
	boss._summon_cooldown_remaining = 0.0
	check(not boss.begin_pattern(boss.Pattern.SUMMON_AGENTS),"No additional summon is accepted while two Agents live")

	# 8. Adds suppress coffee, and any live hostile projectile suppresses chain/summon.
	boss._coffee_cooldown_remaining = 0.0
	check(not boss.begin_pattern(boss.Pattern.TRIPLE_COFFEE),"Live summoned Agents suppress triple coffee pressure")
	for summon_ref: WeakRef in boss._summons:
		var summon = summon_ref.get_ref()
		if is_instance_valid(summon):
			summon.queue_free()
	await process_frame
	scene._spawn_projectile(Vector2(7400,300),0,Vector2.LEFT,"coffee","enemy")
	set_decide(boss)
	boss._chain_cooldown_remaining = 0.0
	boss._summon_cooldown_remaining = 0.0
	player.position.x = boss.position.x-100.0
	check(not boss.begin_pattern(boss.Pattern.CHAIN) and not boss.begin_pattern(boss.Pattern.SUMMON_AGENTS),"A live hostile projectile prevents chain and summon overlap")
	await clear_projectiles(route)

	# 9/10/11. Defeat is single-shot, cancels pressure, cleans adds/projectiles and restart is clean.
	set_decide(boss)
	boss.last_pattern = boss.Pattern.CHAIN
	boss._summon_cooldown_remaining = 0.0
	player.position.x = boss.position.x-300.0
	boss.begin_pattern(boss.Pattern.SUMMON_AGENTS)
	boss._process_telegraph(boss.summon_telegraph)
	scene._spawn_projectile(Vector2(7450,300),0,Vector2.LEFT,"coffee","enemy")
	var closing_count := [0]
	scene.demo_closing_started.connect(func(): closing_count[0] += 1)
	var score_before: int = player.score
	var boss_reward: int = boss.reward_points
	var boss_hp: int = boss.max_health
	var coffee_interval: float = boss.coffee_shot_interval
	var max_agents: int = boss.max_live_summons
	boss.health_component.set_invulnerability(0.0)
	boss.take_damage(999,&"player")
	boss.take_damage(999,&"player")
	check(not boss.active and boss.boss_state==boss.BossState.DEFEATED and not boss.chain_hitbox.active,"Defeated Palermitano stops every pending attack")
	check(closing_count[0]==1 and player.score==score_before+boss_reward,"Victory and boss reward trigger exactly once")
	await process_frame
	check(route.get_node("Enemies").get_child_count()==0 and route.get_node("Projectiles").get_child_count()==0,"Victory cleanup removes summoned Agents and hostile projectiles")
	while scene.get_node("Interface/DialogueBox").active:
		scene.get_node("Interface/DialogueBox").advance()
	await process_frame
	check(scene.current_state==GameSession.DemoState.RESULT,"Boss ending reaches RESULT after cleanup")
	scene.restart_game()
	await process_frame
	await process_frame
	var fresh_scene = current_scene
	check(fresh_scene.current_state==GameSession.DemoState.CHARACTER_SELECT and fresh_scene.get_node("Route38/Enemies").get_child_count()==0 and fresh_scene.get_node("Route38/Projectiles").get_child_count()==0,"Restart leaves no boss, summon or projectile duplication")

	var estimated_seconds := float(boss_hp)/(4.0*0.40)
	check(estimated_seconds>=45.0 and estimated_seconds<=75.0,"Ninety HP estimates to a 45-75 second first-clear window at realistic attack uptime")
	var result := {"passed":failures.is_empty(),"checks":checks,"errors":failures,"hp":boss_hp,"estimated_seconds":estimated_seconds,"coffee_speed":load("res://data/projectiles/coffee.tres").speed,"coffee_interval":coffee_interval,"max_agents":max_agents}
	var output := FileAccess.open("res://validation/palermitano_boss_checks.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(result,"  ")+"\n")
	output.close()
	print(JSON.stringify(result))
	root.get_node("AudioManager").stop_all()
	fresh_scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
