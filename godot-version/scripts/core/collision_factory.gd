class_name CollisionFactory
extends RefCounted
## Shapes derived from existing PNG alpha bounds. Original pixels are never changed.
static var cached_bounds: Dictionary = {}

static func opaque_bounds(texture: Texture2D) -> Rect2:
	var key: String = texture.resource_path
	if cached_bounds.has(key):
		return cached_bounds[key]
	var image: Image = texture.get_image()
	var left: int = image.get_width()
	var top: int = image.get_height()
	var right: int = 0
	var bottom: int = 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.1:
				left = mini(left, x)
				right = maxi(right, x + 1)
				top = mini(top, y)
				bottom = maxi(bottom, y + 1)
	var bounds := Rect2(0, 0, image.get_width(), image.get_height())
	if right > left and bottom > top:
		bounds = Rect2(left, top, right - left, bottom - top)
	cached_bounds[key] = bounds
	return bounds

static func add_shape(body: CollisionObject2D, texture: Texture2D, image_scale: float, feet_anchor: bool = false, width_ratio: float = 0.7) -> CollisionShape2D:
	var bounds: Rect2 = opaque_bounds(texture)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(maxf(6.0, bounds.size.x * image_scale * width_ratio), maxf(6.0, bounds.size.y * image_scale * 0.9))
	var node := CollisionShape2D.new()
	node.name = "CollisionShape2D"
	node.shape = shape
	if feet_anchor:
		node.position.y = -shape.size.y * 0.5
	else:
		node.position = (bounds.get_center() - texture.get_size() * 0.5) * image_scale
	body.add_child(node)
	return node

static func add_floor(body: StaticBody2D, size: Vector2) -> CollisionShape2D:
	var shape := RectangleShape2D.new()
	shape.size = size
	var node := CollisionShape2D.new()
	node.name = "CollisionShape2D"
	node.shape = shape
	body.add_child(node)
	return node
