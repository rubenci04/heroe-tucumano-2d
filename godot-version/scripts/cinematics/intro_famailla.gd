class_name IntroFamailla
extends Node2D

signal completed(skipped: bool)

@export var san_martin_dialogue: Resource

var active: bool = false
var _finishing: bool = false
var _player: CharacterBody2D
var _camera: Camera2D
var _dialogue: Control
var _player_visual_was_visible: bool = true
var _camera_position := Vector2.ZERO
var _camera_offset := Vector2.ZERO
var _camera_smoothing_enabled: bool = true

@onready var protagonist_proxy: AnimatedSprite2D = $Actors/ProtagonistProxy
@onready var champion: Sprite2D = $Actors/Champion
@onready var palermitano: AnimatedSprite2D = $Actors/Palermitano
@onready var kidnapping: Sprite2D = $Actors/Kidnapping
@onready var camera_anchor: Node2D = $CameraAnchor
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var fade_layer: CanvasLayer = $FadeLayer


func _ready() -> void:
	hide()
	fade_layer.visible = false
	set_process(false)


func _process(_delta: float) -> void:
	if active and is_instance_valid(_camera):
		_camera.position = camera_anchor.position


func start(player: CharacterBody2D, camera: Camera2D, dialogue: Control, character_id: StringName) -> bool:
	if active or not is_instance_valid(player) or not is_instance_valid(camera) or not is_instance_valid(dialogue):
		return false
	var sequence: Resource = _resolve_dialogue(character_id)
	if sequence == null or not sequence.is_valid():
		return false
	_player = player
	_camera = camera
	_dialogue = dialogue
	_camera_position = _camera.position
	_camera_offset = _camera.offset
	_camera_smoothing_enabled = _camera.position_smoothing_enabled
	_camera.position_smoothing_enabled = false
	_player_visual_was_visible = _player.visual.visible
	_player.visual.hide()
	protagonist_proxy.sprite_frames = _player.visual.sprite_frames
	protagonist_proxy.animation = _player.character_definition.idle_animation
	protagonist_proxy.play()
	active = true
	_finishing = false
	show()
	fade_layer.visible = true
	set_process(true)
	animation_player.play(&"RESET")
	animation_player.advance(0.0)
	animation_player.play(&"establish")
	_dialogue.line_changed.connect(_on_dialogue_line_changed)
	_dialogue.sequence_finished.connect(_on_dialogue_finished)
	if not _dialogue.start_sequence(sequence,_player,true):
		_disconnect_dialogue()
		_cleanup()
		return false
	return true


func skip() -> bool:
	if not active:
		return false
	if is_instance_valid(_dialogue) and _dialogue.active:
		return _dialogue.skip()
	_finish(true,true)
	return true


func cancel(emit_completion: bool = false) -> bool:
	if not active:
		return false
	_finishing = true
	active = false
	if is_instance_valid(_dialogue) and _dialogue.active:
		_dialogue.cancel(false)
	_disconnect_dialogue()
	_cleanup()
	if emit_completion:
		completed.emit(true)
	return true


func _resolve_dialogue(character_id: StringName) -> Resource:
	# Future protagonist-specific resources can be resolved here without changing the sequence controller.
	if character_id == &"san_martin":
		return san_martin_dialogue
	return san_martin_dialogue


func _on_dialogue_line_changed(index: int, _speaker: String, _text: String) -> void:
	if not active:
		return
	match index:
		1:
			animation_player.play(&"focus_group")
		3:
			animation_player.play(&"kidnapping")
		5:
			animation_player.play(&"return_to_player")


func _on_dialogue_finished(_sequence_id: StringName, skipped: bool) -> void:
	if active and not _finishing:
		_finish(skipped,true)


func _finish(skipped: bool, emit_completion: bool) -> void:
	if not active:
		return
	_finishing = true
	active = false
	_disconnect_dialogue()
	_cleanup()
	_finishing = false
	if emit_completion:
		completed.emit(skipped)


func _disconnect_dialogue() -> void:
	if not is_instance_valid(_dialogue):
		return
	if _dialogue.line_changed.is_connected(_on_dialogue_line_changed):
		_dialogue.line_changed.disconnect(_on_dialogue_line_changed)
	if _dialogue.sequence_finished.is_connected(_on_dialogue_finished):
		_dialogue.sequence_finished.disconnect(_on_dialogue_finished)


func _cleanup() -> void:
	animation_player.stop()
	set_process(false)
	hide()
	fade_layer.visible = false
	if is_instance_valid(_player):
		_player.visual.visible = _player_visual_was_visible
	if is_instance_valid(_camera):
		_camera.position = _camera_position
		_camera.offset = _camera_offset
		_camera.position_smoothing_enabled = _camera_smoothing_enabled
		_camera.reset_smoothing()
	_player = null
	_camera = null
	_dialogue = null
