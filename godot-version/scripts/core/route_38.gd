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
const ENCOUNTER_DIRECTOR = preload("res://scripts/level/encounter_director.gd")
const TRAFFIC_DIRECTOR = preload("res://scripts/level/traffic_director.gd")
const CHECKPOINT_SCENE = preload("res://scenes/level/checkpoint.tscn")
const BATCH_VISUALS = preload("res://scripts/prototype/batch_visuals.gd")
const BOSS_DIRECTOR = preload("res://scripts/prototype/boss_director.gd")
const CFG = preload("res://scripts/prototype/feel_config.gd")
const FEEL_DIRECTOR = preload("res://scripts/prototype/feel_director.gd")
const PROCEDURAL_ANIM = preload("res://scripts/prototype/procedural_anim.gd")
const STAIN_MANAGER = preload("res://scripts/prototype/stain_manager.gd")
const CONTACT_SHADOW = preload("res://scripts/prototype/contact_shadow.gd")
var checkpoint_records: Array = []
var last_safe_position := Vector2(80.0,370.0)
const SAFE_POSITION_MAX_AGE_DISTANCE := 96.0
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
const STATIONARY_VEHICLES: Array[Dictionary] = [
	{"asset":"auto1","x":700.0,"scale":0.777},
	{"asset":"camioneta1","x":1500.0,"scale":0.633},
	{"asset":"auto3","x":2300.0,"scale":0.827},
	{"asset":"auto3","x":3100.0,"scale":0.827},
	{"asset":"camioneta2","x":3900.0,"scale":0.574},
	{"asset":"camion_limones","x":4650.0,"scale":0.612},
	{"asset":"auto2","x":5450.0,"scale":0.729},
	{"asset":"camioneta3","x":6200.0,"scale":0.550},
	{"asset":"camioneta4","x":6900.0,"scale":0.609}
]
# Autos y paradas estacionadas: 0.95 / 0.777 = escala del auto1 del prototipo sobre el de la ruta.
# Ciruja mide lo mismo en ambas versiones (escala 0.42), así que el decorado sube en la misma proporción.
const DECOR_VEHICLE_SCALE := 1.223
var _last_location: String = ""
var _drone_wave_spawn_index := 0
@onready var player: CharacterBody2D = $Player
@onready var encounter_director: ENCOUNTER_DIRECTOR = $EncounterDirector
@onready var traffic_director: TRAFFIC_DIRECTOR = $TrafficDirector
var _batch: BATCH_VISUALS
var feel: Node          # impactos, hit-stop, muertes con peso y fx (scripts/prototype)
var anim: Node          # animación procedural: respiración, retroceso y caídas
var stains: Node        # manchas de café en el piso
var shot_emitter: Node2D  # emisor del disparo en curso; lo lee main para decorar el proyectil
var hud_node: Node        # HUD del juego (main); la usa la intro del jefe
var camera_node: Camera2D # cámara de main
var camera_locked := false  # true durante la intro del jefe: main deja de seguir al jugador
var boss_director: Node

func _ready() -> void:
	_batch = BATCH_VISUALS.new()
	add_child(_batch)
	_batch.attach(player,"ciruja",BATCH_VISUALS.CIRUJA_ALIASES)
	feel = FEEL_DIRECTOR.new()
	add_child(feel)
	feel.setup(self,func(intensity: float,duration: float) -> void: screen_shake_requested.emit(intensity,duration),player)
	feel.arena_bounds = Vector2(40.0,GameConfig.WORLD_WIDTH-40.0)
	anim = PROCEDURAL_ANIM.new()
	anim.scale_variation = CFG.ROUTE_POSE_SCALE_VARIATION
	anim.rotation_limit_degrees = CFG.ROUTE_POSE_ROTATION_DEG
	add_child(anim)
	anim.setup(self,player)
	anim.fx = feel.fx
	stains = STAIN_MANAGER.new()
	add_child(stains)
	stains.setup(self,player,feel.fx)
	_add_contact_shadow(player,"ciruja")
	data = JSON.parse_string(FileAccess.get_file_as_string("res://scenes/levels/route_38_data.json"))
	if not encounter_director.configure(data.encounters,spawn_encounter_actor):
		push_error("Route38 no pudo registrar todos los encuentros configurados")
	if not traffic_director.configure($Vehicles,player):
		push_error("Route38 no pudo configurar el tráfico")
	traffic_director.vehicle_warning.connect(_on_vehicle_warning)
	$Checkpoint.activated.connect(checkpoint_activated.emit)
	_configure_checkpoints()
	var ground := StaticBody2D.new()
	ground.name = "MainGround"
	ground.position = Vector2(4000,GameConfig.GROUND_Y+6.0)
	ground.collision_layer = GameConfig.WORLD_LAYER
	ground.collision_mask = 0
	$Terrain.add_child(ground)
	CollisionFactory.add_floor(ground,Vector2(8400,12))
	var stationary_by_x: Dictionary = {}
	for item: Dictionary in STATIONARY_VEHICLES:
		stationary_by_x[int(item.x)] = _add_stationary_vehicle(item.asset,item.x,item.scale*DECOR_VEHICLE_SCALE)
	var bus_stop := add_generic_platform("RoadsideBusStop",load("res://assets/parada_colectivo2.png"),2700.0,0,0.50*DECOR_VEHICLE_SCALE,110.0,-78.0,true)
	bus_stop.position.y = CFG.backdrop_ground_y(bus_stop.position.x)
	preload("res://scripts/level/route_environment.gd").add_prop_shadow(bus_stop, CollisionFactory.opaque_bounds(bus_stop.platform_texture).size.x * bus_stop.image_scale, bus_stop.position.y)
	bus_stop.z_index = 9
	add_pickup("orange_tree","arbol_naranjas",520,0,0.85,345)
	for x in [1250,4450]:
		add_pickup("stone_pile","montaña_cascote",x,0,0.32)
	add_pickup("sanguche","sanguche",2750,0,0.25,_platform_roof_y(bus_stop)-8.0,&"sanguche_bus_stop")
	for x in [2800]:
		add_pickup("sanguche","sanguche",x,0,0.25)
	add_pickup("sanguche","sanguche",6200,0,0.25,_platform_roof_y(stationary_by_x[6200])-8.0,&"sanguche_6200_0")
	var index: int = 0
	for x in [240,2700,3400,7500]:
		add_pickup("empanada","empanada",x,0,0.14)
		index += 1
	for roof_reward: Dictionary in [
		{"x":700,"legacy_x":750},{"x":1500,"legacy_x":1350},{"x":2300,"legacy_x":2000},
		{"x":3900,"legacy_x":4100},{"x":4650,"legacy_x":4900},{"x":5450,"legacy_x":5600},
		{"x":6900,"legacy_x":7000}
	]:
		var platform: StaticBody2D = stationary_by_x[int(roof_reward.x)]
		add_pickup("empanada","empanada",float(roof_reward.x),0,0.14,_platform_roof_y(platform)-8.0,StringName("empanada_%d_0" % int(roof_reward.legacy_x)))
	for pickup in $Objects.get_children():
		var rewards := {6200:&"route_drone_02"}
		if rewards.has(int(pickup.position.x)):
			pickup.set_meta("reward_after",rewards[int(pickup.position.x)])
			pickup.visible = false
			pickup.set_deferred("monitoring",false)

func _physics_process(delta: float) -> void:
	if demo_closing or not is_instance_valid(player) or not player.controls_enabled:
		return
	$ExpresbusSetPiece.advance(delta,self)
	$TesaSetPiece.advance(delta,self)
	var camera := get_viewport().get_camera_2d()
	encounter_director.update_safety(player.position.x,camera.get_screen_center_position().x if camera else player.position.x,get_viewport_rect().size.x)
	if not _is_bus_set_piece_running():
		encounter_director.advance_spawns(delta,player.position.x)
		encounter_director.update_activation(player.position.x)
	traffic_director.update_traffic(delta,player.position.x)
	_refresh_protected_rewards()
	if miniboss_active:
		player.position.x = clampf(player.position.x,MINIBOSS_ARENA_BOUNDS.x,MINIBOSS_ARENA_BOUNDS.y)
	if boss_active:
		player.position.x = clampf(player.position.x,BOSS_ARENA_BOUNDS.x,BOSS_ARENA_BOUNDS.y)
	update_last_safe_position()
	_update_checkpoints()
	var next_location := current_location(player.position.x)
	if next_location != _last_location:
		_last_location = next_location
		location_changed.emit(_last_location)
	if not boss_started and player.position.x >= float(data.boss.trigger_x) \
			and encounter_director.is_encounter_completed(&"route_wave_06") and not encounter_director.is_resting():
		spawn_palermitano(float(data.boss.x),1)

func _refresh_protected_rewards() -> void:
	for pickup in $Objects.get_children():
		if not pickup.has_meta("reward_after"):
			continue
		var safe: bool = not pickup.used and encounter_director.is_encounter_completed(pickup.get_meta("reward_after"))
		for enemy in $Enemies.get_children():
			if enemy.get("active")==true and absf(enemy.position.x-pickup.position.x)<500.0:
				safe = false
		pickup.visible = safe
		pickup.set_deferred("monitoring",safe)

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
	platform.position = Vector2(x,GameConfig.GROUND_Y)
	$Terrain.add_child(platform)
	return platform

func _add_stationary_vehicle(asset_id: String,x: float,visual_scale: float) -> StaticBody2D:
	var platform = PLATFORM.instantiate()
	platform.name = "Stationary_%s_%d" % [asset_id,int(x)]
	platform.asset = asset_id
	platform.image_scale = visual_scale
	platform.lane_index = 0
	platform.position = Vector2(x,GameConfig.GROUND_Y)
	$Terrain.add_child(platform)
	return platform

func _platform_roof_y(platform: StaticBody2D) -> float:
	var collision: CollisionShape2D = platform.get_node("CollisionShape2D") if platform.has_node("CollisionShape2D") else platform.get_node("RoofCollision")
	var shape := collision.shape as RectangleShape2D
	return platform.global_position.y+collision.position.y-shape.size.y*0.5

func spawn_enemy(archetype: String,x: float,lane: int) -> CharacterBody2D:
	if demo_closing:
		return null
	var enemy = ENEMY.instantiate()
	enemy.archetype = archetype
	enemy.lane_index = 0
	enemy.target = player
	enemy.position = Vector2(x,GameConfig.GROUND_Y)
	enemy.shot_requested.connect(func(o: Vector2,l: int,d: int,k: String,t: String) -> void:
		_relay_shot(enemy,o,l,d,k,t))
	enemy.ground_wave_requested.connect(_spawn_grandote_ground_wave)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.boss_escaped.connect(boss_escaped.emit)
	$Enemies.add_child(enemy)
	_batch.attach(enemy,archetype,BATCH_VISUALS.enemy_aliases(enemy),false)
	_add_contact_shadow(enemy,archetype)
	feel.watch_enemy(enemy)
	anim.watch_enemy(enemy)
	return enemy


## Emisor del disparo en curso (para decorar el proyectil en main) y punto de lanzamiento medido.
func _relay_shot(emitter: Node2D,origin: Vector2,lane: int,direction: Variant,kind: String,team: String) -> void:
	var muzzle := BATCH_VISUALS.muzzle_origin(emitter,origin)
	shot_emitter = emitter
	if direction is Vector2:
		aimed_shot_requested.emit(muzzle,lane,direction,kind,team)
	else:
		shot_requested.emit(muzzle,lane,int(direction),kind,team)
	shot_emitter = null


func _add_contact_shadow(actor: Node2D,character: String) -> void:
	var shadow := CONTACT_SHADOW.new()
	shadow.name = character.capitalize() + "ContactShadow"
	shadow.actor = actor
	shadow.visible_height = CFG.target_height(character)
	shadow.ground_y = GameConfig.GROUND_Y
	shadow.z_index = -1
	add_child(shadow)


func spawn_encounter_actor(archetype: String,x: float,lane: int) -> Node2D:
	if archetype == "drone_wave":
		var formation_index := _drone_wave_spawn_index%5
		_drone_wave_spawn_index += 1
		return spawn_drone(x,lane,formation_index,5)
	if archetype == "drone":
		return spawn_drone(x,lane)
	return spawn_enemy(archetype,x,lane)


func spawn_drone(x: float,lane: int,formation_index: int = 0,formation_size: int = 1) -> Node2D:
	if demo_closing:
		return null
	var drone = DRONE.instantiate()
	drone.formation_index = formation_index
	drone.formation_size = formation_size
	drone.formation_phase = TAU*float(formation_index)/float(maxi(1,formation_size))
	drone.wave_formation = formation_size>1
	drone.lane_index = 0
	drone.target = player
	drone.position = Vector2(x,GameConfig.GROUND_Y-drone.flight_height)
	drone.shot_requested.connect(func(o: Vector2,l: int,d: Vector2,k: String,t: String) -> void:
		_relay_shot(drone,o,l,d,k,t))
	drone.defeated.connect(_on_enemy_defeated)
	$Enemies.add_child(drone)
	feel.watch_enemy(drone)
	return drone


func spawn_palermitano(x: float,lane: int) -> CharacterBody2D:
	if demo_closing or is_instance_valid(boss):
		return boss
	boss_started = true
	boss_active = true
	_boss_feedback_active = true
	boss = PALERMITANO_BOSS.instantiate()
	boss.lane_index = 0
	boss.target = player
	boss.arena_bounds = BOSS_ARENA_BOUNDS
	boss.position = Vector2(x,GameConfig.GROUND_Y)
	boss.aimed_shot_requested.connect(func(o: Vector2,l: int,d: Vector2,k: String,t: String) -> void:
		_relay_shot(boss,o,l,d,k,t))
	boss.summon_requested.connect(_on_boss_summon_requested)
	boss.screen_shake_requested.connect(screen_shake_requested.emit)
	boss.defeated.connect(_on_palermitano_defeated,CONNECT_ONE_SHOT)
	boss.tree_exiting.connect(_on_palermitano_exiting,CONNECT_ONE_SHOT)
	$Enemies.add_child(boss)
	_batch.attach(boss,"palermitano",BATCH_VISUALS.boss_aliases(),false)
	_add_contact_shadow(boss,"palermitano")
	feel.watch_enemy(boss)
	anim.watch_enemy(boss)
	boss_director = BOSS_DIRECTOR.new()
	add_child(boss_director)
	boss_director.trigger_x = -INF
	boss_director.setup(boss,player,camera_node,hud_node,feel,$Enemies,$Projectiles)
	boss_director.intro_started.connect(func(): camera_locked = true)
	boss_director.intro_finished.connect(func(): camera_locked = false)
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
		var offset := -220.0 if index == 0 else 220.0
		var summon := spawn_enemy("agente",clampf(boss.position.x+offset,BOSS_ARENA_BOUNDS.x+80.0,BOSS_ARENA_BOUNDS.y-80.0),0)
		if is_instance_valid(summon):
			boss.register_summon(summon)


func _on_palermitano_defeated(points: int) -> void:
	if not boss_active:
		return
	_on_enemy_defeated(points)
	boss_defeated.emit()
	_clear_boss_feedback()


func _on_palermitano_exiting() -> void:
	camera_locked = false
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
	wave.position = Vector2(origin.x,GameConfig.GROUND_Y)
	wave.lane_index = 0
	wave.direction = direction
	$Projectiles.add_child(wave)
	return wave

## main entrega la HUD y la cámara antes de que aparezca el jefe.
func bind_presentation(hud_ref: Node,camera_ref: Camera2D) -> void:
	hud_node = hud_ref
	camera_node = camera_ref


## Tras elegir o restaurar personaje, el jugador recibe otra vez su SpriteFrames de juego: se vuelven a poner los cuadros nuevos.
func refresh_player_visuals() -> void:
	if player.visual.sprite_frames != null:
		_batch.attach(player,"ciruja",BATCH_VISUALS.CIRUJA_ALIASES)


func _spawn_miniboss_grandote(x: float,lane: int) -> CharacterBody2D:
	if is_instance_valid(miniboss):
		return miniboss
	miniboss = MINIBOSS_GRANDOTE.instantiate()
	miniboss.lane_index = 0
	miniboss.target = player
	miniboss.position = Vector2(x,GameConfig.GROUND_Y)
	miniboss.arena_bounds = MINIBOSS_ARENA_BOUNDS
	miniboss.defeated.connect(_on_miniboss_defeated)
	miniboss.screen_shake_requested.connect(screen_shake_requested.emit)
	miniboss.tree_exiting.connect(_on_miniboss_exiting,CONNECT_ONE_SHOT)
	$Enemies.add_child(miniboss)
	_batch.attach(miniboss,"grandote",BATCH_VISUALS.GRANDOTE_ALIASES,false)
	_add_contact_shadow(miniboss,"grandote")
	feel.watch_enemy(miniboss)
	anim.watch_enemy(miniboss)
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
	pickup.lane_index = 0
	pickup.pickup_id = pickup_id if not pickup_id.is_empty() else StringName("%s_%d_%d" % [kind,int(x),lane])
	pickup.position = Vector2(x,GameConfig.GROUND_Y if ground_y < 0.0 else ground_y)
	pickup.collected_with_id.connect(_on_pickup)
	$Objects.add_child(pickup)
	return pickup

func attach_vehicle_pickup(vehicle: Node2D,kind: StringName,asset: StringName,image_scale: float,pickup_id: StringName) -> Area2D:
	var pickup = PICKUP.instantiate()
	pickup.kind = String(kind)
	pickup.asset = String(asset)
	pickup.image_scale = image_scale
	pickup.lane_index = 0
	pickup.pickup_id = pickup_id
	pickup.position = Vector2(0.0,vehicle.get_roof_world_y()-vehicle.global_position.y-8.0)
	pickup.collected_with_id.connect(_on_pickup)
	vehicle.add_child(pickup)
	pickup.set_collected_state(collected_pickup_ids.has(pickup_id))
	return pickup

func _is_bus_set_piece_running() -> bool:
	return $ExpresbusSetPiece.is_running() or $TesaSetPiece.is_running()

func finish_bus_set_pieces(reason: String) -> void:
	$ExpresbusSetPiece.finish(reason)
	$TesaSetPiece.finish(reason)

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


func _configure_checkpoints() -> void:
	checkpoint_records = JSON.parse_string(FileAccess.get_file_as_string("res://data/checkpoints/route_38.json")).checkpoints
	for index in range(checkpoint_records.size()):
		var record: Dictionary = checkpoint_records[index]
		var checkpoint = $Checkpoint if index == 0 else CHECKPOINT_SCENE.instantiate()
		if index > 0:
			checkpoint.name = "Checkpoint_%s" % record.id
			add_child(checkpoint)
			checkpoint.activated.connect(checkpoint_activated.emit)
		checkpoint.checkpoint_id = StringName(record.id)
		checkpoint.position = Vector2(float(record.x),GameConfig.GROUND_Y+22.5)
		checkpoint.activation_guard = _checkpoint_is_safe.bind(record)
		record["node"] = checkpoint


func _checkpoint_is_safe(record: Dictionary) -> bool:
	if not player.controls_enabled or player.state == player.State.DEATH or not player.is_on_floor() \
			or absf(player.position.y-GameConfig.GROUND_Y)>2.0 or _is_bus_set_piece_running():
		return false
	if not encounter_director._pending.is_empty():
		return false
	for enemy in $Enemies.get_children():
		if enemy.get("active") == true:
			return false
	for encounter_id in record.required_encounters:
		if not encounter_director.is_encounter_completed(StringName(encounter_id)):
			return false
	if get_node(String(record.after_set_piece)).phase != ExpresbusSetPiece.Phase.FINISHED:
		return false
	return is_local_respawn_safe(Vector2(float(record.x),GameConfig.GROUND_Y),0) and is_local_respawn_safe(player.position,0)


func _update_checkpoints() -> void:
	for record: Dictionary in checkpoint_records:
		if player.position.x >= float(record.x) and not record.node.is_activated and _checkpoint_is_safe(record):
			record.node.activate_for(player)


func capture_checkpoint_level_state() -> Dictionary:
	var events: Dictionary = {}
	for event in [$ExpresbusSetPiece,$TesaSetPiece]:
		events[String(event.name)] = {"consumed":event.phase != event.Phase.READY,"spawn_count":event.spawn_count}
	return {"events":events,"location":current_location(player.position.x)}


func get_checkpoint_completed_encounters(respawn_x: float) -> Array[StringName]:
	var result: Array[StringName] = []
	# Delayed activation must not skip sections beyond the checkpoint's respawn point.
	for encounter: Dictionary in data.encounters:
		var encounter_id := StringName(encounter.id)
		if float(encounter.activation.value) <= respawn_x and encounter_director.is_encounter_completed(encounter_id):
			result.append(encounter_id)
	return result


func restore_checkpoint_level_state(snapshot: Dictionary,respawn_x: float) -> void:
	for event in [$ExpresbusSetPiece,$TesaSetPiece]:
		var saved: Dictionary = snapshot.get("events",{}).get(String(event.name),{})
		if bool(saved.get("consumed",false)) or event.trigger_x < respawn_x:
			event.phase = event.Phase.FINISHED
			event.spawn_count = int(saved.get("spawn_count",0))
			event.finish_reason = "checkpoint_restore"
	for record: Dictionary in checkpoint_records:
		if float(record.x) <= respawn_x:
			record.node.is_activated = true
			record.node.set_deferred("monitoring",false)
	last_safe_position = Vector2(respawn_x,GameConfig.GROUND_Y)
	_last_location = current_location(respawn_x)
	location_changed.emit(_last_location)


func update_last_safe_position() -> void:
	if player.state != player.State.DEATH and player.health > 0 and player.is_on_floor() \
			and is_local_respawn_safe(player.position,0):
		last_safe_position = player.position


func find_local_respawn(death_position: Vector2,preferred_lane: int) -> Dictionary:
	var bounds := Vector2(LOCAL_RESPAWN_EDGE_PADDING,GameConfig.WORLD_WIDTH-LOCAL_RESPAWN_EDGE_PADDING)
	if boss_active:
		bounds = Vector2(BOSS_ARENA_BOUNDS.x+LOCAL_RESPAWN_ARENA_PADDING,BOSS_ARENA_BOUNDS.y-LOCAL_RESPAWN_ARENA_PADDING)
	elif miniboss_active:
		bounds = Vector2(MINIBOSS_ARENA_BOUNDS.x+LOCAL_RESPAWN_ARENA_PADDING,MINIBOSS_ARENA_BOUNDS.y-LOCAL_RESPAWN_ARENA_PADDING)
	if absf(last_safe_position.x-death_position.x) <= SAFE_POSITION_MAX_AGE_DISTANCE and is_local_respawn_safe(last_safe_position,0):
		return {"found":true,"position":last_safe_position,"lane_index":0,"used_fallback":false}
	# Prefer the death position, then the closest safe point on either side. Never rewind progress.
	for distance in range(0,257,16):
		for side in [-1.0,1.0]:
			var candidate := Vector2(clampf(death_position.x+distance*side,bounds.x,bounds.y),GameConfig.GROUND_Y)
			if candidate.x < death_position.x-SAFE_POSITION_MAX_AGE_DISTANCE:
				continue
			if is_local_respawn_safe(candidate,0):
				return {"found":true,"position":candidate,"lane_index":0,"used_fallback":false}
	return {"found":false,"position":Vector2.ZERO,"lane_index":0,"used_fallback":true}


func is_local_respawn_safe(candidate: Vector2,lane: int) -> bool:
	if not is_equal_approx(candidate.y,GameConfig.GROUND_Y):
		return false
	if candidate.x < LOCAL_RESPAWN_EDGE_PADDING or candidate.x > GameConfig.WORLD_WIDTH-LOCAL_RESPAWN_EDGE_PADDING:
		return false
	if boss_active and (candidate.x < BOSS_ARENA_BOUNDS.x+LOCAL_RESPAWN_ARENA_PADDING or candidate.x > BOSS_ARENA_BOUNDS.y-LOCAL_RESPAWN_ARENA_PADDING):
		return false
	var player_shape: RectangleShape2D = player.hurtbox.collision_shape.shape
	var player_rect := Rect2(candidate+player.hurtbox.collision_shape.position-player_shape.size*0.5,player_shape.size).grow(8.0)
	for platform in $Terrain.get_children():
		if not platform.is_in_group("stationary_vehicles"):
			continue
		var visual: AnimatedSprite2D = platform.get_node("Visual")
		var texture := visual.sprite_frames.get_frame_texture(visual.animation,visual.frame)
		var bounds := CollisionFactory.opaque_bounds(texture)
		bounds.position -= texture.get_size()*0.5
		if player_rect.intersects(visual.global_transform*bounds):
			return false
	for vehicle in traffic_director.get_active_vehicles():
		if not is_instance_valid(vehicle):
			continue
		var half_width := LOCAL_RESPAWN_VEHICLE_CLEARANCE
		var impact_hitbox := vehicle.get_node_or_null("ImpactHitbox")
		if impact_hitbox != null and impact_hitbox.get("attack_definition") != null:
			half_width = maxf(half_width,float(impact_hitbox.attack_definition.reach.x)*0.5+36.0)
		if absf(vehicle.global_position.x-candidate.x) <= half_width:
			return false
	for enemy in $Enemies.get_children():
		if not is_instance_valid(enemy):
			continue
		if enemy.get("active") != null and not bool(enemy.get("active")):
			continue
		var enemy_shape := enemy.get_node_or_null("Hurtbox/CollisionShape2D") as CollisionShape2D
		if enemy_shape != null and enemy_shape.shape is RectangleShape2D and player_rect.intersects(Rect2(enemy_shape.global_position-enemy_shape.shape.size*0.5,enemy_shape.shape.size)):
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
	if not is_instance_valid(projectile) or projectile.is_queued_for_deletion() or projectile.get("spent") == true or projectile.get("team") == null or StringName(projectile.get("team")) == &"player":
		return false
	return projectile.global_position.distance_to(candidate) <= radius


func _is_active_hitbox_near(hitbox: Node,candidate: Vector2,lane: int) -> bool:
	if hitbox.get("active") == null or not bool(hitbox.get("active")) or hitbox.get("team") == null \
			or StringName(hitbox.get("team")) == &"player":
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
	finish_bus_set_pieces("checkpoint_restore")
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
	_refresh_protected_rewards()
