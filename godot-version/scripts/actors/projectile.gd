extends Area2D

const PROJECTILE_DEFINITION = preload("res://scripts/data/projectile_definition.gd")
const DEFINITIONS: Dictionary = {
	&"orange": preload("res://data/projectiles/orange.tres"),
	&"stone": preload("res://data/projectiles/stone.tres"),
	&"bottle": preload("res://data/projectiles/bottle.tres"),
	&"coffee": preload("res://data/projectiles/coffee.tres"),
	&"bullet": preload("res://data/projectiles/bullet.tres"),
	&"drone_bolt": preload("res://data/projectiles/drone_bolt.tres")
}

signal hit_confirmed(hurtbox: Area2D)
signal impact_confirmed(hurtbox: Area2D,impact_id: StringName)

static var _next_impact_serial: int = 1

@export var definition: PROJECTILE_DEFINITION
var kind: StringName = &"orange"
var team: StringName = &""
var lane_index: int = 0
var direction: int = 1
var travel_direction: Vector2 = Vector2.ZERO
var remaining_life: float = 0.0
var speed: float = 0.0
var damage: int = 0
var spent: bool = false
var impact_serial: int = 0

@onready var visual: AnimatedSprite2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	impact_serial = _next_impact_serial
	_next_impact_serial += 1
	if definition == null:
		definition = get_definition(kind)
	if definition == null or not definition.is_valid():
		push_error("ProjectileDefinition inválida para: %s" % kind)
		queue_free()
		return
	kind = definition.projectile_id
	if team.is_empty():
		team = definition.default_team
	direction = -1 if direction < 0 else 1
	travel_direction = Vector2(direction,0.0) if travel_direction.is_zero_approx() else travel_direction.normalized()
	speed = definition.speed
	damage = definition.damage
	remaining_life = definition.lifetime
	visual.sprite_frames = definition.sprite_frames
	visual.animation = definition.animation
	visual.scale = Vector2.ONE*definition.visual_scale
	# Player projectiles face their travel vector once. Enemy projectile presentation
	# keeps its legacy behavior; the agent bullet itself faces left at rest.
	if kind == &"bullet":
		visual.rotation = PI if direction > 0 else 0.0
	elif team == &"player" or kind in [&"drone_bolt",&"coffee"]:
		visual.rotation = travel_direction.angle()
	visual.play(definition.animation)
	var rectangle := collision_shape.shape as RectangleShape2D
	rectangle.size = definition.collision_size
	collision_shape.position = definition.collision_offset
	collision_layer = GameConfig.PROJECTILE_LAYER
	collision_mask = (GameConfig.ENEMY_LAYER if team == &"player" else GameConfig.PLAYER_LAYER) | (1 << lane_index)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


static func get_definition(projectile_id: StringName) -> PROJECTILE_DEFINITION:
	return DEFINITIONS.get(projectile_id) as PROJECTILE_DEFINITION


func _physics_process(delta: float) -> void:
	if spent or definition == null:
		return
	var displacement := travel_direction*speed*delta
	var query := PhysicsRayQueryParameters2D.create(global_position,global_position+displacement,collision_mask,[get_rid()])
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		_resolve_collision(hit.collider)
	if spent:
		return
	global_position += displacement
	if team != &"player" and kind != &"drone_bolt":
		visual.rotation += direction*deg_to_rad(definition.rotation_speed_degrees)*delta
	remaining_life -= delta
	if remaining_life <= 0.0 or position.x < -120.0 or position.x > GameConfig.WORLD_WIDTH+120.0:
		queue_free()


func _resolve_collision(collider: Node) -> void:
	if spent or collider == null:
		return
	var projectile_receiver := collider
	if not projectile_receiver.has_method("receive_projectile_hit") and collider.get_parent() != null:
		projectile_receiver = collider.get_parent()
	if projectile_receiver.has_method("receive_projectile_hit") and projectile_receiver.receive_projectile_hit(self):
		_spend()
	elif collider is Area2D and collider.has_method("receive_attack"):
		_try_hurtbox(collider)
	elif collider is StaticBody2D:
		_spend()
	elif collider != null and collider.has_node("Hurtbox"):
		_try_hurtbox(collider.get_node("Hurtbox"))


func _try_hurtbox(hurtbox: Area2D) -> bool:
	if spent or not hurtbox.has_method("can_receive_attack"):
		return false
	if not hurtbox.can_receive_attack(self,team,lane_index,definition):
		return false
	var damage_applied: bool = hurtbox.receive_attack(self,team,lane_index,definition)
	if damage_applied:
		hit_confirmed.emit(hurtbox)
		impact_confirmed.emit(hurtbox,StringName("projectile:%d:%d" % [impact_serial,hurtbox.get_instance_id()]))
	_spend()
	return damage_applied


func _on_area_entered(area: Area2D) -> void:
	_try_hurtbox(area)


func _on_body_entered(body: Node2D) -> void:
	_resolve_collision(body)


func _spend() -> void:
	if spent:
		return
	spent = true
	set_deferred("monitoring",false)
	collision_shape.set_deferred("disabled",true)
	queue_free()
