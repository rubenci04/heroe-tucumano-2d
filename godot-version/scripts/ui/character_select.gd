extends Control

signal character_confirmed(character_id: StringName)
signal cancelled

var definitions: Array = []
var selected_index: int = 0

@onready var san_martin_option: Label = $Panel/SanMartinOption
@onready var atletico_option: Label = $Panel/AtleticoOption
@onready var description_label: Label = $Panel/Description
@onready var status_label: Label = $Panel/Status


func configure(next_definitions: Array, preferred_id: StringName) -> void:
	definitions = next_definitions
	selected_index = _index_for_id(preferred_id)
	if selected_index < 0:
		selected_index = _first_available_index()
	if selected_index < 0:
		selected_index = 0
	_refresh()


func move_selection(direction: int) -> void:
	if definitions.is_empty() or direction == 0:
		return
	selected_index = posmod(selected_index + direction, definitions.size())
	_refresh()


func select_character_id(character_id: StringName) -> bool:
	var index := _index_for_id(character_id)
	if index < 0:
		return false
	selected_index = index
	_refresh()
	return true


func confirm_selected() -> bool:
	var definition = get_selected_definition()
	if definition == null:
		status_label.text = "No hay personaje disponible."
		return false
	if not definition.selectable or not definition.is_runtime_ready():
		status_label.text = "BLOQUEADO · Requiere arte y animaciones aprobadas."
		return false
	character_confirmed.emit(definition.character_id)
	return true


func get_selected_definition() -> Resource:
	if definitions.is_empty() or selected_index < 0 or selected_index >= definitions.size():
		return null
	return definitions[selected_index]


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("select_previous"):
		move_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("select_next"):
		move_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("select_confirm"):
		confirm_selected()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("select_cancel"):
		cancelled.emit()
		get_viewport().set_input_as_handled()


func _index_for_id(character_id: StringName) -> int:
	for index in range(definitions.size()):
		if definitions[index].character_id == character_id:
			return index
	return -1


func _first_available_index() -> int:
	for index in range(definitions.size()):
		if definitions[index].selectable and definitions[index].is_runtime_ready():
			return index
	return -1


func _refresh() -> void:
	if definitions.is_empty():
		san_martin_option.text = "Sin personajes configurados"
		atletico_option.text = ""
		description_label.text = ""
		status_label.text = ""
		return
	if definitions.size() > 0:
		san_martin_option.text = _option_text(definitions[0], 0)
	if definitions.size() > 1:
		atletico_option.text = _option_text(definitions[1], 1)
	var selected = get_selected_definition()
	if selected == null:
		return
	description_label.text = selected.description
	status_label.text = "DISPONIBLE · Confirmar para jugar" if selected.selectable and selected.is_runtime_ready() else "BLOQUEADO · Requiere arte y animaciones aprobadas."


func _option_text(definition: Resource, index: int) -> String:
	var cursor := "▶ " if index == selected_index else "  "
	var availability := "DISPONIBLE" if definition.selectable and definition.is_runtime_ready() else "BLOQUEADO"
	return "%s%s  [%s]" % [cursor, definition.display_name, availability]
