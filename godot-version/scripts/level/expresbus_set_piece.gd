class_name ExpresbusSetPiece
extends Node2D
## One designed encounter per run; local/checkpoint deaths consume, never rewind it.
enum Phase { READY, WARNING, CROSSING, FINISHED }
const EVENT_ID := &"route_expresbus_01"
const TRIGGER_X := 2850.0
const SECTOR_END_X := 3500.0
const EXIT_X := 1950.0
const WARNING_SECONDS := 1.0
const BASE_SPEED := 240.0
const MAX_CROSSING_SECONDS := 45.0

@export var event_id: StringName = EVENT_ID
@export var vehicle_asset: StringName = &"exprebus"
@export var trigger_x: float = TRIGGER_X
@export var sector_end_x: float = SECTOR_END_X
@export var exit_x: float = EXIT_X
@export_range(-1,1,2) var travel_direction: int = -1
@export var travel_speed: float = BASE_SPEED
@export var prerequisite_encounter: StringName = &"route_wave_02"
@export var blocked_encounter: StringName = &"route_wave_03"
@export var recovery_seconds: float = 4.0
@export var post_rest_seconds: float = 3.0
@export var roof_pickup_kind: StringName = &"empanada"
@export var roof_pickup_asset: StringName = &"empanada"
@export var roof_pickup_scale: float = 0.14
@export var roof_pickup_id: StringName = &"expresbus_roof_empanada"

var phase := Phase.READY
var remaining := 0.0
var vehicle: TrafficVehicle
var spawn_count := 0
var finish_reason := ""
var warning_position := Vector2.ZERO

func is_running() -> bool:
	return phase in [Phase.WARNING,Phase.CROSSING]

func advance(delta: float,route: Node) -> void:
	var player: Node2D = route.player
	var camera := get_viewport().get_camera_2d()
	var camera_x: float = camera.get_screen_center_position().x if camera else player.position.x
	warning_position = Vector2(camera_x+365.0,GameConfig.GROUND_Y-62.0)
	if phase == Phase.READY:
		if player.position.x < trigger_x or player.position.x >= sector_end_x:
			return
		if not prerequisite_encounter.is_empty() \
				and not route.encounter_director.is_encounter_completed(prerequisite_encounter):
			return
		if not blocked_encounter.is_empty() \
				and route.encounter_director.is_encounter_activated(blocked_encounter):
			return
		for enemy in route.get_node("Enemies").get_children():
			if enemy.get("active") == true:
				return
		phase = Phase.WARNING
		remaining = WARNING_SECONDS
	elif phase == Phase.WARNING:
		remaining -= delta
		if remaining <= 0.0:
			# Entire 313px bus begins beyond the right viewport edge.
			var spawn_x := camera_x+600.0 if travel_direction < 0 else camera_x-600.0
			vehicle = route.traffic_director.spawn_set_piece(event_id,vehicle_asset,spawn_x,travel_direction,travel_speed,false)
			if vehicle == null:
				finish("spawn_unavailable")
			else:
				vehicle.set_meta("designed_route_event",true)
				# Give the player time to reach the stepping car and board after firing.
				vehicle.recovery_delay = recovery_seconds
				if not roof_pickup_id.is_empty():
					route.attach_vehicle_pickup(vehicle,roof_pickup_kind,roof_pickup_asset,roof_pickup_scale,roof_pickup_id)
				spawn_count += 1
				phase = Phase.CROSSING
				remaining = MAX_CROSSING_SECONDS
	elif phase == Phase.CROSSING:
		remaining -= delta
		if not is_instance_valid(vehicle) or not vehicle.active:
			finish("removed")
		elif travel_direction < 0 and vehicle.position.x < exit_x and vehicle.position.x+180.0 < camera_x-400.0:
			finish("sector_exit")
		elif travel_direction > 0 and vehicle.position.x > exit_x and vehicle.position.x-180.0 > camera_x+400.0:
			finish("sector_exit")
		elif absf(vehicle.position.x-camera_x)>950.0:
			finish("offscreen_exit")
		elif remaining <= 0.0:
			finish("timeout")
		if phase == Phase.FINISHED:
			route.encounter_director.add_rest(post_rest_seconds)
	queue_redraw()

func finish(reason: String) -> void:
	if phase in [Phase.READY,Phase.FINISHED]:
		return
	phase = Phase.FINISHED
	finish_reason = reason
	remaining = 0.0
	if is_instance_valid(vehicle):
		vehicle.request_despawn()
		vehicle.queue_free()
	vehicle = null
	queue_redraw()

func _draw() -> void:
	if phase != Phase.WARNING:
		return
	var pulse := 0.55+0.45*absf(sin(remaining*TAU*2.0))
	var color := Color(1.0,0.72,0.12,pulse)
	var sign_x := 1.0 if travel_direction < 0 else -1.0
	for offset in [0.0,14.0]:
		var point := to_local(warning_position)+Vector2(offset,0)
		draw_polyline(PackedVector2Array([point+Vector2(6*sign_x,-9),point+Vector2(-4*sign_x,0),point+Vector2(6*sign_x,9)]),color,3.0,true)
