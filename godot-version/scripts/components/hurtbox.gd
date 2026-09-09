class_name Hurtbox
extends Area2D

@export var team: StringName = &"neutral"
@export var lane_index: int = 0

var combat_owner: Node
var health_component: Node
var receiving_enabled: bool = true

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	monitoring = false
	monitorable = receiving_enabled


func configure(
	actor: Node,
	health: Node,
	actor_team: StringName,
	actor_lane: int,
	detection_layer: int
) -> void:
	combat_owner = actor
	health_component = health
	team = actor_team
	lane_index = actor_lane
	collision_layer = detection_layer
	collision_mask = 0


func copy_shape_from(source: CollisionShape2D) -> void:
	if source == null or source.shape == null:
		return
	collision_shape.shape = source.shape.duplicate()
	collision_shape.position = source.position
	collision_shape.rotation = source.rotation
	collision_shape.scale = source.scale


func set_receiving_enabled(value: bool) -> void:
	receiving_enabled = value
	set_deferred("monitorable",value)
	collision_shape.set_deferred("disabled",not value)


func receive_attack(
	attacker: Node,
	attacker_team: StringName,
	attacker_lane: int,
	definition: Resource
) -> bool:
	if not can_receive_attack(attacker,attacker_team,attacker_lane,definition):
		return false
	if not health_component.has_method("take_damage"):
		return false
	return health_component.take_damage(definition.damage, attacker)


func can_receive_attack(attacker: Node,attacker_team: StringName,attacker_lane: int,definition: Resource) -> bool:
	if not receiving_enabled or combat_owner == null or health_component == null:
		return false
	if attacker == null or attacker == combat_owner:
		return false
	if attacker_team == team or attacker_lane != lane_index:
		return false
	return definition != null and definition.has_method("is_valid") and definition.is_valid()
