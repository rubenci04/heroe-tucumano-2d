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
	await _check_projectiles()
	await _check_boss()
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


func _check_projectiles() -> void:
	var feel: Node = arena.feel
	var hipster := _enemy("hipster")
	var agent := _enemy("agente")
	var boss := _enemy("palermitano")
	for kind in ["bottle", "hipster_coffee"]:
		arena._spawn_projectile(hipster.global_position + Vector2(-24, -42), 0, -1, kind, "enemy", hipster)
		var projectile: Node = arena.projectiles.get_child(-1)
		projectile.set_physics_process(false)
		check(projectile.has_node("TrailFx") and projectile.has_node("ShadowFx"), "Projectile has trail and ground shadow: " + kind)
		var start_rotation: float = projectile.visual.rotation
		var seen_hop := 0.0
		for _i in 18:
			await process_frame
			seen_hop = minf(seen_hop, projectile.visual.position.y)
		check(seen_hop < 0.0, "Projectile bounces while flying: " + kind)
		check(projectile.get_node("TrailFx")._points.size() >= 2, "Projectile leaves a trail: " + kind)
		if kind == "hipster_coffee":
			check(not is_equal_approx(projectile.visual.rotation, start_rotation), "Cup rotates in flight")
		var shadow: Node2D = projectile.get_node("ShadowFx")
		check(shadow.z_index == -1 and shadow.top_level, "Shadow sits on the ground plane beneath actors: " + kind)
		projectile.queue_free()
	feel.fx._casings.clear()
	feel.fx._flashes.clear()
	agent.facing = -1
	arena._spawn_projectile(agent.global_position + Vector2(-22, -58), 0, -1, "agent_orb", "enemy", agent)
	arena.projectiles.get_child(-1).set_physics_process(false)
	check(feel.fx._flashes.size() == 1 and feel.fx._casings.size() == 1, "Agent shot has muzzle flash and ejected casing")
	check(feel.fx._casings[0].vel.x > 0.0, "Casing ejects backwards from the shot direction")
	for _i in 140:
		await process_frame
	check(feel.fx._casings.size() == 0 or feel.fx._casings[0].pos.y <= GameConfig.GROUND_Y + 0.01, "Casing never falls below the ground")
	arena._spawn_projectile(boss.global_position + Vector2(-30, -60), 0, -1, "coffee", "enemy", boss)
	var thrown: Node = arena.projectiles.get_child(-1)
	thrown.set_physics_process(false)
	check(float(thrown.get_node("TrailFx").profile.shadow) > float(CFG.PROJECTILE_FX.bottle.shadow), "Boss throws get the heavy 'stone' presence")
	for child in arena.projectiles.get_children():
		child.queue_free()
	await process_frame


func _check_boss() -> void:
	var director: Node = arena.boss_director
	var boss: CharacterBody2D = arena.boss
	var player: CharacterBody2D = arena.player
	var camera: Camera2D = arena.get_node("ViewportContainer/SubViewport/World/Camera2D")
	check(director.stage == director.Stage.WAITING and not boss.active, "Boss waits inactive before the trigger")
	check(not boss.hurtbox.receiving_enabled if "receiving_enabled" in boss.hurtbox else true, "Boss cannot be hurt before its intro")
	check(arena.hud.boss_panel != null and not arena.hud.boss_panel.visible, "Boss bar hidden before the intro")
	check(not CFG.BOSS_CHAIN_ANIMATED and boss.visual.sprite_frames.get_frame_count(&"boss_punch") == boss.visual.sprite_frames.get_frame_count(&"idle"), "Chain attack is prepared without a dedicated animation")
	check(is_equal_approx(boss.intro_duration, CFG.BOSS_ACTIVATE_REACTION), "Boss reaction pause is configured")
	for enemy in arena.enemies.get_children():
		if enemy != boss:
			enemy.queue_free()
	await process_frame
	player.global_position.x = CFG.BOSS_TRIGGER_X + 10.0
	await process_frame
	check(director.stage == director.Stage.INTRO, "Crossing the trigger starts the 2 s intro")
	check(not player.controls_enabled, "Ciruja is held during the intro")
	check(arena.hud.boss_panel.visible and arena.hud.banner.text == CFG.BOSS_NAME, "Intro shows the boss name and its own life bar")
	check(not boss.active, "Boss stays idle during the intro")
	check(arena.projectiles.process_mode == Node.PROCESS_MODE_DISABLED, "World is frozen during the intro")
	await create_timer(0.6).timeout
	check(camera.zoom.x > 1.0, "Camera pushes in on the boss during the intro")
	director._process(CFG.BOSS_INTRO_DURATION)
	check(director.stage == director.Stage.FIGHT and boss.active and player.controls_enabled, "Fight starts after the intro and releases the camera lock")
	check(camera.zoom == Vector2.ONE and camera.position == director._camera_home, "Camera ends locked on the arena frame")
	boss.set_physics_process(false)
	var speed_before: float = boss.lane_move_speed
	var cooldown_before: float = boss.coffee_cooldown
	var maximum: int = boss.health_component.max_health
	boss.health_component.restore_full(true)
	boss.health_component.set_current_health(int(maximum * CFG.BOSS_PHASE2_THRESHOLD) + 1)
	check(director.stage == director.Stage.FIGHT, "Phase 2 not reached above 50% health")
	boss.health_component.set_current_health(int(maximum * CFG.BOSS_PHASE2_THRESHOLD))
	check(director.stage == director.Stage.PHASE_TWO, "Phase 2 starts at 50% health")
	check(boss.lane_move_speed > speed_before and boss.coffee_cooldown < cooldown_before and boss.visual.speed_scale > 1.0, "Phase 2 is faster in movement, tempo and animation")
	boss.health_component.set_current_health(int(maximum * 0.4))
	check(is_equal_approx(boss.lane_move_speed, speed_before * CFG.BOSS_PHASE2_SPEED_MULT), "Phase 2 multipliers apply only once")
	check(is_equal_approx(arena.hud.boss_bar.value, maximum * 0.4), "Boss bar follows its health")
