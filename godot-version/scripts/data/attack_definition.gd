class_name AttackDefinition
extends Resource

enum ShapeKind { RECTANGLE, CIRCLE }

@export_group("Identity")
@export var attack_id: StringName = &""

@export_group("Damage")
@export_range(1, 999, 1) var damage: int = 1
@export_range(0.01, 10.0, 0.01) var startup_duration: float = 0.08
@export_range(0.01, 10.0, 0.01) var active_duration: float = 0.1
@export_range(0.01, 10.0, 0.01) var recovery_duration: float = 0.1

@export_group("Physical reach")
@export var shape_kind: ShapeKind = ShapeKind.RECTANGLE
@export var reach: Vector2 = Vector2(32.0, 24.0)
@export_range(1.0,1000.0,1.0) var radius: float = 16.0
@export var offset: Vector2 = Vector2.ZERO


func is_valid() -> bool:
	return get_validation_errors().is_empty()


func get_total_duration() -> float:
	return startup_duration + active_duration + recovery_duration


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if attack_id.is_empty():
		errors.append("attack_id must not be empty")
	if damage <= 0:
		errors.append("damage must be greater than zero")
	if startup_duration <= 0.0:
		errors.append("startup_duration must be greater than zero")
	if active_duration <= 0.0:
		errors.append("active_duration must be greater than zero")
	if recovery_duration <= 0.0:
		errors.append("recovery_duration must be greater than zero")
	if shape_kind == ShapeKind.RECTANGLE and (reach.x <= 0.0 or reach.y <= 0.0):
		errors.append("reach components must be greater than zero")
	if shape_kind == ShapeKind.CIRCLE and radius <= 0.0:
		errors.append("radius must be greater than zero")
	return errors
