class_name LaneReadability
extends Node2D

## Presentation-only cues for the two physical lanes. It never changes actor state.
const WORLD_DRAW_WIDTH := GameConfig.WORLD_WIDTH+160.0
const FEEDBACK_DURATION := 0.32

var player: Node2D
var feedback_remaining := 0.0
var feedback_position := Vector2.ZERO
var _was_changing_lane := false


func _ready() -> void:
	z_index = 1
	queue_redraw()


func _process(delta: float) -> void:
	if player == null:
		player = get_parent().get_node_or_null("Player") as Node2D
	if player != null:
		var is_changing := bool(player.get("changing_lane"))
		if is_changing and not _was_changing_lane:
			feedback_position = Vector2(player.position.x,float(player.get("lane_target")))
			feedback_remaining = FEEDBACK_DURATION
		_was_changing_lane = is_changing
	if feedback_remaining > 0.0:
		feedback_remaining = maxf(0.0,feedback_remaining-delta)
	queue_redraw()


func _draw() -> void:
	# Back lane: a restrained warm edge; front lane: a slightly denser asphalt band.
	draw_rect(Rect2(-80.0,GameConfig.LANES[0]-5.0,WORLD_DRAW_WIDTH,10.0),Color(0.94,0.73,0.42,0.055),true)
	draw_line(Vector2(-80.0,GameConfig.LANES[0]+2.0),Vector2(GameConfig.WORLD_WIDTH+80.0,GameConfig.LANES[0]+2.0),Color(0.96,0.78,0.48,0.12),1.0)
	draw_rect(Rect2(-80.0,GameConfig.LANES[1]-8.0,WORLD_DRAW_WIDTH,16.0),Color(0.10,0.06,0.04,0.08),true)
	draw_line(Vector2(-80.0,GameConfig.LANES[1]-4.0),Vector2(GameConfig.WORLD_WIDTH+80.0,GameConfig.LANES[1]-4.0),Color(0.20,0.09,0.05,0.18),1.0)
	for x in range(0,int(GameConfig.WORLD_WIDTH)+1,160):
		draw_line(Vector2(x,GameConfig.LANES[0]-2.0),Vector2(x+44.0,GameConfig.LANES[0]-2.0),Color(1.0,0.81,0.49,0.16),1.0)
		draw_line(Vector2(x+70.0,GameConfig.LANES[1]+4.0),Vector2(x+118.0,GameConfig.LANES[1]+4.0),Color(0.09,0.04,0.02,0.20),1.0)
	if feedback_remaining <= 0.0:
		return
	var progress := 1.0-feedback_remaining/FEEDBACK_DURATION
	var alpha := sin(progress*PI)*0.32
	var radius := lerpf(10.0,28.0,progress)
	draw_circle(feedback_position,radius,Color(1.0,0.79,0.40,alpha*0.16),false,1.5,true)
	draw_circle(feedback_position,6.0+progress*8.0,Color(0.20,0.08,0.03,alpha),true)

