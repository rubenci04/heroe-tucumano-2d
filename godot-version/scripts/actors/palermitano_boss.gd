class_name PalermitanoBoss
extends CharacterBody2D

signal defeated(points: int)
signal aimed_shot_requested(origin: Vector2, lane: int, direction: Vector2, kind: String, team: String)
signal summon_requested(count: int, lane: int)
signal pattern_started(pattern: int)
signal pattern_completed(pattern: int)
signal screen_shake_requested(intensity: float, duration: float)

const HEALTH_COMPONENT = preload("res://scripts/components/health_component.gd")
const HITBOX = preload("res://scripts/components/hitbox.gd")
const HURTBOX = preload("res://scripts/components/hurtbox.gd")
const ATTACK_DEFINITION = preload("res://scripts/data/attack_definition.gd")

enum BossState { INTRO, DECIDE, TELEGRAPH, ATTACK, RECOVERY, DEFEATED }
enum Pattern { NONE, TRIPLE_COFFEE, SUMMON_AGENTS, CHAIN }

@export_group("Boss")
@export_range(1,999,1) var max_health: int = 90
@export_range(0,99999,1) var reward_points: int = 1500
@export var arena_bounds := Vector2(7000.0,7950.0)
@export_range(0.01,5.0,0.01) var intro_duration: float = 0.80
@export_range(0.01,5.0,0.01) var decision_delay: float = 0.35
@export_range(1.0,1000.0,1.0) var lane_move_speed: float = 180.0

@export_group("Triple coffee")
@export_range(0.01,5.0,0.01) var coffee_telegraph: float = 0.30
@export_range(0.01,1.0,0.01) var coffee_shot_interval: float = 0.16
@export_range(0.01,5.0,0.01) var coffee_recovery: float = 0.55
@export_range(0.01,10.0,0.01) var coffee_cooldown: float = 1.80
@export_range(0.0,30.0,0.5) var coffee_spread_degrees: float = 7.0

@export_group("Summons")
@export_range(0.01,5.0,0.01) var summon_telegraph: float = 0.48
@export_range(0.01,5.0,0.01) var summon_recovery: float = 0.70
@export_range(0.01,15.0,0.01) var summon_cooldown: float = 5.00
@export_range(1,2,1) var max_live_summons: int = 2

@export_group("Chain")
@export var chain_definition: ATTACK_DEFINITION
@export_range(1.0,500.0,1.0) var chain_range: float = 155.0
@export_range(0.01,10.0,0.01) var chain_cooldown: float = 1.35

var team: StringName = &"enemy"
var lane_index: int = 1
var target: CharacterBody2D
var boss_state: BossState = BossState.INTRO
var current_pattern: Pattern = Pattern.NONE
var last_pattern: Pattern = Pattern.NONE
var facing: int = -1
var active: bool = true
var coffee_projectiles_emitted: int = 0
var summon_requests_emitted: int = 0
var chain_activations: int = 0

var _state_remaining: float = 0.0
var _state_duration: float = 0.0
var _coffee_interval_remaining: float = 0.0
var _coffee_shots_this_attack: int = 0
var _summon_emitted: bool = false
var _defeat_emitted: bool = false
var _locked_facing: int = -1
var _locked_target_position := Vector2.ZERO
var _coffee_cooldown_remaining: float = 0.0
var _summon_cooldown_remaining: float = 0.0
var _chain_cooldown_remaining: float = 0.0
var _summons: Array[WeakRef] = []

@onready var health_component: HEALTH_COMPONENT = $HealthComponent
@onready var hurtbox: HURTBOX = $Hurtbox
@onready var chain_hitbox: HITBOX = $ChainHitbox
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: AnimatedSprite2D = $Visual

var health: int:
	get:
		return health_component.current_health
	set(value):
		health_component.set_current_health(value)


func _ready() -> void:
	if chain_definition == null or not chain_definition.is_valid():
		push_error("Palermitano requiere una AttackDefinition de cadena válida")
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
	chain_hitbox.configure(self,team,lane_index,chain_definition,facing,GameConfig.PLAYER_LAYER)
	chain_hitbox.deactivate()
	visual.play(&"boss_run")
	_state_remaining = intro_duration
	_state_duration = intro_duration
	add_to_group("enemies")
	add_to_group("boss")


func _physics_process(delta: float) -> void:
	if not active or boss_state == BossState.DEFEATED:
		return
	_tick_cooldowns(delta)
	_update_facing()
	_update_feedback()
	if not is_instance_valid(target) or target.state == target.State.DEATH:
		velocity = Vector2.ZERO
		return
	match boss_state:
		BossState.INTRO:
			_tick_state(delta)
			_apply_gravity_and_move(delta)
			if _state_remaining <= 0.0:
				_enter_decide()
		BossState.DECIDE:
			if _align_lane(delta):
				return
			_tick_state(delta)
			_apply_gravity_and_move(delta)
			if _state_remaining <= 0.0:
				var selected := choose_pattern()
				if selected == Pattern.NONE:
					_state_remaining = 0.10
				else:
					begin_pattern(selected)
		BossState.TELEGRAPH:
			_process_telegraph(delta)
		BossState.ATTACK:
			_process_attack(delta)
		BossState.RECOVERY:
			_tick_state(delta)
			_apply_gravity_and_move(delta)
			if _state_remaining <= 0.0:
				pattern_completed.emit(current_pattern)
				last_pattern = current_pattern
				current_pattern = Pattern.NONE
				_enter_decide()
	z_index = int(GameConfig.LANES[lane_index])+2


func choose_pattern() -> Pattern:
	if not is_instance_valid(target):
		return Pattern.NONE
	var distance: float = absf(target.global_position.x-global_position.x)
	var same_lane: bool = int(target.lane_index) == lane_index
	if same_lane and distance <= chain_range and _chain_cooldown_remaining <= 0.0 and last_pattern != Pattern.CHAIN:
		return Pattern.CHAIN
	var can_summon: bool = get_live_summon_count() < max_live_summons and _summon_cooldown_remaining <= 0.0
	if distance <= 430.0 and can_summon and last_pattern != Pattern.SUMMON_AGENTS:
		return Pattern.SUMMON_AGENTS
	if _coffee_cooldown_remaining <= 0.0:
		return Pattern.TRIPLE_COFFEE
	if can_summon:
		return Pattern.SUMMON_AGENTS
	return Pattern.NONE


func begin_pattern(pattern: Pattern) -> bool:
	if not active or boss_state != BossState.DECIDE or pattern == Pattern.NONE or not is_instance_valid(target):
		return false
	var distance := absf(target.global_position.x-global_position.x)
	if pattern == Pattern.CHAIN and (target.lane_index != lane_index or distance > chain_range or _chain_cooldown_remaining > 0.0):
		return false
	if pattern == Pattern.SUMMON_AGENTS and (get_live_summon_count() >= max_live_summons or _summon_cooldown_remaining > 0.0):
		return false
	if pattern == Pattern.TRIPLE_COFFEE and _coffee_cooldown_remaining > 0.0:
		return false
	current_pattern = pattern
	_locked_facing = facing
	_locked_target_position = target.global_position+Vector2(0.0,-42.0)
	boss_state = BossState.TELEGRAPH
	_state_remaining = get_telegraph_duration(pattern)
	_state_duration = _state_remaining
	velocity = Vector2.ZERO
	_coffee_shots_this_attack = 0
	_summon_emitted = false
	match pattern:
		Pattern.TRIPLE_COFFEE:
			_coffee_cooldown_remaining = coffee_cooldown
			visual.play(&"boss_cofee")
		Pattern.SUMMON_AGENTS:
			_summon_cooldown_remaining = summon_cooldown
			visual.play(&"boss_joke")
		Pattern.CHAIN:
			_chain_cooldown_remaining = chain_cooldown
			visual.play(&"boss_punch")
	_play_effect("alerta")
	pattern_started.emit(pattern)
	return true


func get_telegraph_duration(pattern: Pattern) -> float:
	match pattern:
		Pattern.TRIPLE_COFFEE:
			return coffee_telegraph
		Pattern.SUMMON_AGENTS:
			return summon_telegraph
		Pattern.CHAIN:
			return chain_definition.startup_duration
	return 0.0


func get_recovery_duration(pattern: Pattern) -> float:
	match pattern:
		Pattern.TRIPLE_COFFEE:
			return coffee_recovery
		Pattern.SUMMON_AGENTS:
			return summon_recovery
		Pattern.CHAIN:
			return chain_definition.recovery_duration
	return 0.0


func register_summon(summon: Node) -> void:
	if is_instance_valid(summon):
		_summons.append(weakref(summon))


func get_live_summon_count() -> int:
	for index in range(_summons.size()-1,-1,-1):
		var summon: Node = _summons[index].get_ref() as Node
		if summon == null or not is_instance_valid(summon) or not summon.is_inside_tree():
			_summons.remove_at(index)
	return _summons.size()


func take_damage(amount: int, source_team: StringName = &"player") -> void:
	if active and source_team != team:
		health_component.take_damage(amount,source_team)


func _process_telegraph(delta: float) -> void:
	_tick_state(delta)
	velocity.x = 0.0
	_apply_gravity_and_move(delta)
	if _state_remaining <= 0.0:
		_start_attack()


func _start_attack() -> void:
	boss_state = BossState.ATTACK
	match current_pattern:
		Pattern.TRIPLE_COFFEE:
			_state_remaining = coffee_shot_interval*2.0+0.02
			_coffee_interval_remaining = 0.0
			_emit_next_coffee()
		Pattern.SUMMON_AGENTS:
			_state_remaining = 0.05
			_emit_summons_once()
		Pattern.CHAIN:
			_state_remaining = chain_definition.active_duration
			chain_hitbox.configure(self,team,lane_index,chain_definition,_locked_facing,GameConfig.PLAYER_LAYER)
			chain_hitbox.activate(chain_definition.active_duration)
			chain_activations += 1
			_play_effect("golpe")


func _process_attack(delta: float) -> void:
	_tick_state(delta)
	velocity.x = 0.0
	_apply_gravity_and_move(delta)
	if current_pattern == Pattern.TRIPLE_COFFEE and _coffee_shots_this_attack < 3:
		_coffee_interval_remaining -= delta
		while _coffee_interval_remaining <= 0.0 and _coffee_shots_this_attack < 3:
			_emit_next_coffee()
	if _state_remaining <= 0.0:
		chain_hitbox.deactivate()
		boss_state = BossState.RECOVERY
		_state_remaining = get_recovery_duration(current_pattern)
		_state_duration = _state_remaining


func _emit_next_coffee() -> void:
	if _coffee_shots_this_attack >= 3:
		return
	var origin: Vector2 = global_position+Vector2(_locked_facing*34.0,-62.0)
	var base_direction: Vector2 = (_locked_target_position-origin).normalized()
	var spread: float = float([-coffee_spread_degrees,0.0,coffee_spread_degrees][_coffee_shots_this_attack])
	var shot_direction: Vector2 = base_direction.rotated(deg_to_rad(spread)).normalized()
	aimed_shot_requested.emit(origin,lane_index,shot_direction,"coffee",String(team))
	_coffee_shots_this_attack += 1
	coffee_projectiles_emitted += 1
	_coffee_interval_remaining += coffee_shot_interval


func _emit_summons_once() -> void:
	if _summon_emitted:
		return
	_summon_emitted = true
	var available := maxi(0,max_live_summons-get_live_summon_count())
	var requested := mini(2,available)
	if requested > 0:
		summon_requests_emitted += 1
		summon_requested.emit(requested,lane_index)


func _enter_decide() -> void:
	boss_state = BossState.DECIDE
	_state_remaining = decision_delay
	_state_duration = decision_delay
	velocity = Vector2.ZERO
	visual.play(&"boss_run")


func _align_lane(delta: float) -> bool:
	if target.lane_index == lane_index:
		return false
	collision_mask = 0
	position.y = move_toward(position.y,GameConfig.LANES[target.lane_index],lane_move_speed*delta)
	if absf(position.y-GameConfig.LANES[target.lane_index]) <= 0.1:
		lane_index = target.lane_index
		position.y = GameConfig.LANES[lane_index]
		hurtbox.lane_index = lane_index
		chain_hitbox.lane_index = lane_index
		collision_mask = 1 << lane_index
	return true


func _apply_gravity_and_move(delta: float) -> void:
	velocity.y += GameConfig.GRAVITY*delta
	move_and_slide()
	position.x = clampf(position.x,arena_bounds.x,arena_bounds.y)


func _tick_state(delta: float) -> void:
	_state_remaining = maxf(0.0,_state_remaining-delta)


func _tick_cooldowns(delta: float) -> void:
	_coffee_cooldown_remaining = maxf(0.0,_coffee_cooldown_remaining-delta)
	_summon_cooldown_remaining = maxf(0.0,_summon_cooldown_remaining-delta)
	_chain_cooldown_remaining = maxf(0.0,_chain_cooldown_remaining-delta)


func _update_facing() -> void:
	if not is_instance_valid(target) or boss_state in [BossState.TELEGRAPH,BossState.ATTACK]:
		return
	facing = -1 if target.global_position.x < global_position.x else 1
	visual.flip_h = facing > 0


func _update_feedback() -> void:
	if health_component.is_invulnerable():
		visual.modulate = Color(1.0,0.35,0.35)
	elif boss_state == BossState.TELEGRAPH:
		visual.modulate = Color(1.0,0.75,0.25)
	else:
		visual.modulate = Color.WHITE


func _play_effect(effect_id: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_effect"):
		audio_manager.play_effect(effect_id)


func _on_health_damaged(_amount: int, _current_health: int, _source) -> void:
	_play_effect("golpe")


func _on_health_depleted() -> void:
	if _defeat_emitted:
		return
	_defeat_emitted = true
	active = false
	boss_state = BossState.DEFEATED
	current_pattern = Pattern.NONE
	velocity = Vector2.ZERO
	chain_hitbox.deactivate()
	hurtbox.set_receiving_enabled(false)
	collision_layer = 0
	remove_from_group("enemies")
	screen_shake_requested.emit(7.0,0.30)
	defeated.emit(reward_points)
	var tween := create_tween()
	tween.tween_property(visual,"modulate:a",0.0,0.55)
	tween.tween_callback(queue_free)
