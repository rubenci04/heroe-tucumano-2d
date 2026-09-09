class_name TucumanazoDefinition
extends "res://scripts/data/attack_definition.gd"
## Todos los valores de este recurso son provisionales y ajustables mediante playtesting.

@export_group("Consumable")
@export_range(1,100,1) var starting_uses: int = 5

@export_group("Feedback")
@export_range(0.0,1.0,0.01) var hit_stop_duration: float = 0.08
@export_range(0.01,1.0,0.01) var hit_stop_time_scale: float = 0.08
@export_range(0.0,32.0,0.5) var screen_shake_intensity: float = 8.0
@export_range(0.0,2.0,0.01) var screen_shake_duration: float = 0.25
@export var phrase: String = "¡VAMO' URA!"


func get_validation_errors() -> PackedStringArray:
	var errors := super.get_validation_errors()
	if starting_uses <= 0:
		errors.append("starting_uses must be greater than zero")
	if hit_stop_duration < 0.0:
		errors.append("hit_stop_duration must not be negative")
	if hit_stop_time_scale <= 0.0 or hit_stop_time_scale > 1.0:
		errors.append("hit_stop_time_scale must be between zero and one")
	if screen_shake_intensity < 0.0 or screen_shake_duration < 0.0:
		errors.append("screen shake values must not be negative")
	if phrase.is_empty():
		errors.append("phrase must not be empty")
	return errors
