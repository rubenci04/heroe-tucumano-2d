extends Node
## Game feel de la arena: hit-stop, shake, flash, knockback y spawn de efectos.
## Se conecta a señales existentes desde fuera; no toca scripts de gameplay.

const CFG = preload("res://scripts/prototype/feel_config.gd")
const FX = preload("res://scripts/prototype/feel_fx.gd")
const FLASH_SHADER := "shader_type canvas_item;\nuniform float amount : hint_range(0.0, 1.0) = 0.0;\nvoid fragment() { COLOR.rgb = mix(COLOR.rgb, vec3(1.0), amount); }\n"

var fx: Node2D
var shake_target: Control
## Si el juego tiene su propio shake de cámara, se le delega (intensidad, duración) en vez de mover shake_target.
var shake_handler := Callable()
var player: CharacterBody2D
## Límites X dentro de los que el knockback puede mover a un enemigo.
var arena_bounds := Vector2(0.0, 1.0e6)
var _shake_time := 0.0
var _shake_total := 0.0
var _shake_intensity := 0.0
var _hitstop_frames := 0
var _slowmo_until_ms := 0
var _slowmo_scale := 1.0
var _flash_frames := {}
var _knock := {}   # enemy -> velocidad X de empuje (px/s)
var _flash_shader: Shader
var _time_scale_owned := false   # true solo mientras un efecto nuestro (hit-stop o cámara lenta) cambia Engine.time_scale
var _time_scale_base := 1.0
var _dust_timer := 0.0
var _was_on_floor := true
var _air_time := 0.0


## container: Control de la arena (sacude su posición) o Callable(intensidad, duración) del juego.
func setup(world: Node2D, container: Variant, player_node: CharacterBody2D) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if container is Callable:
		shake_handler = container
	else:
		shake_target = container
	player = player_node
	fx = FX.new()
	world.add_child(fx)
	_flash_shader = Shader.new()
	_flash_shader.code = FLASH_SHADER
	player.shot_requested.connect(_on_player_shot)
	player.health_component.damaged.connect(func(_a, _c, _s):
		shake(CFG.SHAKE_HURT_INTENSITY, CFG.SHAKE_HURT_DURATION)
		request_hitstop(CFG.PLAYER_HURT_HITSTOP_FRAMES))


func watch_enemy(enemy: Node) -> void:
	enemy.health_component.damaged.connect(func(amount, _c, source): _on_enemy_damaged(enemy, amount, source))
	enemy.defeated.connect(func(_p):
		_knock.erase(enemy)
		if is_instance_valid(enemy):
			fx.explosion(enemy.global_position + CFG.DEATH_BODY_OFFSET)
			var slowmo: Dictionary = CFG.DEATH_SLOWMO.get(String(enemy.get_meta("prototype_character", "")), {})
			if not slowmo.is_empty():
				slow_motion(float(slowmo.scale), float(slowmo.time))
		shake(CFG.SHAKE_EXPLODE_INTENSITY, CFG.SHAKE_EXPLODE_DURATION))


func watch_projectile(projectile: Node) -> void:
	projectile.impact_confirmed.connect(func(hurtbox: Area2D, _id):
		if is_instance_valid(hurtbox):
			fx.sparks(hurtbox.global_position))


## Hit-stop + shake + flash + knockback, medidos por personaje y por daño recibido.
func _on_enemy_damaged(enemy: Node, amount: int, source: Variant) -> void:
	if not is_instance_valid(enemy) or (source is Node and source.get("team") == &"enemy"):
		return
	var profile := CFG.impact_profile(String(enemy.get_meta("prototype_character", "")))
	var strength := clampf(float(amount) / CFG.IMPACT_REFERENCE_DAMAGE, CFG.IMPACT_STRENGTH_MIN, CFG.IMPACT_STRENGTH_MAX)
	_flash(enemy, int(profile.flash))
	request_hitstop(clampi(int(profile.hitstop) + (1 if amount >= CFG.IMPACT_HEAVY_DAMAGE else 0), 2, 4))
	shake(float(profile.shake) * strength, CFG.SHAKE_IMPACT_DURATION)
	var away := signf(enemy.global_position.x - player.global_position.x) if is_instance_valid(player) else 0.0
	if away == 0.0:
		away = -float(enemy.facing)
	_knock[enemy] = float(_knock.get(enemy, 0.0)) + away * float(profile.knock) * strength


func request_hitstop(frames: int) -> void:
	if _time_scale_blocked():
		return
	_hitstop_frames = maxi(_hitstop_frames, frames)
	_apply_time_scale()


## Cámara lenta breve en tiempo real (no depende del propio time_scale).
func slow_motion(scale: float, duration: float) -> void:
	if _time_scale_blocked():
		return
	_slowmo_scale = scale
	_slowmo_until_ms = Time.get_ticks_msec() + int(duration * 1000.0)
	_apply_time_scale()


func shake(intensity: float, duration: float) -> void:
	if shake_handler.is_valid():
		shake_handler.call(intensity, duration)
		return
	var remaining := _shake_intensity * clampf(_shake_time / maxf(_shake_total, 0.001), 0.0, 1.0)
	if intensity >= remaining:
		_shake_intensity = intensity
		_shake_time = duration
		_shake_total = duration


func _on_player_shot(origin: Vector2, _lane: int, direction: Variant, _kind: String, _team: String) -> void:
	fx.muzzle_flash(origin, direction if direction is Vector2 else Vector2(float(direction), 0.0))
	shake(CFG.SHAKE_SHOT_INTENSITY, CFG.SHAKE_SHOT_DURATION)


func _flash(enemy: Node, frames: int) -> void:
	if not is_instance_valid(enemy) or enemy.visual == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = _flash_shader
	mat.set_shader_parameter("amount", 1.0)
	enemy.visual.material = mat
	_flash_frames[enemy] = frames


## Solo toca Engine.time_scale mientras hay un efecto propio; al terminar devuelve el valor previo
## (así no pisa la cámara lenta del Tucumanazo ni otros efectos del juego).
## El Tucumanazo tiene su propio hit-stop y captura Engine.time_scale al empezar: mientras esté activo no tocamos el tiempo.
func _time_scale_blocked() -> bool:
	return is_instance_valid(player) and (bool(player.get("special_active")) or bool(player.get("_hit_stop_active")))


func _apply_time_scale() -> void:
	var hit_stop := _hitstop_frames > 0
	var slow_motion_active := Time.get_ticks_msec() < _slowmo_until_ms
	if (hit_stop or slow_motion_active) and not _time_scale_blocked():
		if not _time_scale_owned:
			_time_scale_owned = true
			_time_scale_base = Engine.time_scale
		Engine.time_scale = CFG.HITSTOP_TIME_SCALE if hit_stop else _slowmo_scale
	elif _time_scale_owned:
		_time_scale_owned = false
		Engine.time_scale = _time_scale_base


func _process(delta: float) -> void:
	if _hitstop_frames > 0:
		_hitstop_frames -= 1
	_apply_time_scale()
	# Red de seguridad: si nadie es dueño del tiempo y el Tucumanazo no tiene hit-stop, nada puede dejarlo lento.
	if not _time_scale_owned and Engine.time_scale < 1.0 and not bool(player.get("_hit_stop_active")):
		Engine.time_scale = 1.0
	_update_flashes()
	_update_shake(delta)
	_update_player_dust(delta)


func _physics_process(delta: float) -> void:
	for enemy in _knock.keys():
		if not is_instance_valid(enemy):
			_knock.erase(enemy)
			continue
		var speed: float = _knock[enemy]
		if absf(speed) < CFG.KNOCKBACK_MIN_SPEED:
			_knock.erase(enemy)
			continue
		enemy.global_position.x = clampf(enemy.global_position.x + speed * delta, arena_bounds.x, arena_bounds.y)
		_knock[enemy] = speed * exp(-CFG.KNOCKBACK_DECAY * delta)


func _update_flashes() -> void:
	for enemy in _flash_frames.keys():
		_flash_frames[enemy] -= 1
		if _flash_frames[enemy] <= 0:
			if is_instance_valid(enemy) and enemy.visual != null:
				enemy.visual.material = null
			_flash_frames.erase(enemy)


func _update_shake(delta: float) -> void:
	if shake_target == null:
		return
	if _shake_time > 0.0:
		_shake_time -= delta
		var k := clampf(_shake_time / maxf(_shake_total, 0.001), 0.0, 1.0)
		var amp := _shake_intensity * k
		shake_target.position = Vector2(roundf(randf_range(-amp, amp)), roundf(randf_range(-amp, amp)))
	elif shake_target.position != Vector2.ZERO:
		shake_target.position = Vector2.ZERO
		_shake_intensity = 0.0


func _update_player_dust(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var on_floor := player.is_on_floor()
	if on_floor:
		if not _was_on_floor and _air_time >= CFG.DUST_LAND_MIN_AIR_TIME:
			fx.dust(player.global_position, CFG.DUST_LAND_COUNT)
		_air_time = 0.0
		_dust_timer -= delta
		if absf(player.velocity.x) >= CFG.DUST_RUN_MIN_SPEED and _dust_timer <= 0.0:
			_dust_timer = CFG.DUST_RUN_INTERVAL
			fx.dust(player.global_position, CFG.DUST_RUN_COUNT)
	else:
		_air_time += delta
	_was_on_floor = on_floor


func _exit_tree() -> void:
	if _time_scale_owned:
		Engine.time_scale = _time_scale_base
