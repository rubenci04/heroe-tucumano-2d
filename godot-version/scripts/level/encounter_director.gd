class_name EncounterDirector
extends Node

signal encounter_started(encounter_id: StringName)
signal encounter_completed(encounter_id: StringName)
signal active_enemy_count_changed(encounter_id: StringName, active_count: int)

const ACTIVATION_PLAYER_X := "player_x_at_least"
const COMPLETION_ALL_DEFEATED := "all_enemies_defeated"

var spawn_bounds := Vector2(40.0,7900.0)
var _spawn_enemy: Callable
var _encounters: Dictionary = {}
var _registration_order: Array[StringName] = []
var _activated: Dictionary = {}
var _completed: Dictionary = {}
var _active_enemies: Dictionary = {}
var _resetting: bool = false


func configure(encounters: Array, spawn_enemy: Callable, bounds: Vector2 = Vector2(40.0,7900.0)) -> bool:
	_encounters.clear()
	_registration_order.clear()
	_activated.clear()
	_completed.clear()
	_active_enemies.clear()
	_spawn_enemy = spawn_enemy
	spawn_bounds = bounds
	var valid := _spawn_enemy.is_valid()
	for encounter_data in encounters:
		valid = register_encounter(encounter_data) and valid
	return valid


func register_encounter(encounter_data: Dictionary) -> bool:
	if not _is_valid_encounter(encounter_data):
		return false
	var encounter_id := StringName(encounter_data.id)
	if _encounters.has(encounter_id):
		return false
	_encounters[encounter_id] = encounter_data.duplicate(true)
	_registration_order.append(encounter_id)
	return true


func update_activation(player_x: float) -> void:
	for encounter_id in _registration_order:
		if _activated.has(encounter_id) or _completed.has(encounter_id):
			continue
		var encounter: Dictionary = _encounters[encounter_id]
		var activation: Dictionary = encounter.activation
		if activation.type == ACTIVATION_PLAYER_X and player_x >= float(activation.value):
			activate_encounter(encounter_id,player_x)


func activate_encounter(encounter_id: StringName, activation_x: float = NAN) -> bool:
	if not _encounters.has(encounter_id) or _activated.has(encounter_id) or _completed.has(encounter_id) or not _spawn_enemy.is_valid():
		return false
	var encounter: Dictionary = _encounters[encounter_id]
	if is_nan(activation_x):
		activation_x = float(encounter.activation.value)
	_activated[encounter_id] = true
	_active_enemies[encounter_id] = {}
	encounter_started.emit(encounter_id)
	for spawn_data: Dictionary in encounter.enemies:
		var spawn_x := clampf(activation_x+float(spawn_data.x_offset),spawn_bounds.x,spawn_bounds.y)
		var enemy = _spawn_enemy.call(String(spawn_data.enemy_id),spawn_x,int(spawn_data.lane))
		if enemy is Node:
			_track_enemy(encounter_id,enemy)
	if get_active_enemy_count(encounter_id) == 0:
		_complete_encounter(encounter_id)
	return true


func has_encounter(encounter_id: StringName) -> bool:
	return _encounters.has(encounter_id)


func is_encounter_activated(encounter_id: StringName) -> bool:
	return _activated.has(encounter_id)


func is_encounter_completed(encounter_id: StringName) -> bool:
	return _completed.has(encounter_id)


func get_registered_encounter_ids() -> Array[StringName]:
	return _registration_order.duplicate()


func get_completed_encounter_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for encounter_id in _registration_order:
		if _completed.has(encounter_id):
			result.append(encounter_id)
	return result


func get_active_enemies(encounter_id: StringName) -> Array[Node]:
	var result: Array[Node] = []
	var tracked: Dictionary = _active_enemies.get(encounter_id,{})
	for instance_id in tracked.keys():
		var reference: WeakRef = tracked[instance_id]
		var enemy = reference.get_ref()
		if enemy == null or not is_instance_valid(enemy) or not enemy.is_inside_tree():
			tracked.erase(instance_id)
		else:
			result.append(enemy)
	return result


func get_active_enemy_count(encounter_id: StringName) -> int:
	return get_active_enemies(encounter_id).size()


func reset_runtime_state(remove_spawned_enemies: bool = true) -> void:
	_resetting = true
	if remove_spawned_enemies:
		for encounter_id in _active_enemies:
			for enemy in get_active_enemies(encounter_id):
				enemy.queue_free()
	_activated.clear()
	_completed.clear()
	_active_enemies.clear()
	_resetting = false


func restore_completed_encounters(completed_encounter_ids: Array[StringName]) -> void:
	reset_runtime_state(true)
	for encounter_id in completed_encounter_ids:
		if not _encounters.has(encounter_id):
			continue
		_activated[encounter_id] = true
		_completed[encounter_id] = true


func _track_enemy(encounter_id: StringName, enemy: Node) -> void:
	var instance_id := enemy.get_instance_id()
	var tracked: Dictionary = _active_enemies[encounter_id]
	tracked[instance_id] = weakref(enemy)
	if enemy.has_signal("defeated"):
		enemy.defeated.connect(_on_enemy_defeated.bind(encounter_id,instance_id),CONNECT_ONE_SHOT)
	enemy.tree_exiting.connect(_on_enemy_exiting.bind(encounter_id,instance_id),CONNECT_ONE_SHOT)
	active_enemy_count_changed.emit(encounter_id,tracked.size())


func _on_enemy_defeated(_points: int, encounter_id: StringName, instance_id: int) -> void:
	_remove_enemy_reference(encounter_id,instance_id)


func _on_enemy_exiting(encounter_id: StringName, instance_id: int) -> void:
	_remove_enemy_reference(encounter_id,instance_id)


func _remove_enemy_reference(encounter_id: StringName, instance_id: int) -> void:
	if _resetting or not _active_enemies.has(encounter_id):
		return
	var tracked: Dictionary = _active_enemies[encounter_id]
	if not tracked.erase(instance_id):
		return
	active_enemy_count_changed.emit(encounter_id,tracked.size())
	if tracked.is_empty():
		_complete_encounter(encounter_id)


func _complete_encounter(encounter_id: StringName) -> void:
	if _completed.has(encounter_id):
		return
	var encounter: Dictionary = _encounters[encounter_id]
	if encounter.completion != COMPLETION_ALL_DEFEATED or get_active_enemy_count(encounter_id) > 0:
		return
	_completed[encounter_id] = true
	_active_enemies.erase(encounter_id)
	encounter_completed.emit(encounter_id)


func _is_valid_encounter(encounter_data: Dictionary) -> bool:
	if not encounter_data.has_all(["id","activation","completion","enemies"]):
		return false
	var encounter_id := StringName(encounter_data.id)
	if encounter_id.is_empty() or not encounter_data.activation is Dictionary:
		return false
	var activation: Dictionary = encounter_data.activation
	if not activation.has_all(["type","value"]) or activation.type != ACTIVATION_PLAYER_X:
		return false
	if encounter_data.completion != COMPLETION_ALL_DEFEATED or not encounter_data.enemies is Array or encounter_data.enemies.is_empty():
		return false
	for spawn_data in encounter_data.enemies:
		if not spawn_data is Dictionary or not spawn_data.has_all(["enemy_id","x_offset","lane"]):
			return false
		if StringName(spawn_data.enemy_id).is_empty() or int(spawn_data.lane) < 0 or int(spawn_data.lane) >= GameConfig.LANES.size():
			return false
	return true
