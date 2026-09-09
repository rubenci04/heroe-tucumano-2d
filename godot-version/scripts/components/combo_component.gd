class_name ComboComponent
extends Node

signal combo_changed(combo_count: int)
signal combo_broken(previous_count: int)
signal combo_milestone(combo_count: int)
signal valid_hit_registered(combo_count: int,total_valid_hits: int)

@export_range(0.1,10.0,0.1) var combo_window_seconds: float = 2.0
@export_range(1,100,1) var milestone_interval: int = 5

var current_combo: int = 0
var remaining_window: float = 0.0
var total_valid_hits: int = 0
var _registered_impacts: Dictionary = {}


func _physics_process(delta: float) -> void:
	if current_combo <= 0:
		return
	remaining_window = maxf(remaining_window-delta,0.0)
	if remaining_window <= 0.0:
		break_combo()


func register_hit(impact_id) -> bool:
	if impact_id == null or impact_id == &"" or _registered_impacts.has(impact_id):
		return false
	_registered_impacts[impact_id] = true
	current_combo += 1
	total_valid_hits += 1
	remaining_window = combo_window_seconds
	combo_changed.emit(current_combo)
	valid_hit_registered.emit(current_combo,total_valid_hits)
	if milestone_interval > 0 and current_combo % milestone_interval == 0:
		combo_milestone.emit(current_combo)
	return true


func break_combo() -> void:
	if current_combo <= 0:
		remaining_window = 0.0
		_registered_impacts.clear()
		return
	var previous_count := current_combo
	current_combo = 0
	remaining_window = 0.0
	_registered_impacts.clear()
	combo_broken.emit(previous_count)
	combo_changed.emit(0)


func reset() -> void:
	current_combo = 0
	remaining_window = 0.0
	total_valid_hits = 0
	_registered_impacts.clear()
	combo_changed.emit(0)
