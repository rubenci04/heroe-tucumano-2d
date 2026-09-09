class_name TrafficVehicle
extends AnimatableBody2D

signal despawn_requested(vehicle: Node)
signal slowdown_changed(current_speed: float,base_speed: float)

const ATTACK_DEFINITION = preload("res://scripts/data/attack_definition.gd")

@export var asset_id: StringName = &"auto1"
@export var image_scale: float = 0.95
@export var lane_index: int = 0
@export var direction: int = -1
@export var speed: float = 190.0
@export var impact_definition: ATTACK_DEFINITION
@export_group("Projectile slowdown")
@export_range(0.1,1.0,0.01) var hit_speed_multiplier: float = 0.8
@export_range(0.1,1.0,0.01) var minimum_speed_multiplier: float = 0.55
@export_range(0.0,10.0,0.05) var recovery_delay: float = 1.5
@export_range(0.1,10.0,0.05) var recovery_duration: float = 2.0
@export_range(0.01,1.0,0.01) var impact_flash_duration: float = 0.12

var active: bool = true
var distance_travelled: float = 0.0
var base_speed: float = 190.0
var current_speed: float = 190.0
var recovery_delay_remaining: float = 0.0
var impact_flash_remaining: float = 0.0
var _received_projectile_impacts: Dictionary = {}

@onready var visual: Sprite2D = $Visual
@onready var impact_hitbox: Hitbox = $ImpactHitbox
@onready var roof_collision: CollisionShape2D = $RoofCollision
@onready var projectile_target: Area2D = $ProjectileTarget
@onready var projectile_target_shape: CollisionShape2D = $ProjectileTarget/CollisionShape2D


func _ready() -> void:
	direction = -1 if direction < 0 else 1
	lane_index = clampi(lane_index,0,GameConfig.LANES.size()-1)
	base_speed = maxf(1.0,speed)
	current_speed = base_speed
	collision_layer = 1 << lane_index
	collision_mask = 0
	add_to_group("mobile_platforms")
	var texture := load("res://assets/%s.png" % asset_id) as Texture2D
	if texture == null:
		push_error("TrafficVehicle no pudo cargar el asset legacy: %s" % asset_id)
		active = false
		return
	visual.texture = texture
	visual.scale = Vector2.ONE*image_scale
	visual.position.y = -texture.get_height()*image_scale*0.5
	# Legacy vehicles face left; mirror only those travelling towards the right.
	visual.flip_h = direction > 0
	z_index = int(GameConfig.LANES[lane_index])+1
	var opaque_bounds := CollisionFactory.opaque_bounds(texture)
	var roof_shape := RectangleShape2D.new()
	roof_shape.size = Vector2(maxf(24.0,opaque_bounds.size.x*image_scale*0.8),8.0)
	roof_collision.shape = roof_shape
	roof_collision.position.y = -opaque_bounds.size.y*image_scale+4.0
	roof_collision.one_way_collision = true
	roof_collision.one_way_collision_margin = 8.0
	var runtime_impact := impact_definition.duplicate() as ATTACK_DEFINITION if impact_definition != null else null
	if runtime_impact == null:
		push_error("TrafficVehicle requiere una AttackDefinition de impacto")
		active = false
		return
	runtime_impact.reach = Vector2(
		maxf(24.0,texture.get_width()*image_scale*0.82),
		maxf(18.0,texture.get_height()*image_scale*0.68)
	)
	runtime_impact.offset = Vector2(0.0,-texture.get_height()*image_scale*0.38)
	impact_hitbox.collision_shape.shape = RectangleShape2D.new()
	if not impact_hitbox.configure(self,&"traffic",lane_index,runtime_impact,direction,GameConfig.PLAYER_LAYER):
		push_error("TrafficVehicle no pudo configurar su Hitbox")
		active = false
		return
	impact_hitbox.activate(60.0)
	projectile_target.collision_layer = GameConfig.ENEMY_LAYER
	projectile_target.collision_mask = 0
	projectile_target.monitoring = false
	projectile_target.monitorable = true
	var target_shape := RectangleShape2D.new()
	target_shape.size = runtime_impact.reach
	projectile_target_shape.shape = target_shape
	projectile_target_shape.position = runtime_impact.offset


func configure(vehicle_asset: StringName,vehicle_scale: float,vehicle_lane: int,travel_direction: int,travel_speed: float) -> void:
	asset_id = vehicle_asset
	image_scale = maxf(0.1,vehicle_scale)
	lane_index = clampi(vehicle_lane,0,GameConfig.LANES.size()-1)
	direction = -1 if travel_direction < 0 else 1
	speed = maxf(1.0,travel_speed)
	base_speed = speed
	current_speed = speed


func _physics_process(delta: float) -> void:
	if not active:
		return
	_update_slowdown(delta)
	_update_hit_feedback(delta)
	var movement := current_speed*direction*delta
	position.x += movement
	distance_travelled += absf(movement)


func receive_projectile_hit(projectile: Node) -> bool:
	if not active or projectile == null or projectile.get("team") != &"player":
		return false
	if int(projectile.get("lane_index")) != lane_index or StringName(projectile.get("kind")) not in [&"orange",&"stone"]:
		return false
	var impact_id := int(projectile.get("impact_serial"))
	if impact_id <= 0 or _received_projectile_impacts.has(impact_id):
		return false
	_received_projectile_impacts[impact_id] = true
	current_speed = maxf(base_speed*minimum_speed_multiplier,current_speed*hit_speed_multiplier)
	speed = current_speed
	recovery_delay_remaining = recovery_delay
	impact_flash_remaining = impact_flash_duration
	visual.modulate = Color(1.0,0.62,0.28)
	slowdown_changed.emit(current_speed,base_speed)
	return true


func get_speed_ratio() -> float:
	return current_speed/base_speed if base_speed > 0.0 else 1.0


func get_roof_world_y() -> float:
	return global_position.y+roof_collision.position.y-4.0


func _update_slowdown(delta: float) -> void:
	if recovery_delay_remaining > 0.0:
		recovery_delay_remaining = maxf(0.0,recovery_delay_remaining-delta)
		return
	if current_speed >= base_speed:
		current_speed = base_speed
		speed = base_speed
		return
	var recovery_rate := base_speed*(1.0-minimum_speed_multiplier)/recovery_duration
	current_speed = move_toward(current_speed,base_speed,recovery_rate*delta)
	speed = current_speed
	slowdown_changed.emit(current_speed,base_speed)


func _update_hit_feedback(delta: float) -> void:
	if impact_flash_remaining <= 0.0:
		return
	impact_flash_remaining = maxf(0.0,impact_flash_remaining-delta)
	if impact_flash_remaining <= 0.0:
		visual.modulate = Color.WHITE


func request_despawn() -> void:
	if not active:
		return
	active = false
	impact_hitbox.deactivate()
	collision_layer = 0
	projectile_target.set_deferred("monitorable",false)
	roof_collision.set_deferred("disabled",true)
	despawn_requested.emit(self)
