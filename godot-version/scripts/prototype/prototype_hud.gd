extends CanvasLayer
## HUD de la arena prototipo, armado por código: texto con borde grueso estilo cartoon,
## barra de vida del jefe y cartel central. No toca ui/hud.tscn ni scripts de gameplay.

const CFG = preload("res://scripts/prototype/feel_config.gd")

var root: Control
var boss_panel: Control
var boss_name_label: Label
var boss_bar: ProgressBar
var boss_phase_mark: ColorRect
var banner: Label
var banner_sub: Label
var _banner_tween: Tween


func _ready() -> void:
	layer = 10
	root = Control.new()
	root.name = "Hud"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_boss_bar()
	_build_banner()


## Etiqueta con relleno claro y borde oscuro grueso (legible sobre cualquier fondo).
func make_label(text: String, size: int, color: Color = CFG.HUD_TEXT_COLOR) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", CFG.HUD_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", maxi(2, int(size * CFG.HUD_OUTLINE_RATIO)))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _build_boss_bar() -> void:
	boss_panel = Control.new()
	boss_panel.name = "BossPanel"
	boss_panel.position = Vector2(220.0, 14.0)
	boss_panel.size = Vector2(360.0, 46.0)
	boss_panel.modulate.a = 0.0
	boss_panel.visible = false
	root.add_child(boss_panel)
	boss_name_label = make_label(CFG.BOSS_NAME, 20, Color(1.0, 0.45, 0.25))
	boss_name_label.position = Vector2(0.0, 0.0)
	boss_name_label.size = Vector2(360.0, 26.0)
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_panel.add_child(boss_name_label)
	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(0.0, 28.0)
	boss_bar.size = Vector2(360.0, 18.0)
	boss_bar.show_percentage = false
	boss_bar.add_theme_stylebox_override("background", _style(Color(0.2, 0.08, 0.06, 0.9), CFG.HUD_OUTLINE_COLOR, 8, 3))
	boss_bar.add_theme_stylebox_override("fill", _style(Color(0.9, 0.22, 0.12), Color(1.0, 0.55, 0.25), 6, 1))
	boss_panel.add_child(boss_bar)
	boss_phase_mark = ColorRect.new()
	boss_phase_mark.color = Color(1, 1, 1, 0.75)
	boss_phase_mark.size = Vector2(2.0, 18.0)
	boss_phase_mark.position = Vector2(360.0 * CFG.BOSS_PHASE2_THRESHOLD - 1.0, 28.0)
	boss_phase_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_panel.add_child(boss_phase_mark)


func _build_banner() -> void:
	banner = make_label("", 46, CFG.HUD_TEXT_COLOR)
	banner.name = "Banner"
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.position = Vector2(0.0, 150.0)
	banner.size = Vector2(800.0, 60.0)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.modulate.a = 0.0
	root.add_child(banner)
	banner_sub = make_label("", 20, Color(1, 1, 1))
	banner_sub.name = "BannerSub"
	banner_sub.position = Vector2(0.0, 212.0)
	banner_sub.size = Vector2(800.0, 28.0)
	banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_sub.modulate.a = 0.0
	root.add_child(banner_sub)


func show_boss_bar(maximum: int, current: int) -> void:
	boss_bar.max_value = maximum
	boss_bar.value = 0.0
	boss_panel.visible = true
	create_tween().tween_property(boss_panel, "modulate:a", 1.0, 0.35)
	create_tween().tween_property(boss_bar, "value", float(current), maxf(CFG.BOSS_INTRO_DURATION - 0.6, 0.2)).set_ease(Tween.EASE_OUT)


func set_boss_health(current: int, maximum: int) -> void:
	boss_bar.max_value = maximum
	boss_bar.value = current


func hide_boss_bar(delay: float = 0.0) -> void:
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(boss_panel, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): boss_panel.visible = false)


## Cartel central: título grande con subtítulo; entra, se sostiene y se va.
func show_banner(title: String, subtitle: String, hold: float) -> void:
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	banner.text = title
	banner_sub.text = subtitle
	banner.scale = Vector2(1.25, 1.25)
	banner.pivot_offset = banner.size * 0.5
	_banner_tween = create_tween().set_parallel(true)
	_banner_tween.tween_property(banner, "modulate:a", 1.0, 0.2)
	_banner_tween.tween_property(banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_property(banner_sub, "modulate:a", 1.0 if subtitle != "" else 0.0, 0.3).set_delay(0.15)
	var out := _banner_tween.chain().set_parallel(true)
	out.tween_property(banner, "modulate:a", 0.0, 0.35).set_delay(hold)
	out.tween_property(banner_sub, "modulate:a", 0.0, 0.35).set_delay(hold)
