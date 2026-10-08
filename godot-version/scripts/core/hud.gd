extends Control
const CFG = preload("res://scripts/prototype/feel_config.gd")
const CARTOON = preload("res://scripts/prototype/cartoon_style.gd")
var notice_time: float = 0.0
@onready var life_bar: ProgressBar = $LifeBar
@onready var status: Label = $Status
@onready var location: Label = $Location
@onready var notice: Label = $Notice
@onready var boss_bar: ProgressBar = $BossBar
@onready var boss_name: Label = $BossName
@onready var combo: Label = $Combo
@onready var special_status: Label = $SpecialStatus
@onready var heat_sun: TextureRect = $HeatSun
@onready var heat_alert: Label = $HeatAlert
@onready var heat_shimmer: Control = $HeatShimmer
@onready var shimmer_bands: Array[ColorRect] = [$HeatShimmer/BandUpper,$HeatShimmer/BandMiddle,$HeatShimmer/BandLower]

var _combo_component: Node
var _special_counter: Node
var _health_component: Node
var _game_session: Node
var _banner: Label
var _player_status_source: Node
var _boss_health_component: Node
var _lives: int = 0
var _score: int = 0
var _coins: int = 0
var _stones: int = 0
var _oranges_unlocked: bool = false
var _heat: float = 0.0
var _heat_feedback_time: float = 0.0
var _heat_sun_base_scale: float = 0.42
var _heat_alert_base_scale: float = 1.0
var _heat_shimmer_alpha: float = 0.0
var _heat_feedback_paused: bool = false

func _ready() -> void:
	_apply_cartoon_outline()
	# Barras de arriba y abajo con el mismo panel marrón cartoon que la HUD prototipo.
	$TopBar.color = CFG.HUD_PANEL_FILL
	$BottomBar.color = CFG.HUD_PANEL_FILL
	# Banner grande centrado (intro y fase 2 del jefe), con la misma API que la HUD prototipo.
	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_top = 120.0
	_banner.offset_left = -400.0
	_banner.offset_right = 400.0
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.visible = false
	add_child(_banner)
	CARTOON.style_label(_banner,CFG.HUD_TITLE_SIZE)
	_banner.add_theme_color_override("font_color",CFG.HUD_TEXT_COLOR)


## Todo texto del HUD lleva borde oscuro grueso (estilo cartoon, legible sobre cualquier fondo).
func _apply_cartoon_outline() -> void:
	for label: Label in find_children("*","Label",true,false):
		CARTOON.style_label(label)


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	notice_time = maxf(0.0,notice_time-delta)
	notice.visible = notice_time > 0.0
	_heat_feedback_time += delta
	_update_heat_feedback_motion()

func bind_health(component: Node) -> void:
	if is_instance_valid(_health_component) and _health_component.health_changed.is_connected(_on_health_changed):
		_health_component.health_changed.disconnect(_on_health_changed)
	_health_component = component
	if not is_instance_valid(_health_component):
		_on_health_changed(0,1)
		return
	_health_component.health_changed.connect(_on_health_changed)
	_on_health_changed(_health_component.current_health,_health_component.max_health)


func bind_game_session(session: Node) -> void:
	if is_instance_valid(_game_session):
		if _game_session.progress_changed.is_connected(_on_progress_changed):
			_game_session.progress_changed.disconnect(_on_progress_changed)
		if _game_session.checkpoint_changed.is_connected(_on_checkpoint_changed):
			_game_session.checkpoint_changed.disconnect(_on_checkpoint_changed)
	_game_session = session
	if not is_instance_valid(_game_session):
		_on_progress_changed(0,0)
		return
	_game_session.progress_changed.connect(_on_progress_changed)
	_game_session.checkpoint_changed.connect(_on_checkpoint_changed)
	_on_progress_changed(_game_session.score,_game_session.coins)


func bind_player_status(player: Node) -> void:
	if is_instance_valid(_player_status_source) and _player_status_source.hud_status_changed.is_connected(_on_player_status_changed):
		_player_status_source.hud_status_changed.disconnect(_on_player_status_changed)
	_player_status_source = player
	if not is_instance_valid(_player_status_source):
		_on_player_status_changed(0,0,false,0.0)
		return
	_player_status_source.hud_status_changed.connect(_on_player_status_changed)
	_on_player_status_changed(player.lives,player.stones,player.oranges_unlocked,player.heat)


func bind_boss_health(component: Node, display_name: String = "") -> void:
	if is_instance_valid(_boss_health_component):
		if _boss_health_component.health_changed.is_connected(_on_boss_health_changed):
			_boss_health_component.health_changed.disconnect(_on_boss_health_changed)
		if _boss_health_component.depleted.is_connected(_on_boss_depleted):
			_boss_health_component.depleted.disconnect(_on_boss_depleted)
	_boss_health_component = component
	if not is_instance_valid(_boss_health_component):
		boss_bar.visible = false
		boss_name.visible = false
		return
	_boss_health_component.health_changed.connect(_on_boss_health_changed)
	_boss_health_component.depleted.connect(_on_boss_depleted)
	boss_bar.visible = true
	boss_name.text = display_name
	boss_name.visible = not display_name.is_empty()
	_on_boss_health_changed(_boss_health_component.current_health,_boss_health_component.max_health)


func set_location(town: String) -> void:
	location.text = "%s  |  NARANJAS %s  ·  CASCOTES %d" % [town.to_upper(),"∞" if _oranges_unlocked else "—",_stones]
	if GameConfig.HEAT_ENABLED:
		location.text += "  ·  SOL %d%%" % int(_heat)


func _on_health_changed(current_health: int,max_health: int) -> void:
	life_bar.max_value = max_health
	life_bar.value = current_health


func _on_progress_changed(next_score: int,next_coins: int) -> void:
	_score = next_score
	_coins = next_coins
	_update_status_text()


func _on_player_status_changed(lives: int,stones: int,oranges_unlocked: bool,heat: float) -> void:
	_lives = lives
	_stones = stones
	_oranges_unlocked = oranges_unlocked
	_heat = heat
	_update_status_text()
	_update_heat_feedback()
	var separator := location.text.find("  |")
	var town := location.text.left(separator) if separator >= 0 else "FAMAILLÁ"
	set_location(town)


func _on_checkpoint_changed(checkpoint_id: StringName) -> void:
	if not checkpoint_id.is_empty():
		show_notice("CHECKPOINT")


func _on_boss_health_changed(current_health: int,max_health: int) -> void:
	boss_bar.max_value = max_health
	boss_bar.value = current_health
	boss_bar.visible = current_health > 0


func _on_boss_depleted() -> void:
	boss_bar.visible = false
	boss_name.visible = false


func _update_status_text() -> void:
	status.text = "VIDAS %d  ·  PUNTOS %06d  ·  MONEDAS %03d" % [_lives,_score,_coins]


func _update_heat_feedback() -> void:
	if not GameConfig.HEAT_ENABLED:
		heat_sun.hide()
		heat_alert.hide()
		heat_shimmer.hide()
		return
	var normalized_heat := clampf((_heat-40.0)/60.0,0.0,1.0)
	heat_sun.visible = _heat >= 40.0
	_heat_sun_base_scale = lerpf(0.42,1.0,normalized_heat)
	heat_sun.scale = Vector2.ONE*_heat_sun_base_scale
	heat_sun.modulate = Color(
		1.0,
		lerpf(1.0,0.72,normalized_heat),
		lerpf(1.0,0.5,normalized_heat),
		lerpf(0.55,1.0,normalized_heat)
	)
	var shimmer_progress := clampf((_heat-60.0)/40.0,0.0,1.0)
	_heat_shimmer_alpha = lerpf(0.035,0.13,shimmer_progress) if _heat >= 60.0 else 0.0
	heat_shimmer.visible = _heat >= 60.0 and not _heat_feedback_paused
	heat_shimmer.modulate.a = _heat_shimmer_alpha
	heat_alert.visible = _heat >= 75.0
	_heat_alert_base_scale = lerpf(1.0,1.08,clampf((_heat-90.0)/10.0,0.0,1.0))
	heat_alert.scale = Vector2.ONE*_heat_alert_base_scale
	heat_alert.modulate.a = lerpf(0.86,1.0,clampf((_heat-75.0)/25.0,0.0,1.0))


func _update_heat_feedback_motion() -> void:
	if not GameConfig.HEAT_ENABLED:
		return
	if heat_sun.visible:
		var sun_pulse := 1.0+sin(_heat_feedback_time*4.0)*lerpf(0.01,0.035,clampf((_heat-40.0)/60.0,0.0,1.0))
		heat_sun.scale = Vector2.ONE*_heat_sun_base_scale*sun_pulse
	if heat_alert.visible:
		var alert_pulse := 1.0+sin(_heat_feedback_time*7.0)*lerpf(0.01,0.035,clampf((_heat-75.0)/25.0,0.0,1.0))
		heat_alert.scale = Vector2.ONE*_heat_alert_base_scale*alert_pulse
	if heat_shimmer.visible:
		var shimmer_strength := lerpf(1.5,4.0,clampf((_heat-60.0)/40.0,0.0,1.0))
		for index in range(shimmer_bands.size()):
			shimmer_bands[index].position.x = sin(_heat_feedback_time*(1.7+index*0.35)+index*1.9)*shimmer_strength

func bind_combo(component: Node) -> void:
	if is_instance_valid(_combo_component) and _combo_component.combo_changed.is_connected(_on_combo_changed):
		_combo_component.combo_changed.disconnect(_on_combo_changed)
	_combo_component = component
	if not is_instance_valid(_combo_component):
		_on_combo_changed(0)
		return
	_combo_component.combo_changed.connect(_on_combo_changed)
	_on_combo_changed(_combo_component.current_combo)

func _on_combo_changed(combo_count: int) -> void:
	combo.visible = combo_count > 0
	combo.text = "COMBO x%d" % combo_count

func bind_special(component: Node) -> void:
	if is_instance_valid(_special_counter) and _special_counter.uses_changed.is_connected(_on_special_uses_changed):
		_special_counter.uses_changed.disconnect(_on_special_uses_changed)
	_special_counter = component
	if not is_instance_valid(_special_counter):
		_on_special_uses_changed(0,1)
		return
	_special_counter.uses_changed.connect(_on_special_uses_changed)
	_on_special_uses_changed(_special_counter.current_uses,_special_counter.max_uses)

func _on_special_uses_changed(current_uses: int,_max_uses: int) -> void:
	special_status.text = "TUCUMANAZO x%d" % current_uses

func set_paused(value: bool) -> void:
	$PauseLabel.visible = value
	_heat_feedback_paused = value
	_update_heat_feedback()

func show_notice(text: String) -> void:
	notice.text = text
	notice_time = 3.5
	notice.visible = true

func show_result(title: String,description: String) -> void:
	$Results.visible = true
	$Results/Title.text = title
	$Results/Description.text = description
	$PauseLabel.visible = false


## Barra de jefe con la API de la HUD prototipo (la usa boss_director): reutiliza la barra de bind_boss_health.
func show_boss_bar(maximum: int, current: int) -> void:
	boss_bar.max_value = maximum
	boss_bar.value = current
	boss_bar.visible = true
	boss_name.text = CFG.BOSS_NAME
	boss_name.visible = true


func set_boss_health(current: int, maximum: int) -> void:
	_on_boss_health_changed(current, maximum)


func hide_boss_bar(delay: float = 0.0) -> void:
	var tween := create_tween()
	tween.tween_interval(maxf(delay, 0.0))
	tween.tween_callback(func():
		boss_bar.visible = false
		boss_name.visible = false)


func show_banner(title: String, subtitle: String, hold: float) -> void:
	_banner.text = title if subtitle.is_empty() else "%s\n%s" % [title, subtitle]
	_banner.modulate.a = 1.0
	_banner.visible = true
	var tween := create_tween()
	tween.tween_interval(maxf(hold, 0.0))
	tween.tween_property(_banner, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): _banner.visible = false)
