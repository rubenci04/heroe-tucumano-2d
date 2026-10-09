extends SceneTree
## Lanzar corriendo: correr_lanzar (cuadros nuevos), salida en el cuadro 2, latencia Z→proyectil ≤ 0,10 s,
## velocidad horizontal sin cortes y regreso al ciclo de correr. Parado conserva el lanzamiento actual.

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

func throw_and_measure(route: Node, player: CharacterBody2D, kind: String) -> Dictionary:
	var container: Node = route.get_node("Projectiles")
	for child in container.get_children():
		child.queue_free()
	await physics_frame
	player.shot_cooldown = 0.0
	var speed_before := player.velocity.x
	var started := Time.get_ticks_usec()
	var frames := 0
	player.throw_projectile(kind)
	var animation: StringName = player.visual.animation
	var min_speed := absf(player.velocity.x)
	while container.get_child_count() == 0 and frames < 60:
		await physics_frame
		frames += 1
		min_speed = minf(min_speed,absf(player.velocity.x))
		if frames == 1:
			animation = player.visual.animation
	return {"frames": frames, "latency": frames/60.0, "animation": animation, "min_speed": min_speed, "speed_before": absf(speed_before)}

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
	var player: CharacterBody2D = route.player
	player.health_component.set_invulnerability(100000.0)
	player.oranges_unlocked = true
	player.stones = 50
	route.encounter_director._rest_remaining = 1000000.0
	for direction in ["move_right","move_left"]:
		player.position.x = 2000.0
		Input.action_press(direction)
		for i in 20:
			await physics_frame
		for kind in ["orange","stone"]:
			var m: Dictionary = await throw_and_measure(route,player,kind)
			var tag := "%s %s" % [direction,kind]
			expect(m.animation == &"correr_lanzar","Corriendo lanza con correr_lanzar (%s)" % tag,m)
			expect(m.latency <= 0.1001,"Latencia Z→proyectil ≤ 0,10 s (%s)" % tag,m)
			expect(m.min_speed >= m.speed_before-0.01 and m.speed_before > 100.0,"La velocidad horizontal no se corta (%s)" % tag,m)
			expect(player.visual.flip_h == (direction == "move_left"),"Respeta la dirección (flip_h) (%s)" % tag,{"flip":player.visual.flip_h})
			expect(String(player.visual.sprite_frames.get_frame_texture(&"correr_lanzar",0).resource_path).begins_with("res://characters/"),"correr_lanzar es NUEVO",{})
			# Termina y vuelve al ciclo de correr en el cuadro de reanudación.
			for i in 30:
				await physics_frame
			expect(player.visual.animation == player.character_definition.run_animation,"Vuelve al ciclo correr",{"anim":player.visual.animation})
			for i in 25:
				await physics_frame
		Input.action_release(direction)
		for i in 10:
			await physics_frame
	# Parado: lanzamiento actual (cuadros viejos).
	player.velocity.x = 0.0
	await physics_frame
	var standing: Dictionary = await throw_and_measure(route,player,"orange")
	expect(standing.animation == player.character_definition.throw_orange_animation,"Parado mantiene el lanzamiento actual",standing)
	scene.queue_free()
	await process_frame
	print("RUN_THROW_CHECKS %d/%d" % [checks-failures.size(),checks])
	quit(0 if failures.is_empty() else 1)
