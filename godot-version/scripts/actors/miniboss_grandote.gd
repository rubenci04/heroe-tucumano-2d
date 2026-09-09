class_name MinibossGrandote
extends CharacterBody2D

signal defeated(points: int)
signal pattern_started(pattern: int)
signal pattern_completed(pattern: int)
signal screen_shake_requested(intensity: float, duration: float)

const HEALTH_COMPONENT = preload("res://scripts/components/health_component.gd")
const HITBOX = preload("res://scripts/components/hitbox.gd")
const HURTBOX = preload("res://scripts/components/hurtbox.gd")
const ATTACK_DEFINITION = preload("res://scripts/data/attack_definition.gd")

enum BossState { INTRO, DECIDE, TELEGRAPH, ATTACK, RECOVERY, DEFEATED }
enum Pattern { NONE, CHARGE, PUNCH, GROUND_SLAM }

@export_group("Provisional balance")
@export_range(1,999,1) var max_health: int = 45
@export_range(0,99999,1) var reward_points: int = 1200
@export_range(0.01,5.0,0.01) var intro_duration: float = 0.8
@export_range(0.01,5.0,0.01) var decision_delay: float = 0.45
@export_range(1.0,1000.0,1.0) var charge_speed: float = 420.0
@export_range(1.0,1000.0,1.0) var lane_move_speed: float = 180.0
@export var arena_bounds := Vector2(6900.0,7750.0)

@export_group("Patterns")
@export var charge_definition: ATTACK_DEFINITION
@export var punch_definition: ATTACK_DEFINITION
@export var ground_slam_definition: ATTACK_DEFINITION

var team: StringName = &"enemy"
var lane_index: int = 0
var target: CharacterBody2D
var boss_state: BossState = BossState.INTRO
var current_pattern: Pattern = Pattern.NONE
var facing: int = -1
var active: bool = true
var _state_remaining: float = 0.0
var _state_duration: float = 0.0
var _next_pattern_index: int = 0
var _locked_facing: int = -1
var _defeat_emitted: bool = false
var _base_visual_position := Vector2(0,-90)
var _pattern_order: Array[Pattern] = [Pattern.PUNCH,Pattern.CHARGE,Pattern.GROUND_SLAM]

@onready var health_component: HEALTH_COMPONENT = $HealthComponent
@onready var hurtbox: HURTBOX = $Hurtbox
@onready var attack_hitbox: HITBOX = $AttackHitbox
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: AnimatedSprite2D = $Visual

var health: int:
	get:
		return health_component.current_health
	set(value):
		health_component.set_current_health(value)


func _ready() -> void:
	if not _definitions_are_valid():
		push_error("El Grandote requiere tres AttackDefinitions válidas")
		active = false
		set_physics_process(false)
		return
	health_component.damaged.connect(_on_health_damaged)
	health_component.depleted.connect(_on_health_depleted)
	health_component.configure(max_health,max_health,0.12)
	collision_layer = GameConfig.ENEMY_LAYER
	collision_mask = 1 << lane_index
	floor_snap_length = 6.0
	hurtbox.configure(self,health_component,team,lane_index,GameConfig.ENEMY_LAYER)
	hurtbox.copy_shape_from(body_shape)
	attack_hitbox.configure(self,team,lane_index,punch_definition,facing,GameConfig.PLAYER_LAYER)
	attack_hitbox.deactivate()
	visual.play(&"grandote_run")
	_base_visual_position = visual.position
	_state_remaining = intro_duration
	_state_duration = intro_duration
	add_to_group("enemies")
	add_to_group("miniboss")


func _physics_process(delta: float) -> void:
	if not active or boss_state == BossState.DEFEATED:
		return
	_update_facing()
	_update_feedback()
	if not is_instance_valid(target) or target.state == target.State.DEATH:
		velocity = Vector2.ZERO
		return
	match boss_state:
		BossState.INTRO:
			_tick_state(delta)
			if _state_remaining <= 0.0:
				_enter_decide()
		BossState.DECIDE:
			if _align_lane(delta):
				return
			_tick_state(delta)
			if _state_remaining <= 0.0:
				begin_pattern(_pattern_order[_next_pattern_index])
				_next_pattern_index = (_next_pattern_index+1)%_pattern_order.size()
		BossState.TELEGRAPH:
			_process_telegraph(delta)
		BossState.ATTACK:
			_process_attack(delta)
		BossState.RECOVERY:
			_tick_state(delta)
			velocity.x = 0.0
			_apply_gravity_and_move(delta)
			if _state_remaining <= 0.0:
				pattern_completed.emit(current_pattern)
				current_pattern = Pattern.NONE
				_enter_decide()
	z_index = int(GameConfig.LANES[lane_index])+2


func begin_pattern(pattern: Pattern) -> bool:
	if not active or boss_state != BossState.DECIDE or pattern == Pattern.NONE:
		return false
	var definition := get_pattern_definition(pattern)
	if definition == null or not definition.is_valid():
		return false
	current_pattern = pattern
	_locked_facing = facing
	boss_state = BossState.TELEGRAPH
	_state_remaining = definition.startup_duration
	_state_duration = definition.startup_duration
	velocity = Vector2.ZERO
	visual.play(&"grandote_salto" if pattern == Pattern.GROUND_SLAM else &"grandote_punch")
	AudioManager.play_effect("alerta")
	pattern_started.emit(pattern)
	return true


func get_pattern_definition(pattern: Pattern) -> ATTACK_DEFINITION:
	match pattern:
		Pattern.CHARGE:
			return charge_definition
		Pattern.PUNCH:
			return punch_definition
		Pattern.GROUND_SLAM:
			return ground_slam_definition
	return null


func get_active_pattern_count() -> int:
	return 1 if current_pattern != Pattern.NONE and boss_state in [BossState.TELEGRAPH,BossState.ATTACK,BossState.RECOVERY] else 0


func take_damage(amount: int, source_team: StringName = &"player") -> void:
	if active and source_team != team:
		health_component.take_damage(amount,source_team)


func _process_telegraph(delta: float) -> void:
	_tick_state(delta)
	velocity = Vector2.ZERO
	if current_pattern == Pattern.GROUND_SLAM and _state_duration > 0.0:
		var progress := 1.0-_state_remaining/_state_duration
		visual.position.y = _base_visual_position.y-sin(progress*PI)*72.0
	if _state_remaining <= 0.0:
		_start_attack()


func _start_attack() -> void:
	var definition := get_pattern_definition(current_pattern)
	boss_state = BossState.ATTACK
	_state_remaining = definition.active_duration
	_state_duration = definition.active_duration
	visual.position = _base_visual_position
	attack_hitbox.configure(self,team,lane_index,definition,_locked_facing,GameConfig.PLAYER_LAYER)
	attack_hitbox.activate(definition.active_duration)
	if current_pattern == Pattern.GROUND_SLAM:
		AudioManager.play_effect("golpe")
		screen_shake_requested.emit(5.0,0.18)


func _process_attack(delta: float) -> void:
	_tick_state(delta)
	if current_pattern == Pattern.CHARGE:
		velocity.x = _locked_facing*charge_speed
	else:
		velocity.x = 0.0
	_apply_gravity_and_move(delta)
	position.x = clampf(position.x,arena_bounds.x,arena_bounds.y)
	if _state_remaining <= 0.0:
		attack_hitbox.deactivate()
		boss_state = BossState.RECOVERY
		var definition := get_pattern_definition(current_pattern)
		_state_remaining = definition.recovery_duration
		_state_duration = definition.recovery_duration
		velocity.x = 0.0


func _enter_decide() -> void:
	boss_state = BossState.DECIDE
	_state_remaining = decision_delay
	_state_duration = decision_delay
	velocity.x = 0.0
	visual.position = _base_visual_position
	visual.play(&"grandote_run")


func _align_lane(delta: float) -> bool:
	if target.lane_index == lane_index:
		return false
	collision_mask = 0
	position.y = move_toward(position.y,GameConfig.LANES[target.lane_index],lane_move_speed*delta)
	if absf(position.y-GameConfig.LANES[target.lane_index]) <= 0.1:
		lane_index = target.lane_index
		position.y = GameConfig.LANES[lane_index]
		hurtbox.lane_index = lane_index
		attack_hitbox.lane_index = lane_index
		collision_mask = 1 << lane_index
	return true


func _apply_gravity_and_move(delta: float) -> void:
	velocity.y += GameConfig.GRAVITY*delta
	move_and_slide()


func _tick_state(delta: float) -> void:
	_state_remaining = maxf(0.0,_state_remaining-delta)


func _update_facing() -> void:
	if not is_instance_valid(target) or boss_state in [BossState.TELEGRAPH,BossState.ATTACK]:
		return
	facing = -1 if target.position.x < position.x else 1
	visual.flip_h = facing > 0


func _update_feedback() -> void:
	if health_component.is_invulnerable():
		visual.modulate = Color(1.0,0.35,0.35)
	elif boss_state == BossState.TELEGRAPH:
		visual.modulate = Color(1.0,0.78,0.25) if current_pattern != Pattern.GROUND_SLAM else Color(0.45,0.8,1.0)
	else:
		visual.modulate = Color.WHITE


func _on_health_damaged(_amount: int, _current_health: int, _source) -> void:
	AudioManager.play_effect("golpe")


func _on_health_depleted() -> void:
	if _defeat_emitted:
		return
	_defeat_emitted = true
	active = false
	boss_state = BossState.DEFEATED
	current_pattern = Pattern.NONE
	velocity = Vector2.ZERO
	attack_hitbox.deactivate()
	hurtbox.set_receiving_enabled(false)
	collision_layer = 0
	remove_from_group("enemies")
	screen_shake_requested.emit(7.0,0.3)
	defeated.emit(reward_points)
	var tween := create_tween()
	tween.tween_property(visual,"modulate:a",0.0,0.55)
	tween.tween_callback(queue_free)


func _definitions_are_valid() -> bool:
	return charge_definition != null and charge_definition.is_valid() \
		and punch_definition != null and punch_definition.is_valid() \
		and ground_slam_definition != null and ground_slam_definition.is_valid()

