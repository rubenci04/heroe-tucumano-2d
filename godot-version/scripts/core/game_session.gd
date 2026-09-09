extends Node

signal demo_state_changed(previous_state: int, current_state: int)
signal progress_changed(score: int, coins: int)
signal checkpoint_changed(checkpoint_id: StringName)
signal selected_character_changed(character_id: StringName)

enum DemoState {
	CHARACTER_SELECT,
	INTRO,
	GAMEPLAY,
	PAUSED,
	RESULT,
}

const DEFAULT_CHARACTER: StringName = &"san_martin"
const CHARACTER_DEFINITIONS: Dictionary = {
	DEFAULT_CHARACTER: preload("res://data/characters/san_martin.tres"),
	&"atletico": preload("res://data/characters/atletico.tres"),
}

var selected_character: StringName = DEFAULT_CHARACTER
var score: int = 0
var coins: int = 0
var active_checkpoint: StringName = &""
var respawn_position: Vector2 = Vector2.ZERO
var checkpoint_completed_encounters: Array[StringName] = []
var checkpoint_collected_pickups: Array[StringName] = []
var checkpoint_player_state: Dictionary = {}
var demo_state: int = DemoState.GAMEPLAY


func begin_new_run(preserve_character: bool = true) -> void:
	if not preserve_character:
		set_selected_character(DEFAULT_CHARACTER)
	score = 0
	coins = 0
	active_checkpoint = &""
	respawn_position = Vector2.ZERO
	checkpoint_completed_encounters.clear()
	checkpoint_collected_pickups.clear()
	checkpoint_player_state.clear()
	set_demo_state(DemoState.GAMEPLAY)
	progress_changed.emit(score, coins)
	checkpoint_changed.emit(active_checkpoint)


func set_selected_character(character_id: StringName) -> bool:
	if character_id.is_empty():
		return false
	if selected_character == character_id:
		return true
	selected_character = character_id
	selected_character_changed.emit(selected_character)
	return true


func get_character_definitions() -> Array:
	return [CHARACTER_DEFINITIONS[DEFAULT_CHARACTER], CHARACTER_DEFINITIONS[&"atletico"]]


func get_character_definition(character_id: StringName) -> Resource:
	return CHARACTER_DEFINITIONS.get(character_id)


func resolve_character_definition(character_id: StringName) -> Resource:
	var definition = get_character_definition(character_id)
	if definition != null and definition.selectable and definition.is_runtime_ready():
		return definition
	return CHARACTER_DEFINITIONS[DEFAULT_CHARACTER]


func set_demo_state(next_state: int) -> void:
	if next_state not in DemoState.values():
		push_error("GameSession recibió un estado de demo inválido: %s" % next_state)
		return
	if demo_state == next_state:
		return
	var previous_state := demo_state
	demo_state = next_state
	demo_state_changed.emit(previous_state, demo_state)


func set_progress(next_score: int, next_coins: int) -> void:
	if score == next_score and coins == next_coins:
		return
	score = maxi(0, next_score)
	coins = maxi(0, next_coins)
	progress_changed.emit(score, coins)


func set_respawn_baseline(position: Vector2, player_state: Dictionary) -> void:
	respawn_position = position
	checkpoint_player_state = player_state.duplicate(true)
	checkpoint_completed_encounters.clear()
	checkpoint_collected_pickups.clear()


func set_checkpoint(
	checkpoint_id: StringName,
	position: Vector2 = Vector2.ZERO,
	completed_encounters: Array[StringName] = [],
	collected_pickups: Array[StringName] = [],
	player_state: Dictionary = {}
) -> bool:
	if checkpoint_id.is_empty() or active_checkpoint == checkpoint_id:
		return false
	active_checkpoint = checkpoint_id
	respawn_position = position
	checkpoint_completed_encounters = completed_encounters.duplicate()
	checkpoint_collected_pickups = collected_pickups.duplicate()
	checkpoint_player_state = player_state.duplicate(true)
	checkpoint_changed.emit(active_checkpoint)
	return true


func has_active_checkpoint() -> bool:
	return not active_checkpoint.is_empty()
