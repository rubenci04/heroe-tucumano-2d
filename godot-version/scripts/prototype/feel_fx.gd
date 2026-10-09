extends Node2D
## Partículas, fogonazos y casquillos dibujados por código (sin imágenes).
## Formas: "puff" (bocanada que crece y se desvanece), "spark" (trazo corto) y "chip" (bolita que se achica).

const CFG = preload("res://scripts/prototype/feel_config.gd")

var _particles: Array = []
var _flashes: Array = []
var _casings: Array = []
var _drawn_empty := false


func _ready() -> void:
	z_index = 40


func _process(delta: float) -> void:
	if _particles.is_empty() and _flashes.is_empty() and _casings.is_empty():
		if _drawn_empty:
			return
		_drawn_empty = true
		queue_redraw()
		return
	_drawn_empty = false
	for p in _particles:
		p.life -= delta
		p.vel.y += p.gravity * delta
		p.pos += p.vel * delta
	for f in _flashes:
		f.life -= delta
	for c in _casings:
		_update_casing(c, delta)
	_particles = _particles.filter(func(p): return p.life > 0.0)
	_flashes = _flashes.filter(func(f): return f.life > 0.0)
	_casings = _casings.filter(func(c): return c.life > 0.0)
	queue_redraw()


func _update_casing(c: Dictionary, delta: float) -> void:
	c.life -= delta
	c.vel.y += CFG.CASING_GRAVITY * delta
	c.pos += c.vel * delta
	c.angle += c.spin * delta
	if c.pos.y >= GameConfig.GROUND_Y and c.vel.y > 0.0:
		c.pos.y = GameConfig.GROUND_Y
		if c.bounces > 0:
			c.bounces -= 1
			c.vel = Vector2(c.vel.x * 0.5, -c.vel.y * CFG.CASING_BOUNCE)
			c.spin *= 0.5
		else:
			c.vel = Vector2.ZERO
			c.spin = 0.0


func _draw() -> void:
	for p in _particles:
		var t: float = clampf(p.life / p.max_life, 0.0, 1.0)
		var c: Color = p.color
		match p.shape:
			"puff":
				c.a *= t * 0.75
				draw_circle(p.pos, p.size * (1.0 + 0.9 * (1.0 - t)), c)
			"spark":
				c.a *= t
				draw_line(p.pos, p.pos - p.vel.normalized() * p.size * 3.0, c, maxf(1.0, p.size * 0.6))
			_:
				c.a *= t
				draw_circle(p.pos, p.size * (0.4 + 0.6 * t) * 0.6, c)
	for f in _flashes:
		var t: float = clampf(f.life / CFG.MUZZLE_DURATION, 0.0, 1.0)
		var d: Vector2 = f.dir
		var n := Vector2(-d.y, d.x)
		var l: float = CFG.MUZZLE_LENGTH * f.size * (0.5 + 0.5 * t)
		var w: float = CFG.MUZZLE_WIDTH * f.size * 0.5
		draw_colored_polygon(PackedVector2Array([f.pos + n * w, f.pos + d * l, f.pos - n * w, f.pos - d * 3.0]), CFG.MUZZLE_COLOR)
		draw_circle(f.pos + d * l * 0.25, w * 0.9, Color(1.0, 1.0, 1.0, 0.85 * t))
	for c in _casings:
		var fade: float = clampf(c.life / 0.4, 0.0, 1.0)
		draw_set_transform(c.pos, c.angle, Vector2.ONE)
		draw_rect(Rect2(Vector2(-1.8, -0.9), Vector2(3.6, 1.8)), Color(CFG.CASING_COLOR, fade))
		draw_rect(Rect2(Vector2(0.4, -0.9), Vector2(1.4, 1.8)), Color(CFG.CASING_COLOR.lightened(0.35), fade))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func muzzle_flash(pos: Vector2, dir: Vector2, size: float = 1.0) -> void:
	_flashes.append({"pos": pos, "dir": dir.normalized() if dir != Vector2.ZERO else Vector2.RIGHT, "life": CFG.MUZZLE_DURATION, "size": size})


## Casquillo expulsado hacia arriba y atrás (opuesto a la dirección del disparo); rebota en el suelo.
func casing(pos: Vector2, shot_direction: Vector2) -> void:
	var back := -signf(shot_direction.x) if shot_direction.x != 0.0 else -1.0
	_casings.append({
		"pos": pos, "vel": Vector2(back * randf_range(CFG.CASING_SPEED_X.x, CFG.CASING_SPEED_X.y), -randf_range(CFG.CASING_SPEED_UP.x, CFG.CASING_SPEED_UP.y)),
		"angle": randf() * TAU, "spin": randf_range(-18.0, 18.0), "life": CFG.CASING_LIFE, "bounces": 1,
	})


func sparks(pos: Vector2) -> void:
	_burst(pos, CFG.SPARK_COUNT, CFG.SPARK_SPEED, CFG.SPARK_LIFE, CFG.SPARK_SIZE, [CFG.SPARK_COLOR], 200.0, TAU, 0.0, "spark")


func dust(pos: Vector2, count: int) -> void:
	_burst(pos, count, CFG.DUST_SPEED, CFG.DUST_LIFE, CFG.DUST_SIZE, [CFG.DUST_COLOR], -20.0, PI, -PI * 0.5, "puff")


## Nube de polvo a ras de suelo hacia ambos lados (caída de un cuerpo pesado).
func ground_dust(pos: Vector2, count: int, spread: float) -> void:
	for i in count:
		var side := -1.0 if i % 2 == 0 else 1.0
		var life := CFG.GROUND_DUST_LIFE * randf_range(0.7, 1.2)
		_particles.append({
			"pos": pos + Vector2(randf_range(-spread * 0.35, spread * 0.35), randf_range(-1.0, 0.0)),
			"vel": Vector2(side * randf_range(CFG.GROUND_DUST_SPEED * 0.3, CFG.GROUND_DUST_SPEED), -randf_range(2.0, 14.0)),
			"life": life, "max_life": life, "size": CFG.GROUND_DUST_SIZE * randf_range(0.7, 1.4),
			"color": CFG.DUST_COLOR, "gravity": -4.0, "shape": "puff",
		})


func explosion(pos: Vector2) -> void:
	_burst(pos, CFG.DEATH_COUNT, CFG.DEATH_SPEED, CFG.DEATH_LIFE, CFG.DEATH_SIZE, CFG.DEATH_COLORS, 220.0, TAU, 0.0, "chip")


func _burst(pos: Vector2, count: int, speed: float, life: float, size: float, colors: Array, gravity: float, spread: float, center_angle: float = 0.0, shape: String = "chip") -> void:
	for i in count:
		var a := center_angle + randf_range(-spread * 0.5, spread * 0.5)
		var l := life * randf_range(0.7, 1.2)
		_particles.append({
			"pos": pos, "vel": Vector2.from_angle(a) * speed * randf_range(0.4, 1.0),
			"life": l, "max_life": l, "size": size * randf_range(0.7, 1.3),
			"color": colors[randi() % colors.size()], "gravity": gravity, "shape": shape,
		})
