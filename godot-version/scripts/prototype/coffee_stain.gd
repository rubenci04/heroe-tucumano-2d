extends Node2D
## Prototype only. Mancha en el piso dibujada por código: elipse irregular marrón con borde oscuro y vapor.

const CFG = preload("res://scripts/prototype/feel_config.gd")
const POINTS := 16

var age := 0.0
var _outline := PackedVector2Array()
var _inner := PackedVector2Array()
var _steam: Array[Dictionary] = []
var _steam_timer := 0.0


func _ready() -> void:
	z_index = -4
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in POINTS:
		var angle := TAU * float(i) / POINTS
		var wobble := rng.randf_range(0.72, 1.15)
		_outline.append(Vector2(cos(angle) * CFG.STAIN_RADIUS.x * wobble, sin(angle) * CFG.STAIN_RADIUS.y * wobble))
		_inner.append(Vector2(cos(angle) * CFG.STAIN_RADIUS.x * wobble * 0.55, sin(angle) * CFG.STAIN_RADIUS.y * wobble * 0.5))


func covers(world_x: float) -> bool:
	return absf(world_x - global_position.x) <= CFG.STAIN_RADIUS.x * _fade()


func _fade() -> float:
	var left := CFG.STAIN_DURATION - age
	return clampf(left / CFG.STAIN_FADE_TIME, 0.0, 1.0)


func _process(delta: float) -> void:
	age += delta
	if age >= CFG.STAIN_DURATION:
		queue_free()
		return
	_steam_timer -= delta
	if _steam_timer <= 0.0 and _fade() >= 1.0:
		_steam_timer = CFG.STAIN_STEAM_INTERVAL
		_steam.append({"pos": Vector2(randf_range(-0.6, 0.6) * CFG.STAIN_RADIUS.x, randf_range(-0.5, 0.5) * CFG.STAIN_RADIUS.y), "t": 0.0})
	for puff in _steam:
		puff.t += delta
		puff.pos.y -= CFG.STAIN_STEAM_RISE * delta
		puff.pos.x += sin(puff.t * 5.0) * 4.0 * delta
	_steam = _steam.filter(func(p): return p.t < CFG.STAIN_STEAM_LIFE)
	queue_redraw()


func _draw() -> void:
	var grow := clampf(age / 0.12, 0.2, 1.0)
	var alpha := _fade()
	if alpha < 1.0 and int(age * 14.0) % 2 == 1:
		alpha *= 0.35 # parpadeo final
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * grow)
	draw_colored_polygon(_outline, _tinted(CFG.STAIN_FILL, alpha))
	draw_colored_polygon(_inner, _tinted(CFG.STAIN_INNER, alpha))
	var closed := _outline.duplicate()
	closed.append(_outline[0])
	draw_polyline(closed, _tinted(CFG.STAIN_BORDER, alpha), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for puff in _steam:
		var k: float = puff.t / CFG.STAIN_STEAM_LIFE
		draw_circle(puff.pos, 1.5 + 2.5 * k, _tinted(CFG.STAIN_STEAM_COLOR, (1.0 - k) * alpha))


func _tinted(color: Color, alpha: float) -> Color:
	return Color(color, color.a * alpha)
