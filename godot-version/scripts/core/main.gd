extends Node2D
signal flow_state_changed(previous_state: int, current_state: int)

const INPUT_SETUP = preload("res://scripts/core/input_setup.gd")
const PROJECTILE_SCENE = preload("res://scenes/actors/projectile.tscn")
const GAME_SESSION = preload("res://scripts/core/game_session.gd")
const DEMO_ENDING = preload("res://data/dialogues/demo_ending.tres")

signal demo_closing_started
signal demo_closing_finished
signal exit_requested

var finished: bool = false
var paused_before_gallery: bool = false
var current_state: int = GAME_SESSION.DemoState.GAMEPLAY
var state_before_pause: int = GAME_SESSION.DemoState.GAMEPLAY
var state_before_gallery: int = GAME_SESSION.DemoState.GAMEPLAY
var shake_remaining: float = 0.0
var shake_duration: float = 0.0
var shake_intensity: float = 0.0
var shake_elapsed: float = 0.0
var camera_follow_min_x: float = 400.0
var camera_follow_max_x: float = GameConfig.WORLD_WIDTH-400.0
var demo_closing: bool = false
var demo_closing_complete: bool = false
const LOCAL_RESPAWN_INVULNERABILITY := 1.25

@onready var game_session: Node = get_node("/root/GameSession")
@onready var route = $Route38
@onready var player = $Route38/Player
@onready var camera: Camera2D = $Camera2D
@onready var hud: Control = $Interface/HUD
@onready var gallery: Control = $Interface/AssetGallery
@onready var character_select: Control = $Interface/CharacterSelect
@onready var dialogue: Control = $Interface/DialogueBox
@onready var intro: Node2D = $IntroFamailla

func _ready() -> void:
	INPUT_SETUP.configure()
	player.shot_requested.connect(_spawn_projectile)
	route.aimed_shot_requested.connect(_spawn_projectile)
	player.died.connect(_on_player_died)
	player.respawn_requested.connect(_on_player_respawn_requested)
	player.status_changed.connect(_sync_session_from_player)
	route.shot_requested.connect(_spawn_projectile)
	route.boss_defeated.connect(_on_final_boss_defeated)
	route.boss_finished.connect(_on_miniboss_finished)
	route.boss_arena_changed.connect(_on_boss_arena_changed)
	route.notice_requested.connect(hud.show_notice)
	route.checkpoint_activated.connect(_on_checkpoint_activated)
	route.location_changed.connect(hud.set_location)
	route.boss_spawned.connect(_on_miniboss_spawned)
	route.screen_shake_requested.connect(_start_camera_shake)
	gallery.closed.connect(_close_gallery)
	hud.bind_combo(player.combo_component)
	hud.bind_special(player.tucumanazo_counter)
	hud.bind_health(player.health_component)
	hud.bind_game_session(game_session)
	hud.bind_player_status(player)
	hud.set_location(route.current_location(player.position.x))
	player.special_feedback_requested.connect(hud.show_notice)
	player.screen_shake_requested.connect(_start_camera_shake)
	character_select.character_confirmed.connect(_on_character_confirmed)
	character_select.cancelled.connect(_on_character_selection_cancelled)
	intro.completed.connect(_on_intro_completed)
	_restore_player_progress()
	camera.position = Vector2(400,225)
	camera.reset_smoothing()
	start_new_game()

func _process(delta: float) -> void:
	if current_state != GAME_SESSION.DemoState.GAMEPLAY:
		return
	camera.position.x = clampf(player.position.x,camera_follow_min_x,camera_follow_max_x)
	_update_camera_shake(delta)

func _start_camera_shake(intensity: float,duration: float) -> void:
	shake_intensity = maxf(intensity,0.0)
	shake_duration = maxf(duration,0.0)
	shake_remaining = shake_duration
	shake_elapsed = 0.0
	if shake_remaining <= 0.0:
		camera.offset = Vector2.ZERO

func _on_boss_arena_changed(active: bool,left_bound: float,right_bound: float) -> void:
	if active:
		camera_follow_min_x = maxf(400.0,left_bound+400.0)
		camera_follow_max_x = minf(GameConfig.WORLD_WIDTH-400.0,right_bound-400.0)
	else:
		camera_follow_min_x = 400.0
		camera_follow_max_x = GameConfig.WORLD_WIDTH-400.0

func _on_miniboss_spawned(health_component: Node,display_name: String) -> void:
	hud.bind_boss_health(health_component,display_name)
	AudioManager.request_music(AudioManager.MUSIC_MINIBOSS)

func _on_miniboss_finished() -> void:
	hud.bind_boss_health(null)
	if current_state == GAME_SESSION.DemoState.GAMEPLAY and not demo_closing:
		AudioManager.request_music(AudioManager.MUSIC_GAMEPLAY)


func _on_final_boss_defeated() -> void:
	if demo_closing or demo_closing_complete or current_state != GAME_SESSION.DemoState.GAMEPLAY:
		return
	demo_closing = true
	demo_closing_started.emit()
	AudioManager.play_effect("victoria")
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	player.cancel_tucumanazo()
	player.hurtbox.set_receiving_enabled(false)
	route.begin_demo_closing()
	_on_boss_arena_changed(false,0.0,GameConfig.WORLD_WIDTH)
	shake_remaining = 0.0
	shake_duration = 0.0
	shake_intensity = 0.0
	shake_elapsed = 0.0
	camera.offset = Vector2.ZERO
	camera.reset_smoothing()
	if not dialogue.sequence_finished.is_connected(_on_demo_ending_finished):
		dialogue.sequence_finished.connect(_on_demo_ending_finished)
	if not dialogue.start_sequence(DEMO_ENDING,player,true):
		_finish_demo_closing()


func _on_demo_ending_finished(sequence_id: StringName,_skipped: bool) -> void:
	if sequence_id != DEMO_ENDING.sequence_id:
		return
	if dialogue.sequence_finished.is_connected(_on_demo_ending_finished):
		dialogue.sequence_finished.disconnect(_on_demo_ending_finished)
	_finish_demo_closing()


func _finish_demo_closing() -> void:
	if demo_closing_complete:
		return
	demo_closing_complete = true
	_sync_session_from_player()
	hud.show_result(
		"DEMO COMPLETADA · PALERMITANO DERROTADO",
		"La receta vuelve a estar a salvo en Famaillá.\nPRÓXIMO DESTINO: ACHERAL · CONTINUARÁ…\nPuntaje: %d · Monedas: %d\nR: reiniciar · Esc/B: salir" % [player.score,player.coins]
	)
	change_state(GAME_SESSION.DemoState.RESULT)
	demo_closing_finished.emit()

func _update_camera_shake(delta: float) -> void:
	if shake_remaining <= 0.0:
		camera.offset = Vector2.ZERO
		return
	shake_remaining = maxf(shake_remaining-delta,0.0)
	shake_elapsed += delta
	var strength := shake_intensity*(shake_remaining/shake_duration) if shake_duration > 0.0 else 0.0
	camera.offset = Vector2(sin(shake_elapsed*91.0),cos(shake_elapsed*73.0))*strength
	if shake_remaining <= 0.0:
		camera.offset = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if current_state == GAME_SESSION.DemoState.CHARACTER_SELECT:
		return
	if current_state == GAME_SESSION.DemoState.RESULT:
		if event.is_action_pressed("restart"):
			restart_game()
		elif event.is_action_pressed("select_cancel") or event.is_action_pressed("pause"):
			exit_demo()
		return
	if event.is_action_pressed("asset_gallery"):
		if gallery.visible:
			_close_gallery()
		else:
			state_before_gallery = current_state
			paused_before_gallery = get_tree().paused
			gallery.show()
			if current_state != GAME_SESSION.DemoState.PAUSED and current_state != GAME_SESSION.DemoState.RESULT:
				pause_game()
	elif event.is_action_pressed("pause"):
		if gallery.visible:
			_close_gallery()
		elif not finished:
			if current_state == GAME_SESSION.DemoState.PAUSED:
				resume_game()
			else:
				pause_game()
	elif event.is_action_pressed("restart") and not gallery.visible:
		restart_game()

func change_state(next_state: int, force_apply: bool = false) -> void:
	if next_state not in GAME_SESSION.DemoState.values():
		push_error("Main recibió un estado de flujo inválido: %s" % next_state)
		return
	var previous_state := current_state
	if previous_state == next_state and not force_apply:
		return
	if intro.active and next_state != GAME_SESSION.DemoState.INTRO and next_state != GAME_SESSION.DemoState.PAUSED:
		intro.cancel(false)
	var preserve_intro_dialogue: bool = bool(intro.active) and next_state == GAME_SESSION.DemoState.INTRO
	if dialogue.active and next_state != GAME_SESSION.DemoState.GAMEPLAY and next_state != GAME_SESSION.DemoState.PAUSED and not preserve_intro_dialogue:
		dialogue.cancel(false)
	current_state = next_state
	game_session.set_demo_state(current_state)
	AudioManager.set_gameplay_paused(current_state == GAME_SESSION.DemoState.PAUSED)
	finished = current_state == GAME_SESSION.DemoState.RESULT
	var gameplay_active := current_state == GAME_SESSION.DemoState.GAMEPLAY
	player.controls_enabled = gameplay_active
	if gameplay_active and dialogue.active:
		player.controls_enabled = false
	if not gameplay_active:
		player.velocity = Vector2.ZERO
	match current_state:
		GAME_SESSION.DemoState.CHARACTER_SELECT:
			AudioManager.stop_music(0.0)
			character_select.show()
			get_tree().paused = false
			hud.set_paused(false)
		GAME_SESSION.DemoState.PAUSED:
			get_tree().paused = true
			hud.set_paused(true)
		GAME_SESSION.DemoState.RESULT:
			AudioManager.request_music(AudioManager.MUSIC_RESULT)
			get_tree().paused = true
			hud.set_paused(false)
		_:
			character_select.hide()
			get_tree().paused = false
			hud.set_paused(false)
	flow_state_changed.emit(previous_state, current_state)

func pause_game() -> void:
	if current_state == GAME_SESSION.DemoState.PAUSED or current_state == GAME_SESSION.DemoState.RESULT:
		return
	state_before_pause = current_state
	change_state(GAME_SESSION.DemoState.PAUSED)

func resume_game() -> void:
	if current_state != GAME_SESSION.DemoState.PAUSED:
		return
	change_state(state_before_pause)

func restart_game() -> void:
	intro.cancel(false)
	dialogue.cancel(false)
	AudioManager.reset_for_restart()
	game_session.begin_new_run(true)
	get_tree().paused = false
	get_tree().reload_current_scene()


func exit_demo(quit_tree: bool = true) -> bool:
	if current_state != GAME_SESSION.DemoState.RESULT:
		return false
	exit_requested.emit()
	if quit_tree:
		get_tree().quit()
	return true

func start_new_game() -> void:
	intro.cancel(false)
	dialogue.cancel(false)
	game_session.begin_new_run(true)
	_restore_player_progress()
	game_session.set_respawn_baseline(player.position,player.get_respawn_state())
	character_select.configure(game_session.get_character_definitions(), game_session.selected_character)
	change_state(GAME_SESSION.DemoState.CHARACTER_SELECT)

func start_dialogue(sequence: Resource, allow_skip_override: Variant = null) -> bool:
	if current_state != GAME_SESSION.DemoState.GAMEPLAY:
		return false
	return dialogue.start_sequence(sequence,player,allow_skip_override)

func _on_character_confirmed(character_id: StringName) -> void:
	var definition = game_session.resolve_character_definition(character_id)
	if definition == null or not player.apply_character_definition(definition):
		push_error("No se pudo aplicar la definición seleccionada. Se mantiene el personaje actual.")
		return
	game_session.set_selected_character(definition.character_id)
	begin_intro()

func begin_intro() -> bool:
	change_state(GAME_SESSION.DemoState.INTRO)
	AudioManager.request_music(AudioManager.MUSIC_INTRO)
	if intro.start(player,camera,dialogue,game_session.selected_character):
		return true
	change_state(GAME_SESSION.DemoState.GAMEPLAY)
	AudioManager.request_music(AudioManager.MUSIC_GAMEPLAY)
	hud.show_notice("FAMAILLÁ · ¡SALVÁ LA RECETA! Buscá el naranjo.")
	return false

func _on_intro_completed(_skipped: bool) -> void:
	if current_state != GAME_SESSION.DemoState.INTRO:
		return
	change_state(GAME_SESSION.DemoState.GAMEPLAY)
	AudioManager.request_music(AudioManager.MUSIC_GAMEPLAY)
	hud.show_notice("FAMAILLÁ · ¡SALVÁ LA RECETA! Buscá el naranjo.")

func _on_character_selection_cancelled() -> void:
	character_select.select_character_id(game_session.DEFAULT_CHARACTER)

func _close_gallery() -> void:
	gallery.hide()
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()
	if state_before_gallery == GAME_SESSION.DemoState.PAUSED:
		change_state(GAME_SESSION.DemoState.PAUSED, true)
	elif state_before_gallery == GAME_SESSION.DemoState.RESULT:
		change_state(GAME_SESSION.DemoState.RESULT, true)
	else:
		change_state(state_before_gallery)

func _spawn_projectile(origin: Vector2,lane: int,direction: Variant,kind: String,team: String) -> void:
	if current_state != GAME_SESSION.DemoState.GAMEPLAY:
		return
	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.position = origin
	projectile.lane_index = lane
	if direction is Vector2:
		projectile.travel_direction = direction
	else:
		projectile.direction = int(direction)
	projectile.kind = kind
	projectile.team = team
	if team == "player":
		projectile.impact_confirmed.connect(player.register_valid_hit)
	projectile.z_index = int(GameConfig.LANES[lane])+1
	route.get_node("Projectiles").add_child(projectile)

func _on_player_died() -> void:
	finished = true
	player.controls_enabled = false
	_sync_session_from_player()
	await get_tree().create_timer(0.55).timeout
	hud.show_result("¡TE LIQUIDARON EN LA RUTA!","Puntaje: %d · Monedas: %d\nR para reintentar" % [player.score,player.coins])
	change_state(GAME_SESSION.DemoState.RESULT)


func _on_checkpoint_activated(checkpoint_id: StringName,respawn_position: Vector2) -> void:
	_sync_session_from_player()
	game_session.set_checkpoint(
		checkpoint_id,
		respawn_position,
		route.encounter_director.get_completed_encounter_ids(),
		route.get_collected_pickup_ids(),
		player.get_respawn_state()
	)


func _on_player_respawn_requested() -> void:
	var death_position: Vector2 = player.position
	var current_player_state: Dictionary = player.get_respawn_state()
	var local_respawn: Dictionary = route.find_local_respawn(death_position,player.lane_index)
	if bool(local_respawn.found):
		var respawn_position: Vector2 = local_respawn.position
		var respawn_lane: int = int(local_respawn.lane_index)
		route.prepare_local_respawn_safety(respawn_position,respawn_lane)
		player.respawn_at(respawn_position,current_player_state,LOCAL_RESPAWN_INVULNERABILITY)
	else:
		route.restore_checkpoint_state(
			game_session.checkpoint_completed_encounters,
			game_session.checkpoint_collected_pickups
		)
		player.respawn_at(game_session.respawn_position,game_session.checkpoint_player_state,LOCAL_RESPAWN_INVULNERABILITY)
	_sync_session_from_player()
	camera.position.x = clampf(player.position.x,400.0,GameConfig.WORLD_WIDTH-400.0)
	camera.reset_smoothing()
	hud.show_notice("CONTINUÁ")

func _on_boss_escaped() -> void:
	_sync_session_from_player()
	AudioManager.play_effect("victoria")
	hud.show_result("RÍO SECO · BATALLA GANADA","¡El jefe escapó al Ingenio Arcor!\nNivel 2: interior de la fábrica · Próximamente\nPuntaje: %d · Monedas: %d · R para volver" % [player.score,player.coins])
	change_state(GAME_SESSION.DemoState.RESULT)

func _sync_session_from_player() -> void:
	game_session.set_progress(player.score, player.coins)

func _restore_player_progress() -> void:
	player.score = game_session.score
	player.coins = game_session.coins
