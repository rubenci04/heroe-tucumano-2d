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


# --- Jugador: vidas y puntos ---
var player: CharacterBody2D
var lives_label: Label
var score_label: Label
var head_icon: TextureRect
var overlay: Control
var overlay_title: Label
var overlay_text: Label
var overlay_hint: Label


func bind_player(player_node: CharacterBody2D) -> void:
	player = player_node
	_build_player_panel()
	_build_overlay()


func _build_player_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "PlayerPanel"
	panel.position = Vector2(14.0, 12.0)
	panel.add_theme_stylebox_override("panel", _style(CFG.HUD_PANEL_FILL, CFG.HUD_PANEL_BORDER, 14, 4))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	head_icon = TextureRect.new()
	head_icon.custom_minimum_size = Vector2(46.0, 46.0)
	head_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	head_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head_icon.texture = _head_texture()
	row.add_child(head_icon)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", -4)
	row.add_child(column)
	lives_label = make_label("x 3", 26)
	score_label = make_label("00000", 20, Color(1, 1, 1))
	column.add_child(lives_label)
	column.add_child(score_label)


## Cabeza de Ciruja recortada de su primer cuadro (sin imágenes nuevas): parte alta de la silueta opaca.
func _head_texture() -> Texture2D:
	var frames: SpriteFrames = player.visual.sprite_frames
	for animation in [&"ajustar_gorra", &"correr", &"Idle"]:
		if frames.has_animation(animation) and frames.get_frame_count(animation) > 0:
			var texture := frames.get_frame_texture(animation, 0)
			var bounds := CollisionFactory.opaque_bounds(texture)
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			var side := bounds.size.y * CFG.HUD_HEAD_CROP
			atlas.region = Rect2(bounds.get_center().x - side * 0.5 + CFG.HUD_HEAD_OFFSET_X, bounds.position.y, side, side)
			return atlas
	return null


func _build_overlay() -> void:
	overlay = Control.new()
	overlay.name = "Overlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.1, 0.05, 0.03, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)
	overlay_title = make_label("", 48)
	overlay_title.position = Vector2(0.0, 120.0)
	overlay_title.size = Vector2(800.0, 64.0)
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(overlay_title)
	overlay_text = make_label("", 22, Color(1, 1, 1))
	overlay_text.position = Vector2(0.0, 196.0)
	overlay_text.size = Vector2(800.0, 120.0)
	overlay_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(overlay_text)
	overlay_hint = make_label(CFG.HUD_RESTART_HINT, 20, Color(1.0, 0.7, 0.25))
	overlay_hint.position = Vector2(0.0, 360.0)
	overlay_hint.size = Vector2(800.0, 30.0)
	overlay_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(overlay_hint)


func show_game_over() -> void:
	_show_overlay(CFG.HUD_GAME_OVER_TITLE, CFG.HUD_GAME_OVER_TEXT, Color(1.0, 0.4, 0.3))


func show_victory() -> void:
	_show_overlay(CFG.HUD_VICTORY_TITLE, CFG.HUD_VICTORY_TEXT, CFG.HUD_TEXT_COLOR)


func _show_overlay(title: String, text: String, color: Color) -> void:
	overlay_title.text = title
	overlay_title.add_theme_color_override("font_color", color)
	overlay_text.text = "%s\nPUNTOS: %05d" % [text, player.score if is_instance_valid(player) else 0]
	overlay.modulate.a = 0.0
	overlay.visible = true
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.4)


func _process(_delta: float) -> void:
	if not is_instance_valid(player) or lives_label == null:
		return
	lives_label.text = "x %d" % maxi(player.lives, 0)
	score_label.text = "%05d" % player.score
