class_name DialogueRunner
extends Control

signal sequence_started(sequence_id: StringName)
signal line_changed(line_index: int, speaker: String, text: String)
signal sequence_finished(sequence_id: StringName, skipped: bool)

const DIALOGUE_SEQUENCE = preload("res://scripts/data/dialogue_sequence.gd")

var active_sequence: DIALOGUE_SEQUENCE
var line_index: int = -1
var active: bool = false
var _allow_skip: bool = false
var _control_target: Node
var _restore_controls_to: bool = false

@onready var speaker_label: Label = $Panel/Speaker
@onready var text_label: Label = $Panel/Text
@onready var prompt_label: Label = $Panel/Prompt
@onready var portrait: TextureRect = $Panel/Portrait


func _ready() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not active or get_tree().paused:
		return
	if event.is_action_pressed("dialogue_advance"):
		advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("dialogue_skip") and _allow_skip:
		skip()
		get_viewport().set_input_as_handled()


func start_sequence(sequence: DIALOGUE_SEQUENCE, control_target: Node = null, allow_skip_override: Variant = null) -> bool:
	if active or sequence == null or not sequence.is_valid():
		return false
	active_sequence = sequence
	line_index = 0
	active = true
	_allow_skip = sequence.allow_skip if allow_skip_override == null else bool(allow_skip_override)
	_control_target = control_target
	_restore_controls_to = false
	if is_instance_valid(_control_target) and "controls_enabled" in _control_target:
		_restore_controls_to = _control_target.controls_enabled
		_control_target.controls_enabled = false
	show()
	prompt_label.text = "ACEPTAR: continuar  ·  CANCELAR: omitir" if _allow_skip else "ACEPTAR: continuar"
	sequence_started.emit(active_sequence.sequence_id)
	_show_current_line()
	return true


func advance() -> bool:
	if not active:
		return false
	line_index += 1
	if line_index >= active_sequence.entries.size():
		_finish(false,true)
	else:
		_show_current_line()
	return true


func skip() -> bool:
	if not active or not _allow_skip:
		return false
	_finish(true,true)
	return true


func cancel(restore_controls: bool = false) -> bool:
	if not active:
		return false
	_finish(true,restore_controls)
	return true


func _show_current_line() -> void:
	var entry := active_sequence.get_entry(line_index)
	speaker_label.text = String(entry.speaker)
	text_label.text = String(entry.text)
	var portrait_texture = entry.get("portrait")
	portrait.texture = portrait_texture if portrait_texture is Texture2D else null
	portrait.visible = portrait.texture != null
	line_changed.emit(line_index,speaker_label.text,text_label.text)


func _finish(skipped: bool, restore_controls: bool) -> void:
	var finished_id := active_sequence.sequence_id
	active = false
	active_sequence = null
	line_index = -1
	hide()
	if restore_controls and is_instance_valid(_control_target) and "controls_enabled" in _control_target and not get_tree().paused:
		_control_target.controls_enabled = _restore_controls_to
	_control_target = null
	sequence_finished.emit(finished_id,skipped)


func _exit_tree() -> void:
	active = false
	_control_target = null
