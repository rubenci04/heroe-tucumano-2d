class_name CollisionFactory
extends RefCounted
## Shapes derived from existing PNG alpha bounds. Original pixels are never changed.
static var cached_bounds: Dictionary = {}

static func opaque_bounds(texture: Texture2D) -> Rect2:
	var key: String = texture.resource_path
	if cached_bounds.has(key):
		return cached_bounds[key]
	var image: Image = texture.get_image()
	# get_used_rect() (nativo) da el recuadro con alpha > 0; se ajusta a alpha > 0.1 revisando solo los bordes.
	# Antes se recorrían todos los píxeles en GDScript (~30 ms por cuadro nuevo = tirón al aparecer cada enemigo).
	var used := image.get_used_rect()
	var left: int = used.position.x
	var top: int = used.position.y
	var right: int = used.end.x
	var bottom: int = used.end.y
	while left < right and not _line_opaque(image, left, top, left, bottom - 1):
		left += 1
	while right > left and not _line_opaque(image, right - 1, top, right - 1, bottom - 1):
		right -= 1
	while top < bottom and not _line_opaque(image, left, top, right - 1, top):
		top += 1
	while bottom > top and not _line_opaque(image, left, bottom - 1, right - 1, bottom - 1):
		bottom -= 1
	var bounds := Rect2(0, 0, image.get_width(), image.get_height())
	if right > left and bottom > top:
		bounds = Rect2(left, top, right - left, bottom - top)
	cached_bounds[key] = bounds
	return bounds

static func _line_opaque(image: Image, x0: int, y0: int, x1: int, y1: int) -> bool:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if image.get_pixel(x, y).a > 0.1:
				return true
	return false

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
