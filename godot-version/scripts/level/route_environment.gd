extends Node2D
## Opposed copies share identical edge pixels; the source texture is untouched.
func _ready() -> void:
	var lane: Parallax2D = $RoadLayers/BackLane
	var road: Sprite2D = lane.get_node("Road")
	var mirrored: Sprite2D = lane.get_node("RoadMirror")
	var step := float(road.texture.get_width()-1)
	mirrored.position = road.position+Vector2(step,0)
	lane.repeat_size.x = step*2.0
