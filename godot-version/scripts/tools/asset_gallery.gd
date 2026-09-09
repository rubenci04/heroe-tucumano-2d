extends Control
signal closed
var images: Array = []
var image_picker: OptionButton
var info: Label
var preview: TextureRect
var animated_preview: AnimatedSprite2D
var actor_picker: OptionButton
var animation_picker: OptionButton
var sound_picker: OptionButton
var animation_toggle: CheckButton
const ACTORS: Array[String] = ["player", "hipster", "agente", "grandote", "boss"]

func _ready() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/asset_manifest.json"))
	images = data.images
	var background := ColorRect.new()
	background.color = Color(0.03, 0.045, 0.065, 0.99)
	background.size = Vector2(800,450)
	add_child(background)
	add_label("ARCHIVO DE ASSETS · 100 PNG / 30 animaciones / 11 sonidos", Vector2(22,15), 18)
	var close_button := Button.new()
	close_button.text = "Cerrar [F1]"
	close_button.position = Vector2(675,50)
	close_button.size = Vector2(105,30)
	close_button.pressed.connect(func(): closed.emit())
	add_child(close_button)
	image_picker = OptionButton.new()
	image_picker.position = Vector2(22,50)
	image_picker.size = Vector2(630,30)
	for item: Dictionary in images:
		image_picker.add_item(item.filename)
	image_picker.item_selected.connect(show_image)
	add_child(image_picker)
	preview = TextureRect.new()
	preview.position = Vector2(24,105)
	preview.size = Vector2(350,285)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(preview)
	animated_preview = AnimatedSprite2D.new()
	animated_preview.position = Vector2(200,245)
	animated_preview.scale = Vector2(1.25,1.25)
	animated_preview.visible = false
	add_child(animated_preview)
	info = add_label("", Vector2(400,105), 14)
	info.size = Vector2(375,80)
	actor_picker = OptionButton.new()
	actor_picker.position = Vector2(400,190)
	actor_picker.size = Vector2(165,30)
	for actor: String in ACTORS:
		actor_picker.add_item(actor)
	actor_picker.item_selected.connect(show_actor)
	add_child(actor_picker)
	animation_picker = OptionButton.new()
	animation_picker.position = Vector2(400,228)
	animation_picker.size = Vector2(375,30)
	animation_picker.item_selected.connect(func(index: int): animated_preview.play(animation_picker.get_item_text(index)))
	add_child(animation_picker)
	animation_toggle = CheckButton.new()
	animation_toggle.text = "Reproducir animación"
	animation_toggle.position = Vector2(400,268)
	animation_toggle.toggled.connect(func(enabled: bool):
		animated_preview.visible = enabled
		preview.visible = not enabled
	)
	add_child(animation_toggle)
	sound_picker = OptionButton.new()
	sound_picker.position = Vector2(400,315)
	sound_picker.size = Vector2(230,30)
	for effect: String in AudioManager.EFFECTS:
		sound_picker.add_item(effect)
	add_child(sound_picker)
	var play_button := Button.new()
	play_button.text = "Escuchar"
	play_button.position = Vector2(645,315)
	play_button.size = Vector2(130,30)
	play_button.pressed.connect(func(): AudioManager.play_effect(sound_picker.get_item_text(sound_picker.selected)))
	add_child(play_button)
	add_label("Los PNG originales se conservan sin cambios. El visor no modifica recursos.", Vector2(24,415), 13)
	show_image(0)
	show_actor(0)

func add_label(text: String, at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label

func show_image(index: int) -> void:
	var item: Dictionary = images[index]
	preview.texture = load(item.path)
	info.text = "%d × %d px · %d bytes\n%s\nAnimaciones: %d" % [
		int(item.width), int(item.height), int(item.bytes),
		"Cargado en Phaser" if item.loaded_by_legacy else "Preservado: sin uso en Phaser",
		item.animations.size()]
	if animation_toggle:
		animation_toggle.button_pressed = false

func show_actor(index: int) -> void:
	var frames: SpriteFrames = load("res://assets/animations/" + ACTORS[index] + ".tres")
	animated_preview.sprite_frames = frames
	animation_picker.clear()
	for animation_name: String in frames.get_animation_names():
		animation_picker.add_item(animation_name)
	if animation_picker.item_count > 0:
		animation_picker.select(0)
		animated_preview.play(animation_picker.get_item_text(0))
