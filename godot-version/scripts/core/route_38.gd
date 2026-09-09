extends Node2D
signal shot_requested(origin: Vector2, lane: int, direction: int, kind: String, team: String)
signal aimed_shot_requested(origin: Vector2, lane: int, direction: Vector2, kind: String, team: String)
signal boss_escaped
signal boss_defeated
signal boss_finished
signal notice_requested(text: String)
signal checkpoint_activated(checkpoint_id: StringName, respawn_position: Vector2)
signal location_changed(location_name: String)
signal boss_spawned(health_component: Node, display_name: String)
signal miniboss_spawned(health_component: Node, display_name: String)
signal miniboss_finished
signal miniboss_defeated
signal boss_arena_changed(active: bool, left_bound: float, right_bound: float)
signal screen_shake_requested(intensity: float, duration: float)
const ENEMY = preload("res://scenes/actors/enemy.tscn")
const DRONE = preload("res://scenes/actors/drone.tscn")
const PALERMITANO_BOSS = preload("res://scenes/actors/palermitano_boss.tscn")
const MINIBOSS_GRANDOTE = preload("res://scenes/actors/miniboss_grandote.tscn")
const GRANDOTE_GROUND_WAVE = preload("res://scenes/actors/grandote_ground_wave.tscn")
const PICKUP = preload("res://scenes/actors/pickup.tscn")
const PLATFORM = preload("res://scenes/actors/platform.tscn")
const GENERIC_PLATFORM = preload("res://scenes/actors/generic_platform.tscn")
const BUS_STOP_TEXTURE = preload("res://assets/parada_colectivo.png")
const KIOSK_TEXTURE = preload("res://assets/kiosco_coca.png")
const ENCOUNTER_DIRECTOR = preload("res://scripts/level/encounter_director.gd")
const TRAFFIC_DIRECTOR = preload("res://scripts/level/traffic_director.gd")
var data: Dictionary
var collected_pickup_ids: Dictionary = {}
var boss: CharacterBody2D
var boss_started: bool = false
var boss_active: bool = false
var _boss_feedback_active: bool = false
var miniboss: CharacterBody2D
var miniboss_active: bool = false
var _miniboss_feedback_active: bool = false
var demo_closing: bool = false
const MINIBOSS_ARENA_BOUNDS := Vector2(6900.0,7750.0)
const BOSS_ARENA_BOUNDS := Vector2(7000.0,7950.0)
const LOCAL_RESPAWN_DISTANCES: Array[float] = [160.0,120.0,200.0,220.0]
const LOCAL_RESPAWN_EDGE_PADDING := 40.0
const LOCAL_RESPAWN_ARENA_PADDING := 80.0
const LOCAL_RESPAWN_ENEMY_CLEARANCE := 110.0
const LOCAL_RESPAWN_VEHICLE_CLEARANCE := 90.0
const LOCAL_RESPAWN_PROJECTILE_CLEARANCE := 150.0
const LOCAL_RESPAWN_CLEANUP_RADIUS := 180.0
var _last_location: String = ""
@onready var player: CharacterBody2D = $Player
@onready var encounter_director: ENCOUNTER_DIRECTOR = $EncounterDirector
@onready var traffic_director: TRAFFIC_DIRECTOR = $TrafficDirector

func _ready() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://scenes/levels/route_38_data.json"))
	if not encounter_director.configure(data.encounters,spawn_encounter_actor):
		push_error("Route38 no pudo registrar todos los encuentros configurados")
	if not traffic_director.configure($Vehicles,player):
		push_error("Route38 no pudo configurar el tráfico")
	traffic_director.vehicle_warning.connect(_on_vehicle_warning)
	$Checkpoint.activated.connect(checkpoint_activated.emit)
	for lane in range(2):
		var ground := StaticBody2D.new()
		ground.name = "GroundLane"+str(lane)
		ground.position = Vector2(4000,GameConfig.LANES[lane]+6.0)
		ground.collision_layer = 1 << lane
		ground.collision_mask = 0
		$Terrain.add_child(ground)
		CollisionFactory.add_floor(ground,Vector2(8400,12))
	for item: Array in [["auto1",1900,0.84],["camion_limones",3100,1.25],["auto2",5000,1.10],["auto3",6700,0.95]]:
		var platform = PLATFORM.instantiate()
		platform.asset = item[0]
		platform.image_scale = item[2]
		platform.lane_index = 0
		platform.position = Vector2(item[1],359)
		$Terrain.add_child(platform)
	$Environment/RouteProps/BusStop01.visible = false
	add_generic_platform("KioskPlatformPOC",KIOSK_TEXTURE,1650.0,0,0.72,112.0,-95.0)
	add_generic_platform("BusStopPlatformPOC",BUS_STOP_TEXTURE,2100.0,0,0.62,94.0,-108.0)
	add_pickup("orange_tree","arbol_naranjas",520,0,0.85,345)
	for x in [1250,4450]:
		add_pickup("stone_pile","montaña_cascote",x,0,0.65)
	for x in [2800,6200]:
		add_pickup("sanguche","sanguche",x,1,0.25)
	var index: int = 0
	for x in [240,750,1350,2000,2700,3400,4100,4900,5600,6300,7000,7500]:
		add_pickup("empanada","empanada",x,index%2,0.14)
		index += 1
	index = 0
	for x in [3200,3600,4300,5400,6500,7200]:
		add_pickup("achilata","achilata",x,index%2,0.18)
		index += 1

func _physics_process(delta: float) -> void:
	if demo_closing or not is_instance_valid(player) or not player.controls_enabled:
		return
	encounter_director.update_activation(player.position.x)
	traffic_director.update_traffic(delta,player.position.x)
	if miniboss_active:
		player.position.x = clampf(player.position.x,MINIBOSS_ARENA_BOUNDS.x,MINIBOSS_ARENA_BOUNDS.y)
	if boss_active:
		player.position.x = clampf(player.position.x,BOSS_ARENA_BOUNDS.x,BOSS_ARENA_BOUNDS.y)
	var next_location := current_location(player.position.x)
	if next_location != _last_location:
		_last_location = next_location
		location_changed.emit(_last_location)
	if not boss_started and player.position.x >= float(data.boss.trigger_x) \
			and encounter_director.is_encounter_completed(&"route_wave_06"):
		spawn_palermitano(float(data.boss.x),1)

func current_location(x: float) -> String:
	var result: String = data.locations[0].name
	for location: Dictionary in data.locations:
		if x >= float(location.x):
			result = location.name
	return result


func add_generic_platform(
	platform_name: String,
	texture: Texture2D,
	x: float,
	lane: int,
	visual_scale: float,
	useful_roof_width: float,
	roof_offset: float,
	roof_enabled: bool = true
) -> StaticBody2D:
	var platform = GENERIC_PLATFORM.instantiate()
	platform.name = platform_name
	platform.configure(texture,visual_scale,lane,useful_roof_width,roof_offset,roof_enabled)
	platform.position = Vector2(x,GameConfig.LANES[lane])
	$Terrain.add_child(platform)
	return platform

func spawn_enemy(archetype: String,x: float,lane: int) -> CharacterBody2D:
	if demo_closing:
		return null
	var enemy = ENEMY.instantiate()
	enemy.archetype = archetype
	enemy.lane_index = lane
	enemy.target = player
	enemy.position = Vector2(x,GameConfig.LANES[lane])
	enemy.shot_requested.connect(shot_requested.emit)
	enemy.ground_wave_requested.connect(_spawn_grandote_ground_wave)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.boss_escaped.connect(boss_escaped.emit)
	$Enemies.add_child(enemy)
	return enemy


func spawn_encounter_actor(archetype: String,x: float,lane: int) -> Node2D:
	if archetype == "drone":
		return spawn_drone(x,lane)
	return spawn_enemy(archetype,x,lane)


func spawn_drone(x: float,lane: int) -> Node2D:
	if demo_closing:
		return null
	var drone = DRONE.instantiate()
	drone.lane_index = lane
	drone.target = player
	drone.position = Vector2(x,GameConfig.LANES[lane]-drone.flight_height)
	drone.shot_requested.connect(aimed_shot_requested.emit)
	drone.defeated.connect(_on_enemy_defeated)
	$Enemies.add_child(drone)
	return drone


func spawn_palermitano(x: float,lane: int) -> CharacterBody2D:
	if demo_closing or is_instance_valid(boss):
		return boss
	boss_started = true
	boss_active = true
	_boss_feedback_active = true
	boss = PALERMITANO_BOSS.instantiate()
	boss.lane_index = lane
	boss.target = player
	boss.arena_bounds = BOSS_ARENA_BOUNDS
	boss.position = Vector2(x,GameConfig.LANES[lane])
	boss.aimed_shot_requested.connect(aimed_shot_requested.emit)
	boss.summon_requested.connect(_on_boss_summon_requested)
	boss.screen_shake_requested.connect(screen_shake_requested.emit)
	boss.defeated.connect(_on_palermitano_defeated,CONNECT_ONE_SHOT)
	boss.tree_exiting.connect(_on_palermitano_exiting,CONNECT_ONE_SHOT)
	$Enemies.add_child(boss)
	traffic_director.set_enabled(false,true)
	boss_spawned.emit(boss.health_component,"EL PALERMITANO")
	boss_arena_changed.emit(true,BOSS_ARENA_BOUNDS.x,BOSS_ARENA_BOUNDS.y)
	notice_requested.emit("RÍO SECO · ¡EL PALERMITANO ESTÁ ACÁ!")
	return boss


func _on_boss_summon_requested(count: int,preferred_lane: int) -> void:
	if not boss_active or not is_instance_valid(boss):
		return
	var available := maxi(0,boss.max_live_summons-boss.get_live_summon_count())
	for index in range(mini(count,available)):
		var lane := preferred_lane if index == 0 else 1-preferred_lane
		var offset := -220.0 if index == 0 else 220.0
		var summon := spawn_enemy("agente",clampf(boss.position.x+offset,BOSS_ARENA_BOUNDS.x+80.0,BOSS_ARENA_BOUNDS.y-80.0),lane)
		if is_instance_valid(summon):
			boss.register_summon(summon)


func _on_palermitano_defeated(points: int) -> void:
	if not boss_active:
		return
	_on_enemy_defeated(points)
	boss_defeated.emit()
	_clear_boss_feedback()


func _on_palermitano_exiting() -> void:
	if not demo_closing:
		_clear_boss_feedback()
	boss = null


func _clear_boss_feedback() -> void:
	if not _boss_feedback_active:
		return
	_boss_feedback_active = false
	boss_active = false
	traffic_director.set_enabled(true)
	boss_finished.emit()
	boss_arena_changed.emit(false,0.0,GameConfig.WORLD_WIDTH)


func _spawn_grandote_ground_wave(origin: Vector2,lane: int,direction: int) -> Area2D:
	var wave = GRANDOTE_GROUND_WAVE.instantiate()
	wave.position = Vector2(origin.x,GameConfig.LANES[lane])
	wave.lane_index = lane
	wave.direction = direction
	$Projectiles.add_child(wave)
	return wave

func _spawn_miniboss_grandote(x: float,lane: int) -> CharacterBody2D:
	if is_instance_valid(miniboss):
		return miniboss
	miniboss = MINIBOSS_GRANDOTE.instantiate()
	miniboss.lane_index = lane
	miniboss.target = player
	miniboss.position = Vector2(x,GameConfig.LANES[lane])
	miniboss.arena_bounds = MINIBOSS_ARENA_BOUNDS
	miniboss.defeated.connect(_on_miniboss_defeated)
	miniboss.screen_shake_requested.connect(screen_shake_requested.emit)
	miniboss.tree_exiting.connect(_on_miniboss_exiting,CONNECT_ONE_SHOT)
	$Enemies.add_child(miniboss)
	traffic_director.set_enabled(false,true)
	miniboss_active = true
	_miniboss_feedback_active = true
	miniboss_spawned.emit(miniboss.health_component,"EL GRANDOTE")
	boss_arena_changed.emit(true,MINIBOSS_ARENA_BOUNDS.x,MINIBOSS_ARENA_BOUNDS.y)
	notice_requested.emit("RÍO SECO · EL GRANDOTE")
	return miniboss

func _on_miniboss_defeated(points: int) -> void:
	_on_enemy_defeated(points)
	miniboss_defeated.emit()
	_clear_miniboss_feedback()

func _on_miniboss_exiting() -> void:
	_clear_miniboss_feedback()
	miniboss = null
	miniboss_active = false

func _clear_miniboss_feedback() -> void:
	if not _miniboss_feedback_active:
		return
	_miniboss_feedback_active = false
	miniboss_active = false
	traffic_director.set_enabled(true)
	miniboss_finished.emit()
	boss_arena_changed.emit(false,0.0,GameConfig.WORLD_WIDTH)


func begin_demo_closing() -> bool:
	if demo_closing:
		return false
	demo_closing = true
	set_physics_process(false)
	_clear_boss_feedback()
	_clear_miniboss_feedback()
	traffic_director.set_enabled(false,true)
	for enemy in $Enemies.get_children():
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		enemy.queue_free()
	for projectile in $Projectiles.get_children():
		projectile.process_mode = Node.PROCESS_MODE_DISABLED
		projectile.queue_free()
	boss = null
	boss_started = true
	boss_active = false
	return true

func _on_enemy_defeated(points: int) -> void:
	player.score += points
	player.status_changed.emit()

func _on_vehicle_warning(_lane: int,_direction: int) -> void:
	AudioManager.play_effect("alerta")

func add_pickup(kind: String,asset: String,x: float,lane: int,image_scale: float,ground_y: float = -1.0,pickup_id: StringName = &"") -> Area2D:
	var pickup = PICKUP.instantiate()
	pickup.kind = kind
	pickup.asset = asset
	pickup.image_scale = image_scale
	pickup.lane_index = lane
	pickup.pickup_id = pickup_id if not pickup_id.is_empty() else StringName("%s_%d_%d" % [kind,int(x),lane])
	pickup.position = Vector2(x,GameConfig.LANES[lane] if ground_y < 0.0 else ground_y)
	pickup.collected_with_id.connect(_on_pickup)
	$Objects.add_child(pickup)
	return pickup

func _on_pickup(pickup_id: StringName,kind: String) -> void:
	collected_pickup_ids[pickup_id] = true
	if kind == "orange_tree":
		notice_requested.emit("¡NARANJAS LISTAS! Z: naranja · X: cascote")
	elif kind == "stone_pile":
		notice_requested.emit("¡20 CASCOTES! Tirálos con X")
	elif kind == "sanguche":
		notice_requested.emit("¡FURIA MILANESA! 10 segundos de arrase")


func get_collected_pickup_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for pickup_id in collected_pickup_ids:
		result.append(pickup_id)
	result.sort()
	return result


func find_local_respawn(death_position: Vector2,preferred_lane: int) -> Dictionary:
	var lane_order: Array[int] = [clampi(preferred_lane,0,GameConfig.LANES.size()-1)]
	for lane in range(GameConfig.LANES.size()):
		if not lane_order.has(lane):
			lane_order.append(lane)
	var bounds := Vector2(LOCAL_RESPAWN_EDGE_PADDING,GameConfig.WORLD_WIDTH-LOCAL_RESPAWN_EDGE_PADDING)
	if boss_active:
		bounds = Vector2(BOSS_ARENA_BOUNDS.x+LOCAL_RESPAWN_ARENA_PADDING,BOSS_ARENA_BOUNDS.y-LOCAL_RESPAWN_ARENA_PADDING)
	elif miniboss_active:
		bounds = Vector2(MINIBOSS_ARENA_BOUNDS.x+LOCAL_RESPAWN_ARENA_PADDING,MINIBOSS_ARENA_BOUNDS.y-LOCAL_RESPAWN_ARENA_PADDING)
	var tested_positions: Dictionary = {}
	for lane in lane_order:
		for distance in LOCAL_RESPAWN_DISTANCES:
			var candidate := Vector2(clampf(death_position.x-distance,bounds.x,bounds.y),GameConfig.LANES[lane])
			var candidate_key := "%d:%d" % [lane,int(candidate.x)]
			if tested_positions.has(candidate_key):
				continue
			tested_positions[candidate_key] = true
			if is_local_respawn_safe(candidate,lane):
				return {"found":true,"position":candidate,"lane_index":lane,"used_fallback":false}
	return {"found":false,"position":Vector2.ZERO,"lane_index":lane_order[0],"used_fallback":true}


func is_local_respawn_safe(candidate: Vector2,lane: int) -> bool:
	if lane < 0 or lane >= GameConfig.LANES.size() or not is_equal_approx(candidate.y,GameConfig.LANES[lane]):
		return false
	if candidate.x < LOCAL_RESPAWN_EDGE_PADDING or candidate.x > GameConfig.WORLD_WIDTH-LOCAL_RESPAWN_EDGE_PADDING:
		return false
	if boss_active and (candidate.x < BOSS_ARENA_BOUNDS.x+LOCAL_RESPAWN_ARENA_PADDING or candidate.x > BOSS_ARENA_BOUNDS.y-LOCAL_RESPAWN_ARENA_PADDING):
		return false
	for vehicle in traffic_director.get_active_vehicles():
		if not is_instance_valid(vehicle) or int(vehicle.get("lane_index")) != lane:
			continue
		var half_width := LOCAL_RESPAWN_VEHICLE_CLEARANCE
		var impact_hitbox := vehicle.get_node_or_null("ImpactHitbox")
		if impact_hitbox != null and impact_hitbox.get("attack_definition") != null:
			half_width = maxf(half_width,float(impact_hitbox.attack_definition.reach.x)*0.5+36.0)
		if absf(vehicle.global_position.x-candidate.x) <= half_width:
			return false
	for enemy in $Enemies.get_children():
		if not is_instance_valid(enemy) or enemy.get("lane_index") == null or int(enemy.get("lane_index")) != lane:
			continue
		if enemy.get("active") != null and not bool(enemy.get("active")):
			continue
		if absf(enemy.global_position.x-candidate.x) <= LOCAL_RESPAWN_ENEMY_CLEARANCE:
			return false
		if enemy.has_method("has_dangerous_aim_near") and enemy.has_dangerous_aim_near(candidate,LOCAL_RESPAWN_PROJECTILE_CLEARANCE):
			return false
	for hitbox in $Enemies.find_children("*","Hitbox",true,false):
		if _is_active_hitbox_near(hitbox,candidate,lane):
			return false
	for projectile in $Projectiles.get_children():
		if _is_hostile_projectile_near(projectile,candidate,lane,LOCAL_RESPAWN_PROJECTILE_CLEARANCE):
			return false
	return true


func prepare_local_respawn_safety(respawn_position: Vector2,lane: int) -> Dictionary:
	var removed_projectiles := 0
	var cancelled_drone_aims := 0
	for projectile in $Projectiles.get_children():
		if _is_hostile_projectile_near(projectile,respawn_position,lane,LOCAL_RESPAWN_CLEANUP_RADIUS):
			projectile.process_mode = Node.PROCESS_MODE_DISABLED
			projectile.queue_free()
			removed_projectiles += 1
	for enemy in $Enemies.get_children():
		if is_instance_valid(enemy) and enemy.has_method("cancel_dangerous_aim_near") \
				and enemy.cancel_dangerous_aim_near(respawn_position,LOCAL_RESPAWN_CLEANUP_RADIUS):
			cancelled_drone_aims += 1
	return {"removed_projectiles":removed_projectiles,"cancelled_drone_aims":cancelled_drone_aims}


func _is_hostile_projectile_near(projectile: Node,candidate: Vector2,lane: int,radius: float) -> bool:
	if not is_instance_valid(projectile) or projectile.get("team") == null or StringName(projectile.get("team")) == &"player":
		return false
	if projectile.get("lane_index") == null or int(projectile.get("lane_index")) != lane:
		return false
	return projectile.global_position.distance_to(candidate) <= radius


func _is_active_hitbox_near(hitbox: Node,candidate: Vector2,lane: int) -> bool:
	if hitbox.get("active") == null or not bool(hitbox.get("active")) or hitbox.get("team") == null \
			or StringName(hitbox.get("team")) == &"player" or int(hitbox.get("lane_index")) != lane:
		return false
	var shape_node := hitbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null or shape_node.disabled:
		return false
	if shape_node.shape is RectangleShape2D:
		var half_size: Vector2 = (shape_node.shape as RectangleShape2D).size*0.5+Vector2(32.0,52.0)
		return absf(shape_node.global_position.x-candidate.x) <= half_size.x \
			and absf(shape_node.global_position.y-candidate.y) <= half_size.y
	if shape_node.shape is CircleShape2D:
		return shape_node.global_position.distance_to(candidate) <= (shape_node.shape as CircleShape2D).radius+52.0
	return false


func restore_checkpoint_state(completed_encounters: Array[StringName],collected_pickups: Array[StringName]) -> void:
	demo_closing = false
	set_physics_process(true)
	_clear_boss_feedback()
	_clear_miniboss_feedback()
	traffic_director.reset_runtime_state(true)
	miniboss = null
	miniboss_active = false
	encounter_director.restore_completed_encounters(completed_encounters)
	for enemy in $Enemies.get_children():
		enemy.queue_free()
	for projectile in $Projectiles.get_children():
		projectile.queue_free()
	boss = null
	boss_started = false
	boss_active = false
	collected_pickup_ids.clear()
	for pickup_id in collected_pickups:
		collected_pickup_ids[pickup_id] = true
	for pickup in $Objects.get_children():
		if pickup.has_method("set_collected_state"):
			pickup.set_collected_state(collected_pickup_ids.has(pickup.pickup_id))
