extends SceneTree
## Focused regression checks for Player muzzle placement and vehicle-platform filtering.

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
	var player = route.player
	route.set_physics_process(false)
	player.set_physics_process(false)
	player.oranges_unlocked = true
	player.facing = 1
	var auto: StaticBody2D = route.get_node("Terrain").get_children().filter(func(node: Node): return node.is_in_group("stationary_vehicles") and node.get("asset")=="auto1")[0]
	for pickup in route.get_node("Objects").get_children():
		if absf(pickup.position.x-auto.position.x)<1.0:
			pickup.queue_free()
	await process_frame
	var roof_shape: CollisionShape2D = auto.get_node("CollisionShape2D")
	var roof_y := auto.global_position.y+roof_shape.position.y-(roof_shape.shape as RectangleShape2D).size.y*0.5
	expect(auto.collision_layer==GameConfig.PLAYER_PLATFORM_LAYER and player.collision_mask&GameConfig.PLAYER_PLATFORM_LAYER!=0,"Stationary auto uses a Player-only physical platform layer")

	# 1. Horizontal beside the auto reaches an enemy beyond it.
	player.position = Vector2(auto.position.x-150.0,GameConfig.GROUND_Y)
	var target = route.spawn_enemy("hipster",auto.position.x+150.0,0)
	target.set_physics_process(false)
	target.contact.monitoring = false
	await physics_frame
	var horizontal = fire(scene,player,Vector2.RIGHT)
	expect(horizontal!=null and horizontal.travel_direction==Vector2.RIGHT,"Horizontal shot is emitted toward input beside an auto")
	expect(horizontal!=null and not overlaps_platform(horizontal),"Horizontal muzzle does not start inside vehicle roof")
	for step in range(40):
		if horizontal==null or horizontal.spent:
			break
		horizontal._physics_process(0.015)
	expect(target.health==1,"Horizontal projectile crosses the vehicle area and damages the enemy")
	target.queue_free()
	await physics_frame

	# 2. Horizontal fire while standing on the roof remains alive past its edge.
	player.position = Vector2(auto.position.x,roof_y)
	var roof_horizontal = fire(scene,player,Vector2.RIGHT)
	expect(roof_horizontal!=null and not overlaps_platform(roof_horizontal),"Shot from vehicle roof starts clear of its collider")
	roof_horizontal._physics_process(0.12)
	expect(not roof_horizontal.spent,"Horizontal shot from roof is not absorbed by the vehicle")
	roof_horizontal.queue_free()

	# 3. Upper diagonal beside the auto preserves exact input direction.
	player.position = Vector2(auto.position.x-150.0,GameConfig.GROUND_Y)
	var upper_diagonal = fire(scene,player,Vector2(1,-1))
	expect(upper_diagonal.travel_direction.is_equal_approx(Vector2(1,-1).normalized()) and not overlaps_platform(upper_diagonal),"Upper diagonal uses its input vector and a clear muzzle")
	upper_diagonal._physics_process(0.08)
	expect(not upper_diagonal.spent,"Upper diagonal remains unobstructed beside vehicle")
	upper_diagonal.queue_free()

	# 4. Lower diagonal deliberately crosses the one-way roof without impact.
	player.position = Vector2(auto.position.x,roof_y)
	var lower_diagonal = fire(scene,player,Vector2(1,1))
	expect(lower_diagonal.travel_direction.is_equal_approx(Vector2(1,1).normalized()) and not overlaps_platform(lower_diagonal),"Lower diagonal from roof starts above, not inside, the collider")
	lower_diagonal._physics_process(0.05)
	expect(not lower_diagonal.spent and lower_diagonal.position.y>roof_y-10.0,"Lower diagonal crosses one-way roof without being consumed")
	lower_diagonal.queue_free()

	# 5. Straight-up fire keeps its direction and explicit overhead muzzle.
	player.position = Vector2(auto.position.x-150.0,GameConfig.GROUND_Y)
	var upward = fire(scene,player,Vector2.UP)
	expect(upward.travel_direction==Vector2.UP and upward.position==player.position+Vector2(0.0,-74.0),"Straight-up projectile uses the overhead muzzle")
	upward._physics_process(0.08)
	expect(not upward.spent,"Straight-up fire is not intercepted by nearby vehicle")
	upward.queue_free()

	# 6/7. Every discrete muzzle is clear; projectiles scan world/enemies, not roofs.
	for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2(1,-1),Vector2(-1,-1),Vector2(1,1),Vector2(-1,1),Vector2.DOWN]:
		player.position = Vector2(auto.position.x,roof_y)
		var projectile = fire(scene,player,direction)
		expect(projectile!=null and not overlaps_platform(projectile),"Muzzle is clear for %s" % direction)
		if projectile == null:
			await process_frame
			continue
		expect(projectile.collision_mask&GameConfig.PLAYER_PLATFORM_LAYER==0 and projectile.collision_mask&GameConfig.WORLD_LAYER!=0,"Player projectile ignores vehicle roof but retains solid-world collision")
		projectile.queue_free()
		await process_frame

	# 8. Existing close-range Punch still wins over projectile emission.
	player.position = Vector2(2600.0,GameConfig.GROUND_Y)
	var punch_target = route.spawn_enemy("hipster",2660.0,0)
	punch_target.set_physics_process(false)
	punch_target.contact.monitoring = false
	await physics_frame
	var projectile_count: int = route.get_node("Projectiles").get_child_count()
	player.cancel_collection()
	player.shot_cooldown = 0.0
	player.throw_projectile("orange",Vector2.RIGHT)
	expect(player.punch_active and route.get_node("Projectiles").get_child_count()==projectile_count,"Close target still selects Punch without spawning projectile")
	player.cancel_punch()

	# 9. Outside Punch range, ordinary projectile behavior returns.
	punch_target.position.x = 2780.0
	player.shot_cooldown = 0.0
	var ranged = fire(scene,player,Vector2.RIGHT)
	expect(not player.punch_active and ranged!=null and ranged.travel_direction==Vector2.RIGHT,"Normal projectile returns outside Punch range")
	ranged.queue_free()
	punch_target.queue_free()
	await physics_frame

	var result := {"passed":failures.is_empty(),"checks":checks,"errors":failures}
	var output := FileAccess.open("res://validation/player_vehicle_shot_checks.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(result,"  ")+"\n")
	output.close()
	print(JSON.stringify(result))
	root.get_node("AudioManager").stop_all()
	await create_timer(0.3).timeout
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func fire(scene: Node,player: Node,direction: Vector2):
	player.cancel_punch()
	player.cancel_collection()
	player.shot_cooldown = 0.0
	var container := scene.get_node("Route38/Projectiles")
	var existing_ids: Array[int] = []
	for child in container.get_children():
		existing_ids.append(child.get_instance_id())
	player.throw_projectile("orange",direction)
	var spawned := container.get_children().filter(func(child: Node): return child.get_instance_id() not in existing_ids)
	if spawned.is_empty():
		return null
	var projectile = spawned[-1]
	projectile.set_physics_process(false)
	return projectile

func overlaps_platform(projectile: Area2D) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = projectile.collision_shape.shape
	query.transform = projectile.collision_shape.global_transform
	query.collision_mask = GameConfig.PLAYER_PLATFORM_LAYER
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [projectile.get_rid()]
	return not projectile.get_world_2d().direct_space_state.intersect_shape(query,8).is_empty()
