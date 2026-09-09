class_name Drone
extends Node2D

signal shot_requested(origin: Vector2, lane: int, direction: Vector2, kind: String, team: String)
signal defeated(points: int)

const ENEMY_DEFINITION = preload("res://scripts/data/enemy_definition.gd")
const HEALTH_COMPONENT = preload("res://scripts/components/health_component.gd")
const HURTBOX = preload("res://scripts/components/hurtbox.gd")
const DEFAULT_DEFINITION: ENEMY_DEFINITION = preload("res://data/enemies/drone.tres")

enum AIState { ENTRY, IDLE, AIM, FIRE, COOLDOWN, DEAD }

@export var enemy_definition: ENEMY_DEFINITION = DEFAULT_DEFINITION
@export var flight_height: float = 145.0
@export var bob_amplitude: float = 5.0
@export var bob_speed: float = 2.2
@export_range(0.0,5.0,0.01) var aim_tracking_duration: float = 0.70

var team: StringName = &"enemy"
var archetype: String = "drone"
var lane_index: int = 0
var target: CharacterBody2D
var definition: ENEMY_DEFINITION
var ai_state: AIState = AIState.ENTRY
var active: bool = true
var uses_gravity: bool = false
var flight_anchor_y: float = 0.0
var patrol_center_x: float = 0.0
var cooldown_remaining: float = 0.0
var state_remaining: float = 0.0
var aim_elapsed: float = 0.0
var locked_target_position: Vector2 = Vector2.ZERO
var aim_target_locked: bool = false
var shots_emitted: int = 0
var _shot_emitted_this_attack: bool = false
var _elapsed: float = 0.0
var _defeat_emitted: bool = false

@onready var health_component: HEALTH_COMPONENT = $HealthComponent
@onready var hurtbox: HURTBOX = $Hurtbox
@onready var visual: AnimatedSprite2D = $Visual
@onready var aim_reticle: Node2D = $AimReticle

var health: int:
	get:
		return health_component.current_health
	set(value):
		health_component.set_current_health(value)

var max_health: int:
	get:
		return health_component.max_health


func _ready() -> void:
	definition = enemy_definition
	if definition == null or not definition.is_valid() or not definition.sprite_frames.has_animation(&"fire"):
		push_error("Drone requires its valid aerial EnemyDefinition and idle/aim/fire visuals")
		active = false
		ai_state = AIState.DEAD
		set_physics_process(false)
		return
	health_component.configure(definition.max_health,definition.max_health,0.12)
	health_component.damaged.connect(_on_health_damaged)
	health_component.depleted.connect(_on_health_depleted)
	visual.sprite_frames = definition.sprite_frames
	visual.scale = Vector2.ONE*definition.visual_scale
	visual.position = definition.visual_offset
	visual.play(definition.run_animation)
	flight_anchor_y = position.y
	patrol_center_x = position.x
	hurtbox.configure(self,health_component,team,lane_index,GameConfig.ENEMY_LAYER)
	var texture := visual.sprite_frames.get_frame_texture(definition.run_animation,0)
	var bounds := CollisionFactory.opaque_bounds(texture)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(bounds.size.x*definition.visual_scale*definition.collision_width_ratio,bounds.size.y*definition.visual_scale*0.72)
	hurtbox.collision_shape.shape = shape
	hurtbox.collision_shape.position = (bounds.get_center()-texture.get_size()*0.5)*definition.visual_scale
	aim_reticle.clear()
	add_to_group("enemies")
	add_to_group("aerial_enemy")
	z_index = int(GameConfig.LANES[lane_index])+35


func _physics_process(delta: float) -> void:
	if not active:
		return
	_elapsed += delta
	position.y = flight_anchor_y+sin(_elapsed*bob_speed)*bob_amplitude
	if not is_instance_valid(target) or target.state == target.State.DEATH:
		aim_reticle.clear()
		ai_state = AIState.IDLE
		visual.play(definition.run_animation)
		return
	match ai_state:
		AIState.ENTRY:
			_process_entry(delta)
		AIState.IDLE:
			_process_idle(delta)
		AIState.AIM:
			_process_aim(delta)
		AIState.FIRE:
			_process_fire(delta)
		AIState.COOLDOWN:
			_process_cooldown(delta)


func _process_entry(delta: float) -> void:
	var side := -1.0 if position.x > target.position.x else 1.0
	var destination_x := target.position.x-side*definition.preferred_distance
	position.x = move_toward(position.x,destination_x,definition.move_speed*delta)
	visual.flip_h = target.position.x > position.x
	if absf(position.x-destination_x) <= 1.0:
		patrol_center_x = position.x
		ai_state = AIState.IDLE
		cooldown_remaining = 0.35


func _process_idle(delta: float) -> void:
	cooldown_remaining = maxf(0.0,cooldown_remaining-delta)
	var patrol_target := patrol_center_x+sin(_elapsed*0.7)*45.0
	position.x = move_toward(position.x,patrol_target,definition.move_speed*0.35*delta)
	visual.flip_h = target.position.x > position.x
	if cooldown_remaining <= 0.0 and global_position.distance_to(target.global_position) <= definition.detection_range:
		_begin_aim()


func _begin_aim() -> bool:
	if not active or not is_instance_valid(target) or ai_state == AIState.DEAD:
		return false
	ai_state = AIState.AIM
	state_remaining = definition.telegraph_duration
	aim_elapsed = 0.0
	aim_target_locked = false
	locked_target_position = _target_point()
	_shot_emitted_this_attack = false
	visual.play(definition.attack_animation)
	aim_reticle.show_target(_target_point())
	return true


func _process_aim(delta: float) -> void:
	if ai_state != AIState.AIM:
		return
	aim_elapsed = minf(definition.telegraph_duration,aim_elapsed+delta)
	state_remaining = maxf(0.0,definition.telegraph_duration-aim_elapsed)
	var tracking_duration := minf(aim_tracking_duration,definition.telegraph_duration)
	if not aim_target_locked:
		locked_target_position = _target_point()
		if aim_elapsed >= tracking_duration:
			aim_target_locked = true
	aim_reticle.update_charge(aim_elapsed/definition.telegraph_duration,locked_target_position)
	if state_remaining <= 0.0:
		aim_reticle.clear()
		ai_state = AIState.FIRE
		state_remaining = definition.projectile_release_duration
		visual.play(&"fire")
		_emit_locked_shot()


func _process_fire(delta: float) -> void:
	state_remaining = maxf(0.0,state_remaining-delta)
	if state_remaining <= 0.0:
		ai_state = AIState.COOLDOWN
		cooldown_remaining = definition.attack_cooldown
		visual.play(definition.run_animation)


func _process_cooldown(delta: float) -> void:
	cooldown_remaining = maxf(0.0,cooldown_remaining-delta)
	if cooldown_remaining <= 0.0:
		ai_state = AIState.IDLE


func _emit_locked_shot() -> void:
	if _shot_emitted_this_attack or not active:
		return
	_shot_emitted_this_attack = true
	var origin := global_position+Vector2(0.0,18.0)
	var shot_direction := origin.direction_to(locked_target_position)
	if shot_direction.is_zero_approx():
		shot_direction = Vector2.DOWN
	shots_emitted += 1
	shot_requested.emit(origin,lane_index,shot_direction,String(definition.projectile_definition.projectile_id),String(team))
	AudioManager.play_effect("alerta")


func _target_point() -> Vector2:
	return target.global_position+Vector2(0.0,-35.0)


func has_dangerous_aim_near(point: Vector2,radius: float) -> bool:
	return active and ai_state == AIState.AIM and locked_target_position.distance_to(point) <= radius


func cancel_dangerous_aim_near(point: Vector2,radius: float) -> bool:
	if not has_dangerous_aim_near(point,radius):
		return false
	aim_reticle.clear()
	aim_target_locked = false
	_shot_emitted_this_attack = false
	ai_state = AIState.COOLDOWN
	state_remaining = 0.0
	cooldown_remaining = definition.attack_cooldown
	visual.play(definition.run_animation)
	return true


func take_damage(amount: int,source_team: StringName = &"player") -> void:
	if not active or source_team == team:
		return
	health_component.take_damage(amount,source_team)


func _on_health_damaged(_amount: int,_current_health: int,_source) -> void:
	visual.modulate = Color(1.0,0.35,0.35)
	var tween := create_tween()
	tween.tween_property(visual,"modulate",Color.WHITE,0.1)
	AudioManager.play_effect("golpe")


func _on_health_depleted() -> void:
	if _defeat_emitted:
		return
	_defeat_emitted = true
	active = false
	ai_state = AIState.DEAD
	aim_reticle.clear()
	hurtbox.set_receiving_enabled(false)
	remove_from_group("enemies")
	defeated.emit(definition.reward_points)
	var tween := create_tween()
	tween.tween_property(visual,"modulate:a",0.0,0.2)
	tween.tween_callback(queue_free)


func _exit_tree() -> void:
	aim_reticle.clear()
