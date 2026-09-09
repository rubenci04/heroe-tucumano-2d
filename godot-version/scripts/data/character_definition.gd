class_name CharacterDefinition
extends Resource

@export_group("Identity")
@export var character_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var selectable: bool = true

@export_group("Visuals")
@export var sprite_frames: SpriteFrames
@export var portrait: Texture2D
@export var visual_scale: float = 0.42
@export var visual_offset: Vector2 = Vector2(0.0, -42.0)
@export var collision_width_ratio: float = 0.65

@export_group("Animations")
@export var idle_animation: StringName = &"Idle"
@export var run_animation: StringName = &"Run"
@export var jump_animation: StringName = &"Jump"
@export var throw_orange_animation: StringName = &"Throw Orange"
@export var throw_stone_animation: StringName = &"Throw Stone"
@export var headbutt_animation: StringName = &"Headbutt"
@export var hit_animation: StringName = &"Hit"
@export var death_animation: StringName = &"Death"

@export_group("Base Parameters")
@export var walk_speed: float = 230.0
@export var fury_speed: float = 330.0
@export var gravity: float = 1300.0
@export var jump_speed: float = 580.0
@export var lane_duration: float = 0.2
@export var floor_snap: float = 6.0
@export var max_health: int = 3
@export var starting_lives: int = 3

@export_group("Voice")
@export var voice_clips: Array[AudioStream] = []
@export var phrases: PackedStringArray = []


func get_animation_names() -> PackedStringArray:
	return PackedStringArray([
		idle_animation,
		run_animation,
		jump_animation,
		throw_orange_animation,
		throw_stone_animation,
		headbutt_animation,
		hit_animation,
		death_animation,
	])


func get_validation_errors(for_runtime: bool = true) -> PackedStringArray:
	var errors := PackedStringArray()
	if character_id.is_empty():
		errors.append("falta un identificador estable")
	if display_name.strip_edges().is_empty():
		errors.append("falta el nombre visible")
	if walk_speed <= 0.0:
		errors.append("walk_speed debe ser mayor que cero")
	if fury_speed <= 0.0:
		errors.append("fury_speed debe ser mayor que cero")
	if gravity <= 0.0:
		errors.append("gravity debe ser mayor que cero")
	if jump_speed <= 0.0:
		errors.append("jump_speed debe ser mayor que cero")
	if lane_duration <= 0.0:
		errors.append("lane_duration debe ser mayor que cero")
	if floor_snap < 0.0:
		errors.append("floor_snap no puede ser negativo")
	if max_health <= 0:
		errors.append("max_health debe ser mayor que cero")
	if starting_lives <= 0:
		errors.append("starting_lives debe ser mayor que cero")
	if visual_scale <= 0.0:
		errors.append("visual_scale debe ser mayor que cero")
	if collision_width_ratio <= 0.0:
		errors.append("collision_width_ratio debe ser mayor que cero")
	if not for_runtime:
		return errors
	if not selectable:
		errors.append("el personaje todavía no está habilitado para jugar")
	if sprite_frames == null:
		errors.append("faltan los SpriteFrames")
		return errors
	for animation_name: String in get_animation_names():
		if animation_name.is_empty():
			errors.append("hay una animación requerida sin asignar")
		elif not sprite_frames.has_animation(animation_name):
			errors.append("falta la animación '%s' en SpriteFrames" % animation_name)
	return errors


func is_runtime_ready() -> bool:
	return get_validation_errors(true).is_empty()
