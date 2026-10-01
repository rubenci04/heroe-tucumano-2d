extends StaticBody2D
## Roof geometry is generated from opaque pixels. The vehicle image is untouched.
var asset: String = "auto1"
var image_scale: float = 0.95
var lane_index: int = 0

func _ready() -> void:
	lane_index = 0
	collision_layer = GameConfig.PLAYER_PLATFORM_LAYER
	collision_mask = 0
	add_to_group("platforms")
	add_to_group("stationary_vehicles")
	var texture: Texture2D = load("res://assets/"+asset+".png")
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_frame("idle",texture)
	$Visual.sprite_frames = frames
	$Visual.animation = &"idle"
	$Visual.scale = Vector2.ONE*image_scale
	$Visual.position.y = -texture.get_height()*image_scale*0.5
	z_index = 10
	var bounds: Rect2 = CollisionFactory.opaque_bounds(texture)
	$Visual.position.y = (texture.get_height()*0.5-bounds.end.y)*image_scale
	var collision: CollisionShape2D = CollisionFactory.add_floor(self,Vector2(bounds.size.x*image_scale*0.8,8.0))
	collision.position.y = -bounds.size.y*image_scale+4.0
	collision.one_way_collision = true
	collision.one_way_collision_margin = 8.0

func get_ground_anchor_world_y() -> float:
	return global_position.y
