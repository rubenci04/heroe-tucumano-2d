extends Node
## Native audio playback with independent music and SFX buses.
signal music_state_changed(previous_state: StringName, current_state: StringName, has_track: bool)

const MUSIC_SILENT: StringName = &"silent"
const MUSIC_INTRO: StringName = &"intro"
const MUSIC_GAMEPLAY: StringName = &"gameplay"
const MUSIC_MINIBOSS: StringName = &"miniboss"
const MUSIC_RESULT: StringName = &"result"
const EFFECTS: Array[String] = [
	"salto", "disparo_naranja", "disparo_cascote", "empanada", "achilata",
	"sanguche", "golpe", "danio", "victoria", "cabezazo", "alerta"
]

var voices: Array[AudioStreamPlayer] = []
var streams: Dictionary = {}
var next_voice: int = 0
var music_tracks: Dictionary = {}
var sfx_paused: bool = false
var current_music_state: StringName = MUSIC_SILENT
var music_change_count: int = 0
var music_loop_requested: bool = true
var music_player: AudioStreamPlayer
var _music_tween: Tween
var _transition_generation: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = &"Music"
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)
	for effect: String in EFFECTS:
		streams[effect] = load("res://audio/" + effect + ".wav")
	for index in range(8):
		var voice := AudioStreamPlayer.new()
		voice.name = "SFXVoice%02d" % index
		voice.bus = &"SFX"
		add_child(voice)
		voices.append(voice)


func play_effect(effect: String) -> void:
	if sfx_paused or not streams.has(effect) or voices.is_empty():
		return
	var voice: AudioStreamPlayer = voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stream = streams[effect]
	voice.play()


func register_music(state: StringName,stream: AudioStream) -> bool:
	if state.is_empty() or state == MUSIC_SILENT or stream == null:
		return false
	music_tracks[state] = stream
	return true


func clear_music_registry() -> void:
	music_tracks.clear()
	stop_music(0.0)


func request_music(state: StringName,fade_duration: float = 0.2,loop: bool = true) -> bool:
	if state.is_empty():
		return false
	var next_stream := music_tracks.get(state) as AudioStream
	if current_music_state == state and music_player.stream == next_stream:
		if next_stream != null and not music_player.playing:
			music_player.play()
		return next_stream != null
	var previous_state := current_music_state
	current_music_state = state
	music_loop_requested = loop
	music_change_count += 1
	_transition_generation += 1
	_cancel_music_tween()
	var transition_generation := _transition_generation
	music_state_changed.emit(previous_state,current_music_state,next_stream != null)
	if music_player.playing and fade_duration > 0.0:
		_music_tween = create_tween()
		_music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_music_tween.tween_property(music_player,"volume_db",-40.0,fade_duration)
		_music_tween.finished.connect(_complete_music_transition.bind(transition_generation,next_stream,fade_duration))
	else:
		_apply_music_stream(next_stream,fade_duration)
	return next_stream != null


func stop_music(fade_duration: float = 0.2) -> void:
	request_music(MUSIC_SILENT,fade_duration,false)


func set_gameplay_paused(value: bool) -> void:
	sfx_paused = value
	for voice: AudioStreamPlayer in voices:
		if voice.playing:
			voice.stream_paused = value
	# Music intentionally continues during pause for a stable arcade presentation.
	if is_instance_valid(music_player):
		music_player.stream_paused = false


func set_music_volume(linear_volume: float) -> void:
	_set_bus_volume(&"Music",linear_volume)


func set_sfx_volume(linear_volume: float) -> void:
	_set_bus_volume(&"SFX",linear_volume)


func reset_for_restart() -> void:
	_transition_generation += 1
	_cancel_music_tween()
	for voice: AudioStreamPlayer in voices:
		voice.stop()
		voice.stream = null
		voice.stream_paused = false
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null
		music_player.volume_db = 0.0
		music_player.stream_paused = false
	current_music_state = MUSIC_SILENT
	sfx_paused = false
	music_loop_requested = false
	music_change_count = 0
	next_voice = 0


func stop_all() -> void:
	reset_for_restart()


func _exit_tree() -> void:
	stop_all()
	streams.clear()
	music_tracks.clear()


func _complete_music_transition(generation: int,next_stream: AudioStream,fade_duration: float) -> void:
	if generation != _transition_generation:
		return
	_apply_music_stream(next_stream,fade_duration)


func _apply_music_stream(next_stream: AudioStream,fade_duration: float) -> void:
	music_player.stop()
	music_player.stream = next_stream
	music_player.volume_db = 0.0 if next_stream == null or fade_duration <= 0.0 else -40.0
	if next_stream == null:
		return
	music_player.play()
	if fade_duration > 0.0:
		_music_tween = create_tween()
		_music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_music_tween.tween_property(music_player,"volume_db",0.0,fade_duration)


func _on_music_finished() -> void:
	if music_loop_requested and music_player.stream != null:
		music_player.play()


func _cancel_music_tween() -> void:
	if is_instance_valid(_music_tween):
		_music_tween.kill()
	_music_tween = null


func _set_bus_volume(bus_name: StringName,linear_volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var safe_volume := clampf(linear_volume,0.0,1.0)
	AudioServer.set_bus_volume_db(bus_index,-80.0 if safe_volume <= 0.0 else linear_to_db(safe_volume))
