class_name AgentVehicle
extends Node2D
## Vehículo de agentes (estilo Metal Slug): llega por el borde con aviso, frena, baja agentes y se va.
## Mientras está en pantalla se lo puede destruir (naranjas, cascotes, cabezazo): vida propia, destello, humo al 50 %,
## explosión, restos que se desvanecen en ≤ 2 s y empanadas. Solo usa arte de vehículos existente (assets/*.png).
## Parámetros en scenes/levels/route_38_data.json -> "vehicle_types".

signal defeated(points: int)

enum Phase { WARNING, ARRIVING, UNLOADING, LEAVING, DESTROYED }

const HURTBOX = preload("res://scripts/components/hurtbox.gd")
const HEALTH = preload("res://scripts/components/health_component.gd")
const CFG = preload("res://scripts/prototype/feel_config.gd")

var archetype := "agent_vehicle"
var team: StringName = &"enemy"
var active := true
var config: Dictionary = {}
var target: Node2D
var fx: Node2D                       # FX compartidos (humo, explosión)
var dismount_handler: Callable       # () -> Node2D: baja un agente y lo registra en el encuentro; null = sin cupo
var destroyed_handler: Callable      # (vehicle) -> void: monedas, temblor
var phase: int = Phase.WARNING
var agents_inside := 0
var agents_released := 0
var health_component: Node
var hurtbox: Area2D
var visual: Sprite2D

var _phase_time := 0.0
var _unload_timer := 0.0
var _waiting_slot := 0.0
var _speed := 0.0
var _smoke_timer := 0.0
var smoke_puffs := 0 # tandas de humo emitidas (observable por tests)
var _flash := 0.0
var _warning_label: Label
var _stop_x := 0.0

var health: int:
	get:
		return health_component.current_health
var max_health: int:
	get:
		return health_component.max_health
## Compatibilidad con probes de ruta que leen ai_state de todos los actores: el ciclo del vehículo.
var ai_state: int:
	get:
		return phase


func _ready() -> void:
	z_index = 12
	agents_inside = int(config.get("agents", 2))
	visual = Sprite2D.new()
	visual.name = "Visual"
	var texture := load("res://assets/%s.png" % String(config.get("asset", "camioneta3"))) as Texture2D
	var image_scale := float(config.get("scale", 0.8))
	visual.texture = texture
	visual.scale = Vector2.ONE*image_scale
	add_child(visual)
	var bounds := CollisionFactory.opaque_bounds(texture)
	visual.position.y = (texture.get_height()*0.5-bounds.end.y)*image_scale   # pies del vehículo sobre el suelo
	health_component = HEALTH.new()
	health_component.name = "HealthComponent"
	add_child(health_component)
	health_component.configure(int(config.get("health", 6)),int(config.get("health", 6)),float(config.get("hit_immunity", 0.08)))
	health_component.damaged.connect(_on_damaged)
	health_component.depleted.connect(_on_depleted)
	hurtbox = Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.set_script(HURTBOX)
	var shape_node := CollisionShape2D.new()
	shape_node.name = "CollisionShape2D"
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(bounds.size.x*image_scale*0.85,bounds.size.y*image_scale*0.8)
	shape_node.shape = rectangle
	shape_node.position.y = -bounds.size.y*image_scale*0.5
	hurtbox.add_child(shape_node)
	add_child(hurtbox)
	hurtbox.configure(self,health_component,team,0,GameConfig.ENEMY_LAYER)
	_phase_time = float(config.get("warning_time", 1.0))
	_make_warning()


func take_damage(amount: int,source_team: StringName = &"player") -> void:
	if not active or source_team == team:
		return
	health_component.take_damage(amount,source_team)


func get_roof_position() -> Vector2:
	var bounds := CollisionFactory.opaque_bounds(visual.texture)
	return global_position+Vector2(0.0,-bounds.size.y*visual.scale.y*0.9)


func _camera_edges() -> Vector2:
	var camera := get_viewport().get_camera_2d()
	var center: float = camera.get_screen_center_position().x if camera else (target.global_position.x if target else global_position.x)
	var half: float = get_viewport_rect().size.x/(camera.zoom.x if camera else 1.0)*0.5
	return Vector2(center-half,center+half)


func _make_warning() -> void:
	_warning_label = Label.new()
	_warning_label.text = "¡AGENTES!"
	_warning_label.top_level = true
	_warning_label.z_index = 250
	_warning_label.add_theme_font_size_override("font_size",14)
	_warning_label.add_theme_constant_override("outline_size",5)
	_warning_label.add_theme_color_override("font_outline_color",Color.BLACK)
	_warning_label.modulate = Color(1.0,0.3,0.2)
	add_child(_warning_label)
	AudioManager.play_effect("alerta")


func _physics_process(delta: float) -> void:
	if not active:
		return
	_flash = maxf(0.0,_flash-delta)
	if _flash <= 0.0 and visual.modulate != Color.WHITE and phase != Phase.DESTROYED:
		visual.modulate = Color.WHITE
	var edges := _camera_edges()
	match phase:
		Phase.WARNING:
			_warning_label.global_position = Vector2(edges.y-96.0,GameConfig.GROUND_Y-120.0)
			_warning_label.visible = int(_phase_time*6.0)%2 == 0
			_phase_time -= delta
			if _phase_time <= 0.0:
				_warning_label.queue_free()
				phase = Phase.ARRIVING
				_speed = float(config.get("speed", 260.0))
		Phase.ARRIVING:
			_stop_x = edges.y-float(config.get("stop_from_edge", 170.0))
			var remaining := global_position.x-_stop_x
			var brake := maxf(1.0,float(config.get("brake_distance", 220.0)))
			var current := float(config.get("speed", 260.0))*clampf(remaining/brake,0.08,1.0)
			_speed = current
			global_position.x = maxf(_stop_x,global_position.x-current*delta)
			if global_position.x <= _stop_x+1.0:
				phase = Phase.UNLOADING
				_unload_timer = float(config.get("unload_delay", 0.45))
				_phase_time = 0.0
				_speed = 0.0
		Phase.UNLOADING:
			_phase_time += delta
			_unload_timer -= delta
			if agents_released >= agents_inside:
				if _unload_timer <= -float(config.get("leave_delay", 1.4)):
					_begin_leaving()
			elif _unload_timer <= 0.0:
				var agent = dismount_handler.call() if dismount_handler.is_valid() else null
				if agent != null:
					agents_released += 1
					_unload_timer = float(config.get("unload_interval", 0.55))
					_waiting_slot = 0.0
				else:
					_waiting_slot += delta
					_unload_timer = 0.0
					if _waiting_slot >= float(config.get("slot_wait_limit", 6.0)):
						agents_inside = agents_released # sin cupo: nadie más baja y el vehículo se va
		Phase.LEAVING:
			_speed = minf(_speed+float(config.get("speed", 260.0))*delta,float(config.get("speed", 260.0)))
			global_position.x += _speed*delta
			if global_position.x > edges.y+160.0 or global_position.x < edges.x-420.0:
				active = false
				queue_free()
	_update_smoke(delta)


func _begin_leaving() -> void:
	phase = Phase.LEAVING
	visual.flip_h = true # el arte mira a la izquierda: se va marcha atrás hacia el borde por el que llegó
	_speed = 0.0


func _update_smoke(delta: float) -> void:
	if fx == null or phase == Phase.DESTROYED or health > max_health*float(config.get("smoke_ratio", 0.5)):
		return
	_smoke_timer -= delta
	if _smoke_timer <= 0.0:
		_smoke_timer = 0.28
		fx.dust(get_roof_position()+Vector2(randf_range(-18.0,18.0),0.0),2)
		smoke_puffs += 1


func _on_damaged(_amount: int,_current: int,_source) -> void:
	_flash = float(config.get("flash", 0.1))
	visual.modulate = Color(1.0,0.62,0.28)
	AudioManager.play_effect("golpe")


func _on_depleted() -> void:
	active = false
	phase = Phase.DESTROYED
	hurtbox.set_receiving_enabled(false)
	if is_instance_valid(_warning_label):
		_warning_label.queue_free()
	var inside := maxi(0,agents_inside-agents_released) # los agentes que no bajaron mueren con el vehículo
	defeated.emit(int(config.get("points", 150))+inside*int(config.get("agent_points", 100)))
	if fx != null:
		fx.explosion(get_roof_position())
		fx.ground_dust(global_position,6,70.0)
	if destroyed_handler.is_valid():
		destroyed_handler.call(self)
	# Restos: oscurecidos, parpadean y se liberan en ≤ 2 s.
	visual.modulate = Color(0.22,0.2,0.2)
	var wreck := create_tween()
	wreck.tween_interval(float(config.get("wreck_linger", 0.8)))
	var fade := float(config.get("wreck_fade", 0.9))
	wreck.tween_method(func(t: float) -> void:
		if is_instance_valid(visual):
			visual.modulate = Color(0.22,0.2,0.2,(1.0-t)*(1.0 if int(t*fade*CFG.DEATH_BLINK_HZ*2.0)%2 == 0 else 0.3)),0.0,1.0,fade)
	wreck.tween_callback(queue_free)
