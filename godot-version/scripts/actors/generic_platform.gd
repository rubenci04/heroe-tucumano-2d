class_name GenericPlatform
extends StaticBody2D

@export var platform_texture: Texture2D
@export_range(0.1,4.0,0.01) var image_scale: float = 1.0
@export_range(0,1,1) var lane_index: int = 0
@export_range(0.0,2000.0,1.0) var roof_width: float = 0.0
@export var roof_vertical_offset: float = 0.0
@export var roof_enabled: bool = true
@export_range(2.0,32.0,1.0) var roof_thickness: float = 8.0

@onready var visual: Sprite2D = $Visual
@onready var roof_collision: CollisionShape2D = $RoofCollision


func configure(
	texture: Texture2D,
	visual_scale: float,
	platform_lane: int,
	useful_roof_width: float = 0.0,
	roof_offset: float = 0.0,
	collision_enabled: bool = true
) -> void:
	platform_texture = texture
	image_scale = maxf(0.1,visual_scale)
	lane_index = clampi(platform_lane,0,GameConfig.LANES.size()-1)
	roof_width = maxf(0.0,useful_roof_width)
	roof_vertical_offset = roof_offset
	roof_enabled = collision_enabled


func _ready() -> void:
	lane_index = clampi(lane_index,0,GameConfig.LANES.size()-1)
	collision_mask = 0
	add_to_group("platforms")
	add_to_group("generic_platforms")
	if platform_texture == null:
		push_error("GenericPlatform requiere una textura")
		roof_enabled = false
		visual.visible = false
		_apply_roof_state()
		return
	visual.texture = platform_texture
	visual.scale = Vector2.ONE*image_scale
	visual.position.y = -platform_texture.get_height()*image_scale*0.5
	var opaque_bounds := CollisionFactory.opaque_bounds(platform_texture)
	var resolved_width := roof_width if roof_width > 0.0 else opaque_bounds.size.x*image_scale*0.8
	var resolved_offset := roof_vertical_offset
	if is_zero_approx(resolved_offset):
		resolved_offset = -opaque_bounds.size.y*image_scale+roof_thickness*0.5
	roof_width = resolved_width
	roof_vertical_offset = resolved_offset
	var roof_shape := roof_collision.shape as RectangleShape2D
	if roof_shape == null:
		roof_shape = RectangleShape2D.new()
		roof_collision.shape = roof_shape
	roof_shape.size = Vector2(roof_width,roof_thickness)
	roof_collision.position.y = roof_vertical_offset
	roof_collision.one_way_collision = true
	roof_collision.one_way_collision_margin = 8.0
	_apply_roof_state()
	z_index = int(GameConfig.LANES[lane_index])


func _apply_roof_state() -> void:
	collision_layer = (1 << lane_index) if roof_enabled else 0
	roof_collision.disabled = not roof_enabled


func get_roof_world_y() -> float:
	return global_position.y+roof_vertical_offset-roof_thickness*0.5
