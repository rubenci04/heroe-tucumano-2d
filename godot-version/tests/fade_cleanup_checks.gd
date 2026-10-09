extends SceneTree
## Cadáveres y manchas se desvanecen (con parpadeo) y se liberan: cuerpo en el suelo ≤ 2 s, mancha ≤ 2 s.

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
	var CFG = load("res://scripts/prototype/feel_config.gd")
	expect(CFG.DEATH_LINGER+CFG.DEATH_FADE <= 2.0 and CFG.DEATH_LINGER_HEAVY+CFG.DEATH_FADE <= 2.0,"Cuerpo en el suelo + parpadeo ≤ 2 s",{})
	expect(CFG.STAIN_DURATION <= 2.0,"La mancha dura ≤ 2 s",{})
	route.player.health_component.set_invulnerability(100000.0)
	for archetype in ["agente","grandote"]:
		var before: Dictionary = {}
		for child in route.get_children():
			before[child.get_instance_id()] = true
		var enemy = route.spawn_enemy(archetype,route.player.position.x+200.0,0)
		await process_frame
		enemy.take_damage(999,&"player")
		await process_frame
		var ghosts: Array[Node] = []
		for child in route.get_children():
			if child is AnimatedSprite2D and not before.has(child.get_instance_id()):
				ghosts.append(child)
		expect(not ghosts.is_empty(),"%s deja un cuerpo visible" % archetype,{})
		var elapsed := 0.0
		var saw_blink := false
		while elapsed < 4.0 and ghosts.any(func(g): return is_instance_valid(g)):
			await process_frame
			elapsed += scene.get_process_delta_time()
			for g in ghosts:
				if is_instance_valid(g) and g.modulate.a > 0.0 and g.modulate.a < 0.95:
					saw_blink = true
		var limit: float = CFG.ENEMY_DEATH_DURATION+(CFG.DEATH_LINGER_HEAVY if archetype == "grandote" else CFG.DEATH_LINGER)+CFG.DEATH_FADE+0.4
		expect(not ghosts.any(func(g): return is_instance_valid(g)) and elapsed <= limit,"%s: el cuerpo se libera tras desvanecerse" % archetype,{"elapsed":elapsed,"limit":limit})
		expect(saw_blink,"%s: el cuerpo parpadea/desvanece antes de liberarse" % archetype,{})
	route.stains.add_stain(Vector2(route.player.position.x+100.0,GameConfig.GROUND_Y))
	var stain: Node2D = route.stains.stains[-1]
	var elapsed := 0.0
	while elapsed < 3.0 and is_instance_valid(stain):
		await process_frame
		elapsed += scene.get_process_delta_time()
	expect(not is_instance_valid(stain) and elapsed <= CFG.STAIN_DURATION+0.3,"La mancha se libera en ≤ 2 s",{"elapsed":elapsed})
	scene.queue_free()
	await process_frame
	print("FADE_CLEANUP_CHECKS %d/%d" % [checks-failures.size(),checks])
	quit(0 if failures.is_empty() else 1)
