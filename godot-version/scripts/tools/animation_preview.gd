extends Node2D

const FRAMES := preload("res://assets/animations/player.tres")
const MANIFEST_PATH := "res://data/animation_manifest.json"

var sprite: AnimatedSprite2D
var title: Label
var animation_names: Array[StringName] = []
var animation_index := 0
var offset_tables: Dictionary = {}

func _ready() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	for animation_name: String in data.characters.ciruja.animations:
		var entry: Dictionary = data.characters.ciruja.animations[animation_name]
		if entry.has("frame_offsets") and entry.frame_offsets is Array:
			offset_tables[StringName(animation_name)] = entry.frame_offsets
	sprite = AnimatedSprite2D.new()
	sprite.name = "Preview"
	sprite.sprite_frames = FRAMES
	sprite.position = Vector2(400,300)
	sprite.scale = Vector2(1.5,1.5)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.frame_changed.connect(_apply_frame_offset)
	add_child(sprite)
	title = Label.new()
	title.position = Vector2(24,20)
	title.add_theme_font_size_override("font_size",24)
	add_child(title)
	var help := Label.new()
	help.text = "←/→ animación · Espacio pausa/reproduce · F voltear"
	help.position = Vector2(24,55)
	add_child(help)
	animation_names.assign(FRAMES.get_animation_names())
	animation_names.sort()
	_show_animation(0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_show_animation(animation_index-1)
	elif event.is_action_pressed("ui_right"):
		_show_animation(animation_index+1)
	elif event.is_action_pressed("ui_accept"):
		if sprite.is_playing(): sprite.pause()
		else: sprite.play()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F:
		sprite.flip_h = not sprite.flip_h

func _show_animation(index: int) -> void:
	if animation_names.is_empty():
		return
	animation_index = posmod(index,animation_names.size())
	var animation_name := animation_names[animation_index]
	sprite.play(animation_name)
	title.text = "%s · %d frames · %.1f FPS" % [animation_name,FRAMES.get_frame_count(animation_name),FRAMES.get_animation_speed(animation_name)]
	_apply_frame_offset()

func _apply_frame_offset() -> void:
	var offsets: Array = offset_tables.get(sprite.animation,[])
	if sprite.frame >= 0 and sprite.frame < offsets.size():
		var value: Array = offsets[sprite.frame]
		sprite.offset = Vector2(float(value[0]),float(value[1]))
	else:
		sprite.offset = Vector2.ZERO
