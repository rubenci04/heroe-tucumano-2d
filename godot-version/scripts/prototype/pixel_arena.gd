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


func _ready() -> void:
	INPUT_SETUP.configure()
	feel = FEEL_DIRECTOR.new()
	add_child(feel)
	feel.setup(world,$ViewportContainer,player)
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
	player.shot_requested.connect(_spawn_projectile.bind(player))
	player.respawn_requested.connect(_on_player_respawn_requested)
	_refill_player()
	_spawn_enemy("hipster",ARENA_RIGHT-60.0)
	_spawn_enemy("agente",ARENA_RIGHT-140.0)
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


func _spawn_enemy(archetype: String,x: float) -> void:
	var enemy = ENEMY_SCENE.instantiate()
	enemy.archetype = archetype
	enemy.target = player
	enemy.position = Vector2(x,GameConfig.GROUND_Y)
	enemy.shot_requested.connect(_spawn_projectile.bind(enemy))
	enemies.add_child(enemy)
	CHARACTER_SCALE.remember(enemy)
	if archetype == "agente":
		_apply_batch_frames(enemy, "agente", {
			enemy.definition.run_animation: &"correr", enemy.definition.attack_animation: &"disparar",
			&"Punch": &"punio", &"Death": &"muerte"
		})
	CHARACTER_SCALE.apply(enemy, archetype)
	feel.watch_enemy(enemy)
	anim.watch_enemy(enemy)


func _apply_batch_frames(actor: Node, character: String, aliases: Dictionary) -> void:
	var path := BATCH_FRAMES + character + ".tres"
	if not ResourceLoader.exists(path):
		push_warning("Build character frames first: " + path)
		return
	var incoming := load(path) as SpriteFrames
	var sprite: AnimatedSprite2D = actor.visual
	var frames: SpriteFrames = sprite.sprite_frames.duplicate(true)
	# Keep every folder available under its source name; aliases bridge existing states.
	for name in incoming.get_animation_names():
		_copy_animation(incoming, name, frames, name)
	for name in aliases:
		if incoming.has_animation(aliases[name]):
			_copy_animation(incoming, aliases[name], frames, name)
	# No Idle folder for Ciruja/Agente: a static first Run pose, not a fabricated animation.
	if incoming.has_animation(&"correr"):
		var idle_name: StringName = actor.character_definition.idle_animation if character == "ciruja" else &"Idle"
		if not frames.has_animation(idle_name):
			frames.add_animation(idle_name)
		frames.clear(idle_name)
		frames.add_frame(idle_name, incoming.get_frame_texture(&"correr", 0))
		frames.set_animation_speed(idle_name, 1.0)
		frames.set_animation_loop(idle_name, true)
	var current := sprite.animation
	sprite.sprite_frames = frames
	sprite.play(current)
	sprite.set_meta("batch_ground_y", float(incoming.get_meta("ground_y")))
	# Retain the original actor colliders and scale; this is a prototype visual swap.
	if character == "ciruja":
		actor._visual_frame_offsets.clear()
	else:
		actor._visual_offset_profiles.clear()
	batch_visuals.append(sprite)
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
	batch_visuals.append(sprite)
	_anchor_batch_visual(sprite)


func _process(_delta: float) -> void:
	for sprite in batch_visuals:
		if is_instance_valid(sprite):
			_anchor_batch_visual(sprite)


func _anchor_batch_visual(sprite: AnimatedSprite2D) -> void:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	var is_batch := texture.resource_path.begins_with("res://characters/") or texture.resource_path.begins_with("res://assets/characters/")
	var feet_y := float(sprite.get_meta("batch_ground_y")) if is_batch else texture.get_height() * 0.5 + 98.0
	# Centered sprite: canvas y=240 maps to actor origin, including rotation/stretch.
	sprite.offset = Vector2(0.0, texture.get_height() * 0.5 - feet_y)
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
