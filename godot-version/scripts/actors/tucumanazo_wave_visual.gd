class_name TucumanazoWaveVisual
extends Node2D

var activation_count: int = 0
var active: bool = false
var radius: float = 150.0
var duration: float = 0.15
var elapsed: float = 0.0


func _ready() -> void:
	visible = false
	set_process(false)


func activate(wave_radius: float,wave_duration: float) -> void:
	activation_count += 1
	active = true
	radius = maxf(1.0,wave_radius)
	duration = maxf(0.01,wave_duration)
	elapsed = 0.0
	visible = true
	set_process(true)
	queue_redraw()


func cancel() -> void:
	active = false
	visible = false
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	if not active:
		return
	elapsed = minf(duration,elapsed+delta)
	queue_redraw()
	if elapsed >= duration:
		cancel()


func _draw() -> void:
	if not active:
		return
	var progress := clampf(elapsed/duration,0.0,1.0)
	var current_radius := lerpf(radius*0.18,radius,progress)
	var alpha := (1.0-progress)*0.78
	draw_arc(Vector2.ZERO,current_radius,0.0,TAU,64,Color(1.0,0.9,0.28,alpha),5.0,true)
	draw_arc(Vector2.ZERO,current_radius*0.72,0.0,TAU,48,Color(1.0,0.38,0.12,alpha*0.65),3.0,true)
