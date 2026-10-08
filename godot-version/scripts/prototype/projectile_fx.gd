extends Node2D
## Presencia visual de proyectiles creados por código: giro, rebote, estela y sombra en el suelo.
## Solo toca el sprite `visual` y dibuja a su alrededor; la física del proyectil no cambia.
## Se adjunta como hijo del proyectil con `decorate()`; dos instancias: estela (z 19) y sombra (z -1).

const CFG = preload("res://scripts/prototype/feel_config.gd")
const SELF = preload("res://scripts/prototype/projectile_fx.gd")

var projectile: Node2D
var profile: Dictionary = {}
var shadow_mode := false
var outline_mode := false
var _time := 0.0
var _points: Array[Vector2] = []
var _base_y := 0.0
var _spin_dir := 1.0


static func profile_for(kind: String, emitter_character: String) -> Dictionary:
	if CFG.PROJECTILE_FX_BY_EMITTER.has(emitter_character):
		return CFG.PROJECTILE_FX_BY_EMITTER[emitter_character]
	return CFG.PROJECTILE_FX.get(kind, CFG.PROJECTILE_FX_DEFAULT)


## Debe llamarse con el proyectil ya dentro del árbol (necesita `visual`).
static func decorate(target: Node2D, kind: String, emitter_character: String = "") -> void:
	_fit_readable_visual(target, kind)
	var data := profile_for(kind, emitter_character)
	for shadow in [true, false]:
		var rig: Node2D = SELF.new()
		rig.name = "ShadowFx" if shadow else "TrailFx"
		rig.projectile = target
		rig.profile = data
		rig.shadow_mode = shadow
		rig.top_level = true
		rig.z_as_relative = false
		rig.z_index = -1 if shadow else 19
		target.add_child(rig)


static func _fit_readable_visual(target: Node2D, kind: String) -> void:
	if not CFG.PROJECTILE_FX_VISIBLE_HEIGHTS.has(kind):
		return
	var visual: AnimatedSprite2D = target.visual
	var texture := visual.sprite_frames.get_frame_texture(visual.animation, 0)
	var old_scale := visual.scale.y
	var inner_height: float = CFG.PROJECTILE_FX_VISIBLE_HEIGHTS[kind] - 2.0 * CFG.PROJECTILE_FX_OUTLINE_WIDTH
	visual.scale = Vector2.ONE * inner_height / CollisionFactory.opaque_bounds(texture).size.y
	var ratio := visual.scale.y / old_scale
	var shape: RectangleShape2D = target.collision_shape.shape.duplicate()
	shape.size = Vector2(maxf(CFG.ARC_HITBOX_MIN, shape.size.x * ratio), maxf(CFG.ARC_HITBOX_MIN, shape.size.y * ratio))
	target.collision_shape.shape = shape
	target.collision_shape.position *= ratio
	# Eight dark silhouettes behind the source make a real screen-pixel outline.
	# Child of Visual: follows rotation/hop without changing projectile physics.
	var outline: Node2D = SELF.new()
	outline.name = "ReadableOutline"
	outline.z_index = -1
	outline.projectile = target
	outline.outline_mode = true
	visual.add_child(outline)


func _ready() -> void:
	if projectile == null:
		return
	var visual: Node2D = projectile.get("visual")
	if visual != null:
		_base_y = visual.position.y
	_spin_dir = float(projectile.get("direction")) if projectile.get("direction") != null else 1.0
	if _spin_dir == 0.0:
		_spin_dir = 1.0


func _process(delta: float) -> void:
	if outline_mode:
		return
	if not is_instance_valid(projectile):
		return
	_time += delta
	var visual: Node2D = projectile.get("visual")
	if visual == null:
		return
	if not shadow_mode:
		var spin := float(profile.get("spin", 0.0))
		if spin != 0.0:
			visual.rotation += deg_to_rad(spin) * _spin_dir * delta
		var hop := float(profile.get("hop", 0.0))
		if hop > 0.0:
			visual.position.y = _base_y - absf(sin(_time * PI * float(profile.get("hop_hz", 2.0)))) * hop
		_points.append(visual.global_position)
		while _points.size() > int(profile.get("trail", 0)):
			_points.pop_front()
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(projectile):
		return
	if outline_mode:
		var visual: AnimatedSprite2D = projectile.visual
		var texture := visual.sprite_frames.get_frame_texture(visual.animation, visual.frame)
		var local_width := CFG.PROJECTILE_FX_OUTLINE_WIDTH / visual.scale.y
		for index in 8:
			draw_texture(texture, -texture.get_size() * 0.5 + visual.offset + Vector2.from_angle(index * TAU / 8) * local_width, CFG.PROJECTILE_FX_OUTLINE_COLOR)
		return
	if shadow_mode:
		var height := maxf(0.0, GameConfig.GROUND_Y - projectile.global_position.y)
		var near := clampf(1.0 - height / CFG.PROJECTILE_SHADOW_HEIGHT_RANGE, CFG.PROJECTILE_SHADOW_MIN_SCALE, 1.0)
		var width := CFG.PROJECTILE_SHADOW_WIDTH * float(profile.get("shadow", 1.0)) * near
		draw_set_transform(Vector2(projectile.global_position.x, GameConfig.GROUND_Y + 1.0), 0.0, Vector2(width, width * CFG.PROJECTILE_SHADOW_FLATNESS))
		draw_circle(Vector2.ZERO, 1.0, Color(0.04, 0.035, 0.03, CFG.PROJECTILE_SHADOW_ALPHA * near))
		return
	var count := _points.size()
	if count < 2:
		return
	var color: Color = profile.get("trail_color", Color(1, 1, 1, 0.4))
	var width := float(profile.get("trail_width", 2.0))
	for i in range(1, count):
		var k := float(i) / float(count)
		draw_line(_points[i - 1], _points[i], Color(color, color.a * k), maxf(0.8, width * k))
