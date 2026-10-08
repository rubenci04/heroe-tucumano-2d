extends Node2D
const CFG = preload("res://scripts/prototype/feel_config.gd")
const CONTACT_SHADOW = preload("res://scripts/prototype/contact_shadow.gd")
## Opposed copies share identical edge pixels; the source texture is untouched.
func _ready() -> void:
	var lane: Parallax2D = $RoadLayers/BackLane
	var road: Sprite2D = lane.get_node("Road")
	var mirrored: Sprite2D = lane.get_node("RoadMirror")
	var step := float(road.texture.get_width()-1)
	mirrored.position = road.position+Vector2(step,0)
	lane.repeat_size.x = step*2.0
	for group in [$FamaillaLandmarks, $RouteProps, $LightPosts]:
		for prop: Sprite2D in group.get_children():
			ground_prop(prop)

static func ground_prop(prop: Sprite2D) -> void:
	var bounds := CollisionFactory.opaque_bounds(prop.texture)
	var ground := CFG.backdrop_ground_y(prop.global_position.x)
	prop.global_position.y = ground - (bounds.end.y - prop.texture.get_height() * 0.5 + prop.offset.y) * prop.global_scale.y
	add_prop_shadow(prop, maxf(CFG.BACKDROP_PROP_SHADOW_MIN_WIDTH, bounds.size.x * prop.global_scale.x), ground)
	prop.set_meta("grounded_prop", true)

static func add_prop_shadow(actor: Node2D, width: float, ground: float) -> void:
	var shadow := CONTACT_SHADOW.new()
	shadow.name = "PropContactShadow"
	shadow.actor = actor
	shadow.visible_height = width * 2.0
	shadow.ground_y = ground
	shadow.follow_elevation = false
	shadow.top_level = true
	shadow.z_index = -1
	actor.add_child(shadow)
