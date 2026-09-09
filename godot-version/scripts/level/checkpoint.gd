class_name Checkpoint
extends Area2D

signal activated(checkpoint_id: StringName, respawn_position: Vector2)

@export var checkpoint_id: StringName = &"route_midpoint"
@export var respawn_offset: Vector2 = Vector2(0.0,-22.5)
var is_activated: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = GameConfig.PLAYER_LAYER
	body_entered.connect(_on_body_entered)


func activate_for(body: Node) -> bool:
	if is_activated or checkpoint_id.is_empty() or body == null or not body.is_in_group("player"):
		return false
	is_activated = true
	set_deferred("monitoring",false)
	activated.emit(checkpoint_id,global_position+respawn_offset)
	return true


func _on_body_entered(body: Node) -> void:
	activate_for(body)
