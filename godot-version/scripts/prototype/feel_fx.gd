extends Node2D
## Partículas y muzzle flash dibujados por código (sin imágenes).

const CFG = preload("res://scripts/prototype/feel_config.gd")

var _particles: Array = []
var _flashes: Array = []


func _ready() -> void:
	z_index = 40


func _process(delta: float) -> void:
	for p in _particles:
		p.life -= delta
		p.vel.y += p.gravity * delta
		p.pos += p.vel * delta
	for f in _flashes:
		f.life -= delta
	_particles = _particles.filter(func(p): return p.life > 0.0)
	_flashes = _flashes.filter(func(f): return f.life > 0.0)
	queue_redraw()


func _draw() -> void:
	for p in _particles:
		var t: float = clampf(p.life / p.max_life, 0.0, 1.0)
		var s: float = p.size * (0.4 + 0.6 * t)
		var c: Color = p.color
		c.a *= t
		draw_rect(Rect2(p.pos - Vector2(s, s) * 0.5, Vector2(s, s)), c)
	for f in _flashes:
		var t: float = clampf(f.life / CFG.MUZZLE_DURATION, 0.0, 1.0)
		var d: Vector2 = f.dir
		var n := Vector2(-d.y, d.x)
		var l: float = CFG.MUZZLE_LENGTH * (0.5 + 0.5 * t)
		var w: float = CFG.MUZZLE_WIDTH * 0.5
		draw_colored_polygon(PackedVector2Array([f.pos + n * w, f.pos + d * l, f.pos - n * w, f.pos - d * 3.0]), CFG.MUZZLE_COLOR)


func muzzle_flash(pos: Vector2, dir: Vector2) -> void:
	_flashes.append({"pos": pos, "dir": dir.normalized() if dir != Vector2.ZERO else Vector2.RIGHT, "life": CFG.MUZZLE_DURATION})


func sparks(pos: Vector2) -> void:
	_burst(pos, CFG.SPARK_COUNT, CFG.SPARK_SPEED, CFG.SPARK_LIFE, CFG.SPARK_SIZE, [CFG.SPARK_COLOR], 200.0, TAU)


func dust(pos: Vector2, count: int) -> void:
	_burst(pos, count, CFG.DUST_SPEED, CFG.DUST_LIFE, CFG.DUST_SIZE, [CFG.DUST_COLOR], -20.0, PI, -PI * 0.5)


func explosion(pos: Vector2) -> void:
	_burst(pos, CFG.DEATH_COUNT, CFG.DEATH_SPEED, CFG.DEATH_LIFE, CFG.DEATH_SIZE, CFG.DEATH_COLORS, 220.0, TAU)


func _burst(pos: Vector2, count: int, speed: float, life: float, size: float, colors: Array, gravity: float, spread: float, center_angle: float = 0.0) -> void:
	for i in count:
		var a := center_angle + randf_range(-spread * 0.5, spread * 0.5)
		var l := life * randf_range(0.7, 1.2)
		_particles.append({
			"pos": pos, "vel": Vector2.from_angle(a) * speed * randf_range(0.4, 1.0),
			"life": l, "max_life": l, "size": size * randf_range(0.7, 1.3),
			"color": colors[randi() % colors.size()], "gravity": gravity,
		})
