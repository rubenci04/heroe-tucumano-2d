extends RefCounted
## Cambia solo la apariencia de Ciruja en la arena (sprites pixelados). No toca player.gd ni assets originales.

const CFG = preload("res://scripts/prototype/feel_config.gd")
const PIXEL_DIR := "res://assets/prototype/ciruja_pixel/"
const SRC_H := 198.0
const PIXEL_H := 64.0
const CANVAS_CENTER_Y := 36.0
const ANCHOR_Y := 68.0
const ORIGINAL_GROUND_Y := -0.84   # pie del sprite original respecto al origen del player (-42 + 98*0.42)


static func apply(player: CharacterBody2D) -> void:
	var skin: int = CFG.CIRUJA_SKIN
	if skin == CFG.CirujaSkin.ORIGINAL or not CFG.CIRUJA_SKIN_DIRS.has(skin):
		return
	var dir: String = PIXEL_DIR + CFG.CIRUJA_SKIN_DIRS[skin] + "/"
	var visual: AnimatedSprite2D = player.visual
	var frames: SpriteFrames = visual.sprite_frames.duplicate(true)
	var cache := {}
	for anim in frames.get_animation_names():
		for i in frames.get_frame_count(anim):
			var tex := frames.get_frame_texture(anim, i)
			var file := tex.resource_path.get_file() if tex != null else ""
			if file == "":
				continue
			if not cache.has(file):
				var img := Image.load_from_file(ProjectSettings.globalize_path(dir + file))
				cache[file] = ImageTexture.create_from_image(img) if img != null else null
			if cache[file] != null:
				frames.set_frame(anim, i, cache[file], frames.get_frame_duration(anim, i))
	var scale_px: float = player.character_visual_scale * SRC_H / PIXEL_H   # mismo tamaño en pantalla que el original
	visual.sprite_frames = frames
	player.character_visual_scale = scale_px   # player.gd lo reutiliza al resetear la escala
	visual.scale = Vector2.ONE * scale_px
	visual.position = Vector2(0.0, ORIGINAL_GROUND_Y - (ANCHOR_Y - CANVAS_CENTER_Y) * scale_px)
	player._visual_frame_offsets = {}   # los offsets del manifiesto son para los sprites originales; los pixel ya vienen alineados
	visual.offset = Vector2.ZERO
