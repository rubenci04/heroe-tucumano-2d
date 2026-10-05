extends Node
## Prototype only. Crea manchas (máx. STAIN_MAX, la más vieja se borra) y aplica su efecto a Ciruja:
## velocidad ×STAIN_SLOW y quemadura periódica con destello rojizo.

const CFG = preload("res://scripts/prototype/feel_config.gd")
const STAIN = preload("res://scripts/prototype/coffee_stain.gd")

var world: Node2D
var player: CharacterBody2D
var fx: Node2D
var stains: Array[Node2D] = []
var _base_walk := 0.0
var _base_fury := 0.0
var _burn_timer := CFG.STAIN_BURN_FIRST_DELAY
var _flash := 0.0
var _slowed := false


func setup(world_node: Node2D, player_node: CharacterBody2D, fx_node: Node2D) -> void:
	world = world_node
	player = player_node
	fx = fx_node
	_base_walk = player.walk_speed
	_base_fury = player.fury_speed


func add_stain(position: Vector2) -> void:
	stains = stains.filter(func(s): return is_instance_valid(s))
	while stains.size() >= CFG.STAIN_MAX:
		stains.pop_front().queue_free()
	var stain: Node2D = STAIN.new()
	stain.position = position + Vector2(0.0, CFG.STAIN_OFFSET_Y)
	world.add_child(stain)
	stains.append(stain)


func standing_on_stain() -> bool:
	if not is_instance_valid(player) or player.state == player.State.DEATH or not player.is_on_floor():
		return false
	for stain in stains:
		if is_instance_valid(stain) and stain.covers(player.global_position.x):
			return true
	return false


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var on := standing_on_stain()
	if on != _slowed:
		_slowed = on
		var mult := CFG.STAIN_SLOW if on else 1.0
		player.walk_speed = _base_walk * mult
		player.fury_speed = _base_fury * mult
		if not on:
			_burn_timer = CFG.STAIN_BURN_FIRST_DELAY
	if not on:
		return
	_burn_timer -= delta
	if _burn_timer <= 0.0:
		_burn_timer = CFG.STAIN_BURN_INTERVAL
		_burn()


func _burn() -> void:
	var health: int = player.health
	var floor_health := 0 if CFG.STAIN_CAN_KILL else 1
	if health <= floor_health:
		return
	# Sin pasar por take_damage: la quemadura no aturde ni corta el movimiento de Ciruja.
	player.health_component.set_current_health(maxi(floor_health, health - CFG.STAIN_DAMAGE))
	_flash = CFG.STAIN_BURN_FLASH_TIME
	AudioManager.play_effect("danio")
	if fx != null:
		fx.dust(player.global_position + Vector2(0.0, -4.0), 3)


func _process(delta: float) -> void:
	if _flash <= 0.0 or not is_instance_valid(player):
		return
	_flash -= delta
	if player.state != player.State.DEATH:
		var tint := CFG.STAIN_BURN_FLASH_COLOR
		player.visual.modulate = Color(tint.r, tint.g, tint.b, player.visual.modulate.a)
