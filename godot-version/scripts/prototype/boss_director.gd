extends Node
## Palermitano en la arena: espera, intro de 2 s (cámara bloqueada + nombre + barra), pelea y fase 2.
## Solo usa propiedades públicas/exportadas y señales del jefe; no cambia scripts de gameplay.

const CFG = preload("res://scripts/prototype/feel_config.gd")
const BOSS_AURA = preload("res://scripts/prototype/boss_aura.gd")

signal intro_started
signal intro_finished
signal phase_two_started
signal fight_won

enum Stage { WAITING, INTRO, FIGHT, PHASE_TWO, DEFEATED }

var boss: CharacterBody2D
var player: CharacterBody2D
var camera: Camera2D
var hud: CanvasLayer
var feel: Node
var enemies: Node2D
var projectiles: Node2D
var stage: Stage = Stage.WAITING
var _intro_time := 0.0
var _camera_home := Vector2.ZERO
var _frozen: Array[Node] = []
var _aura: Node2D
var _aura_time := 0.0


func setup(boss_node: CharacterBody2D, player_node: CharacterBody2D, camera_node: Camera2D, hud_node: CanvasLayer, feel_node: Node, enemy_root: Node2D, projectile_root: Node2D) -> void:
	boss = boss_node
	player = player_node
	camera = camera_node
	hud = hud_node
	feel = feel_node
	enemies = enemy_root
	projectiles = projectile_root
	_camera_home = camera.position
	# Hasta que arranque la intro el jefe no actúa ni recibe daño.
	boss.active = false
	boss.hurtbox.set_receiving_enabled(false)
	boss.health_component.health_changed.connect(_on_boss_health_changed)
	boss.defeated.connect(func(_points): _on_boss_defeated())
	boss.screen_shake_requested.connect(func(intensity: float, duration: float): feel.shake(intensity, duration))


func _process(delta: float) -> void:
	if not is_instance_valid(boss):
		return
	match stage:
		Stage.WAITING:
			if is_instance_valid(player) and player.global_position.x >= CFG.BOSS_TRIGGER_X and player.state != player.State.DEATH:
				_start_intro()
		Stage.INTRO:
			_intro_time += delta
			if _intro_time >= CFG.BOSS_INTRO_DURATION:
				_finish_intro()


func _start_intro() -> void:
	stage = Stage.INTRO
	_intro_time = 0.0
	player.controls_enabled = false
	player.velocity.x = 0.0
	# Congela al resto de la arena durante la intro (enemigos y proyectiles en vuelo).
	for enemy in enemies.get_children():
		if enemy != boss:
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
			_frozen.append(enemy)
	projectiles.process_mode = Node.PROCESS_MODE_DISABLED
	boss.visual.play(&"idle_v2")
	hud.show_boss_bar(boss.health_component.max_health, boss.health_component.current_health)
	hud.show_banner(CFG.BOSS_NAME, CFG.BOSS_SUBTITLE, CFG.BOSS_INTRO_DURATION - 0.8)
	# Cámara: se acerca al jefe y vuelve al plano fijo de la arena (queda bloqueada ahí).
	var focus := _camera_home.lerp(boss.global_position + Vector2(0.0, -60.0), 0.55)
	var move := create_tween().set_parallel(true)
	move.tween_property(camera, "zoom", Vector2.ONE * CFG.BOSS_INTRO_ZOOM, CFG.BOSS_INTRO_ZOOM_IN).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	move.tween_property(camera, "position", focus, CFG.BOSS_INTRO_ZOOM_IN).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	var back := move.chain().set_parallel(true)
	back.tween_property(camera, "zoom", Vector2.ONE, CFG.BOSS_INTRO_ZOOM_OUT).set_delay(CFG.BOSS_INTRO_DURATION - CFG.BOSS_INTRO_ZOOM_IN - CFG.BOSS_INTRO_ZOOM_OUT).set_ease(Tween.EASE_IN_OUT)
	back.tween_property(camera, "position", _camera_home, CFG.BOSS_INTRO_ZOOM_OUT).set_delay(CFG.BOSS_INTRO_DURATION - CFG.BOSS_INTRO_ZOOM_IN - CFG.BOSS_INTRO_ZOOM_OUT).set_ease(Tween.EASE_IN_OUT)
	feel.shake(2.0, 0.2)
	intro_started.emit()


func _finish_intro() -> void:
	stage = Stage.FIGHT
	for node in _frozen:
		if is_instance_valid(node):
			node.process_mode = Node.PROCESS_MODE_INHERIT
	_frozen.clear()
	projectiles.process_mode = Node.PROCESS_MODE_INHERIT
	camera.zoom = Vector2.ONE
	camera.position = _camera_home
	player.controls_enabled = true
	boss.active = true
	boss.hurtbox.set_receiving_enabled(true)
	intro_finished.emit()


func _on_boss_health_changed(current: int, maximum: int) -> void:
	hud.set_boss_health(current, maximum)
	if stage == Stage.FIGHT and float(current) <= float(maximum) * CFG.BOSS_PHASE2_THRESHOLD and current > 0:
		_start_phase_two()


## Fase 2: rugido (pausa corta), flash rojo, tinte y aura persistentes, y patrón más agresivo.
func _start_phase_two() -> void:
	stage = Stage.PHASE_TWO
	var tempo := CFG.BOSS_PHASE2_TEMPO_MULT
	boss.lane_move_speed *= CFG.BOSS_PHASE2_SPEED_MULT
	for property in [&"decision_delay", &"coffee_telegraph", &"coffee_shot_interval", &"coffee_recovery", &"coffee_cooldown", &"summon_telegraph", &"summon_recovery", &"summon_cooldown", &"chain_cooldown"]:
		boss.set(property, float(boss.get(property)) * tempo)
	# Patrón distinto: menos pausa entre golpes, abanico de café más abierto, cadena más larga y frecuente.
	boss.decision_delay *= CFG.BOSS_PHASE2_DECISION_MULT
	boss.coffee_spread_degrees = CFG.BOSS_PHASE2_COFFEE_SPREAD
	boss.chain_range *= CFG.BOSS_PHASE2_CHAIN_RANGE_MULT
	boss.chain_cooldown *= CFG.BOSS_PHASE2_CHAIN_COOLDOWN_MULT
	boss.summon_cooldown *= CFG.BOSS_PHASE2_SUMMON_COOLDOWN_MULT
	boss.visual.speed_scale = CFG.BOSS_PHASE2_ANIM_SPEED
	boss.visual.self_modulate = CFG.BOSS_PHASE2_TINT
	_add_aura()
	_roar()
	_screen_flash()
	feel.shake(CFG.BOSS_PHASE2_SHAKE, 0.3)
	feel.request_hitstop(4)
	feel.fx.sparks(boss.global_position + CFG.DEATH_BODY_OFFSET)
	hud.show_banner(CFG.BOSS_PHASE2_BANNER, "", CFG.BOSS_PHASE2_BANNER_TIME)
	phase_two_started.emit()


func _roar() -> void:
	# Quieto y rugiendo un momento: el jefe no actúa, así que la transición no castiga al jugador.
	boss.active = false
	boss.visual.play(CFG.BOSS_PHASE2_ROAR_ANIM)
	await get_tree().create_timer(CFG.BOSS_PHASE2_ROAR_TIME).timeout
	if is_instance_valid(boss) and stage == Stage.PHASE_TWO and boss.boss_state != boss.BossState.DEFEATED:
		boss.active = true


func _screen_flash() -> void:
	var flash := ColorRect.new()
	flash.color = CFG.BOSS_PHASE2_FLASH_COLOR
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, CFG.BOSS_PHASE2_FLASH_TIME)
	tween.tween_callback(flash.queue_free)


func _add_aura() -> void:
	_aura = BOSS_AURA.new()
	_aura.scale = Vector2.ONE / boss.scale
	_aura.position = CFG.DEATH_BODY_OFFSET / boss.scale
	boss.add_child(_aura)
	_aura_time = 0.0


func _physics_process(delta: float) -> void:
	if stage != Stage.PHASE_TWO or not is_instance_valid(boss):
		return
	_aura_time += delta
	if _aura_time >= CFG.BOSS_PHASE2_AURA_INTERVAL:
		_aura_time = 0.0
		var origin := boss.global_position + CFG.DEATH_BODY_OFFSET + Vector2(randf_range(-14.0, 14.0), randf_range(-16.0, 18.0))
		if randf() < 0.5:
			feel.fx.sparks(origin)
		else:
			feel.fx.dust(origin, 2)


func _on_boss_defeated() -> void:
	stage = Stage.DEFEATED
	if is_instance_valid(_aura):
		_aura.queue_free()
	hud.hide_boss_bar(1.2)
	fight_won.emit()
