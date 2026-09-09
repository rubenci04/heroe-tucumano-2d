class_name ProjectileDefinition
extends Resource

@export_group("Identity")
@export var projectile_id: StringName = &""
@export var default_team: StringName = &"neutral"

@export_group("Gameplay")
@export_range(1,999,1) var damage: int = 1
@export_range(1.0,2000.0,1.0) var speed: float = 100.0
@export_range(0.01,30.0,0.01) var lifetime: float = 3.0

@export_group("Visual")
@export var sprite_frames: SpriteFrames
@export var animation: StringName = &"fly"
@export var visual_scale: float = 1.0
@export var rotation_speed_degrees: float = 1200.0

@export_group("Collision")
@export var collision_size: Vector2 = Vector2(8.0,8.0)
@export var collision_offset: Vector2 = Vector2.ZERO


func is_valid() -> bool:
	return get_validation_errors().is_empty()


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if projectile_id.is_empty():
		errors.append("projectile_id must not be empty")
	if default_team.is_empty() or default_team == &"neutral":
		errors.append("default_team must identify an attacking team")
	if damage <= 0:
		errors.append("damage must be greater than zero")
	if speed <= 0.0:
		errors.append("speed must be greater than zero")
	if lifetime <= 0.0:
		errors.append("lifetime must be greater than zero")
	if sprite_frames == null or not sprite_frames.has_animation(animation):
		errors.append("sprite_frames must contain the configured animation")
	if visual_scale <= 0.0:
		errors.append("visual_scale must be greater than zero")
	if collision_size.x <= 0.0 or collision_size.y <= 0.0:
		errors.append("collision_size components must be greater than zero")
	return errors
