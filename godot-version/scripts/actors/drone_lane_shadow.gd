extends Node2D

## Presentation-only ground anchor: it follows the Drone's assigned physical lane.
var ground_y: float = 0.0


func _ready() -> void:
	z_as_relative = false
	z_index = 1
	queue_redraw()


func _process(_delta: float) -> void:
	var drone := get_parent() as Node2D
	if drone != null:
		ground_y = GameConfig.LANES[clampi(int(drone.get("lane_index")),0,GameConfig.LANES.size()-1)]
	queue_redraw()


func _draw() -> void:
	var drone := get_parent() as Node2D
	if drone == null:
		return
	var local_ground_y := ground_y-drone.position.y
	draw_line(Vector2(0.0,12.0),Vector2(0.0,local_ground_y-5.0),Color(0.18,0.05,0.03,0.16),1.0)
	draw_set_transform(Vector2(0.0,local_ground_y),0.0,Vector2(1.0,0.34))
	draw_circle(Vector2.ZERO,22.0,Color(0.09,0.025,0.02,0.28),true)
	draw_circle(Vector2.ZERO,22.0,Color(0.86,0.22,0.10,0.22),false,1.0,true)
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

