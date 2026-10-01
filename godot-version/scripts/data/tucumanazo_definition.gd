class_name TucumanazoDefinition
extends "res://scripts/data/attack_definition.gd"
## Todos los valores de este recurso son provisionales y ajustables mediante playtesting.

@export_group("Consumable")
@export_range(1,100,1) var starting_uses: int = 5

@export_group("Rush")
@export_range(2.0,2.4,0.05) var rush_speed_multiplier: float = 2.2
@export_range(180.0,260.0,1.0) var rush_distance: float = 240.0
@export_range(0.45,1.0,0.01) var rush_timeout: float = 0.7
@export_range(0.18,0.3,0.01) var finish_startup_duration: float = 0.2
@export var rush_attack: Resource
@export_range(0.0,400.0,10.0) var rush_knockback_speed: float = 240.0
@export_range(0.0,400.0,10.0) var final_knockback_speed: float = 280.0
@export_range(0.05,0.4,0.01) var stagger_duration: float = 0.2

@export_group("Feedback")
@export_range(0.0,1.0,0.01) var hit_stop_duration: float = 0.08
@export_range(0.01,1.0,0.01) var hit_stop_time_scale: float = 0.08
@export_range(0.0,32.0,0.5) var screen_shake_intensity: float = 8.0
@export_range(0.0,2.0,0.01) var screen_shake_duration: float = 0.25
@export var phrase: String = "¡VAMO' URA!"


func get_validation_errors() -> PackedStringArray:
	var errors := super.get_validation_errors()
	if rush_attack == null or not rush_attack.has_method("is_valid") or not rush_attack.is_valid():
		errors.append("rush_attack must be a valid AttackDefinition")
	elif rush_attack.damage >= damage:
		errors.append("rush damage must be lower than final damage")
	if rush_distance <= 0.0 or rush_speed_multiplier <= 0.0 or rush_timeout <= 0.0 or finish_startup_duration <= 0.0:
		errors.append("rush movement and finish startup must be positive")
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


func get_total_duration() -> float:
	return super.get_total_duration()+rush_timeout+finish_startup_duration
