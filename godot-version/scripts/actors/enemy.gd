extends CharacterBody2D

signal shot_requested(origin: Vector2, lane: int, direction: int, kind: String, team: String)
signal ground_wave_requested(origin: Vector2, lane: int, direction: int)
signal defeated(points: int)
signal boss_escaped

const ENEMY_DEFINITION = preload("res://scripts/data/enemy_definition.gd")
const HEALTH_COMPONENT = preload("res://scripts/components/health_component.gd")
const HITBOX = preload("res://scripts/components/hitbox.gd")
const HURTBOX = preload("res://scripts/components/hurtbox.gd")
const ANIMATION_OFFSET_PROFILE = preload("res://scripts/components/animation_offset_profile.gd")
const DEFINITIONS: Dictionary = {
	&"hipster": preload("res://data/enemies/hipster.tres"),
	&"agente": preload("res://data/enemies/agente.tres"),
	&"grandote": preload("res://data/enemies/grandote.tres"),
	&"boss": preload("res://data/enemies/boss.tres")
}

enum AIState { CHASE, TELEGRAPH, ATTACK, RECOVERY, DISABLED, ENTER, REACT, REPOSITION }
enum AttackKind { NONE, PRIMARY, GROUND_SLAM }

const GRANDOTE_SLAM_ANIMATION: StringName = &"grandote_ground_slam"
const GRANDOTE_SLAM_DEFINITION = preload("res://data/attacks/grandote_ground_wave.tres")
const GRANDOTE_SLAM_MIN_RANGE := 125.0
const GRANDOTE_SLAM_MAX_RANGE := 360.0
const GRANDOTE_SLAM_COOLDOWN := 2.20
const GRANDOTE_WAVE_OFFSET := Vector2(40.6,-4.0)
const AGENT_BURST_SHOT_COUNT := 1
const AGENT_BURST_INTERVAL := 0.13
const HIPSTER_BURST_INTERVAL := 0.85
const AGENT_MUZZLE_OFFSET := Vector2(22.0,-58.0)

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
var _visual_offset_profiles: Dictionary = {}
var _burst_shots_remaining: int = 0
var _burst_interval_remaining: float = 0.0
var _super_stagger_remaining := 0.0
var _super_knockback_speed := 0.0
var _entry_remaining := 0.0
var _first_reaction_stagger := 0.0
var _observed_player_lives := 0
var _waiting_respawn_read := false

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
	lane_index = 0
	collision_mask = GameConfig.WORLD_LAYER
	floor_snap_length = 6.0
	visual.sprite_frames = definition.sprite_frames
	visual.scale = Vector2.ONE*definition.visual_scale
	visual.position = definition.visual_offset
	_visual_offset_profiles = ANIMATION_OFFSET_PROFILE.load_character(definition.enemy_id,_animation_manifest_mapping())
	visual.frame_changed.connect(_refresh_visual_frame_offset)
	visual.animation_changed.connect(_refresh_visual_frame_offset)
	visual.play(definition.run_animation)
	_refresh_visual_frame_offset()
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
	if uses_ranged_lifecycle():
		var order := 0
		for sibling in get_parent().get_children():
			if sibling == self:
				break
			if sibling.has_method("uses_ranged_lifecycle") and sibling.uses_ranged_lifecycle():
				order += 1
		_first_reaction_stagger = (order%6)*definition.first_action_stagger
		_observed_player_lives = target.lives if is_instance_valid(target) else 0
		_waiting_respawn_read = is_instance_valid(target) and target.invulnerability > 0.0 and target.hit_time <= 0.0
		attack_cooldown = 0.0 # ENTER + REACT replace the former spawn cooldown.
		_reset_ranged_entry()


func uses_ranged_lifecycle() -> bool:
	return definition != null and definition.attack_mode == ENEMY_DEFINITION.AttackMode.PROJECTILE and definition.entry_duration > 0.0


func _reset_ranged_entry() -> void:
	ai_state = AIState.ENTER
	_entry_remaining = definition.entry_duration
	_state_remaining = 0.0
	visual.play(definition.run_animation)


func _ranged_entry_visible() -> bool:
	if has_meta("attack_coordinator"):
		return _attack_is_visible()
	var camera := get_viewport().get_camera_2d()
	var center_x: float = camera.get_screen_center_position().x if camera else target.global_position.x
	return absf(global_position.x-center_x) <= get_viewport_rect().size.x*0.5-24.0


func _reposition_velocity(distance: float) -> float:
	var gap := absf(distance)-definition.preferred_distance
	if absf(gap) <= definition.distance_tolerance:
		return 0.0
	var direction := facing if gap > 0.0 else -facing
	if (position.x <= 40.0 and direction < 0) or (position.x >= GameConfig.WORLD_WIDTH-40.0 and direction > 0):
		return 0.0
	return direction*definition.move_speed


func _advance_ranged_lifecycle(delta: float,distance: float) -> void:
	velocity.x = 0.0
	if not target.controls_enabled or (_waiting_respawn_read and target.invulnerability > 0.0):
		return
	_waiting_respawn_read = false
	if ai_state == AIState.ENTER:
		velocity.x = facing*definition.move_speed
		if not _ranged_entry_visible():
			return # Reading begins inside the useful viewport, never at offscreen spawn.
		_entry_remaining = maxf(0.0,_entry_remaining-delta)
		if _entry_remaining <= 0.0:
			ai_state = AIState.REACT
			_state_remaining = definition.reaction_time+_first_reaction_stagger
			_first_reaction_stagger = 0.0
	elif ai_state == AIState.REACT:
		if not _ranged_entry_visible():
			_reset_ranged_entry()
			return
		_state_remaining = maxf(0.0,_state_remaining-delta)
		if _state_remaining <= 0.0 and absf(distance) < definition.attack_range and attack_cooldown <= 0.0:
			_begin_attack()
		elif absf(distance) >= definition.attack_range:
			velocity.x = _reposition_velocity(distance)
	elif ai_state == AIState.REPOSITION:
		velocity.x = _reposition_velocity(distance)
		_state_remaining = maxf(0.0,_state_remaining-delta)
		if _state_remaining <= 0.0:
			ai_state = AIState.REACT
			_state_remaining = definition.reaction_time


func _animation_manifest_mapping() -> Dictionary:
	match definition.enemy_id:
		&"agente":
			return {definition.run_animation:"Run",definition.attack_animation:"Shoot"}
		&"hipster":
			return {definition.run_animation:"Ride",definition.attack_animation:"Shoot Coffee"}
		&"grandote":
			return {&"grandote_idle":"Idle",definition.run_animation:"Run",definition.attack_animation:"Punch",GRANDOTE_SLAM_ANIMATION:"Ground Slam"}
	return {}


func _refresh_visual_frame_offset() -> void:
	ANIMATION_OFFSET_PROFILE.apply(visual,_visual_offset_profiles)


func _physics_process(delta: float) -> void:
	if escaping:
		_process_escape(delta)
		return
	if not active or not is_instance_valid(target) or target.state == target.State.DEATH:
		return
	if uses_ranged_lifecycle():
		if target.lives < _observed_player_lives:
			cancel_offscreen_attack()
			_waiting_respawn_read = true
			_reset_ranged_entry()
		_observed_player_lives = target.lives
	if _super_stagger_remaining > 0.0:
		_super_stagger_remaining = maxf(0.0,_super_stagger_remaining-delta)
		velocity = Vector2(_super_knockback_speed,velocity.y+GameConfig.GRAVITY*delta)
		visual.modulate = Color(1,0.35,0.35)
		move_and_slide()
		return
	attack_cooldown = maxf(0.0,attack_cooldown-delta)
	ground_slam_cooldown = maxf(0.0,ground_slam_cooldown-delta)
	visual.modulate = Color(1,0.35,0.35) if invulnerability > 0.0 else Color.WHITE
	var distance: float = target.position.x-position.x
	facing = -1 if distance < 0.0 else 1
	visual.flip_h = facing > 0
	z_index = 14
	velocity.y += GameConfig.GRAVITY*delta
	# Spaced arrivals approach on the continuous entrance floor before normal AI.
	# In particular, Grandote must not idle outside its normal detection range.
	var entering: bool = get_meta("wave_entry", false) and not _attack_is_visible()
	if entering:
		velocity.x = facing * definition.move_speed
	elif uses_ranged_lifecycle() and ai_state in [AIState.ENTER,AIState.REACT,AIState.REPOSITION]:
		remove_meta("wave_entry")
		_advance_ranged_lifecycle(delta,distance)
	elif ai_state == AIState.CHASE:
		remove_meta("wave_entry")
		_update_chase(distance)
	else:
		velocity.x = 0.0
		_advance_attack_state(delta)
	move_and_slide()
	_process_contact_damage()


func _update_chase(distance: float) -> void:
	var distance_abs := absf(distance)
	velocity.x = facing*definition.move_speed if distance_abs <= definition.detection_range and distance_abs > definition.preferred_distance else 0.0
	if attack_cooldown <= 0.0 and distance_abs < definition.attack_range:
		_begin_attack()
	elif definition.enemy_id == &"grandote" and ground_slam_cooldown <= 0.0 \
			and distance_abs >= GRANDOTE_SLAM_MIN_RANGE and distance_abs <= GRANDOTE_SLAM_MAX_RANGE:
		_begin_ground_slam()


func _begin_attack() -> void:
	var ready_to_prepare := ai_state == AIState.REACT and _state_remaining <= 0.0 and attack_cooldown <= 0.0 if uses_ranged_lifecycle() else ai_state == AIState.CHASE
	if not ready_to_prepare or not active or not _attack_is_visible():
		return
	if definition.attack_mode == ENEMY_DEFINITION.AttackMode.PROJECTILE and has_meta("attack_coordinator") and not get_meta("attack_coordinator").request_attack(self):
		return
	ai_state = AIState.TELEGRAPH
	_state_remaining = definition.telegraph_duration
	attack_windup = _state_remaining
	attack_visual = definition.telegraph_duration + definition.get_active_duration() + definition.recovery_duration
	attack_cooldown = definition.attack_cooldown
	_attack_executed = false
	_burst_shots_remaining = 0
	_burst_interval_remaining = 0.0
	active_attack_kind = AttackKind.PRIMARY
	_locked_attack_direction = facing
	velocity.x = 0.0
	visual.play(definition.attack_animation)


func _begin_ground_slam() -> bool:
	if definition.enemy_id != &"grandote" or ai_state != AIState.CHASE or not active or ground_slam_cooldown > 0.0 or not _attack_is_visible():
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
	if not _attack_is_visible() or (uses_ranged_lifecycle() and not _ranged_entry_visible()):
		cancel_offscreen_attack()
		return
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
	elif ai_state == AIState.ATTACK:
		_advance_projectile_burst(delta)
		if _state_remaining <= 0.0:
			_burst_shots_remaining = 0
			melee_hitbox.deactivate()
			ai_state = AIState.RECOVERY
			_state_remaining = definition.recovery_duration
	elif ai_state == AIState.RECOVERY and _state_remaining <= 0.0:
		_release_attack_token()
		if definition.enemy_id == &"hipster":
			# Hipster cooldown starts after the complete two-cup attack/recovery.
			attack_cooldown = definition.attack_cooldown
		ai_state = AIState.REPOSITION if uses_ranged_lifecycle() else AIState.CHASE
		if uses_ranged_lifecycle():
			_state_remaining = definition.reposition_duration
		active_attack_kind = AttackKind.NONE
		attack_visual = 0.0
		visual.play(definition.run_animation)


func _advance_ground_slam(delta: float) -> void:
	_state_remaining = maxf(_state_remaining-delta,0.0)
	attack_visual = maxf(attack_visual-delta,0.0)
	if ai_state == AIState.TELEGRAPH:
		attack_windup = _state_remaining
		var telegraph_progress := 1.0-_state_remaining/GRANDOTE_SLAM_DEFINITION.startup_duration
		_set_ground_slam_frame(clampi(int(floor(telegraph_progress*9.0)),0,8))
		if _state_remaining <= 0.0:
			ai_state = AIState.ATTACK
			_state_remaining = GRANDOTE_SLAM_DEFINITION.active_duration
			attack_windup = 0.0
			_set_ground_slam_frame(9)
	elif ai_state == AIState.ATTACK and _state_remaining <= 0.0:
		ai_state = AIState.RECOVERY
		_state_remaining = GRANDOTE_SLAM_DEFINITION.recovery_duration
		_set_ground_slam_frame(10)
		_emit_ground_wave()
	elif ai_state == AIState.RECOVERY:
		var recovery_progress := 1.0-_state_remaining/GRANDOTE_SLAM_DEFINITION.recovery_duration
		_set_ground_slam_frame(clampi(10+int(floor(recovery_progress*3.0)),10,12))
		if _state_remaining <= 0.0:
			_release_attack_token()
			ai_state = AIState.CHASE
			active_attack_kind = AttackKind.NONE
			attack_visual = 0.0
			visual.position = _ground_slam_base_visual_position
			visual.play(definition.run_animation)


func _set_ground_slam_frame(frame_index: int) -> void:
	visual.frame = clampi(frame_index,0,visual.sprite_frames.get_frame_count(GRANDOTE_SLAM_ANIMATION)-1)


func _emit_ground_wave() -> void:
	if _attack_executed or not active or not _can_emit_ground_shot():
		return
	_attack_executed = true
	ground_waves_emitted += 1
	var origin := global_position+Vector2(GRANDOTE_WAVE_OFFSET.x*_locked_attack_direction,GRANDOTE_WAVE_OFFSET.y)
	ground_wave_requested.emit(origin,lane_index,_locked_attack_direction)
	AudioManager.play_effect("golpe")


func execute_attack() -> void:
	if uses_ranged_lifecycle() and ai_state != AIState.ATTACK:
		return
	if _attack_executed or not active or not is_instance_valid(target) or not _attack_is_visible():
		return
	if definition.attack_mode == ENEMY_DEFINITION.AttackMode.PROJECTILE and has_meta("attack_coordinator") and not get_meta("attack_coordinator").request_attack(self):
		return
	_attack_executed = true
	if definition.attack_mode == ENEMY_DEFINITION.AttackMode.MELEE:
		melee_hitbox.configure(self,team,lane_index,definition.melee_attack,facing,GameConfig.PLAYER_LAYER)
		melee_hitbox.activate(definition.get_active_duration())
	else:
		_emit_projectile_shot()
		if definition.enemy_id == &"agente":
			_burst_shots_remaining = AGENT_BURST_SHOT_COUNT-1
			_burst_interval_remaining = AGENT_BURST_INTERVAL
		elif definition.enemy_id == &"hipster":
			_burst_shots_remaining = 1
			_burst_interval_remaining = HIPSTER_BURST_INTERVAL


func _advance_projectile_burst(delta: float) -> void:
	if definition.attack_mode != ENEMY_DEFINITION.AttackMode.PROJECTILE \
			or definition.enemy_id not in [&"agente",&"hipster"] or _burst_shots_remaining <= 0:
		return
	_burst_interval_remaining -= delta
	while _burst_shots_remaining > 0 and _burst_interval_remaining <= 0.0:
		_emit_projectile_shot()
		_burst_shots_remaining -= 1
		_burst_interval_remaining += HIPSTER_BURST_INTERVAL if definition.enemy_id == &"hipster" else AGENT_BURST_INTERVAL


func _emit_projectile_shot() -> void:
	if uses_ranged_lifecycle() and (ai_state != AIState.ATTACK or not _ranged_entry_visible() or not target.controls_enabled):
		return
	if not _can_emit_ground_shot():
		return
	var shot_facing := _locked_attack_direction if definition.enemy_id == &"hipster" else facing
	var muzzle_offset := Vector2(shot_facing*24.0,-42.0)
	if definition.enemy_id == &"agente":
		muzzle_offset = Vector2(shot_facing*AGENT_MUZZLE_OFFSET.x,AGENT_MUZZLE_OFFSET.y)
	shot_requested.emit(
		global_position+muzzle_offset,
		lane_index,
		shot_facing,
		String(definition.projectile_definition.projectile_id),
		String(team)
	)

func _attack_is_visible() -> bool:
	# Encounter actors only: Palermitano and its summons retain their own contract.
	return not has_meta("attack_coordinator") or get_meta("attack_coordinator").is_attack_visible(self)

func _can_emit_ground_shot() -> bool:
	return not has_meta("attack_coordinator") or get_meta("attack_coordinator").can_emit_ground_shot(self)

func cancel_offscreen_attack() -> void:
	_release_attack_token()
	if uses_ranged_lifecycle() and ai_state in [AIState.ENTER,AIState.REACT,AIState.REPOSITION]:
		if not _ranged_entry_visible():
			_reset_ranged_entry()
		return
	if ai_state in [AIState.CHASE,AIState.DISABLED]:
		return
	_burst_shots_remaining = 0
	_burst_interval_remaining = 0.0
	_attack_executed = true
	_state_remaining = 0.0
	attack_windup = 0.0
	attack_visual = 0.0
	melee_hitbox.deactivate()
	active_attack_kind = AttackKind.NONE
	ai_state = AIState.CHASE
	attack_cooldown = definition.attack_cooldown
	visual.play(definition.run_animation)
	if uses_ranged_lifecycle():
		_reset_ranged_entry()


func _update_lane(delta: float) -> bool:
	return false


func _process_contact_damage() -> void:
	if target.special_active and target.special_phase == target.SpecialPhase.RUSH:
		return
	for body in contact.get_overlapping_bodies():
		if body == target:
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


# Short, collision-respecting displacement; normal AI resumes afterwards.
func receive_super_knockback(horizontal_speed: float,duration: float) -> void:
	if not active:
		return
	cancel_offscreen_attack()
	_super_stagger_remaining = duration
	_super_knockback_speed = horizontal_speed * (0.45 if definition.enemy_id == &"grandote" else 1.0)


func _on_health_damaged(_amount: int,_current_health: int,_source) -> void:
	AudioManager.play_effect("golpe")

func _release_attack_token() -> void:
	if has_meta("attack_coordinator") and is_instance_valid(get_meta("attack_coordinator")):
		get_meta("attack_coordinator").release_attack(self)

func _exit_tree() -> void:
	_release_attack_token()


func _on_health_depleted() -> void:
	_release_attack_token()
	active = false
	ai_state = AIState.DISABLED
	active_attack_kind = AttackKind.NONE
	_burst_shots_remaining = 0
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
