extends Node2D
## Arena experimental: reutiliza player/enemy/projectile/vehicle tal cual, sin tocar route_38.

const INPUT_SETUP = preload("res://scripts/core/input_setup.gd")
const PROJECTILE_SCENE = preload("res://scenes/actors/projectile.tscn")
const ENEMY_SCENE = preload("res://scenes/actors/enemy.tscn")
const VEHICLE_SCENE = preload("res://scenes/actors/vehicle.tscn")
const FEEL_DIRECTOR = preload("res://scripts/prototype/feel_director.gd")
const CIRUJA_SKIN = preload("res://scripts/prototype/ciruja_skin.gd")
const PROCEDURAL_ANIM = preload("res://scripts/prototype/procedural_anim.gd")
const CHARACTER_SCALE = preload("res://scripts/prototype/character_scale.gd")
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
const BATCH_FRAMES := "res://assets/animations/generated/"
var batch_visuals: Array[AnimatedSprite2D] = []

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
	backdrop = PROTOTYPE_BACKDROP.new()
	world.add_child(backdrop)
	backdrop.setup(player,ARENA_LEFT,($ViewportContainer/SubViewport/World/Camera2D as Camera2D).position.x)
	feel = FEEL_DIRECTOR.new()
	add_child(feel)
	feel.setup(world,$ViewportContainer,player)
	feel.arena_bounds = Vector2(ARENA_LEFT + 20.0,ARENA_RIGHT - 15.0)
	_apply_batch_frames(player, "ciruja", {
		&"Run": &"correr", &"Punch": &"pinazo", &"Headbutt": &"embestida", &"Death": &"muerte"
	})
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
	enemy.ground_wave_requested.connect(_spawn_ground_wave.bind(enemy))
	enemies.add_child(enemy)
	CHARACTER_SCALE.remember(enemy)
	if archetype == "agente":
		_apply_batch_frames(enemy, "agente", {
			enemy.definition.run_animation: &"correr", enemy.definition.attack_animation: &"disparar",
			&"Punch": &"punio", &"Death": &"muerte"
		})
	elif archetype == "hipster":
		_apply_batch_frames(enemy, "hipster", {
			enemy.definition.run_animation: &"avanzar_idle", enemy.definition.attack_animation: &"tirar_cafe",
			&"Death": &"caida"
		})
	elif archetype == "grandote":
		_apply_batch_frames(enemy, "grandote", {
			enemy.definition.run_animation: &"correr", enemy.definition.attack_animation: &"punio",
			&"grandote_ground_slam": &"golpe_piso", &"Death": &"muerte"
		})
	CHARACTER_SCALE.apply(enemy, archetype)
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
	boss.summon_requested.connect(func(count: int, _lane: int):
		for _index in count:
			if boss.get_live_summon_count() < boss.max_live_summons:
				boss.register_summon(_spawn_enemy("agente", ARENA_RIGHT - 45.0)))
	enemies.add_child(boss)
	CHARACTER_SCALE.remember(boss)
	_apply_batch_frames(boss, "palermitano", {
		&"boss_run": &"correr", &"boss_idle": &"idle", &"boss_punch": &"golpe_v2" if CFG.BOSS_CHAIN_ANIMATED else &"idle",
		&"boss_joke": &"idle_v2", &"boss_order": &"idle_v2", &"Death": &"derrota"
	})
	CHARACTER_SCALE.apply(boss, "palermitano")
	_add_contact_shadow(boss, "palermitano")
	feel.watch_enemy(boss)
	anim.watch_enemy(boss)
	if CFG.BOSS_CHAIN_ANIMATED:
		boss.pattern_started.connect(func(pattern: int):
			if pattern == boss.Pattern.CHAIN:
				boss.visual.play(&"golpe" if boss.chain_activations % 2 == 0 else &"golpe_v2"))
	boss.health_component.damaged.connect(func(_amount, _health, _source):
		if boss.boss_state in [boss.BossState.DECIDE, boss.BossState.RECOVERY]:
			boss.visual.play(&"golpes_recibidos"))
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


func _apply_batch_frames(actor: Node, character: String, aliases: Dictionary) -> void:
	var path := BATCH_FRAMES + character + ".tres"
	if not ResourceLoader.exists(path):
		push_warning("Build character frames first: " + path)
		return
	var incoming := load(path) as SpriteFrames
	var sprite: AnimatedSprite2D = actor.visual
	sprite.set_meta("batch_character", character)
	sprite.set_meta("legacy_offsets", (actor._visual_frame_offsets if character == "ciruja" else actor._visual_offset_profiles).duplicate(true))
	var frames: SpriteFrames = sprite.sprite_frames.duplicate(true)
	# Keep every folder available under its source name; aliases bridge existing states.
	for name in incoming.get_animation_names():
		_copy_animation(incoming, name, frames, name)
	for name in aliases:
		if incoming.has_animation(aliases[name]):
			_copy_animation(incoming, aliases[name], frames, name)
	# Ciruja: idle = f_00 de ajustar_gorra (parado, neutro). Agente: primera pose de Run.
	if incoming.has_animation(&"correr"):
		var idle_name: StringName = actor.character_definition.idle_animation if character == "ciruja" else &"Idle"
		if not frames.has_animation(idle_name):
			frames.add_animation(idle_name)
		frames.clear(idle_name)
		var idle_texture := incoming.get_frame_texture(&"correr", 0)
		if character == "ciruja" and incoming.has_animation(CFG.IDLE_SOURCE_ANIMATION):
			idle_texture = incoming.get_frame_texture(CFG.IDLE_SOURCE_ANIMATION, CFG.IDLE_SOURCE_FRAME)
		frames.add_frame(idle_name, idle_texture)
		frames.set_animation_speed(idle_name, 1.0)
		frames.set_animation_loop(idle_name, true)
	var current := sprite.animation
	sprite.sprite_frames = frames
	sprite.play(current)
	sprite.set_meta("batch_ground_y", float(incoming.get_meta("ground_y")))
	sprite.set_meta("batch_visual_scale", sprite.scale.y)
	sprite.set_meta("batch_reference_height", CollisionFactory.opaque_bounds(incoming.get_frame_texture(aliases.values()[0], 0)).size.y)
	# Retain the original actor colliders and scale; this is a prototype visual swap.
	if character == "ciruja":
		actor._visual_frame_offsets.clear()
	else:
		actor._visual_offset_profiles.clear()
	batch_visuals.append(sprite)
	sprite.animation_changed.connect(_anchor_batch_visual.bind(sprite))
	sprite.frame_changed.connect(_anchor_batch_visual.bind(sprite))
	_anchor_batch_visual(sprite)


func _copy_animation(source: SpriteFrames, source_name: StringName, target: SpriteFrames, target_name: StringName) -> void:
	if not target.has_animation(target_name):
		target.add_animation(target_name)
	target.clear(target_name)
	target.set_animation_speed(target_name, source.get_animation_speed(source_name))
	target.set_animation_loop(target_name, source.get_animation_loop(source_name))
	for index in source.get_frame_count(source_name):
		target.add_frame(target_name, source.get_frame_texture(source_name, index), source.get_frame_duration(source_name, index))


func _spawn_campeona() -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.name = "CampeonaBatch"
	sprite.sprite_frames = load(BATCH_FRAMES + "campeona.tres") as SpriteFrames
	sprite.position = Vector2(ARENA_LEFT + 25.0, GameConfig.GROUND_Y)
	world.add_child(sprite)
	sprite.set_meta("batch_ground_y", float(sprite.sprite_frames.get_meta("ground_y")))
	sprite.set_meta("batch_static_actor", true)
	sprite.play(&"idle")
	CHARACTER_SCALE.apply_npc(sprite, "campeona")
	_add_contact_shadow(sprite, "campeona")
	batch_visuals.append(sprite)
	_anchor_batch_visual(sprite)
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
		batch_visuals.erase(sprite)
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
	for enemy in enemies.get_children():
		if enemy.get("boss_state") != null and enemy.active:
			if enemy.boss_state == enemy.BossState.DECIDE:
				var idle: StringName = &"idle_v2" if enemy.last_pattern == enemy.Pattern.SUMMON_AGENTS else &"idle"
				if enemy.visual.animation != &"golpes_recibidos" or not enemy.visual.is_playing():
					enemy.visual.play(idle)
		if enemy.get("archetype") == "hipster":
			enemy.visual.flip_h = enemy.facing < 0 # New scooter artwork faces right.
			_update_hipster_attack(enemy)
		if enemy.get("archetype") == "grandote" and enemy.active_attack_kind == enemy.AttackKind.GROUND_SLAM:
			# Existing slam gameplay has 13 legacy poses; map its stages onto seven new poses.
			if enemy.ai_state == enemy.AIState.TELEGRAPH:
				var progress: float = 1.0 - enemy._state_remaining / enemy.GRANDOTE_SLAM_DEFINITION.startup_duration
				enemy.visual.frame = clampi(int(progress * 4.0), 0, 3)
			elif enemy.ai_state == enemy.AIState.ATTACK:
				enemy.visual.frame = 4
			elif enemy.ai_state == enemy.AIState.RECOVERY:
				enemy.visual.frame = 5 if enemy._state_remaining > enemy.GRANDOTE_SLAM_DEFINITION.recovery_duration * 0.5 else 6
	for sprite in batch_visuals:
		if is_instance_valid(sprite):
			_anchor_batch_visual(sprite)


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


func _anchor_batch_visual(sprite: AnimatedSprite2D) -> void:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return # animation_changed can fire before Godot resets the previous frame index.
	var is_batch := texture.resource_path.begins_with("res://characters/") or texture.resource_path.begins_with("res://assets/characters/")
	var feet_y := float(sprite.get_meta("batch_ground_y")) if is_batch else CollisionFactory.opaque_bounds(texture).end.y
	var base_scale: float = sprite.get_meta("batch_visual_scale", sprite.scale.y)
	if not is_batch:
		var first := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
		base_scale *= float(sprite.get_meta("batch_reference_height", 190.0)) / CollisionFactory.opaque_bounds(first).size.y
	sprite.scale = Vector2.ONE * base_scale * Vector2(sprite.get_meta("pose_multiplier", Vector2.ONE))
	# Centered sprite: canvas y=240 maps to actor origin, including rotation/stretch.
	sprite.offset = Vector2(0.0, texture.get_height() * 0.5 - feet_y)
	if not is_batch:
		var offsets: Array = sprite.get_meta("legacy_offsets", {}).get(sprite.animation, [])
		if sprite.frame < offsets.size():
			var saved = offsets[sprite.frame]
			sprite.offset.x = saved.x if saved is Vector2 else float(saved[0])
	if not sprite.has_meta("batch_static_actor"):
		sprite.position.y = 0.0


func _spawn_car() -> void:
	car = VEHICLE_SCENE.instantiate()
	car.configure(&"auto1",0.95,0,-1,120.0)
	car.position = Vector2(ARENA_RIGHT+120.0,GameConfig.GROUND_Y)
	vehicles.add_child(car)


func _spawn_projectile(origin: Vector2,_lane: int,direction: Variant,kind: String,team: String, emitter: Node2D = null) -> void:
	if is_instance_valid(emitter):
		origin = emitter.global_position + (origin - emitter.global_position) * emitter.scale
		var sockets: Dictionary = preload("res://scripts/prototype/feel_config.gd").BATCH_MUZZLE_SOURCE
		var character: String = emitter.get_meta("prototype_character", "")
		if sockets.has(character):
			# Source pixels follow the visual transform, including its procedural recoil.
			var socket: Vector2 = sockets[character] - Vector2(160, 240)
			var mirrored: bool = emitter.facing < 0 if character == "hipster" else emitter.facing > 0
			if mirrored:
				socket.x = -socket.x
			origin = emitter.visual.to_global(socket)
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
