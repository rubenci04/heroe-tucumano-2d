class_name TrafficDirector
extends Node

signal vehicle_warning(lane: int, direction: int)
signal vehicle_spawned(vehicle: Node)
signal vehicle_removed(vehicle_id: int)

const VEHICLE_SCENE = preload("res://scenes/actors/vehicle.tscn")
const SET_PIECE_CONFIGS: Dictionary = {
	&"exprebus": {"scale":1.007,"speed":130.0},
	&"tesa": {"scale":0.922,"speed":130.0},
}

@export_range(1,8,1) var max_simultaneous: int = 2
@export_range(0.25,30.0,0.05) var spawn_interval: float = 4.0
@export_range(0.0,10.0,0.05) var initial_spawn_delay: float = 1.5
@export var active_zones: Array[Vector2] = [Vector2(1400.0,6500.0)]
@export_range(100.0,1000.0,1.0) var camera_half_width: float = 400.0
@export_range(20.0,500.0,1.0) var offscreen_margin: float = 180.0
@export_range(50.0,1000.0,1.0) var despawn_margin: float = 280.0

var enabled: bool = true
var spawn_remaining: float = 0.0
var sequence_index: int = 0
var _vehicle_container: Node
var _player: Node2D
var _active_vehicles: Dictionary = {}
var _started_set_pieces: Dictionary = {}
var _clearing: bool = false


func configure(vehicle_container: Node,player: Node2D) -> bool:
	_vehicle_container = vehicle_container
	_player = player
	reset_runtime_state(true)
	return is_instance_valid(_vehicle_container) and is_instance_valid(_player)


func update_traffic(delta: float,player_x: float) -> void:
	_cleanup_invalid_references()
	_despawn_distant_vehicles(player_x)
	# El tráfico aleatorio está retirado. Los colectivos se crean sólo por trigger explícito.


func spawn_now(player_x: float) -> Node:
	return null


func spawn_set_piece(event_id: StringName,asset_id: StringName,spawn_x: float,direction: int = -1,speed_override: float = -1.0,emit_warning: bool = true) -> Node:
	if not enabled or event_id.is_empty() or _started_set_pieces.has(event_id) \
			or not SET_PIECE_CONFIGS.has(asset_id) or not is_instance_valid(_vehicle_container):
		return null
	var config: Dictionary = SET_PIECE_CONFIGS[asset_id]
	var vehicle = VEHICLE_SCENE.instantiate()
	var resolved_speed := speed_override if speed_override > 0.0 else float(config.speed)
	vehicle.configure(asset_id,float(config.scale),0,direction,resolved_speed)
	vehicle.position = Vector2(spawn_x,GameConfig.GROUND_Y)
	vehicle.despawn_requested.connect(_on_vehicle_despawn_requested)
	vehicle.tree_exiting.connect(_on_vehicle_exiting.bind(vehicle.get_instance_id()),CONNECT_ONE_SHOT)
	if emit_warning:
		vehicle_warning.emit(0,direction)
	_vehicle_container.add_child(vehicle)
	_active_vehicles[vehicle.get_instance_id()] = weakref(vehicle)
	_started_set_pieces[event_id] = true
	vehicle_spawned.emit(vehicle)
	return vehicle


func set_enabled(value: bool,clear_existing: bool = false) -> void:
	enabled = value
	if not enabled and clear_existing:
		clear_traffic()


func is_position_active(player_x: float) -> bool:
	for zone: Vector2 in active_zones:
		if player_x >= minf(zone.x,zone.y) and player_x <= maxf(zone.x,zone.y):
			return true
	return false


func get_active_vehicles() -> Array[Node]:
	_cleanup_invalid_references()
	var result: Array[Node] = []
	for reference: WeakRef in _active_vehicles.values():
		var vehicle = reference.get_ref()
		if vehicle != null and is_instance_valid(vehicle) and vehicle.is_inside_tree():
			result.append(vehicle)
	return result


func get_active_vehicle_count() -> int:
	return get_active_vehicles().size()


func clear_traffic() -> void:
	_clearing = true
	for vehicle in get_active_vehicles():
		vehicle.request_despawn()
		vehicle.queue_free()
	_active_vehicles.clear()
	_clearing = false


func reset_runtime_state(clear_existing: bool = true) -> void:
	if clear_existing:
		clear_traffic()
	enabled = true
	sequence_index = 0
	spawn_remaining = initial_spawn_delay
	_started_set_pieces.clear()


func _despawn_distant_vehicles(player_x: float) -> void:
	var maximum_distance := camera_half_width+despawn_margin
	for vehicle in get_active_vehicles():
		if vehicle.has_meta("designed_route_event"):
			continue # The designed event owns its fixed exit and timeout.
		if absf(vehicle.position.x-player_x) > maximum_distance:
			vehicle.request_despawn()
			vehicle.queue_free()


func _cleanup_invalid_references() -> void:
	for instance_id in _active_vehicles.keys():
		var reference: WeakRef = _active_vehicles[instance_id]
		var vehicle = reference.get_ref()
		if vehicle == null or not is_instance_valid(vehicle) or not vehicle.is_inside_tree():
			_active_vehicles.erase(instance_id)


func _on_vehicle_despawn_requested(vehicle: Node) -> void:
	var instance_id := vehicle.get_instance_id()
	if _active_vehicles.erase(instance_id):
		vehicle_removed.emit(instance_id)


func _on_vehicle_exiting(instance_id: int) -> void:
	if _clearing:
		return
	if _active_vehicles.erase(instance_id):
		vehicle_removed.emit(instance_id)
