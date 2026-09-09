class_name DroneAimReticle
extends Node2D

const MIN_RADIUS := 8.0
const MAX_RADIUS := 22.0

var active: bool = false
var charge_progress: float = 0.0
var current_radius: float = MIN_RADIUS


func show_target(world_target: Vector2) -> void:
	active = true
	visible = true
	charge_progress = 0.0
	current_radius = MIN_RADIUS
	global_position = world_target
	queue_redraw()


func update_charge(progress: float,world_target: Vector2) -> void:
	if not active:
		show_target(world_target)
	charge_progress = clampf(progress,0.0,1.0)
	current_radius = lerpf(MIN_RADIUS,MAX_RADIUS,charge_progress)
	global_position = world_target
	queue_redraw()


func clear() -> void:
	active = false
	visible = false
	charge_progress = 0.0
	current_radius = MIN_RADIUS
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	var color := Color(1.0,0.08,0.05,0.9)
	draw_arc(Vector2.ZERO,current_radius,0.0,TAU,32,color,2.0,true)
	var inner := current_radius*0.45
	draw_line(Vector2(-current_radius-4.0,0.0),Vector2(-inner,0.0),color,2.0,true)
	draw_line(Vector2(current_radius+4.0,0.0),Vector2(inner,0.0),color,2.0,true)
	draw_line(Vector2(0.0,-current_radius-4.0),Vector2(0.0,-inner),color,2.0,true)
	draw_line(Vector2(0.0,current_radius+4.0),Vector2(0.0,inner),color,2.0,true)
	draw_circle(Vector2.ZERO,2.0,color)
