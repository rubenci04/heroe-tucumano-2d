extends RefCounted
## Estilo cartoon de la HUD (borde oscuro grueso, sombra y paneles). Lo usan la HUD prototipo y la HUD de la ruta 38.

const CFG = preload("res://scripts/prototype/feel_config.gd")


## Texto con relleno claro y borde oscuro grueso (legible sobre cualquier fondo).
static func style_label(label: Label, font_size: int = -1) -> void:
	if font_size > 0:
		label.add_theme_font_size_override("font_size", font_size)
	var size := label.get_theme_font_size("font_size")
	label.add_theme_color_override("font_outline_color", CFG.HUD_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", maxi(2, int(size * CFG.HUD_OUTLINE_RATIO)))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	label.add_theme_constant_override("shadow_offset_y", 3)


static func panel(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style
