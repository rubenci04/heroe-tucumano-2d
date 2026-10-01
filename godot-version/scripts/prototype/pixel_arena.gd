extends Node2D
## Arena experimental: reutiliza player/enemy/projectile/vehicle tal cual, sin tocar route_38.

const INPUT_SETUP = preload("res://scripts/core/input_setup.gd")
const PROJECTILE_SCENE = preload("res://scenes/actors/projectile.tscn")
const ENEMY_SCENE = preload("res://scenes/actors/enemy.tscn")
const VEHICLE_SCENE = preload("res://scenes/actors/vehicle.tscn")
const FEEL_DIRECTOR = preload("res://scripts/prototype/feel_director.gd")
const CIRUJA_SKIN = preload("res://scripts/prototype/ciruja_skin.gd")
const PROCEDURAL_ANIM = preload("res://scripts/prototype/procedural_anim.gd")
const ARENA_LEFT := 200.0
const ARENA_RIGHT := 600.0
const PLAYER_START := Vector2(260.0,370.0)

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
	CIRUJA_SKIN.apply(player)
	anim = PROCEDURAL_ANIM.new()
	add_child(anim)
	anim.setup(world,player)
	player.shot_requested.connect(_spawn_projectile)
	player.respawn_requested.connect(_on_player_respawn_requested)
	_refill_player()
	_spawn_enemy("hipster",ARENA_RIGHT-60.0)
	_spawn_enemy("agente",ARENA_RIGHT-140.0)
	_spawn_car()


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
	enemy.shot_requested.connect(_spawn_projectile)
	enemies.add_child(enemy)
	feel.watch_enemy(enemy)
	anim.watch_enemy(enemy)


func _spawn_car() -> void:
	car = VEHICLE_SCENE.instantiate()
	car.configure(&"auto1",0.95,0,-1,120.0)
	car.position = Vector2(ARENA_RIGHT+120.0,GameConfig.GROUND_Y)
	vehicles.add_child(car)


func _spawn_projectile(origin: Vector2,_lane: int,direction: Variant,kind: String,team: String) -> void:
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
