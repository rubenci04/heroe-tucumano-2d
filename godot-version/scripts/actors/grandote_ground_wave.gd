class_name GrandoteGroundWave
extends Area2D

signal hit_confirmed(body: Node)

const ATTACK_DEFINITION = preload("res://scripts/data/attack_definition.gd")

@export var attack_definition: ATTACK_DEFINITION
@export_range(1.0,1000.0,1.0) var speed: float = 300.0
@export_range(0.01,10.0,0.01) var lifetime: float = 1.4
@export_range(1.0,2000.0,1.0) var max_distance: float = 420.0
@export_range(1.0,200.0,1.0) var jump_clearance: float = 28.0

var team: StringName = &"enemy"
var lane_index: int = 0
var direction: int = 1
var _remaining_lifetime: float = 0.0
var _distance_travelled: float = 0.0
var _spent: bool = false


func _ready() -> void:
	direction = -1 if direction < 0 else 1
	_remaining_lifetime = lifetime
	collision_layer = GameConfig.PROJECTILE_LAYER
	collision_mask = GameConfig.PLAYER_LAYER
	z_index = int(GameConfig.LANES[lane_index])+1
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _spent:
		return
	var travel := speed*delta
	position.x += direction*travel
	_distance_travelled += travel
	_remaining_lifetime = maxf(0.0,_remaining_lifetime-delta)
	if _remaining_lifetime <= 0.0 or _distance_travelled >= max_distance:
		_spent = true
		queue_free()


func can_hit_body(body: Node) -> bool:
	if _spent or body == null or not body.has_method("get_height"):
		return false
	if body.get("lane_index") == null or int(body.get("lane_index")) != lane_index:
		return false
	return float(body.get_height()) < jump_clearance


func try_hit_body(body: Node) -> bool:
	if not can_hit_body(body):
		return false
	var hurtbox := body.get_node_or_null("Hurtbox") as Area2D
	if hurtbox == null or not hurtbox.has_method("receive_attack"):
		return false
	if not hurtbox.receive_attack(self,team,lane_index,attack_definition):
		return false
	_spent = true
	monitoring = false
	hit_confirmed.emit(body)
	queue_free()
	return true


func _on_body_entered(body: Node) -> void:
	try_hit_body(body)
