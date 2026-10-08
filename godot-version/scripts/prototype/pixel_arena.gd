extends Node2D
## Arena experimental: reutiliza player/enemy/projectile/vehicle tal cual, sin tocar route_38.

const INPUT_SETUP = preload("res://scripts/core/input_setup.gd")
const PROJECTILE_SCENE = preload("res://scenes/actors/projectile.tscn")
const ENEMY_SCENE = preload("res://scenes/actors/enemy.tscn")
const VEHICLE_SCENE = preload("res://scenes/actors/vehicle.tscn")
const FEEL_DIRECTOR = preload("res://scripts/prototype/feel_director.gd")
const CIRUJA_SKIN = preload("res://scripts/prototype/ciruja_skin.gd")
const PROCEDURAL_ANIM = preload("res://scripts/prototype/procedural_anim.gd")
const BATCH_VISUALS = preload("res://scripts/prototype/batch_visuals.gd")
const BOSS_SCENE = preload("res://scenes/actors/palermitano_boss.tscn")
const GROUND_WAVE_SCENE = preload("res://scenes/actors/grandote_ground_wave.tscn")
const CONTACT_SHADOW = preload("res://scripts/prototype/contact_shadow.gd")
const PROJECTILE_FX = preload("res://scripts/prototype/projectile_fx.gd")
const BOSS_DIRECTOR = preload("res://scripts/prototype/boss_director.gd")
const PROTOTYPE_HUD = preload("res://scripts/prototype/prototype_hud.gd")
const PROTOTYPE_BACKDROP = preload("res://scripts/prototype/prototype_backdrop.gd")
const CFG = preload("res://scripts/prototype/feel_config.gd")
const ARC_SHOT = preload("res://scripts/prototype/arc_shot.gd")
const STAIN_MANAGER = preload("res://scripts/prototype/stain_manager.gd")
const ARENA_LEFT := 200.0
const ARENA_RIGHT := 600.0
const PLAYER_START := Vector2(260.0,370.0)
var batch: Node

@onready var world: Node2D = $ViewportContainer/SubViewport/World
@onready var player: CharacterBody2D = $ViewportContainer/SubViewport/World/Player
@onready var enemies: Node2D = $ViewportContainer/SubViewport/World/Enemies
@onready var projectiles: Node2D = $ViewportContainer/SubViewport/World/Projectiles
@onready var vehicles: Node2D = $ViewportContainer/SubViewport/World/Vehicles
var car: Node2D
var feel: Node
var anim: Node
var hud: CanvasLayer
var boss_director: Node
var backdrop: Node2D
var boss: CharacterBody2D
var stains: Node
var campeona: AnimatedSprite2D
var campeona_taken := false


func _ready() -> void:
	INPUT_SETUP.configure()
	batch = BATCH_VISUALS.new()
	add_child(batch)
	backdrop = PROTOTYPE_BACKDROP.new()
	world.add_child(backdrop)
	backdrop.setup(player,ARENA_LEFT,($ViewportContainer/SubViewport/World/Camera2D as Camera2D).position.x)
	feel = FEEL_DIRECTOR.new()
	add_child(feel)
	feel.setup(world,$ViewportContainer,player)
	feel.arena_bounds = Vector2(ARENA_LEFT + 20.0,ARENA_RIGHT - 15.0)
	batch.attach(player, "ciruja", BATCH_VISUALS.CIRUJA_ALIASES)
	# Keep the previous skin fallback only when no new batch resource is present.
	if not player.visual.has_meta("batch_ground_y"):
		CIRUJA_SKIN.apply(player)
		CIRUJA_SKIN.apply_run_pixellab(player)
	anim = PROCEDURAL_ANIM.new()
	add_child(anim)
	anim.setup(world,player)
	anim.fx = feel.fx
	stains = STAIN_MANAGER.new()
	add_child(stains)
	stains.setup(world,player,feel.fx)
	player.shot_requested.connect(_spawn_projectile.bind(player))
	player.respawn_requested.connect(_on_player_respawn_requested)
	_refill_player()
	_add_contact_shadow(player, "ciruja")
	_spawn_enemy("hipster",ARENA_RIGHT-60.0)
	_spawn_enemy("agente",ARENA_RIGHT-140.0)
	_spawn_enemy("grandote",ARENA_RIGHT-210.0)
	hud = PROTOTYPE_HUD.new()
	add_child(hud)
	hud.bind_player(player)
	boss = _spawn_boss()
	boss_director = BOSS_DIRECTOR.new()
	add_child(boss_director)
	boss_director.setup(boss,player,$ViewportContainer/SubViewport/World/Camera2D,hud,feel,enemies,projectiles)
	boss_director.fight_won.connect(_show_result_after_delay.bind(&"victory"))
	boss_director.intro_started.connect(_take_campeona)
	player.died.connect(_show_result_after_delay.bind(&"game_over"))
	_spawn_campeona()
	_spawn_car()
	# Apply anchoring after existing procedural animation; production code is untouched.
	process_priority = 100


func _physics_process(_delta: float) -> void:
	if is_instance_valid(car) and car.position.x < ARENA_LEFT-120.0:
		car.position.x = ARENA_RIGHT+120.0


func _refill_player() -> void:
	player.stones = 99
	player.oranges_unlocked = true


## Mismo cableado que route_38: sin esto el puntaje queda en 0 (00000) en el HUD y en la pantalla final.
func _on_enemy_defeated(points: int) -> void:
	player.score += points
	player.status_changed.emit()


func _on_player_respawn_requested() -> void:
	player.lives = maxi(player.lives,1)
	player.respawn_at(PLAYER_START,{})
	_refill_player()


func _spawn_enemy(archetype: String,x: float) -> CharacterBody2D:
	var enemy = ENEMY_SCENE.instantiate()
	enemy.archetype = archetype
	enemy.target = player
	enemy.position = Vector2(x,GameConfig.GROUND_Y)
	enemy.shot_requested.connect(_spawn_projectile.bind(enemy))
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.ground_wave_requested.connect(_spawn_ground_wave.bind(enemy))
	enemies.add_child(enemy)
	batch.attach(enemy, archetype, BATCH_VISUALS.enemy_aliases(enemy))
	_add_contact_shadow(enemy, archetype)
	feel.watch_enemy(enemy)
	anim.watch_enemy(enemy)
	return enemy


func _spawn_boss() -> CharacterBody2D:
	var boss = BOSS_SCENE.instantiate()
	boss.intro_duration = CFG.BOSS_ACTIVATE_REACTION
	boss.target = player
	boss.position = Vector2(ARENA_RIGHT - 15.0, GameConfig.GROUND_Y)
	boss.arena_bounds = Vector2(ARENA_LEFT + 20.0, ARENA_RIGHT - 15.0)
	boss.aimed_shot_requested.connect(_spawn_projectile.bind(boss))
	boss.defeated.connect(_on_enemy_defeated)
	boss.summon_requested.connect(func(count: int, _lane: int):
		for _index in count:
			if boss.get_live_summon_count() < boss.max_live_summons:
				boss.register_summon(_spawn_enemy("agente", ARENA_RIGHT - 45.0)))
	enemies.add_child(boss)
	batch.attach(boss, "palermitano", BATCH_VISUALS.boss_aliases())
	_add_contact_shadow(boss, "palermitano")
	feel.watch_enemy(boss)
	anim.watch_enemy(boss)
	if CFG.BOSS_CHAIN_ANIMATED:
		boss.pattern_started.connect(func(pattern: int):
			if pattern == boss.Pattern.CHAIN:
				boss.visual.play(&"golpe" if boss.chain_activations % 2 == 0 else &"golpe_v2"))
	return boss


func _spawn_ground_wave(origin: Vector2, lane: int, direction: int, emitter: Node2D) -> void:
	var wave = GROUND_WAVE_SCENE.instantiate()
	wave.position = emitter.global_position + (origin - emitter.global_position) * emitter.scale
	wave.lane_index = lane
	wave.direction = direction
	projectiles.add_child(wave)
	# The legacy wave toggles monitoring on hit; defer that call outside the physics signal.
	wave.body_entered.disconnect(wave._on_body_entered)
	wave.body_entered.connect(func(body: Node): wave.call_deferred("try_hit_body", body))


func _spawn_campeona() -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.name = "CampeonaBatch"
	sprite.position = Vector2(ARENA_LEFT + 25.0, GameConfig.GROUND_Y)
	world.add_child(sprite)
	batch.attach_npc(sprite, "campeona", &"idle")
	_add_contact_shadow(sprite, "campeona")
	campeona = sprite


## Forcejea y es arrastrada a la derecha fuera de cámara; después se elimina (no vuelve a la esquina).
func _take_campeona() -> void:
	if campeona_taken or not is_instance_valid(campeona):
		return
	campeona_taken = true
	var sprite := campeona
	var camera := $ViewportContainer/SubViewport/World/Camera2D as Camera2D
	sprite.play(&"forcejeo")
	var exit_x := camera.position.x + 200.0 + CFG.CAMPEONA_EXIT_MARGIN
	var tween := create_tween()
	tween.tween_interval(CFG.CAMPEONA_STRUGGLE_TIME)
	tween.tween_callback(func():
		sprite.flip_h = true
		feel.shake(CFG.CAMPEONA_DRAG_SHAKE, CFG.CAMPEONA_DRAG_TIME))
	tween.tween_property(sprite, "position:x", exit_x, CFG.CAMPEONA_DRAG_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		batch.release(sprite)
		sprite.queue_free()
		campeona = null)


func _add_contact_shadow(actor: Node2D, character: String) -> void:
	var shadow = CONTACT_SHADOW.new()
	shadow.name = character.capitalize() + "ContactShadow"
	shadow.actor = actor
	shadow.visible_height = preload("res://scripts/prototype/feel_config.gd").target_height(character)
	shadow.ground_y = GameConfig.GROUND_Y
	shadow.z_index = -1
	world.add_child(shadow)


func _process(_delta: float) -> void:
	if player.state == player.State.DEATH:
		player.visual.rotation = 0.0 # New death poses already contain the fall.
	# Pose, volteo y anclaje de los cuadros nuevos: BATCH_VISUALS (compartido con la ruta 38).
	for enemy in enemies.get_children():
		if enemy.get("archetype") == "hipster":
			_update_hipster_attack(enemy)


func _update_hipster_attack(enemy: Node) -> void:
	# Alternate existing throw actions locally; production Hipster stays coffee-only.
	var preparing: bool = enemy.ai_state == enemy.AIState.TELEGRAPH
	if preparing and not enemy.get_meta("batch_preparing", false):
		var bottle: bool = not enemy.get_meta("batch_last_bottle", true)
		enemy.set_meta("batch_last_bottle", bottle)
		enemy.definition.projectile_definition = load("res://data/projectiles/bottle.tres" if bottle else "res://data/projectiles/hipster_coffee.tres")
		enemy.definition.attack_animation = &"tirar_botella" if bottle else &"tirar_cafe"
		enemy.visual.play(enemy.definition.attack_animation)
	enemy.set_meta("batch_preparing", preparing)


func _spawn_car() -> void:
	car = VEHICLE_SCENE.instantiate()
	car.configure(&"auto1",0.95,0,-1,120.0)
	car.position = Vector2(ARENA_RIGHT+120.0,GameConfig.GROUND_Y)
	vehicles.add_child(car)


func _spawn_projectile(origin: Vector2,_lane: int,direction: Variant,kind: String,team: String, emitter: Node2D = null) -> void:
	if is_instance_valid(emitter):
		origin = BATCH_VISUALS.muzzle_origin(emitter, origin)
	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.position = origin
	projectile.lane_index = 0
	if direction is Vector2:
		projectile.travel_direction = direction
	else:
		projectile.direction = int(direction)
	projectile.kind = kind
	projectile.team = team
	if team == "player":
		projectile.impact_confirmed.connect(player.register_valid_hit)
		feel.watch_projectile(projectile)
	projectile.z_index = 20
	projectiles.add_child(projectile)
	var emitter_character: String = emitter.get_meta("prototype_character", "") if is_instance_valid(emitter) else ""
	PROJECTILE_FX.decorate(projectile, kind, emitter_character)
	if team == "enemy" and kind in CFG.ARC_KINDS and is_instance_valid(player):
		ARC_SHOT.attach(projectile, player.global_position + CFG.ARC_AIM_OFFSET, kind).landed.connect(stains.add_stain)
	if emitter_character == "agente":
		var shot_direction: Vector2 = direction if direction is Vector2 else Vector2(float(direction), 0.0)
		feel.fx.muzzle_flash(origin, shot_direction, CFG.ENEMY_MUZZLE_SIZE)
		feel.fx.casing(origin, shot_direction)


func _show_result_after_delay(result: StringName) -> void:
	if is_instance_valid(player):
		player.controls_enabled = false
	await get_tree().create_timer(CFG.HUD_RESULT_DELAY).timeout
	if result == &"victory":
		hud.show_victory()
	else:
		hud.show_game_over()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()
