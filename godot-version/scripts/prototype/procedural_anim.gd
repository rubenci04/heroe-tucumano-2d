extends Node
## Animación procedural de la arena: squash/stretch, respiración, retroceso y muerte con tweens.
## Solo toca el sprite visual (scale/rotation/position de AnimatedSprite2D), nunca colisiones ni gameplay.

const CFG = preload("res://scripts/prototype/feel_config.gd")

const CIRUJA_GROUND_Y := -0.84   # pie del sprite original respecto al origen del player (igual que ciruja_skin.gd)

class Pose extends RefCounted:
	var recoil := 0.0   # 0..1, se anima con tween

var world: Node2D
var player: CharacterBody2D
var _p_pose := Pose.new()
var _p_tween: Tween
var _p_land := 0.0
var _p_land_tween: Tween
var _p_stretch := 0.0
var _p_lean := 0.0
var _p_base_pos := Vector2.ZERO
var _p_was_on_floor := true
var _p_air_time := 0.0
var _time := 0.0
var _enemies := {}   # enemy -> {pose, tween, base_pos, base_scale}
var fx: Node2D   # capa de partículas (feel_fx) para el polvo de caída


func setup(world_node: Node2D, player_node: CharacterBody2D) -> void:
	world = world_node
	player = player_node
	_p_base_pos = player.visual.position
	player.shot_requested.connect(_on_player_shot)


func watch_enemy(enemy: Node) -> void:
	var data := {"pose": Pose.new(), "tween": null, "base_pos": enemy.visual.position, "base_scale": enemy.visual.scale, "wheel_angle": 0.0}
	_enemies[enemy] = data
	enemy.health_component.damaged.connect(func(_a, _c, _s): _on_enemy_hit(enemy))
	enemy.defeated.connect(func(_p): _on_enemy_defeated(enemy))


func _on_player_shot(_o: Vector2, _l: int, _d: Variant, _k: String, _t: String) -> void:
	if _p_tween != null and _p_tween.is_valid():
		_p_tween.kill()
	_p_tween = _make_kick(_p_pose, CFG.PLAYER_SHOT_KICK_IN, CFG.PLAYER_SHOT_KICK_OUT)


func _make_kick(pose: Pose, t_in: float, t_out: float) -> Tween:
	var t := create_tween()
	t.tween_property(pose, "recoil", 1.0, t_in)
	t.tween_property(pose, "recoil", 0.0, t_out).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	return t


func _on_enemy_hit(enemy: Node) -> void:
	if not _enemies.has(enemy):
		return
	var d: Dictionary = _enemies[enemy]
	if d.tween != null and d.tween.is_valid():
		d.tween.kill()
	d.tween = _make_kick(d.pose, CFG.ENEMY_HIT_IN, CFG.ENEMY_HIT_OUT)


func _on_enemy_defeated(enemy: Node) -> void:
	if not _enemies.has(enemy) or not is_instance_valid(enemy):
		return
	var d: Dictionary = _enemies[enemy]
	_enemies.erase(enemy)
	if d.tween != null and d.tween.is_valid():
		d.tween.kill()
	if enemy.get("definition") != null and enemy.definition.escapes_when_depleted:
		return
	var src: AnimatedSprite2D = enemy.visual
	var ghost: AnimatedSprite2D = src.duplicate()
	ghost.material = null
	ghost.modulate = Color.WHITE
	world.add_child(ghost)
	ghost.global_position = src.global_position
	ghost.global_transform = src.global_transform
	if ghost.has_node("WheelSpokes"):
		ghost.get_node("WheelSpokes").hide()
	ghost.z_index = 15
	ghost.stop()
	src.visible = false
	var character := String(enemy.get_meta("prototype_character", ""))
	var heavy: bool = CFG.DEATH_SLOWMO.has(character)
	var linger: float = CFG.DEATH_LINGER_HEAVY if heavy else CFG.DEATH_LINGER
	var ground_pos := Vector2(ghost.global_position.x, GameConfig.GROUND_Y)
	if src.has_meta("batch_ground_y") and src.sprite_frames.has_animation(&"Death"):
		ghost.play(&"Death")
		ghost.frame_changed.connect(func():
			var texture := ghost.sprite_frames.get_frame_texture(ghost.animation, ghost.frame)
			ghost.offset = Vector2(0.0, texture.get_height() * 0.5 - 240.0))
		ghost.offset = Vector2(0.0, ghost.sprite_frames.get_frame_texture(&"Death", 0).get_height() * 0.5 - 240.0)
		var fall_time: float = ghost.sprite_frames.get_frame_count(&"Death") / maxf(ghost.sprite_frames.get_animation_speed(&"Death"), 1.0) * CFG.DEATH_DUST_AT
		_schedule_fall_dust(ground_pos, character, fall_time)
		ghost.animation_finished.connect(func(): _linger_and_fade(ghost, linger))
		return
	var away := signf(enemy.global_position.x - player.global_position.x)
	if away == 0.0:
		away = -float(enemy.facing)
	var dur: float = CFG.ENEMY_DEATH_DURATION
	var start := ghost.position
	var t := ghost.create_tween().set_parallel(true)
	t.tween_property(ghost, "rotation", away * deg_to_rad(CFG.ENEMY_DEATH_SPIN_DEG), dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_property(ghost, "position:x", start.x + away * CFG.ENEMY_DEATH_PUSH, dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	var ty := ghost.create_tween()
	ty.tween_property(ghost, "position:y", start.y - CFG.ENEMY_DEATH_HOP, dur * 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	ty.tween_property(ghost, "position:y", start.y + CFG.ENEMY_DEATH_FALL, dur * 0.7).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_schedule_fall_dust(Vector2(start.x + away * CFG.ENEMY_DEATH_PUSH, GameConfig.GROUND_Y), character, dur * CFG.DEATH_DUST_FALLBACK_AT)
	t.finished.connect(func(): _linger_and_fade(ghost, linger))


func _process(delta: float) -> void:
	_time += delta
	_update_player(delta)
	for enemy in _enemies.keys():
		if is_instance_valid(enemy):
			_update_enemy(enemy, _enemies[enemy])
		else:
			_enemies.erase(enemy)


func _foot_y(v: AnimatedSprite2D) -> float:
	var tex: Texture2D = null
	if v.sprite_frames != null and v.sprite_frames.has_animation(v.animation):
		tex = v.sprite_frames.get_frame_texture(v.animation, v.frame)
	if v.has_meta("batch_ground_y") and tex != null:
		return float(v.get_meta("batch_ground_y")) - tex.get_height() * 0.5 + v.offset.y
	return (tex.get_height() * 0.5 if tex != null else 0.0) + v.offset.y


## Aplica escala/rotación/desplazamiento manteniendo los pies en el mismo punto.
func _apply(v: AnimatedSprite2D, base_pos: Vector2, base_scale: Vector2, mult: Vector2, rot: float, shift_x: float) -> void:
	var new_scale := base_scale * mult
	v.scale = new_scale
	v.set_meta("pose_multiplier", mult)
	v.rotation = rot
	v.position = Vector2(base_pos.x + shift_x, base_pos.y + _foot_y(v) * (base_scale.y - new_scale.y))


func _update_player(delta: float) -> void:
	if not is_instance_valid(player) or player.state == player.State.DEATH:
		return
	var v: AnimatedSprite2D = player.visual
	var facing := float(player.facing)
	var on_floor := player.is_on_floor()
	var vx := absf(player.velocity.x)
	if on_floor:
		if not _p_was_on_floor and _p_air_time >= CFG.LAND_MIN_AIR_TIME:
			if _p_land_tween != null and _p_land_tween.is_valid():
				_p_land_tween.kill()
			_p_land = 1.0
			_p_land_tween = create_tween()
			_p_land_tween.tween_property(self, "_p_land", 0.0, CFG.LAND_SQUASH_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		_p_air_time = 0.0
	else:
		_p_air_time += delta
	_p_was_on_floor = on_floor
	var target_stretch := 0.0
	if not on_floor:
		if player.velocity.y < 0.0:
			target_stretch = CFG.JUMP_STRETCH * clampf(-player.velocity.y / GameConfig.JUMP_SPEED, 0.0, 1.0)
		else:
			target_stretch = CFG.FALL_STRETCH
	_p_stretch = lerpf(_p_stretch, target_stretch, clampf(CFG.STRETCH_SMOOTH * delta, 0.0, 1.0))
	var target_lean := 0.0
	if on_floor:
		target_lean = deg_to_rad(CFG.RUN_LEAN_DEG) * clampf(vx / GameConfig.WALK_SPEED, 0.0, 1.0) * facing
	_p_lean = lerpf(_p_lean, target_lean, clampf(CFG.RUN_LEAN_SMOOTH * delta, 0.0, 1.0))
	var breath := 0.0
	if on_floor and vx < 10.0 and player.state == player.State.IDLE:
		breath = sin(_time * TAU * CFG.BREATH_SPEED) * CFG.BREATH_AMOUNT
	var sy := 1.0 + _p_stretch - _p_land * CFG.LAND_SQUASH + breath
	var sx := 1.0 - _p_stretch * 0.5 + _p_land * CFG.LAND_SQUASH * 0.6 - breath * 0.5
	var base_pos := _p_base_pos
	var base_scale: float = player.character_visual_scale
	if player.has_meta("run_pl_anim") and v.animation == player.get_meta("run_pl_anim"):
		# cuadros PixelLab de carrera: otra resolución, mismo alto visual y mismo punto de suelo
		base_scale *= player.get_meta("run_pl_ratio")
		base_pos.y = CIRUJA_GROUND_Y - player.get_meta("run_pl_foot") * base_scale
	_apply(v, base_pos, Vector2.ONE * base_scale, Vector2(sx, sy), _p_lean, -facing * CFG.PLAYER_SHOT_KICK * _p_pose.recoil)


func _update_enemy(enemy: Node, d: Dictionary) -> void:
	if enemy.get("boss_state") != null:
		return # Boss already owns telegraph feedback; do not apply generic AI state logic.
	var v: AnimatedSprite2D = enemy.visual
	var facing := float(enemy.facing)
	var antic := 0.0
	if enemy.ai_state == enemy.AIState.TELEGRAPH and enemy.attack_windup > 0.0:
		antic = clampf(1.0 - enemy._state_remaining / enemy.attack_windup, 0.0, 1.0)
		antic *= antic
	var away := -facing
	if is_instance_valid(player):
		away = signf(enemy.global_position.x - player.global_position.x)
	var recoil: float = d.pose.recoil
	var sy := 1.0 - CFG.ENEMY_ANTIC_SQUASH * antic
	var sx := 1.0 + CFG.ENEMY_ANTIC_SQUASH * 0.5 * antic
	var rot := -facing * deg_to_rad(CFG.ENEMY_ANTIC_LEAN_DEG) * antic + away * deg_to_rad(CFG.ENEMY_HIT_LEAN_DEG) * recoil
	var shift := -facing * CFG.ENEMY_ANTIC_PULL * antic + away * CFG.ENEMY_HIT_PUSH * recoil
	if enemy.get_meta("prototype_character", "") == "hipster" and absf(enemy.velocity.x) > 1.0:
		sy += sin(_time * 9.0) * 0.025
		sx -= sin(_time * 9.0) * 0.0125
	_apply(v, d.base_pos, d.base_scale, Vector2(sx, sy), rot, shift)
	if enemy.get_meta("prototype_character", "") == "hipster" and enemy.ai_state not in [enemy.AIState.TELEGRAPH, enemy.AIState.ATTACK]:
		v.rotation += sin(_time * 9.0) * 0.015
		# Roll about the two existing wheel centers, never rotate the entire scooter.
		if not v.has_node("WheelSpokes"):
			var spokes := Node2D.new()
			spokes.name = "WheelSpokes"
			v.add_child(spokes)
			spokes.draw.connect(func():
				for center in [Vector2(-46.0, -17.0), Vector2(38.0, -17.0)]:
					var direction := Vector2.from_angle(d.wheel_angle) * 5.0
					spokes.draw_line(center - direction, center + direction, Color(0.3, 0.3, 0.3, 0.6), 1.0))
		d.wheel_angle += enemy.velocity.x * get_process_delta_time() / maxf(2.0, 5.0 * v.scale.x * enemy.scale.x)
		v.get_node("WheelSpokes").queue_redraw()


## Polvo a ras de suelo cuando el cuerpo cae (retardo = momento de impacto con el piso).
func _schedule_fall_dust(position: Vector2, character: String, delay: float) -> void:
	if fx == null:
		return
	var profile: Dictionary = CFG.DEATH_DUST.get(character, CFG.DEATH_DUST_DEFAULT)
	get_tree().create_timer(maxf(delay, 0.01)).timeout.connect(func():
		if is_instance_valid(fx):
			fx.ground_dust(position, int(profile.count), float(profile.spread))
			fx.dust(position, int(profile.count) / 2))


## El cuerpo queda `linger` segundos en el suelo y recién después se desvanece.
func _linger_and_fade(body: CanvasItem, linger: float) -> void:
	if not is_instance_valid(body):
		return
	var fade := body.create_tween()
	fade.tween_interval(linger)
	fade.tween_property(body, "modulate:a", 0.0, CFG.DEATH_FADE)
	fade.tween_callback(body.queue_free)
