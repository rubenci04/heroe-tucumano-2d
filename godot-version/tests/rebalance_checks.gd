extends RefCounted

static func run(tree: SceneTree, scene: Node) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var route = scene.get_node("Route38")
	var player = route.player
	route.set_physics_process(false)
	player.set_physics_process(false)
	player.position = Vector2(1000,370)
	player.facing = 1
	player.stones = 4
	player.oranges_unlocked = true
	player.shot_cooldown = 0.0
	var enemy = route.spawn_enemy("grandote",1060,0)
	enemy.set_physics_process(false)
	enemy.contact.monitoring = false
	await tree.frames(2)
	var shots: Array = []
	player.shot_requested.connect(func(_origin,_lane,_direction,kind,_team): shots.append(kind))
	player.throw_projectile("stone")
	results.append({"ok":player.punch_active and shots.is_empty() and player.stones==4 and player.visual.animation==&"Punch","message":"Close attack prioritizes seven-frame Punch without a projectile or ammunition cost"})
	player._update_punch(1.0/14.0)
	results.append({"ok":enemy.health==6 and player.punch_hitbox.get_child(0).disabled,"message":"Punch startup has no active hitbox"})
	player._update_punch(1.1/14.0)
	results.append({"ok":enemy.health==4 and not player.punch_hitbox.get_child(0).disabled,"message":"Punch frame 3 activates its hitbox and applies two damage"})
	player._update_punch(2.0/14.0)
	results.append({"ok":enemy.health==4,"message":"Punch central frames cannot apply duplicate damage"})
	player._update_punch(1.0/14.0)
	results.append({"ok":player.punch_hitbox.get_child(0).disabled and player.punch_active,"message":"Punch frame 6 is recovery with no hitbox"})
	player._update_punch(0.2)
	results.append({"ok":not player.punch_active and player.shot_cooldown>0.0,"message":"Punch finishes with a clear attack cooldown"})
	player.shot_cooldown = 0.0
	enemy.position.x = 1200
	await tree.frames(2)
	player.throw_projectile("stone")
	results.append({"ok":shots==["stone"] and player.stones==3 and not player.punch_active,"message":"Outside melee range normal projectile and ammunition rules return"})
	player.shot_cooldown = 0.0
	enemy.position.x = 940
	await tree.frames(2)
	results.append({"ok":player._find_punch_target()==null,"message":"Punch does not acquire an enemy behind Player"})
	enemy.position.x = 1060
	var wall := StaticBody2D.new()
	wall.collision_layer = GameConfig.WORLD_LAYER
	wall.position = Vector2(1030,332)
	route.add_child(wall)
	CollisionFactory.add_floor(wall,Vector2(8,90))
	await tree.frames(2)
	results.append({"ok":player._find_punch_target()==null,"message":"Solid geometry blocks melee acquisition"})
	wall.queue_free()
	await tree.frames(2)
	player.shot_cooldown = 0.0
	player.throw_projectile("orange")
	var roof := StaticBody2D.new()
	roof.collision_layer = GameConfig.WORLD_LAYER
	roof.position = Vector2(1030,332)
	route.add_child(roof)
	var roof_shape := CollisionFactory.add_floor(roof,Vector2(8,90))
	roof_shape.one_way_collision = true
	await tree.frames(2)
	enemy.invulnerability = 0.0
	var protected_health: int = enemy.health
	player._update_punch(3.0/14.0)
	results.append({"ok":enemy.health==protected_health,"message":"Geometry introduced after startup also blocks Punch damage"})
	player.cancel_punch()
	await tree.frames(1)
	results.append({"ok":not player.punch_active and player.punch_hitbox.get_child(0).disabled,"message":"Deferred Punch cancellation safely disables its shape"})
	roof.queue_free()
	enemy.queue_free()
	for shot in route.get_node("Projectiles").get_children():
		shot.queue_free()
	await tree.frames(2)
	var director = route.encounter_director
	director.reset_runtime_state(true)
	director.update_activation(900.0)
	results.append({"ok":director.get_active_enemy_count(&"route_wave_01")==1 and director._pending.size()==5,"message":"Designed first wave queues its frequent entries"})
	director.update_activation(900.0)
	director.advance_spawns(0.44)
	results.append({"ok":director.get_active_enemy_count(&"route_wave_01")==1 and director._pending.size()==5,"message":"Repeated triggers cannot duplicate scheduled entries"})
	director.advance_spawns(0.02,1470.0)
	results.append({"ok":director.get_active_enemy_count(&"route_wave_01")==2 and director._pending.size()==4,"message":"Second enemy enters after 0.45 seconds"})
	var arrivals: Array[Node] = director.get_active_enemies(&"route_wave_01")
	results.append({"ok":arrivals[-1].position.x>=1470.0+460.0,"message":"Delayed entry stays ahead of a rushing Player instead of appearing on top"})
	director.update_activation(7000.0)
	results.append({"ok":not director.is_encounter_activated(&"route_drone_01") and not director.is_encounter_activated(&"route_wave_04"),"message":"Crossing later triggers cannot stack Drone and Grandote over a live wave"})
	director.advance_spawns(2.3,1470.0)
	for actor in director.get_active_enemies(&"route_wave_01"):
		actor.take_damage(999,&"player")
	for step in 10:
		if director.is_encounter_completed(&"route_wave_01"):
			break
		director.advance_spawns(1.21,1470.0)
		for actor in director.get_active_enemies(&"route_wave_01"):
			actor.take_damage(999,&"player")
		await tree.frames(1)
	results.append({"ok":director.is_encounter_completed(&"route_wave_01") and director._pending.is_empty(),"message":"All configured pairs are defeated before the completion rest"})
	director.update_activation(1850.0)
	results.append({"ok":not director.is_encounter_activated(&"route_wave_02"),"message":"Completed group leaves a rest before the next wave"})
	director.advance_spawns(0.81)
	director.update_activation(1850.0)
	# Completion rest and the inter-group gap are independent budgets.
	director.advance_spawns(preload("res://scripts/prototype/feel_config.gd").WAVE_GROUP_DELAY - 0.81 + 0.02)
	results.append({"ok":director.get_active_enemy_count(&"route_micro_01")==1,"message":"Next registered microencounter starts one entry after the rest"})
	director.reset_runtime_state(true)
	director.activate_encounter(&"route_wave_03",3500,true)
	director.reset_runtime_state(true)
	director.advance_spawns(10.0)
	results.append({"ok":director._pending.is_empty() and director.get_active_enemy_count(&"route_wave_03")==0,"message":"Reset cancels delayed births without orphan enemies"})
	await tree.frames(2)
	return results
