extends SceneTree
## Validación del game feel del prototipo (impacto, muertes, proyectiles, jefe, HUD, parallax).
## Godot --headless --path godot-version --script res://tools/prototype_feel_checks.gd
const CFG = preload("res://scripts/prototype/feel_config.gd")
var checks := 0
var failures := 0
var arena: Node


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)


func _initialize() -> void:
	_run.call_deferred()


func _frames(count: int) -> void:
	for _i in count:
		await process_frame


func _enemy(archetype: String) -> Node:
	for enemy in arena.enemies.get_children():
		if enemy.get("archetype") == archetype or (archetype == "palermitano" and enemy.get("boss_state") != null):
			return enemy
	return null


func _run() -> void:
	arena = load("res://scenes/prototype/pixel_arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await _frames(2)
	await _check_impact()
	await _check_death()
	arena.queue_free()
	await process_frame
	Engine.time_scale = 1.0
	print("PROTOTYPE_FEEL %d/%d PASS, %d FAIL" % [checks - failures, checks, failures])
	quit(0 if failures == 0 else 1)


func _check_impact() -> void:
	var feel: Node = arena.feel
	var agent := _enemy("agente")
	var grandote := _enemy("grandote")
	var boss := _enemy("palermitano")
	for enemy in arena.enemies.get_children():
		enemy.set_physics_process(false)
	arena.player.set_physics_process(false)
	arena.anim.set_process(false)
	for character in ["agente", "hipster", "grandote", "palermitano"]:
		var profile: Dictionary = CFG.impact_profile(character)
		check(int(profile.hitstop) >= 2 and int(profile.hitstop) <= 4, "Hit-stop stays within 2-4 frames: " + character)
	check(int(CFG.impact_profile("grandote").hitstop) > int(CFG.impact_profile("agente").hitstop), "Grandote hit-stop stronger than Agente")
	check(float(CFG.impact_profile("palermitano").shake) > float(CFG.impact_profile("agente").shake), "Boss shake stronger than Agente")
	# Light enemy: knockback moves it away from Ciruja, flash material appears, time freezes.
	agent.global_position.x = arena.player.global_position.x + 60.0
	var start_x: float = agent.global_position.x
	agent.health_component.take_damage(1, &"player")
	check(feel._hitstop_frames >= 2 and Engine.time_scale < 0.1, "Hit-stop frames requested on connect")
	check(agent.visual.material is ShaderMaterial, "White flash material applied to the hurt sprite")
	check(feel._shake_intensity >= float(CFG.impact_profile("agente").shake) * CFG.IMPACT_STRENGTH_MIN, "Camera shake proportional to the blow")
	for _i in 6:
		feel._physics_process(1.0 / 60.0)
	check(agent.global_position.x > start_x, "Knockback pushes the enemy away from Ciruja")
	for _i in 8:
		await process_frame
	check(Engine.time_scale == 1.0, "Time scale returns to normal after hit-stop")
	check(agent.visual.material == null, "Flash ends after its configured frames")
	# Heavy enemy reacts with more shake and hit-stop but less displacement.
	grandote.global_position.x = arena.player.global_position.x + 70.0
	var g_start: float = grandote.global_position.x
	var a_start: float = agent.global_position.x
	agent.health_component.set_current_health(agent.health_component.max_health)
	feel._shake_intensity = 0.0
	feel._shake_time = 0.0
	grandote.health_component.take_damage(1, &"player")
	var grandote_shake: float = feel._shake_intensity
	check(feel._hitstop_frames >= int(CFG.impact_profile("grandote").hitstop), "Grandote requests the stronger hit-stop")
	feel._knock.erase(agent)
	for _i in 30:
		feel._physics_process(1.0 / 60.0)
	check(grandote.global_position.x - g_start < 30.0 and grandote.global_position.x > g_start, "Grandote slides back less than light enemies")
	check(grandote_shake > float(CFG.impact_profile("agente").shake), "Grandote shake exceeds a light enemy's")
	check(a_start > 0.0 and boss != null, "Enemies resolved")
	await _frames(8)
	Engine.time_scale = 1.0


func _ghost_for(character_animation: StringName) -> AnimatedSprite2D:
	for child in arena.world.get_children():
		if child is AnimatedSprite2D and child.animation == character_animation and child.z_index == 15:
			return child
	return null


func _check_death() -> void:
	var feel: Node = arena.feel
	var grandote := _enemy("grandote")
	grandote.set_physics_process(false)
	Engine.time_scale = 1.0
	feel._hitstop_frames = 0
	feel.fx._particles.clear()
	grandote.health_component.restore_full(true)
	grandote.health_component.take_damage(999, &"player")
	check(feel._slowmo_until_ms > Time.get_ticks_msec() and is_equal_approx(feel._slowmo_scale, float(CFG.DEATH_SLOWMO.grandote.scale)), "Big enemy death triggers slow motion")
	feel._hitstop_frames = 0
	feel._apply_time_scale()
	check(Engine.time_scale < 1.0, "Slow motion lowers the time scale")
	var ghost := _ghost_for(&"Death")
	check(ghost != null, "Dying enemy leaves a body that plays its Death frames")
	var ground_before: int = 0
	for _i in 120:
		await process_frame
	Engine.time_scale = 1.0
	feel._slowmo_until_ms = 0
	check(feel.fx._particles.size() > ground_before, "Fall raises ground dust")
	check(is_instance_valid(ghost), "Body persists while Death plays")
	if is_instance_valid(ghost):
		ghost.animation_finished.emit()
		await create_timer(0.4).timeout
		check(is_instance_valid(ghost) and is_equal_approx(ghost.modulate.a, 1.0), "Body stays visible after the fall before fading")
		ghost.queue_free()
	var agent := _enemy("agente")
	check(CFG.DEATH_SLOWMO.has("grandote") and not CFG.DEATH_SLOWMO.has("agente") and agent != null, "Only big enemies get slow motion")
