class_name HealthComponent
extends Node

signal health_changed(current_health: int, max_health: int)
signal damaged(amount: int, current_health: int, source)
signal depleted

@export var max_health: int = 1
@export var current_health: int = 1
@export var invulnerability_duration: float = 0.0

var invulnerability_remaining: float = 0.0
var _is_depleted: bool = false


func _ready() -> void:
	max_health = maxi(1, max_health)
	current_health = clampi(current_health, 0, max_health)
	invulnerability_duration = maxf(0.0, invulnerability_duration)
	_is_depleted = current_health == 0


func _physics_process(delta: float) -> void:
	invulnerability_remaining = maxf(0.0, invulnerability_remaining - delta)


func configure(maximum: int, initial: int = -1, immunity_duration: float = 0.0) -> void:
	max_health = maxi(1, maximum)
	current_health = max_health if initial < 0 else clampi(initial, 0, max_health)
	invulnerability_duration = maxf(0.0, immunity_duration)
	invulnerability_remaining = 0.0
	_is_depleted = current_health == 0
	health_changed.emit(current_health, max_health)


func take_damage(amount: int, source = null) -> bool:
	if amount <= 0 or _is_depleted or is_invulnerable():
		return false
	var previous_health := current_health
	current_health = maxi(0, current_health - amount)
	var applied_damage := previous_health - current_health
	_is_depleted = current_health == 0
	invulnerability_remaining = invulnerability_duration
	health_changed.emit(current_health, max_health)
	damaged.emit(applied_damage, current_health, source)
	if _is_depleted:
		depleted.emit()
	return true


func set_current_health(value: int) -> void:
	var was_depleted := _is_depleted
	var next_health := clampi(value, 0, max_health)
	if current_health == next_health:
		return
	current_health = next_health
	_is_depleted = current_health == 0
	health_changed.emit(current_health, max_health)
	if _is_depleted and not was_depleted:
		depleted.emit()


func restore_full(clear_immunity: bool = false) -> void:
	_is_depleted = false
	current_health = max_health
	if clear_immunity:
		invulnerability_remaining = 0.0
	health_changed.emit(current_health, max_health)


func set_invulnerability(duration: float) -> void:
	invulnerability_remaining = maxf(0.0, duration)


func is_invulnerable() -> bool:
	return invulnerability_remaining > 0.0


func is_depleted() -> bool:
	return _is_depleted
