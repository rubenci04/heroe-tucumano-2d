class_name EnemyDefinition
extends Resource

enum AttackMode { MELEE, PROJECTILE }

@export_group("Identity")
@export var enemy_id: StringName = &""
@export var display_name: String = ""
@export var attack_mode: AttackMode = AttackMode.MELEE

@export_group("Gameplay")
@export_range(1,999,1) var max_health: int = 1
@export_range(0.0,1000.0,1.0) var move_speed: float = 0.0
@export_range(0,99999,1) var reward_points: int = 0
@export_range(1.0,10000.0,1.0) var detection_range: float = 8000.0
@export_range(0.0,2000.0,1.0) var preferred_distance: float = 70.0
@export_range(1.0,2000.0,1.0) var attack_range: float = 100.0
@export_range(0.01,10.0,0.01) var telegraph_duration: float = 0.3
@export_range(0.01,10.0,0.01) var projectile_release_duration: float = 0.05
@export_range(0.01,10.0,0.01) var recovery_duration: float = 0.15
@export_range(0.01,30.0,0.01) var attack_cooldown: float = 1.0
@export_range(0,999,1) var contact_damage: int = 1
@export_range(0,999,1) var fury_contact_damage: int = 20
@export var melee_attack: AttackDefinition
@export var projectile_definition: ProjectileDefinition

@export_group("Visual")
@export var sprite_frames: SpriteFrames
@export var run_animation: StringName = &""
@export var attack_animation: StringName = &""
@export var visual_scale: float = 1.0
@export var visual_offset: Vector2 = Vector2.ZERO
@export_range(0.1,1.0,0.01) var collision_width_ratio: float = 0.65

@export_group("Legacy level compatibility")
@export var can_change_lanes: bool = false
@export var escapes_when_depleted: bool = false
@export_range(0.01,10.0,0.01) var escape_duration: float = 2.4
@export_range(0.0,1000.0,1.0) var escape_speed: float = 330.0


func is_valid() -> bool:
	return get_validation_errors().is_empty()


func get_active_duration() -> float:
	if attack_mode == AttackMode.MELEE and melee_attack != null:
		return melee_attack.active_duration
	return projectile_release_duration


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if enemy_id.is_empty():
		errors.append("enemy_id must not be empty")
	if display_name.is_empty():
		errors.append("display_name must not be empty")
	if max_health <= 0:
		errors.append("max_health must be greater than zero")
	if detection_range < attack_range:
		errors.append("detection_range must cover attack_range")
	if attack_range < preferred_distance:
		errors.append("attack_range must cover preferred_distance")
	if sprite_frames == null:
		errors.append("sprite_frames must be assigned")
	else:
		if not sprite_frames.has_animation(run_animation):
			errors.append("sprite_frames must contain run_animation")
		if not sprite_frames.has_animation(attack_animation):
			errors.append("sprite_frames must contain attack_animation")
	if visual_scale <= 0.0:
		errors.append("visual_scale must be greater than zero")
	if attack_mode == AttackMode.MELEE:
		if melee_attack == null or not melee_attack.is_valid():
			errors.append("melee enemies require a valid AttackDefinition")
	elif projectile_definition == null or not projectile_definition.is_valid():
		errors.append("ranged enemies require a valid ProjectileDefinition")
	return errors
