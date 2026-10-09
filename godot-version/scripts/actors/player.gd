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
const CFG = preload("res://scripts/prototype/feel_config.gd")
const ANIMATION_MANIFEST_PATH := "res://data/animation_manifest.json"

enum State { IDLE, RUN, JUMP, THROW, COLLECT, HIT, DEATH, SUPER_STARTUP, SUPER_RUSH, SUPER_FINISH, SUPER_RECOVERY }
enum SpecialPhase { READY, STARTUP, ACTIVE, RECOVERY, RUSH, FINISH }
const PUNCH_RANGE := 78.0
const PUNCH_FPS := 14.0
const PUNCH_DURATION := 7.0/PUNCH_FPS
const MUZZLE_OFFSETS: Dictionary = {
	Vector2i(1,0): Vector2(32.0,-42.0),
	Vector2i(-1,0): Vector2(-32.0,-42.0),
	Vector2i(0,-1): Vector2(0.0,-74.0),
	Vector2i(1,-1): Vector2(26.0,-68.0),
	Vector2i(-1,-1): Vector2(-26.0,-68.0),
	Vector2i(1,1): Vector2(26.0,-24.0),
	Vector2i(-1,1): Vector2(-26.0,-24.0),
	Vector2i(0,1): Vector2(0.0,-24.0)
}
var punch_active := false
var punch_elapsed := 0.0
var punch_direction := 1
var punch_hits: Dictionary = {}
var punch_hitbox: Area2D
const PUNCH_DAMAGE := 2
const COLLECTION_DURATION := 0.5
const COLLECTION_REWARD_TIME := 0.4
const COLLECTION_KINDS := [&"orange_tree",&"stone_pile"]
@export var character_definition: CHARACTER_DEFINITION
@export var tucumanazo_definition: TUCUMANAZO_DEFINITION
var state: State = State.IDLE
var special_phase: SpecialPhase = SpecialPhase.READY
var special_phase_remaining: float = 0.0
var special_active: bool = false
var special_direction := 1
var special_rush_distance := 0.0
var special_rush_speed := 0.0
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
var heat: float = 0.0:
	set(value):
		heat = value if GameConfig.HEAT_ENABLED else 0.0
var heat_damage_time: float = 0.0
var collection_active: bool = false
var collection_kind: String = ""
var collection_remaining: float = 0.0
var collection_reward_granted: bool = false
var _collection_pickup: Node
var action_animation: StringName = &"Idle"
## Agacharse: NONE -> DOWN (agacharse) -> HELD (agachado, bucle) -> UP (levantarse) -> NONE.
enum CrouchPhase { NONE, DOWN, HELD, UP }
var crouch_phase: int = CrouchPhase.NONE
var crouching: bool:
	get: return crouch_phase == CrouchPhase.DOWN or crouch_phase == CrouchPhase.HELD
var _crouch_timer: float = 0.0
var _hurtbox_crouched: bool = false
var _hurtbox_base: Dictionary = {}
## Compatibilidad de lectura para saves/tests antiguos; el cambio de carril está retirado.
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
@onready var super_rush_hitbox: HITBOX = $SuperRushHitbox
@onready var tucumanazo_wave_visual: TUCUMANAZO_WAVE_VISUAL = $TucumanazoWaveVisual
@onready var visual: AnimatedSprite2D = $Visual
var _visual_frame_offsets: Dictionary = {}

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
	_load_visual_frame_offsets()
	visual.frame_changed.connect(_apply_visual_frame_offset)
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	collision_layer = GameConfig.PLAYER_LAYER
	lane_index = 0
	collision_mask = GameConfig.PLAYER_WORLD_MASK
	var body_shape := CollisionFactory.add_shape(self,visual.sprite_frames.get_frame_texture(character_definition.idle_animation,0),character_visual_scale,true,collision_width_ratio)
	hurtbox.configure(self,health_component,team,lane_index,GameConfig.PLAYER_LAYER)
	hurtbox.copy_shape_from(body_shape)
	if tucumanazo_definition == null or not tucumanazo_definition.is_valid():
		push_error("La definición de Tucumanazo no es válida")
	else:
		tucumanazo_counter.configure(tucumanazo_definition.starting_uses,tucumanazo_definition.starting_uses)
		tucumanazo_hitbox.configure(self,team,lane_index,tucumanazo_definition,facing,GameConfig.ENEMY_LAYER)
	tucumanazo_hitbox.impact_confirmed.connect(_on_tucumanazo_impact)
	super_rush_hitbox.impact_confirmed.connect(_on_super_rush_impact)
	punch_hitbox = Area2D.new()
	punch_hitbox.name = "PunchHitbox"
	punch_hitbox.collision_layer = 0
	punch_hitbox.collision_mask = 0
	punch_hitbox.monitoring = false
	punch_hitbox.monitorable = false
	var punch_shape := CollisionShape2D.new()
	punch_shape.shape = RectangleShape2D.new()
	punch_shape.shape.size = Vector2(PUNCH_RANGE,48.0)
	punch_shape.disabled = true
	punch_hitbox.add_child(punch_shape)
	add_child(punch_hitbox)
	add_to_group("player")
	visual.play(character_definition.idle_animation)
	_apply_visual_frame_offset()

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
	return maxf(0.0,GameConfig.GROUND_Y-position.y)

func _physics_process(delta: float) -> void:
	if state == State.DEATH:
		return
	hit_time = maxf(0.0,hit_time-delta)
	action_time = maxf(0.0,action_time-delta)
	shot_cooldown = maxf(0.0,shot_cooldown-delta)
	_update_tucumanazo(delta)
	_update_collection(delta)
	_update_punch(delta)
	fury_time = maxf(0.0,fury_time-delta)
	if GameConfig.HEAT_ENABLED and position.x > 3200.0 and controls_enabled:
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
	visual.modulate.a = CFG.INVULNERABILITY_BLINK_ALPHA if invulnerability > 0.0 and int(invulnerability*12.0)%2 == 0 else 1.0
	var axis: float = Input.get_axis("move_left","move_right") if controls_enabled and hit_time <= 0.0 and not special_active and not collection_active and not punch_active else 0.0
	_update_crouch(delta,axis)
	if special_active:
		facing = special_direction
		velocity.x = special_direction*minf(special_rush_speed,maxf(0.0,tucumanazo_definition.rush_distance-special_rush_distance)/maxf(delta,0.001)) if special_phase == SpecialPhase.RUSH else 0.0
	elif hit_time <= 0.0:
		velocity.x = axis * (fury_speed if fury_time > 0.0 else walk_speed) * (CFG.CROUCH_SPEED_MULT if crouching else 1.0)
	if not is_zero_approx(axis):
		facing = -1 if axis < 0.0 else 1
	visual.flip_h = facing < 0
	velocity.y += gravity*delta
	if controls_enabled and hit_time <= 0.0 and not special_active and not collection_active:
		if is_on_floor() and Input.is_action_just_pressed("jump"):
			velocity.y = -jump_speed
			AudioManager.play_effect("salto")
		if Input.is_action_just_released("jump") and velocity.y < -120.0:
			velocity.y *= 0.5
		if Input.is_action_just_pressed("tucumanazo"):
			start_tucumanazo()
		elif Input.is_action_just_pressed("throw_orange"):
			throw_projectile("orange")
		elif Input.is_action_just_pressed("throw_stone"):
			throw_projectile("stone")
	var motion_start := global_position
	var rushing := special_active and special_phase == SpecialPhase.RUSH
	move_and_slide()
	position.x = clampf(position.x,20.0,GameConfig.WORLD_WIDTH-20.0)
	if rushing:
		var allowed := _super_motion_bounds()
		position.x = clampf(position.x,allowed.x,allowed.y)
		# A sweep over actual travelled space cannot hit through a blocking wall.
		_poll_super_hitbox(super_rush_hitbox,motion_start,global_position)
		if special_active:
			special_rush_distance += absf(global_position.x-motion_start.x)
			if special_rush_distance >= tucumanazo_definition.rush_distance-0.1 or is_on_wall() \
					or position.x <= allowed.x+0.1 or position.x >= allowed.y-0.1 or not is_on_floor():
				_begin_super_finish()
	if special_active and special_phase == SpecialPhase.ACTIVE:
		_poll_super_hitbox(tucumanazo_hitbox,global_position,global_position)
	z_index = 15
	if special_active:
		match special_phase:
			SpecialPhase.STARTUP: state = State.SUPER_STARTUP
			SpecialPhase.RUSH: state = State.SUPER_RUSH
			SpecialPhase.FINISH,SpecialPhase.ACTIVE: state = State.SUPER_FINISH
			SpecialPhase.RECOVERY: state = State.SUPER_RECOVERY
	elif punch_active:
		state = State.THROW
	elif collection_active:
		state = State.COLLECT
		play_animation(character_definition.idle_animation)
	elif hit_time > 0.0:
		state = State.HIT
		play_animation(character_definition.hit_animation)
	elif crouch_phase != CrouchPhase.NONE:
		state = State.IDLE
		play_animation(CFG.CROUCH_ANIMATIONS[crouch_phase])
	elif action_time > 0.0:
		state = State.THROW
		play_animation(action_animation)
	elif not is_on_floor():
		state = State.JUMP
		play_animation(character_definition.jump_animation)
	elif not is_zero_approx(axis):
		state = State.RUN
		play_animation(character_definition.run_animation)
	else:
		state = State.IDLE
		play_animation(character_definition.idle_animation)

func _set_crouch_phase_safe() -> void:
	crouch_phase = CrouchPhase.NONE
	_apply_crouch_hurtbox(false)

func _update_crouch(delta: float,axis: float) -> void:
	var available := visual.sprite_frames != null and visual.sprite_frames.has_animation(&"agachado")
	var can := available and controls_enabled and is_on_floor() and hit_time <= 0.0 and not special_active and not collection_active and not punch_active and state != State.DEATH
	var down := can and Input.is_action_pressed("aim_down")
	var leave := not can or Input.is_action_just_pressed("jump") # saltar cancela el agachado
	_crouch_timer = maxf(0.0,_crouch_timer-delta)
	match crouch_phase:
		CrouchPhase.NONE:
			if down and is_zero_approx(axis) and not leave:
				_set_crouch_phase(CrouchPhase.DOWN)
		CrouchPhase.DOWN:
			if leave:
				_set_crouch_phase(CrouchPhase.NONE)
			elif not down:
				_set_crouch_phase(CrouchPhase.UP)
			elif _crouch_timer <= 0.0:
				_set_crouch_phase(CrouchPhase.HELD)
		CrouchPhase.HELD:
			if leave:
				_set_crouch_phase(CrouchPhase.NONE)
			elif not down:
				_set_crouch_phase(CrouchPhase.UP)
		CrouchPhase.UP:
			if leave or not is_zero_approx(axis):
				_set_crouch_phase(CrouchPhase.NONE)
			elif down:
				_set_crouch_phase(CrouchPhase.DOWN)
			elif _crouch_timer <= 0.0:
				_set_crouch_phase(CrouchPhase.NONE)

func _set_crouch_phase(phase: int) -> void:
	crouch_phase = phase
	if phase == CrouchPhase.DOWN or phase == CrouchPhase.UP:
		var animation: StringName = CFG.CROUCH_ANIMATIONS[phase]
		_crouch_timer = visual.sprite_frames.get_frame_count(animation)/maxf(visual.sprite_frames.get_animation_speed(animation),1.0)
	_apply_crouch_hurtbox(phase == CrouchPhase.DOWN or phase == CrouchPhase.HELD)

## Agachado la hurtbox baja a CROUCH_HURTBOX_RATIO de la altura, con los pies fijos: los disparos altos pasan por encima.
func _apply_crouch_hurtbox(on: bool) -> void:
	# También el cuerpo: los proyectiles detectan al jugador por su colisión y luego por la hurtbox.
	var nodes: Array[CollisionShape2D] = [hurtbox.collision_shape]
	var body_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_node != null:
		nodes.append(body_node)
	if on and not _hurtbox_crouched:
		_hurtbox_base.clear()
		for index in nodes.size():
			var rect := nodes[index].shape as RectangleShape2D
			if rect == null:
				continue
			_hurtbox_base[index] = {"size": rect.size, "y": nodes[index].position.y}
			var height := rect.size.y*CFG.CROUCH_HURTBOX_RATIO
			nodes[index].position.y += (rect.size.y-height)*0.5
			rect.size.y = height
		_hurtbox_crouched = true
	elif not on and _hurtbox_crouched:
		for index in _hurtbox_base:
			var rect := nodes[index].shape as RectangleShape2D
			if rect != null:
				rect.size = _hurtbox_base[index].size
				nodes[index].position.y = _hurtbox_base[index].y
		_hurtbox_crouched = false

func begin_lane_change(destination: int) -> void:
	# API legacy intencionalmente inerte durante la migración de saves/tests.
	destination_lane = 0
	lane_index = 0
	changing_lane = false
	lane_start = GameConfig.GROUND_Y
	lane_target = GameConfig.GROUND_Y

func register_valid_hit(_hurtbox: Area2D,impact_id: StringName) -> void:
	combo_component.register_hit(impact_id)

func start_tucumanazo() -> bool:
	if not controls_enabled or state == State.DEATH or special_active or collection_active:
		return false
	if not is_on_floor() or hit_time > 0.0:
		return false
	if shot_cooldown > 0.0:
		return false
	if tucumanazo_definition == null or not tucumanazo_definition.is_valid():
		return false
	if not tucumanazo_counter.consume_one():
		return false
	cancel_punch()
	special_active = true
	special_direction = facing
	special_rush_distance = 0.0
	special_rush_speed = walk_speed*tucumanazo_definition.rush_speed_multiplier
	special_phase = SpecialPhase.STARTUP
	state = State.SUPER_STARTUP
	special_phase_remaining = tucumanazo_definition.startup_duration
	_special_hit_stop_used = false
	velocity.x = 0.0
	action_animation = character_definition.headbutt_animation
	action_time = tucumanazo_definition.get_total_duration()
	shot_cooldown = tucumanazo_definition.get_total_duration()
	play_animation(character_definition.headbutt_animation)
	visual.pause()
	visual.frame = 0
	special_feedback_requested.emit(tucumanazo_definition.phrase)
	AudioManager.play_effect("alerta")
	return true

func cancel_tucumanazo() -> void:
	if not special_active and special_phase == SpecialPhase.READY:
		return
	special_active = false
	special_phase = SpecialPhase.READY
	special_phase_remaining = 0.0
	special_rush_distance = 0.0
	velocity.x = 0.0
	super_rush_hitbox.deactivate()
	tucumanazo_hitbox.deactivate()
	super_rush_hitbox._hit_targets.clear()
	tucumanazo_hitbox._hit_targets.clear()
	tucumanazo_wave_visual.cancel()
	_cancel_hit_stop()
	screen_shake_requested.emit(0.0,0.0)
	if action_animation == character_definition.headbutt_animation:
		action_time = 0.0
	visual.speed_scale = 1.0
	if state in [State.SUPER_STARTUP,State.SUPER_RUSH,State.SUPER_FINISH,State.SUPER_RECOVERY]:
		state = State.IDLE
		visual.play(character_definition.idle_animation)

func _update_tucumanazo(delta: float) -> void:
	if not special_active:
		return
	special_phase_remaining -= delta
	while special_active and special_phase_remaining <= 0.0:
		var carried_time := -special_phase_remaining
		match special_phase:
			SpecialPhase.STARTUP:
				special_phase = SpecialPhase.RUSH
				state = State.SUPER_RUSH
				special_phase_remaining = tucumanazo_definition.rush_timeout
				super_rush_hitbox.configure(self,team,lane_index,tucumanazo_definition.rush_attack,special_direction,GameConfig.ENEMY_LAYER)
				super_rush_hitbox.activate(tucumanazo_definition.rush_timeout)
				visual.speed_scale = tucumanazo_definition.rush_speed_multiplier
				visual.play(character_definition.run_animation)
			SpecialPhase.RUSH:
				_begin_super_finish()
			SpecialPhase.FINISH:
				special_phase = SpecialPhase.ACTIVE
				special_phase_remaining = tucumanazo_definition.active_duration-carried_time
				visual.pause()
				visual.frame = mini(2,visual.sprite_frames.get_frame_count(character_definition.headbutt_animation)-1)
				tucumanazo_hitbox.configure(self,team,lane_index,tucumanazo_definition,special_direction,GameConfig.ENEMY_LAYER)
				tucumanazo_hitbox.activate(tucumanazo_definition.active_duration)
				tucumanazo_wave_visual.activate(tucumanazo_definition.radius,tucumanazo_definition.active_duration)
				screen_shake_requested.emit(tucumanazo_definition.screen_shake_intensity,tucumanazo_definition.screen_shake_duration)
			SpecialPhase.ACTIVE:
				tucumanazo_hitbox.deactivate()
				special_phase = SpecialPhase.RECOVERY
				state = State.SUPER_RECOVERY
				visual.frame = mini(3,visual.sprite_frames.get_frame_count(character_definition.headbutt_animation)-1)
				special_phase_remaining = tucumanazo_definition.recovery_duration-carried_time
			SpecialPhase.RECOVERY:
				cancel_tucumanazo()
				shot_cooldown = 0.0


func _super_motion_bounds() -> Vector2:
	var bounds := Vector2(20.0,GameConfig.WORLD_WIDTH-20.0)
	var level := get_parent()
	if level.get("boss_active") == true:
		bounds = level.BOSS_ARENA_BOUNDS
	elif level.get("miniboss_active") == true:
		bounds = level.MINIBOSS_ARENA_BOUNDS
	return bounds


func _begin_super_finish() -> void:
	super_rush_hitbox.deactivate()
	velocity.x = 0.0
	special_phase = SpecialPhase.FINISH
	state = State.SUPER_FINISH
	special_phase_remaining = tucumanazo_definition.finish_startup_duration
	visual.speed_scale = 1.0
	visual.play(character_definition.headbutt_animation)
	visual.frame = 0


func _poll_super_hitbox(hitbox: HITBOX,from: Vector2,to: Vector2) -> void:
	if not hitbox.active:
		return
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = hitbox.collision_shape.shape
	query.collision_mask = GameConfig.ENEMY_LAYER
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var steps := maxi(1,ceili(from.distance_to(to)/16.0))
	for index in range(steps+1):
		query.transform = hitbox.collision_shape.global_transform
		query.transform.origin += from.lerp(to,float(index)/steps)-global_position
		for hit in get_world_2d().direct_space_state.intersect_shape(query):
			hitbox.try_hit(hit.collider)


func _on_super_rush_impact(target_hurtbox: Area2D,_impact_id: StringName) -> void:
	_apply_super_knockback(target_hurtbox,tucumanazo_definition.rush_knockback_speed)
	AudioManager.play_effect("golpe")
	screen_shake_requested.emit(2.0,0.08)


func _apply_super_knockback(target_hurtbox: Area2D,speed: float) -> void:
	var actor = target_hurtbox.combat_owner
	if is_instance_valid(actor) and actor.has_method("receive_super_knockback"):
		actor.receive_super_knockback(special_direction*speed,tucumanazo_definition.stagger_duration)

func _on_tucumanazo_impact(_hurtbox: Area2D,_impact_id: StringName) -> void:
	_apply_super_knockback(_hurtbox,tucumanazo_definition.final_knockback_speed)
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
	var aim_y := Input.get_axis("aim_up","aim_down")
	if is_on_floor():
		aim_y = minf(aim_y,0.0) # apuntar abajo solo vale en el aire (↓ en el piso es agacharse)
	var raw_direction := Vector2(
		Input.get_axis("move_left","move_right"),
		aim_y
	)
	return resolve_shot_direction(raw_direction,not is_on_floor(),facing)

static func get_muzzle_offset(shot_direction: Vector2) -> Vector2:
	var key := Vector2i(int(signf(shot_direction.x)),int(signf(shot_direction.y)))
	return MUZZLE_OFFSETS.get(key,MUZZLE_OFFSETS[Vector2i(1,0)])

func throw_projectile(kind: String,aim_override: Vector2 = Vector2.ZERO) -> void:
	if shot_cooldown > 0.0 or special_active or collection_active:
		return
	if not controls_enabled or state == State.DEATH or hit_time > 0.0:
		return
	if _find_punch_target() != null:
		start_punch()
		return
	if kind == "stone" and stones <= 0:
		return
	if kind == "orange" and not oranges_unlocked:
		return
	if kind == "stone":
		stones -= 1
	action_animation = character_definition.throw_stone_animation if kind == "stone" else character_definition.throw_orange_animation
	action_time = 0.25
	# Corriendo: animación de correr y lanzar (cuadros nuevos). Arranca ya, y el movimiento horizontal no se corta.
	if is_on_floor() and absf(velocity.x) > 1.0 and visual.sprite_frames.has_animation(CFG.CIRUJA_RUN_THROW):
		action_animation = CFG.CIRUJA_RUN_THROW
		action_time = float(visual.sprite_frames.get_frame_count(CFG.CIRUJA_RUN_THROW)) / maxf(visual.sprite_frames.get_animation_speed(CFG.CIRUJA_RUN_THROW),1.0)
		visual.play(CFG.CIRUJA_RUN_THROW)
		visual.frame = 0
	shot_cooldown = 0.25
	if crouching:
		action_time = 0.0 # agachado se mantiene en pantalla: se lanza sin cambiar de animación
	var shot_direction := get_shot_direction() if aim_override.is_zero_approx() else resolve_shot_direction(aim_override,not is_on_floor(),facing)
	var muzzle := global_position+get_muzzle_offset(shot_direction)
	if crouching:
		muzzle.y += CFG.CROUCH_MUZZLE_DROP
	shot_requested.emit(muzzle,lane_index,shot_direction,kind,team)
	AudioManager.play_effect("disparo_cascote" if kind == "stone" else "disparo_naranja")
	_emit_status_changed()

func _punch_target_valid(enemy: Node) -> bool:
	if not is_instance_valid(enemy) or enemy.get("active") != true or not enemy.has_node("Hurtbox"):
		return false
	var offset: Vector2 = enemy.global_position-global_position
	var direction_to_use := punch_direction if punch_active else facing
	if absf(offset.x)>PUNCH_RANGE or offset.x*direction_to_use < -16.0 or absf(offset.y)>36.0:
		return false
	var origin := global_position+Vector2(0,-38)
	var endpoint: Vector2 = enemy.global_position+Vector2(0,-38)
	var query := PhysicsRayQueryParameters2D.create(origin,endpoint,GameConfig.PLAYER_WORLD_MASK,[get_rid()])
	query.hit_from_inside = true
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _find_punch_target() -> Node:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if _punch_target_valid(enemy):
			return enemy
	return null

func start_punch() -> void:
	if special_active:
		return
	punch_active = true
	punch_elapsed = 0.0
	punch_direction = facing
	punch_hits.clear()
	action_animation = &"Punch"
	action_time = PUNCH_DURATION
	shot_cooldown = PUNCH_DURATION+0.12
	velocity.x = 0.0
	visual.play(&"Punch")
	visual.pause()
	visual.frame = 0

func cancel_punch() -> void:
	punch_active = false
	if is_instance_valid(punch_hitbox):
		punch_hitbox.get_child(0).set_deferred("disabled",true)

func _update_punch(delta: float) -> void:
	if not punch_active:
		return
	punch_elapsed += delta
	var frame_index := mini(6,int(punch_elapsed*PUNCH_FPS))
	visual.frame = frame_index
	punch_hitbox.position = Vector2(punch_direction*PUNCH_RANGE*0.5,-38)
	var shape_node: CollisionShape2D = punch_hitbox.get_child(0)
	shape_node.disabled = frame_index not in [2,3,4]
	if not shape_node.disabled:
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = shape_node.shape
		query.transform = shape_node.global_transform
		query.collision_mask = GameConfig.ENEMY_LAYER
		query.collide_with_areas = true
		query.collide_with_bodies = false
		for hit in get_world_2d().direct_space_state.intersect_shape(query):
			var hurtbox = hit.collider
			var enemy = hurtbox.get_parent()
			if _punch_target_valid(enemy) and not punch_hits.has(enemy.get_instance_id()):
				punch_hits[enemy.get_instance_id()] = true
				enemy.take_damage(PUNCH_DAMAGE,&"player")
	if punch_elapsed >= PUNCH_DURATION:
		cancel_punch()

func take_damage(amount: int, _source_team: String = "enemy") -> void:
	if _source_team == "sun" and not GameConfig.HEAT_ENABLED:
		return
	if state == State.DEATH or not controls_enabled:
		return
	if special_active and special_phase == SpecialPhase.RUSH and _source_team == "enemy":
		return # Weak body contact only; hostile hitboxes/projectiles use HealthComponent directly.
	health_component.take_damage(amount,_source_team)

func _on_health_damaged(_amount: int,current_health: int,_source) -> void:
	cancel_punch()
	cancel_collection()
	cancel_tucumanazo()
	combo_component.break_combo()
	AudioManager.play_effect("danio")
	if current_health > 0:
		_apply_hit_response()

func _on_health_depleted() -> void:
	cancel_punch()
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
	_set_crouch_phase_safe()
	cancel_punch()
	cancel_collection()
	cancel_tucumanazo()
	combo_component.reset()
	state = State.IDLE
	velocity = Vector2.ZERO
	position = respawn_position
	lane_index = 0
	destination_lane = lane_index
	lane_start = GameConfig.GROUND_Y
	lane_target = lane_start
	lane_progress = 0.0
	changing_lane = false
	collision_layer = GameConfig.PLAYER_LAYER
	collision_mask = GameConfig.PLAYER_WORLD_MASK
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
			tucumanazo_counter.reset_full()
			lives = mini(3,lives+1)
			fury_time = 10.0
			AudioManager.play_effect("sanguche")
		"achilata":
			score += 100
			if GameConfig.HEAT_ENABLED:
				heat = maxf(0.0,heat-50.0)
			AudioManager.play_effect("achilata")
	_emit_status_changed()


func begin_pickup_interaction(kind: String,pickup: Node) -> bool:
	if collection_active or not controls_enabled or state == State.DEATH or special_active:
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
		var leaving_run_throw: bool = visual.animation == CFG.CIRUJA_RUN_THROW
		visual.play(animation_name)
		if leaving_run_throw and animation_name == character_definition.run_animation:
			visual.set_frame_and_progress(mini(CFG.CIRUJA_RUN_RESUME_FRAME,visual.sprite_frames.get_frame_count(animation_name)-1),0.0) # sin salto visual
		_apply_visual_frame_offset()

func _load_visual_frame_offsets() -> void:
	_visual_frame_offsets.clear()
	if visual.sprite_frames == null or visual.sprite_frames.resource_path != "res://assets/animations/player.tres":
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(ANIMATION_MANIFEST_PATH))
	if not data is Dictionary or not data.has("characters") or not data.characters.has("ciruja"):
		return
	var aliases := {
		&"idle": &"Idle", &"correr": &"Run", &"salto": &"Jump",
		&"disparar_naranja": &"Throw Orange", &"disparar_cascote": &"Throw Stone",
		&"cabezazo_anim": &"Headbutt"
	}
	for animation_name: String in data.characters.ciruja.animations:
		var entry: Dictionary = data.characters.ciruja.animations[animation_name]
		if entry.has("frame_offsets") and entry.frame_offsets is Array:
			_visual_frame_offsets[StringName(animation_name)] = entry.frame_offsets
	for alias: StringName in aliases:
		if _visual_frame_offsets.has(aliases[alias]):
			_visual_frame_offsets[alias] = _visual_frame_offsets[aliases[alias]]

func _apply_visual_frame_offset() -> void:
	var offsets: Array = _visual_frame_offsets.get(visual.animation,[])
	if visual.frame >= 0 and visual.frame < offsets.size():
		var value: Array = offsets[visual.frame]
		visual.offset = Vector2(float(value[0]),float(value[1]))
	else:
		visual.offset = Vector2.ZERO

func _exit_tree() -> void:
	cancel_tucumanazo()
	_cancel_hit_stop()
