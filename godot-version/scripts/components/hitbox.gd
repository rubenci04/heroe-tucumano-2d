class_name Hitbox
extends Area2D

const ATTACK_DEFINITION = preload("res://scripts/data/attack_definition.gd")

signal hit_confirmed(hurtbox: Area2D)
signal impact_confirmed(hurtbox: Area2D,impact_id: StringName)

@export var attack_definition: ATTACK_DEFINITION
@export var team: StringName = &"neutral"
@export var lane_index: int = 0
@export var direction: int = 1

var combat_owner: Node
var active: bool = false
var _active_remaining: float = 0.0
var _hit_targets: Dictionary = {}
var _activation_serial: int = 0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var damage: int:
	get:
		return attack_definition.damage if attack_definition != null else 0


func _ready() -> void:
	monitoring = false
	monitorable = false
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if not active:
		return
	_active_remaining = maxf(_active_remaining - delta, 0.0)
	if _active_remaining <= 0.0:
		deactivate()


func configure(
	actor: Node,
	actor_team: StringName,
	actor_lane: int,
	definition: ATTACK_DEFINITION,
	attack_direction: int = 1,
	target_mask: int = 0
) -> bool:
	combat_owner = actor
	team = actor_team
	lane_index = actor_lane
	attack_definition = definition
	direction = -1 if attack_direction < 0 else 1
	collision_layer = 0
	collision_mask = target_mask
	return _apply_definition()


func activate(duration_override: float = -1.0) -> bool:
	if not _apply_definition():
		deactivate()
		return false
	_hit_targets.clear()
	_activation_serial += 1
	active = true
	_active_remaining = duration_override if duration_override > 0.0 else attack_definition.active_duration
	monitoring = true
	collision_shape.disabled = false
	return true


func deactivate() -> void:
	active = false
	_active_remaining = 0.0
	set_deferred("monitoring",false)
	collision_shape.set_deferred("disabled",true)


func try_hit(hurtbox: Area2D) -> bool:
	if not active or hurtbox == null or not hurtbox.has_method("receive_attack"):
		return false
	var target_id := hurtbox.get_instance_id()
	if _hit_targets.has(target_id):
		return false
	var accepted: bool = hurtbox.receive_attack(
		combat_owner,
		team,
		lane_index,
		attack_definition
	)
	if accepted:
		_hit_targets[target_id] = true
		hit_confirmed.emit(hurtbox)
		impact_confirmed.emit(hurtbox,_impact_id(hurtbox))
	return accepted


func _impact_id(hurtbox: Area2D) -> StringName:
	return StringName("hitbox:%d:%d:%d" % [get_instance_id(),_activation_serial,hurtbox.get_instance_id()])


func _apply_definition() -> bool:
	if attack_definition == null or not attack_definition.is_valid():
		return false
	if attack_definition.shape_kind == ATTACK_DEFINITION.ShapeKind.CIRCLE:
		var circle := collision_shape.shape as CircleShape2D
		if circle == null:
			circle = CircleShape2D.new()
			collision_shape.shape = circle
		circle.radius = attack_definition.radius
	else:
		var rectangle := collision_shape.shape as RectangleShape2D
		if rectangle == null:
			rectangle = RectangleShape2D.new()
			collision_shape.shape = rectangle
		rectangle.size = attack_definition.reach
	collision_shape.position = Vector2(
		attack_definition.offset.x * direction,
		attack_definition.offset.y
	)
	return true


func _on_area_entered(area: Area2D) -> void:
	try_hit(area)
