extends CharacterBody2D

signal shot_requested(origin: Vector2, lane: int, direction: int, kind: String, team: String)
signal ground_wave_requested(origin: Vector2, lane: int, direction: int)
signal defeated(points: int)
signal boss_escaped

const ENEMY_DEFINITION = preload("res://scripts/data/enemy_definition.gd")
const HEALTH_COMPONENT = preload("res://scripts/components/health_component.gd")
const HITBOX = preload("res://scripts/components/hitbox.gd")
const HURTBOX = preload("res://scripts/components/hurtbox.gd")
const DEFINITIONS: Dictionary = {
	&"hipster": preload("res://data/enemies/hipster.tres"),
	&"agente": preload("res://data/enemies/agente.tres"),
	&"grandote": preload("res://data/enemies/grandote.tres"),
	&"boss": preload("res://data/enemies/boss.tres")
}

enum AIState { CHASE, TELEGRAPH, ATTACK, RECOVERY, DISABLED }
enum AttackKind { NONE, PRIMARY, GROUND_SLAM }

const GRANDOTE_SLAM_ANIMATION: StringName = &"grandote_ground_slam"
const GRANDOTE_SLAM_DEFINITION = preload("res://data/attacks/grandote_ground_wave.tres")
const GRANDOTE_SLAM_MIN_RANGE := 125.0
const GRANDOTE_SLAM_MAX_RANGE := 360.0
const GRANDOTE_SLAM_COOLDOWN := 2.20
const GRANDOTE_WAVE_OFFSET := Vector2(48.0,-4.0)
const GRANDOTE_SLAM_FRAME_OFFSETS := [Vector2(0,2),Vector2(0,8),Vector2(0,28)]

@export var enemy_definition: ENEMY_DEFINITION
var archetype: String = "hipster"
var team: StringName = &"enemy"
var lane_index: int = 0
var target: CharacterBody2D
var definition: ENEMY_DEFINITION
var ai_state: AIState = AIState.CHASE
var attack_cooldown: float = 1.0
var attack_windup: float = 0.0
var attack_visual: float = 0.0
var active: bool = true
var escaping: bool = false
var escape_time: float = 0.0
var facing: int = -1
var contact: Area2D
var _state_remaining: float = 0.0
var _attack_executed: bool = false
var active_attack_kind: AttackKind = AttackKind.NONE
var ground_slam_cooldown: float = 0.0
var ground_waves_emitted: int = 0
var _locked_attack_direction: int = 1
var _ground_slam_base_visual_position := Vector2.ZERO

@onready var health_component: HEALTH_COMPONENT = $HealthComponent
@onready var hurtbox: HURTBOX = $Hurtbox
@onready var melee_hitbox: HITBOX = $MeleeHitbox
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


static func resolve_definition(enemy_id: StringName) -> ENEMY_DEFINITION:
	return DEFINITIONS.get(enemy_id) as ENEMY_DEFINITION


func _ready() -> void:
	definition = enemy_definition
	if definition == null:
		definition = resolve_definition(StringName(archetype))
	if definition == null or not definition.is_valid():
		push_error("Enemy requires a valid EnemyDefinition for archetype '%s'" % archetype)
		active = false
		ai_state = AIState.DISABLED
		set_physics_process(false)
		return
	enemy_definition = definition
	archetype = String(definition.enemy_id)
	health_component.damaged.connect(_on_health_damaged)
	health_component.depleted.connect(_on_health_depleted)
	health_component.configure(definition.max_health,definition.max_health,0.18)
	collision_layer = GameConfig.ENEMY_LAYER
	collision_mask = 1 << lane_index
	floor_snap_length = 6.0
	visual.sprite_frames = definition.sprite_frames
	visual.scale = Vector2.ONE*definition.visual_scale
	visual.position = definition.visual_offset
	visual.play(definition.run_animation)
	var texture: Texture2D = visual.sprite_frames.get_frame_texture(definition.run_animation,0)
	var body_shape := CollisionFactory.add_shape(self,texture,definition.visual_scale,true,definition.collision_width_ratio)
	hurtbox.configure(self,health_component,team,lane_index,GameConfig.ENEMY_LAYER)
	hurtbox.copy_shape_from(body_shape)
	if definition.attack_mode == ENEMY_DEFINITION.AttackMode.MELEE:
		melee_hitbox.configure(self,team,lane_index,definition.melee_attack,facing,GameConfig.PLAYER_LAYER)
	else:
		melee_hitbox.deactivate()
	contact = Area2D.new()
	contact.name = "Contact"
	contact.collision_layer = 0
	contact.collision_mask = GameConfig.PLAYER_LAYER
	add_child(contact)
	CollisionFactory.add_shape(contact,texture,definition.visual_scale,true,definition.collision_width_ratio)
	add_to_group("enemies")
	if definition.enemy_id == &"grandote":
		add_to_group("elite_enemy")


func _physics_process(delta: float) -> void:
	if escaping:
		_process_escape(delta)
		return
	if not active or not is_instance_valid(target) or target.state == target.State.DEATH:
		return
	attack_cooldown = maxf(0.0,attack_cooldown-delta)
	ground_slam_cooldown = maxf(0.0,ground_slam_cooldown-delta)
	visual.modulate = Color(1,0.35,0.35) if invulnerability > 0.0 else Color.WHITE
	var distance: float = target.position.x-position.x
	facing = -1 if distance < 0.0 else 1
	visual.flip_h = facing > 0
	z_index = int(GameConfig.LANES[lane_index])
	if _update_lane(delta):
		return
	velocity.y += GameConfig.GRAVITY*delta
	if ai_state == AIState.CHASE:
		_update_chase(distance)
	else:
		velocity.x = 0.0
		_advance_attack_state(delta)
	move_and_slide()
	_process_contact_damage()


func _update_chase(distance: float) -> void:
	var distance_abs := absf(distance)
	velocity.x = facing*definition.move_speed if distance_abs <= definition.detection_range and distance_abs > definition.preferred_distance else 0.0
	if lane_index != target.lane_index:
		return
	if attack_cooldown <= 0.0 and distance_abs < definition.attack_range:
		_begin_attack()
	elif definition.enemy_id == &"grandote" and ground_slam_cooldown <= 0.0 \
			and distance_abs >= GRANDOTE_SLAM_MIN_RANGE and distance_abs <= GRANDOTE_SLAM_MAX_RANGE:
		_begin_ground_slam()


func _begin_attack() -> void:
	if ai_state != AIState.CHASE or not active:
		return
	ai_state = AIState.TELEGRAPH
	_state_remaining = definition.telegraph_duration
	attack_windup = _state_remaining
	attack_visual = definition.telegraph_duration + definition.get_active_duration() + definition.recovery_duration
	attack_cooldown = definition.attack_cooldown
	_attack_executed = false
	active_attack_kind = AttackKind.PRIMARY
	_locked_attack_direction = facing
	velocity.x = 0.0
	visual.play(definition.attack_animation)


func _begin_ground_slam() -> bool:
	if definition.enemy_id != &"grandote" or ai_state != AIState.CHASE or not active or ground_slam_cooldown > 0.0:
		return false
	ai_state = AIState.TELEGRAPH
	active_attack_kind = AttackKind.GROUND_SLAM
	_state_remaining = GRANDOTE_SLAM_DEFINITION.startup_duration
	attack_windup = _state_remaining
	attack_visual = GRANDOTE_SLAM_DEFINITION.get_total_duration()
	ground_slam_cooldown = GRANDOTE_SLAM_COOLDOWN
	_attack_executed = false
	_locked_attack_direction = facing
	velocity.x = 0.0
	_ground_slam_base_visual_position = visual.position
	visual.animation = GRANDOTE_SLAM_ANIMATION
	visual.pause()
	_set_ground_slam_frame(0)
	return true


func _advance_attack_state(delta: float) -> void:
	if active_attack_kind == AttackKind.GROUND_SLAM:
		_advance_ground_slam(delta)
		return
	_state_remaining = maxf(_state_remaining-delta,0.0)
	attack_visual = maxf(attack_visual-delta,0.0)
	if ai_state == AIState.TELEGRAPH:
		attack_windup = _state_remaining
		if _state_remaining <= 0.0:
			ai_state = AIState.ATTACK
			_state_remaining = definition.get_active_duration()
			attack_windup = 0.0
			execute_attack()
	elif ai_state == AIState.ATTACK and _state_remaining <= 0.0:
		melee_hitbox.deactivate()
		ai_state = AIState.RECOVERY
		_state_remaining = definition.recovery_duration
	elif ai_state == AIState.RECOVERY and _state_remaining <= 0.0:
		ai_state = AIState.CHASE
		active_attack_kind = AttackKind.NONE
		attack_visual = 0.0
		visual.play(definition.run_animation)


func _advance_ground_slam(delta: float) -> void:
	_state_remaining = maxf(_state_remaining-delta,0.0)
	attack_visual = maxf(attack_visual-delta,0.0)
	if ai_state == AIState.TELEGRAPH:
		attack_windup = _state_remaining
		if _state_remaining <= 0.0:
			ai_state = AIState.ATTACK
			_state_remaining = GRANDOTE_SLAM_DEFINITION.active_duration
			attack_windup = 0.0
			_set_ground_slam_frame(1)
	elif ai_state == AIState.ATTACK and _state_remaining <= 0.0:
		ai_state = AIState.RECOVERY
		_state_remaining = GRANDOTE_SLAM_DEFINITION.recovery_duration
		_set_ground_slam_frame(2)
		_emit_ground_wave()
	elif ai_state == AIState.RECOVERY and _state_remaining <= 0.0:
		ai_state = AIState.CHASE
		active_attack_kind = AttackKind.NONE
		attack_visual = 0.0
		visual.position = _ground_slam_base_visual_position
		visual.play(definition.run_animation)


func _set_ground_slam_frame(frame_index: int) -> void:
	visual.frame = frame_index
	visual.position = _ground_slam_base_visual_position+GRANDOTE_SLAM_FRAME_OFFSETS[frame_index]


func _emit_ground_wave() -> void:
	if _attack_executed or not active:
		return
	_attack_executed = true
	ground_waves_emitted += 1
	var origin := global_position+Vector2(GRANDOTE_WAVE_OFFSET.x*_locked_attack_direction,GRANDOTE_WAVE_OFFSET.y)
	ground_wave_requested.emit(origin,lane_index,_locked_attack_direction)
	AudioManager.play_effect("golpe")


func execute_attack() -> void:
	if _attack_executed or not active or not is_instance_valid(target):
		return
	_attack_executed = true
	if definition.attack_mode == ENEMY_DEFINITION.AttackMode.MELEE:
		melee_hitbox.configure(self,team,lane_index,definition.melee_attack,facing,GameConfig.PLAYER_LAYER)
		melee_hitbox.activate(definition.get_active_duration())
	else:
		shot_requested.emit(
			global_position+Vector2(facing*24.0,-42.0),
			lane_index,
			facing,
			String(definition.projectile_definition.projectile_id),
			String(team)
		)


func _update_lane(delta: float) -> bool:
	if not definition.can_change_lanes or target.lane_index == lane_index or ai_state != AIState.CHASE:
		return false
	collision_mask = 0
	position.y = move_toward(position.y,GameConfig.LANES[target.lane_index],225.0*delta)
	if absf(position.y-GameConfig.LANES[target.lane_index]) < 0.1:
		lane_index = target.lane_index
		hurtbox.lane_index = lane_index
		melee_hitbox.lane_index = lane_index
		collision_mask = 1 << lane_index
	velocity = Vector2.ZERO
	return true


func _process_contact_damage() -> void:
	for body in contact.get_overlapping_bodies():
		if body == target and target.lane_index == lane_index:
			if target.fury_time > 0.0:
				take_damage(definition.fury_contact_damage,&"player")
			else:
				target.take_damage(definition.contact_damage,team)


func _process_escape(delta: float) -> void:
	escape_time -= delta
	velocity = Vector2(definition.escape_speed,velocity.y+GameConfig.GRAVITY*delta)
	move_and_slide()
	if escape_time <= 0.0:
		boss_escaped.emit()
		queue_free()


func take_damage(amount: int, source_team: StringName = &"player") -> void:
	if not active or source_team == team:
		return
	health_component.take_damage(amount,source_team)


func _on_health_damaged(_amount: int,_current_health: int,_source) -> void:
	AudioManager.play_effect("golpe")


func _on_health_depleted() -> void:
	active = false
	ai_state = AIState.DISABLED
	active_attack_kind = AttackKind.NONE
	melee_hitbox.deactivate()
	collision_layer = 0
	hurtbox.set_receiving_enabled(false)
	contact.set_deferred("monitoring",false)
	remove_from_group("enemies")
	defeated.emit(definition.reward_points)
	if definition.escapes_when_depleted:
		escaping = true
		escape_time = definition.escape_duration
		visual.modulate = Color.WHITE
		visual.flip_h = true
		visual.play(definition.run_animation)
	else:
		velocity = Vector2.ZERO
		visual.stop()
		var tween := create_tween()
		tween.tween_property(visual,"modulate:a",0.0,0.25)
		tween.tween_callback(queue_free)
