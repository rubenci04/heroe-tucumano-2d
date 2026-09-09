extends CharacterBody2D
signal shot_requested(origin: Vector2, lane: int, direction: Vector2, kind: String, team: String)
signal status_changed
signal hud_status_changed(lives: int, stones: int, oranges_unlocked: bool, heat: float)
signal died
signal respawn_requested
signal special_feedback_requested(text: String)
signal screen_shake_requested(intensity: float,duration: float)

const CHARACTER_DEFINITION = preload("res://scripts/data/character_definition.gd")
const HEALTH_COMPONENT = preload("res://scripts/components/health_component.gd")
const HURTBOX = preload("res://scripts/components/hurtbox.gd")
const HITBOX = preload("res://scripts/components/hitbox.gd")
const COMBO_COMPONENT = preload("res://scripts/components/combo_component.gd")
const TUCUMANAZO_COUNTER_COMPONENT = preload("res://scripts/components/special_meter_component.gd")
const TUCUMANAZO_DEFINITION = preload("res://scripts/data/tucumanazo_definition.gd")
const TUCUMANAZO_WAVE_VISUAL = preload("res://scripts/actors/tucumanazo_wave_visual.gd")
const DEFAULT_CHARACTER_DEFINITION: CHARACTER_DEFINITION = preload("res://data/characters/san_martin.tres")

enum State { IDLE, RUN, JUMP, THROW, COLLECT, HIT, DEATH }
enum SpecialPhase { READY, STARTUP, ACTIVE, RECOVERY }
const COLLECTION_DURATION := 0.5
const COLLECTION_REWARD_TIME := 0.4
const COLLECTION_KINDS := [&"orange_tree",&"stone_pile"]
@export var character_definition: CHARACTER_DEFINITION
@export var tucumanazo_definition: TUCUMANAZO_DEFINITION
var state: State = State.IDLE
var special_phase: SpecialPhase = SpecialPhase.READY
var special_phase_remaining: float = 0.0
var special_active: bool = false
var _special_hit_stop_used: bool = false
var _hit_stop_active: bool = false
var _hit_stop_generation: int = 0
var _time_scale_before_hit_stop: float = 1.0
var team: String = "player"
var lane_index: int = 0
var facing: int = 1
var lives: int = 3
var score: int = 0
var coins: int = 0
var stones: int = 0
var oranges_unlocked: bool = false
var hit_time: float = 0.0
var action_time: float = 0.0
var shot_cooldown: float = 0.0
var fury_time: float = 0.0
var heat: float = 0.0
var heat_damage_time: float = 0.0
var collection_active: bool = false
var collection_kind: String = ""
var collection_remaining: float = 0.0
var collection_reward_granted: bool = false
var _collection_pickup: Node
var action_animation: StringName = &"Idle"
var changing_lane: bool = false
var lane_progress: float = 0.0
var lane_start: float = 370.0
var lane_target: float = 370.0
var destination_lane: int = 0
var controls_enabled: bool = true:
	set(value):
		controls_enabled = value
var walk_speed: float = GameConfig.WALK_SPEED
var fury_speed: float = 330.0
var gravity: float = GameConfig.GRAVITY
var jump_speed: float = GameConfig.JUMP_SPEED
var lane_duration: float = GameConfig.LANE_DURATION
var character_visual_scale: float = 0.42
var collision_width_ratio: float = 0.65
var last_definition_error: String = ""
@onready var health_component: HEALTH_COMPONENT = $HealthComponent
@onready var hurtbox: HURTBOX = $Hurtbox
@onready var combo_component: COMBO_COMPONENT = $ComboComponent
@onready var tucumanazo_counter: TUCUMANAZO_COUNTER_COMPONENT = $TucumanazoCounterComponent
@onready var tucumanazo_hitbox: HITBOX = $TucumanazoHitbox
@onready var tucumanazo_wave_visual: TUCUMANAZO_WAVE_VISUAL = $TucumanazoWaveVisual
@onready var visual: AnimatedSprite2D = $Visual

var health: int:
	get:
		return health_component.current_health
	set(value):
		health_component.set_current_health(value)

var max_health: int:
	get:
		return health_component.max_health

var invulnerability: float:
	get:
		return health_component.invulnerability_remaining
	set(value):
		health_component.set_invulnerability(value)

func _ready() -> void:
	health_component.damaged.connect(_on_health_damaged)
	health_component.depleted.connect(_on_health_depleted)
	var requested_definition := character_definition if character_definition != null else DEFAULT_CHARACTER_DEFINITION
	if not apply_character_definition(requested_definition):
		push_warning("CharacterDefinition rechazada: %s. Se usará San Martín." % last_definition_error)
		if not apply_character_definition(DEFAULT_CHARACTER_DEFINITION):
			push_error("La definición predeterminada de San Martín no es válida: %s" % last_definition_error)
			return
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	collision_layer = GameConfig.PLAYER_LAYER
	collision_mask = 1 << lane_index
	var body_shape := CollisionFactory.add_shape(self,visual.sprite_frames.get_frame_texture(character_definition.idle_animation,0),character_visual_scale,true,collision_width_ratio)
	hurtbox.configure(self,health_component,team,lane_index,GameConfig.PLAYER_LAYER)
	hurtbox.copy_shape_from(body_shape)
	if tucumanazo_definition == null or not tucumanazo_definition.is_valid():
		push_error("La definición de Tucumanazo no es válida")
	else:
		tucumanazo_counter.configure(tucumanazo_definition.starting_uses,tucumanazo_definition.starting_uses)
		tucumanazo_hitbox.configure(self,team,lane_index,tucumanazo_definition,facing,GameConfig.ENEMY_LAYER)
	tucumanazo_hitbox.impact_confirmed.connect(_on_tucumanazo_impact)
	add_to_group("player")
	visual.play(character_definition.idle_animation)

func apply_character_definition(definition: CHARACTER_DEFINITION) -> bool:
	if definition == null:
		last_definition_error = "no se proporcionó una definición"
		return false
	var errors := definition.get_validation_errors(true)
	if not errors.is_empty():
		last_definition_error = "; ".join(errors)
		return false
	character_definition = definition
	last_definition_error = ""
	visual.sprite_frames = definition.sprite_frames
	visual.scale = Vector2.ONE * definition.visual_scale
	visual.position = definition.visual_offset
	character_visual_scale = definition.visual_scale
	collision_width_ratio = definition.collision_width_ratio
	walk_speed = definition.walk_speed
	fury_speed = definition.fury_speed
	gravity = definition.gravity
	jump_speed = definition.jump_speed
	lane_duration = definition.lane_duration
	floor_snap_length = definition.floor_snap
	health_component.configure(definition.max_health,definition.max_health,0.8)
	lives = definition.starting_lives
	action_animation = definition.idle_animation
	return true

func get_height() -> float:
	return maxf(0.0,GameConfig.LANES[lane_index]-position.y)

func _physics_process(delta: float) -> void:
	if state == State.DEATH:
		return
	hit_time = maxf(0.0,hit_time-delta)
	action_time = maxf(0.0,action_time-delta)
	shot_cooldown = maxf(0.0,shot_cooldown-delta)
	_update_tucumanazo(delta)
	_update_collection(delta)
	fury_time = maxf(0.0,fury_time-delta)
	if position.x > 3200.0 and controls_enabled:
		var previous_heat_percent := int(heat)
		heat = minf(100.0,heat+2.1*delta)
		if heat >= 100.0:
			heat_damage_time += delta
			if heat_damage_time >= 2.0:
				heat_damage_time = 0.0
				take_damage(1,"sun")
		else:
			heat_damage_time = 0.0
		if int(heat) != previous_heat_percent:
			_emit_hud_status()
	if state == State.DEATH:
		return
	if fury_time > 0.0:
		visual.modulate = Color(1,0.88,0.3)
	elif hit_time > 0.0:
		visual.modulate = Color(1,0.25,0.25)
	else:
		visual.modulate = Color.WHITE
	visual.modulate.a = 0.4 if invulnerability > 0.0 and int(invulnerability*12.0)%2 == 0 else 1.0
	var axis: float = Input.get_axis("move_left","move_right") if controls_enabled and hit_time <= 0.0 and not special_active and not collection_active else 0.0
	if hit_time <= 0.0:
		velocity.x = axis * (fury_speed if fury_time > 0.0 else walk_speed)
	if not is_zero_approx(axis):
		facing = -1 if axis < 0.0 else 1
	visual.flip_h = facing < 0
	if changing_lane:
		lane_progress = minf(1.0,lane_progress+delta/lane_duration)
		var next_y: float = lerpf(lane_start,lane_target,smoothstep(0.0,1.0,lane_progress))-sin(lane_progress*PI)*20.0
		velocity.y = (next_y-position.y)/delta
		move_and_slide()
		if lane_progress >= 1.0:
			changing_lane = false
			lane_index = destination_lane
			hurtbox.lane_index = lane_index
			collision_mask = 1 << lane_index
			position.y = lane_target
			velocity.y = 0.0
	else:
		velocity.y += gravity*delta
		if controls_enabled and hit_time <= 0.0 and not special_active and not collection_active:
			var projectile_input_pressed := Input.is_action_just_pressed("throw_orange") or Input.is_action_just_pressed("throw_stone")
			if is_on_floor():
				if absf(position.y-GameConfig.LANES[lane_index]) < 8.0:
					if Input.is_action_just_pressed("lane_up") and lane_index == 1 and not projectile_input_pressed:
						begin_lane_change(0)
					elif Input.is_action_just_pressed("lane_down") and lane_index == 0 and not projectile_input_pressed:
						begin_lane_change(1)
				if Input.is_action_just_pressed("jump") and not changing_lane:
					velocity.y = -jump_speed
					AudioManager.play_effect("salto")
			if Input.is_action_just_released("jump") and velocity.y < -120.0:
				velocity.y *= 0.5
			if not changing_lane:
				if Input.is_action_just_pressed("tucumanazo"):
					start_tucumanazo()
				elif Input.is_action_just_pressed("throw_orange"):
					throw_projectile("orange")
				elif Input.is_action_just_pressed("throw_stone"):
					throw_projectile("stone")
		move_and_slide()
	position.x = clampf(position.x,20.0,GameConfig.WORLD_WIDTH-20.0)
	z_index = int(GameConfig.LANES[lane_index])
	if collection_active:
		state = State.COLLECT
		play_animation(character_definition.idle_animation)
	elif hit_time > 0.0:
		state = State.HIT
		play_animation(character_definition.hit_animation)
	elif action_time > 0.0:
		state = State.THROW
		play_animation(action_animation)
	elif not is_on_floor() or changing_lane:
		state = State.JUMP
		play_animation(character_definition.jump_animation)
	elif not is_zero_approx(axis):
		state = State.RUN
		play_animation(character_definition.run_animation)
	else:
		state = State.IDLE
		play_animation(character_definition.idle_animation)

func begin_lane_change(destination: int) -> void:
	if changing_lane or state == State.DEATH or special_active or collection_active:
		return
	lane_start = position.y
	lane_target = GameConfig.LANES[destination]
	destination_lane = destination
	lane_progress = 0.0
	changing_lane = true
	collision_mask = 0
	AudioManager.play_effect("salto")

func register_valid_hit(_hurtbox: Area2D,impact_id: StringName) -> void:
	combo_component.register_hit(impact_id)

func start_tucumanazo() -> bool:
	if not controls_enabled or state == State.DEATH or changing_lane or special_active or collection_active:
		return false
	if shot_cooldown > 0.0:
		return false
	if tucumanazo_definition == null or not tucumanazo_definition.is_valid():
		return false
	if not tucumanazo_counter.consume_one():
		return false
	special_active = true
	special_phase = SpecialPhase.STARTUP
	special_phase_remaining = tucumanazo_definition.startup_duration
	_special_hit_stop_used = false
	velocity.x = 0.0
	action_animation = character_definition.headbutt_animation
	action_time = tucumanazo_definition.get_total_duration()
	shot_cooldown = tucumanazo_definition.get_total_duration()
	play_animation(character_definition.headbutt_animation)
	special_feedback_requested.emit(tucumanazo_definition.phrase)
	AudioManager.play_effect("alerta")
	return true

func cancel_tucumanazo() -> void:
	if not special_active and special_phase == SpecialPhase.READY:
		return
	special_active = false
	special_phase = SpecialPhase.READY
	special_phase_remaining = 0.0
	tucumanazo_hitbox.deactivate()
	tucumanazo_wave_visual.cancel()
	_cancel_hit_stop()
	screen_shake_requested.emit(0.0,0.0)
	if action_animation == character_definition.headbutt_animation:
		action_time = 0.0

func _update_tucumanazo(delta: float) -> void:
	if not special_active:
		return
	special_phase_remaining -= delta
	while special_active and special_phase_remaining <= 0.0:
		var carried_time := -special_phase_remaining
		match special_phase:
			SpecialPhase.STARTUP:
				special_phase = SpecialPhase.ACTIVE
				special_phase_remaining = tucumanazo_definition.active_duration-carried_time
				tucumanazo_hitbox.configure(self,team,lane_index,tucumanazo_definition,facing,GameConfig.ENEMY_LAYER)
				tucumanazo_hitbox.activate(tucumanazo_definition.active_duration)
				tucumanazo_wave_visual.activate(tucumanazo_definition.radius,tucumanazo_definition.active_duration)
				screen_shake_requested.emit(tucumanazo_definition.screen_shake_intensity,tucumanazo_definition.screen_shake_duration)
			SpecialPhase.ACTIVE:
				tucumanazo_hitbox.deactivate()
				special_phase = SpecialPhase.RECOVERY
				special_phase_remaining = tucumanazo_definition.recovery_duration-carried_time
			SpecialPhase.RECOVERY:
				special_active = false
				special_phase = SpecialPhase.READY
				special_phase_remaining = 0.0

func _on_tucumanazo_impact(_hurtbox: Area2D,_impact_id: StringName) -> void:
	if _special_hit_stop_used:
		return
	_special_hit_stop_used = true
	AudioManager.play_effect("golpe")
	_begin_hit_stop()

func _begin_hit_stop() -> void:
	if tucumanazo_definition.hit_stop_duration <= 0.0 or _hit_stop_active:
		return
	_hit_stop_active = true
	_hit_stop_generation += 1
	var generation := _hit_stop_generation
	_time_scale_before_hit_stop = Engine.time_scale
	Engine.time_scale = tucumanazo_definition.hit_stop_time_scale
	await get_tree().create_timer(tucumanazo_definition.hit_stop_duration,true,false,true).timeout
	if generation == _hit_stop_generation:
		Engine.time_scale = _time_scale_before_hit_stop
		_hit_stop_active = false

func _cancel_hit_stop() -> void:
	_hit_stop_generation += 1
	if _hit_stop_active:
		Engine.time_scale = _time_scale_before_hit_stop
		_hit_stop_active = false
static func resolve_shot_direction(raw_direction: Vector2,_airborne: bool,fallback_facing: int) -> Vector2:
	var discrete := Vector2(signf(raw_direction.x),signf(raw_direction.y))
	if discrete.is_zero_approx():
		discrete.x = -1.0 if fallback_facing < 0 else 1.0
	return discrete.normalized()

func get_shot_direction() -> Vector2:
	var raw_direction := Vector2(
		Input.get_axis("move_left","move_right"),
		Input.get_axis("lane_up","lane_down")
	)
	return resolve_shot_direction(raw_direction,not is_on_floor(),facing)

func throw_projectile(kind: String,aim_override: Vector2 = Vector2.ZERO) -> void:
	if shot_cooldown > 0.0 or special_active or collection_active:
		return
	if kind == "stone" and stones <= 0:
		return
	if kind == "orange" and not oranges_unlocked:
		return
	if kind == "stone":
		stones -= 1
	action_animation = character_definition.throw_stone_animation if kind == "stone" else character_definition.throw_orange_animation
	action_time = 0.25
	shot_cooldown = 0.25
	var shot_direction := get_shot_direction() if aim_override.is_zero_approx() else resolve_shot_direction(aim_override,not is_on_floor(),facing)
	shot_requested.emit(global_position+Vector2(0.0,-42.0)+shot_direction*24.0,lane_index,shot_direction,kind,team)
	AudioManager.play_effect("disparo_cascote" if kind == "stone" else "disparo_naranja")
	_emit_status_changed()

func take_damage(amount: int, _source_team: String = "enemy") -> void:
	if state == State.DEATH or not controls_enabled:
		return
	health_component.take_damage(amount,_source_team)

func _on_health_damaged(_amount: int,current_health: int,_source) -> void:
	cancel_collection()
	cancel_tucumanazo()
	combo_component.break_combo()
	AudioManager.play_effect("danio")
	if current_health > 0:
		_apply_hit_response()

func _on_health_depleted() -> void:
	cancel_collection()
	cancel_tucumanazo()
	combo_component.reset()
	lives -= 1
	if lives <= 0:
		state = State.DEATH
		velocity = Vector2.ZERO
		collision_layer = 0
		hurtbox.set_receiving_enabled(false)
		play_animation(character_definition.death_animation)
		visual.modulate = Color(0.5,0.5,0.5)
		create_tween().tween_property(visual,"rotation",facing*PI*0.5,0.35)
		_emit_status_changed()
		died.emit()
		return
	respawn_requested.emit()


func get_respawn_state() -> Dictionary:
	return {
		"score": score,
		"coins": coins,
		"stones": stones,
		"oranges_unlocked": oranges_unlocked,
		"heat": heat,
		"tucumanazos": tucumanazo_counter.current_uses
	}


func respawn_at(respawn_position: Vector2, saved_state: Dictionary,invulnerability_duration: float = -1.0) -> void:
	cancel_collection()
	cancel_tucumanazo()
	combo_component.reset()
	state = State.IDLE
	velocity = Vector2.ZERO
	position = respawn_position
	lane_index = 0 if absf(respawn_position.y-GameConfig.LANES[0]) <= absf(respawn_position.y-GameConfig.LANES[1]) else 1
	destination_lane = lane_index
	lane_start = GameConfig.LANES[lane_index]
	lane_target = lane_start
	lane_progress = 0.0
	changing_lane = false
	collision_layer = GameConfig.PLAYER_LAYER
	collision_mask = 1 << lane_index
	hurtbox.lane_index = lane_index
	hurtbox.set_receiving_enabled(true)
	tucumanazo_hitbox.lane_index = lane_index
	hit_time = 0.0
	action_time = 0.0
	shot_cooldown = 0.0
	fury_time = 0.0
	heat_damage_time = 0.0
	score = int(saved_state.get("score",score))
	coins = int(saved_state.get("coins",coins))
	stones = int(saved_state.get("stones",stones))
	oranges_unlocked = bool(saved_state.get("oranges_unlocked",oranges_unlocked))
	heat = float(saved_state.get("heat",heat))
	tucumanazo_counter.set_uses(int(saved_state.get("tucumanazos",tucumanazo_definition.starting_uses)))
	health_component.restore_full()
	health_component.set_invulnerability(invulnerability_duration if invulnerability_duration >= 0.0 else health_component.invulnerability_duration)
	visual.rotation = 0.0
	visual.modulate = Color.WHITE
	play_animation(character_definition.idle_animation)
	_emit_status_changed()

func _apply_hit_response() -> void:
	hit_time = 0.25
	velocity.x = 0.0
	_emit_status_changed()

func collect(kind: String) -> void:
	match kind:
		"orange_tree":
			oranges_unlocked = true
			AudioManager.play_effect("empanada")
		"stone_pile":
			stones += 20
			AudioManager.play_effect("achilata")
		"empanada":
			score += 25
			coins += 1
			AudioManager.play_effect("empanada")
		"sanguche":
			health_component.restore_full()
			lives = mini(3,lives+1)
			fury_time = 10.0
			AudioManager.play_effect("sanguche")
		"achilata":
			score += 100
			heat = maxf(0.0,heat-50.0)
			AudioManager.play_effect("achilata")
	_emit_status_changed()


func begin_pickup_interaction(kind: String,pickup: Node) -> bool:
	if collection_active or not controls_enabled or state == State.DEATH or changing_lane or special_active:
		return false
	if not COLLECTION_KINDS.has(StringName(kind)) or not is_instance_valid(pickup):
		return false
	if visual.sprite_frames == null or not visual.sprite_frames.has_animation(character_definition.idle_animation):
		return false
	cancel_tucumanazo()
	collection_active = true
	collection_kind = kind
	collection_remaining = COLLECTION_DURATION
	collection_reward_granted = false
	_collection_pickup = pickup
	velocity.x = 0.0
	action_time = 0.0
	state = State.COLLECT
	visual.scale = Vector2.ONE*character_visual_scale
	visual.play(character_definition.idle_animation)
	return true


func _update_collection(delta: float) -> void:
	if not collection_active:
		return
	collection_remaining = maxf(0.0,collection_remaining-delta)
	var reward_remaining := COLLECTION_DURATION-COLLECTION_REWARD_TIME
	if not collection_reward_granted and collection_remaining <= reward_remaining:
		if is_instance_valid(_collection_pickup) and _collection_pickup.has_method("complete_collection"):
			collection_reward_granted = bool(_collection_pickup.complete_collection(self))
		if not collection_reward_granted:
			cancel_collection()
			return
	if collection_remaining <= 0.0:
		_finish_collection()


func cancel_collection() -> void:
	if not collection_active:
		return
	if not collection_reward_granted and is_instance_valid(_collection_pickup) and _collection_pickup.has_method("cancel_collection"):
		_collection_pickup.cancel_collection(self)
	_clear_collection_state()


func _finish_collection() -> void:
	_clear_collection_state()
	if state != State.DEATH:
		state = State.IDLE
		visual.play(character_definition.idle_animation)


func _clear_collection_state() -> void:
	collection_active = false
	collection_kind = ""
	collection_remaining = 0.0
	collection_reward_granted = false
	_collection_pickup = null
	visual.scale = Vector2.ONE*character_visual_scale


func _emit_status_changed() -> void:
	status_changed.emit()
	_emit_hud_status()


func _emit_hud_status() -> void:
	hud_status_changed.emit(lives,stones,oranges_unlocked,heat)

func play_animation(animation_name: StringName) -> void:
	if visual.animation != animation_name:
		visual.play(animation_name)

func _exit_tree() -> void:
	_cancel_hit_stop()
