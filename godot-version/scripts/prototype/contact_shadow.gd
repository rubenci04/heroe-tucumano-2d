extends Node2D
## Prototype-only ground-plane contact ellipse, independent of jumping sprites.
var actor: Node2D
var visible_height := 74.0
var ground_y := 370.0
var follow_elevation := true

func _process(_delta: float) -> void:
	if not is_instance_valid(actor):
		queue_free()
		return
	visible = actor.visible and (actor.get("health") == null or int(actor.get("health")) > 0)
	global_position = Vector2(actor.global_position.x, ground_y + 1.0)
	var elevation := maxf(0.0, ground_y - actor.global_position.y) if follow_elevation else 0.0
	var proximity := clampf(1.0 - elevation / 180.0, 0.45, 1.0)
	scale = Vector2(visible_height * 0.25, visible_height * 0.047) * proximity
	modulate.a = proximity
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 1.0, Color(0.04, 0.035, 0.03, 0.28))
